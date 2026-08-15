import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/app_lock_controller.dart';
import 'package:mobile/features/auth/presentation/splash_screen.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/role_guard.dart';

class HomeRouter extends ConsumerStatefulWidget {
  const HomeRouter({super.key});

  @override
  ConsumerState<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends ConsumerState<HomeRouter> {
  bool _navigated = false;

  void _navigateOnce(String route) {
    if (_navigated) return;
    _navigated = true;
    debugPrint('HomeRouter scheduling navigation to $route');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('HomeRouter postFrameCallback firing, mounted=$mounted');
      if (mounted) Navigator.of(context).pushReplacementNamed(route);
      debugPrint('HomeRouter pushReplacementNamed call completed');
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeRouter build, userAsync state...');
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const SplashScreen(),
      error: (err, _) {
        _navigateOnce("/login");
        return const SplashScreen();
      },
      data: (user) {
        if (user["has_passcode"] != true) {
          ref.read(appLockProvider.notifier).unlock();
          _navigateOnce("/set_passcode");
          return const SplashScreen();
        }

        final roles = user["roles"] as List<dynamic>;
        final route = RoleGuard.homeRouteFor(roles);
        ref.read(fcmServiceProvider).registerToken();
        _navigateOnce(route);

        return const SplashScreen();
      },
    );
  }
}