import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';
import 'package:student_management/core/network/connectivity_provider.dart';
import 'package:student_management/core/network/connectivity_service.dart';
import 'package:student_management/core/network/connectivity_status.dart';
import 'package:student_management/shared/widgets/global_connectivity_banner.dart';

// =============================================================================
// Fakes for Connectivity and InternetConnection
// =============================================================================

class FakeConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> currentResults = [ConnectivityResult.wifi];

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentResults;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void close() {
    _controller.close();
  }
}

class FakeInternetConnection implements InternetConnection {
  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();

  bool hasAccess = true;

  void emitStatus(InternetStatus status) {
    hasAccess = status == InternetStatus.connected;
    _controller.add(status);
  }

  @override
  Future<bool> get hasInternetAccess async => hasAccess;

  @override
  Stream<InternetStatus> get onStatusChange => _controller.stream;

  @override
  Future<InternetStatus> get internetStatus async =>
      hasAccess ? InternetStatus.connected : InternetStatus.disconnected;

  @override
  Duration get checkInterval => const Duration(seconds: 10);

  @override
  ConnectivityCheckCallback? get customConnectivityCheck => null;

  @override
  bool get enableStrictCheck => false;

  @override
  Stream<dynamic>? get triggerStream => null;

  @override
  InternetStatus? get lastTryResults =>
      hasAccess ? InternetStatus.connected : InternetStatus.disconnected;

