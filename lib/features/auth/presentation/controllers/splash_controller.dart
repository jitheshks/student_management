import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_management/features/auth/presentation/providers/auth_providers.dart';
import 'package:student_management/shared/models/user_entity.dart';

class SplashNavigationTarget {
  final String routeName;
  final Object? arguments;

  const SplashNavigationTarget({required this.routeName, this.arguments});
}

final splashNavigationProvider =
    FutureProvider.autoDispose<SplashNavigationTarget>((ref) async {
      // Splash branding / animation delay
      await Future.delayed(const Duration(milliseconds: 1800));

      final authRepository = ref.watch(authRepositoryProvider);
      final currentUser = await authRepository.getCurrentUser();

      if (currentUser == null) {
        return const SplashNavigationTarget(routeName: '/loginScreen');
      }

      switch (currentUser.role) {
        case UserRole.admin:
          return const SplashNavigationTarget(routeName: '/adminDashboard');
        case UserRole.staff:
          return const SplashNavigationTarget(routeName: '/staffDashboard');
        case UserRole.student:
          return SplashNavigationTarget(
            routeName: '/studentDashboard',
            arguments: {'studentId': currentUser.id},
          );
      }
    });
