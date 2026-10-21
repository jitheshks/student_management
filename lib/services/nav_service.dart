import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:student_management/core/routing/app_router.dart';

class NavService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    final ctx = context;
    if (ctx != null) {
      return ctx.push<T>(location, extra: extra);
    }
    return appRouter.push<T>(location, extra: extra);
  }

  static void go(String location, {Object? extra}) {
    final ctx = context;
    if (ctx != null) {
      ctx.go(location, extra: extra);
    } else {
      appRouter.go(location, extra: extra);
    }
  }

  static void pushReplacement(String location, {Object? extra}) {
    final ctx = context;
    if (ctx != null) {
      ctx.pushReplacement(location, extra: extra);
    } else {
      appRouter.pushReplacement(location, extra: extra);
    }
  }

  static void pop<T extends Object?>([T? result]) {
    final ctx = context;
    if (ctx != null) {
      ctx.pop(result);
    } else {
      appRouter.pop(result);
    }
  }

  // Backward compatibility helpers for legacy Navigator callers
  static Future<T?> pushNamed<T extends Object?>(String location, {Object? arguments}) {
    return push<T>(location, extra: arguments);
  }

  static void pushReplacementNamed(String location, {Object? arguments}) {
    pushReplacement(location, extra: arguments);
  }

  static void pushNamedAndRemoveUntil(String location, {Object? arguments}) {
    go(location, extra: arguments);
  }
}
