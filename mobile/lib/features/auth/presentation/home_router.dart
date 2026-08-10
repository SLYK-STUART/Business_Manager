import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => const Scaffold(body: Center(child: Text("Failed to load user"))),
      data: (user) {
        if (user["has_passcode"] != true) {
          _navigateOnce("/set_passcode");
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final roles = user["roles"] as List<dynamic>;
        final route = RoleGuard.homeRouteFor(roles);
        ref.read(fcmServiceProvider).registerToken();
        _navigateOnce(route);

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}