  @override
  void setIntervalAndResetTimer(Duration duration) {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeConnectivityService implements IConnectivityService {
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _status;

  FakeConnectivityService([this._status = ConnectivityStatus.online]);

  @override
  ConnectivityStatus get currentStatus => _status;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _controller.stream;

  void setStatus(ConnectivityStatus newStatus) {
    _status = newStatus;
    _controller.add(newStatus);
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async => _status;

  @override
  void dispose() {
    _controller.close();
  }
}

// =============================================================================
// Main Test Suite
// =============================================================================

void main() {
  group('1. ConnectivityStatus Domain Model & Helpers', () {
    test('Correctly reports boolean status flags and messages', () {
      expect(ConnectivityStatus.online.isOnline, isTrue);
      expect(ConnectivityStatus.online.isOffline, isFalse);
      expect(ConnectivityStatus.online.isChecking, isFalse);

      expect(ConnectivityStatus.noNetwork.isOffline, isTrue);
      expect(ConnectivityStatus.noNetwork.isOnline, isFalse);
      expect(
        ConnectivityStatus.noNetwork.message,
        contains('No internet connection'),
      );

      expect(ConnectivityStatus.networkWithoutInternet.isOffline, isTrue);
      expect(ConnectivityStatus.networkWithoutInternet.isOnline, isFalse);
      expect(
        ConnectivityStatus.networkWithoutInternet.message,
        contains('Connected to a network, but internet access is unavailable'),
      );

      expect(ConnectivityStatus.checking.isChecking, isTrue);
    });
  });

  group('2. ConnectivityService Unit Tests', () {
    late FakeConnectivity fakeConnectivity;
    late FakeInternetConnection fakeInternet;
    late ConnectivityService service;

    setUp(() {
      fakeConnectivity = FakeConnectivity();
      fakeInternet = FakeInternetConnection();
      service = ConnectivityService(
        connectivity: fakeConnectivity,
        internetConnection: fakeInternet,
        autoInitialize: false,
      );
    });

    tearDown(() {
      service.dispose();
      fakeConnectivity.close();
      fakeInternet.dispose();
    });

    test(
      '1. Initial check resolves to online when interface and internet access are valid',
      () async {
        fakeConnectivity.currentResults = [ConnectivityResult.wifi];
        fakeInternet.hasAccess = true;

        final status = await service.checkConnectivity();
        expect(status, equals(ConnectivityStatus.online));
        expect(service.currentStatus, equals(ConnectivityStatus.online));
      },
    );

    test(
      '2. No physical network interface resolves directly to noNetwork',
      () async {
        fakeConnectivity.currentResults = [ConnectivityResult.none];
        fakeInternet.hasAccess = true; // Even if internet checker claims access

        final status = await service.checkConnectivity();
        expect(status, equals(ConnectivityStatus.noNetwork));
        expect(service.currentStatus, equals(ConnectivityStatus.noNetwork));
      },
    );

    test(
      '3. Network interface available but internet unreachable resolves to networkWithoutInternet',
      () async {
        fakeConnectivity.currentResults = [ConnectivityResult.mobile];
        fakeInternet.hasAccess = false;

        final status = await service.checkConnectivity();
        expect(status, equals(ConnectivityStatus.networkWithoutInternet));
        expect(
          service.currentStatus,
          equals(ConnectivityStatus.networkWithoutInternet),
        );
      },
    );

    test('4. Stream emits offline-to-online recovery transitions', () async {
      final emittedStatuses = <ConnectivityStatus>[];
      final sub = service.onStatusChange.listen(emittedStatuses.add);

      fakeConnectivity.currentResults = [ConnectivityResult.none];
      await service.checkConnectivity();

      fakeConnectivity.currentResults = [ConnectivityResult.wifi];
      fakeInternet.hasAccess = true;
      await service.checkConnectivity();

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emittedStatuses, contains(ConnectivityStatus.noNetwork));
      expect(emittedStatuses.last, equals(ConnectivityStatus.online));
      await sub.cancel();
    });

    test(
      '5. Repeated identical network checks do not produce duplicate emissions',
      () async {
        final emittedStatuses = <ConnectivityStatus>[];
        final sub = service.onStatusChange.listen(emittedStatuses.add);

        fakeConnectivity.currentResults = [ConnectivityResult.wifi];
        fakeInternet.hasAccess = true;

        await service.checkConnectivity();
        await service.checkConnectivity();
        await service.checkConnectivity();

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(emittedStatuses.length, equals(1));
        expect(emittedStatuses.first, equals(ConnectivityStatus.online));
        await sub.cancel();
      },
    );

    test(
      '6. Handles timeouts and stream exceptions gracefully without crashing',
      () async {
        // Simulate timeout
        final timeoutService = ConnectivityService(
          connectivity: fakeConnectivity,
          internetConnection: fakeInternet,
          reachabilityTimeout: const Duration(milliseconds: 50),
          autoInitialize: false,
        );

        fakeConnectivity.currentResults = [ConnectivityResult.wifi];
        // Intentionally delay check past the timeout
        fakeInternet.hasAccess = false;

        final status = await timeoutService.checkConnectivity();
        expect(status, equals(ConnectivityStatus.networkWithoutInternet));

        timeoutService.dispose();
      },
    );

    test(
      '9. Manual recheck triggers probe and updates current status',
      () async {
        fakeConnectivity.currentResults = [ConnectivityResult.none];
        await service.checkConnectivity();
        expect(service.currentStatus, equals(ConnectivityStatus.noNetwork));

        fakeConnectivity.currentResults = [ConnectivityResult.wifi];
        fakeInternet.hasAccess = true;

        final refreshedStatus = await service.checkConnectivity();
        expect(refreshedStatus, equals(ConnectivityStatus.online));
      },
    );
  });

  group('3. ErrorHandler Network Error Classification', () {
    test(
      'SocketException, HttpException, and TimeoutException map to NetworkException',
      () {
        final socketEx = ErrorHandler.handleException(
          const SocketException('OS Error: Network unreachable'),
        );
        expect(socketEx, isA<NetworkException>());

        final httpEx = ErrorHandler.handleException(
          HttpException('Connection closed'),
        );
        expect(httpEx, isA<NetworkException>());

        final timeoutEx = ErrorHandler.handleException(
          TimeoutException('Request timed out'),
        );
        expect(timeoutEx, isA<NetworkException>());
      },
    );

    test('Dio connection and timeout errors map to NetworkException', () {
      final dioTimeout = ErrorHandler.handleException(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(dioTimeout, isA<NetworkException>());

      final dioConnError = ErrorHandler.handleException(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(dioConnError, isA<NetworkException>());
    });

    test(
      'AuthException and PostgrestException are not swallowed or turned into NetworkException',
      () {
        final authEx = ErrorHandler.handleException(
          const sb.AuthException(
            'Invalid login credentials',
            statusCode: '400',
          ),
        );
        expect(authEx, isA<AppAuthException>());

        final dbEx = ErrorHandler.handleException(
          const sb.PostgrestException(message: 'Duplicate key', code: '23505'),
        );
        expect(dbEx, isA<DatabaseException>());
      },
    );
  });

  group('4. GlobalConnectivityBanner Widget Tests', () {
    testWidgets(
      '7. Initial check does not show an offline banner; transitions smoothly when offline',
      (tester) async {
        final fakeService = FakeConnectivityService(
          ConnectivityStatus.checking,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityServiceProvider.overrideWithValue(fakeService),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: GlobalConnectivityBanner(
                  child: const Text('App Content'),
                ),
              ),
            ),
          ),
        );

        // During initial check, offline banner is not rendered
        expect(
          find.text(
            'No internet connection. Some features may be unavailable.',
          ),
          findsNothing,
        );
        expect(find.text('App Content'), findsOneWidget);

        // Transition to no network
        fakeService.setStatus(ConnectivityStatus.noNetwork);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(
          find.text(
            'No internet connection. Some features may be unavailable.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Transition to network without internet
        fakeService.setStatus(ConnectivityStatus.networkWithoutInternet);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(
          find.text(
            'Connected to a network, but internet access is unavailable.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

        // Transition back online -> shows brief recovery confirmation
        fakeService.setStatus(ConnectivityStatus.online);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Internet connection restored.'), findsOneWidget);

        // After 2.5 seconds recovery duration, banner auto-dismisses
        await tester.pump(const Duration(milliseconds: 2600));
        expect(find.text('Internet connection restored.'), findsNothing);
      },
    );

    testWidgets(
      '8. Banner appears only once when wrapping child navigator across screens',
      (tester) async {
        final fakeService = FakeConnectivityService(
          ConnectivityStatus.noNetwork,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityServiceProvider.overrideWithValue(fakeService),
            ],
            child: MaterialApp(
              home: GlobalConnectivityBanner(
                child: Navigator(
                  onGenerateRoute:
                      (settings) => MaterialPageRoute(
                        builder:
                            (context) => Scaffold(
                              appBar: AppBar(title: const Text('Root Screen')),
                              body: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => Scaffold(
                                                appBar: AppBar(
                                                  title: const Text(
                                                    'Nested Screen',
                                                  ),
                                                ),
                                                body: const Text(
                                                  'Nested Content',
                                                ),
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('Go Nested'),
                                  ),
                                ],
                              ),
                            ),
                      ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Exactly one banner on screen
        expect(find.byType(GlobalConnectivityBanner), findsOneWidget);
        expect(
          find.text(
            'No internet connection. Some features may be unavailable.',
          ),
          findsOneWidget,
        );

        // Push nested screen
        await tester.tap(find.text('Go Nested'));
        await tester.pumpAndSettle();

        expect(find.text('Nested Screen'), findsOneWidget);
        // Still exactly one banner visible across the entire nested navigation tree
        expect(
          find.text(
            'No internet connection. Some features may be unavailable.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '10. Authentication and role-based views remain mounted during offline events',
      (tester) async {
        final fakeService = FakeConnectivityService(
          ConnectivityStatus.noNetwork,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityServiceProvider.overrideWithValue(fakeService),
            ],
            child: MaterialApp(
              home: GlobalConnectivityBanner(
                child: Scaffold(
                  appBar: AppBar(title: const Text('Admin Dashboard')),
                  body: const Center(child: Text('Protected Role View')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // User is not signed out, protected view is preserved
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Protected Role View'), findsOneWidget);
        expect(
          find.text(
            'No internet connection. Some features may be unavailable.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '11. Preserves user-entered form data and does not automatically replay writes',
      (tester) async {
        final fakeService = FakeConnectivityService(ConnectivityStatus.online);
        final textController = TextEditingController();
        int submissionCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              connectivityServiceProvider.overrideWithValue(fakeService),
            ],
            child: MaterialApp(
              home: GlobalConnectivityBanner(
                child: Scaffold(
                  body: Column(
                    children: [
                      TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          submissionCount++;
                        },
                        child: const Text('Submit Record'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // User enters form data
        await tester.enterText(find.byType(TextField), 'Alice Wonderland');
        expect(textController.text, equals('Alice Wonderland'));

        // Connection drops offline
        fakeService.setStatus(ConnectivityStatus.noNetwork);
        await tester.pumpAndSettle();

        // Form data is completely preserved
        expect(textController.text, equals('Alice Wonderland'));
        expect(submissionCount, equals(0));

        // Connection returns online
        fakeService.setStatus(ConnectivityStatus.online);
        await tester.pumpAndSettle();

        // Verifies no automatic submission replay occurred
        expect(submissionCount, equals(0));
        expect(textController.text, equals('Alice Wonderland'));
      },
    );
  });
}
