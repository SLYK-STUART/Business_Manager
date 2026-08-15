import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'app_lock_controller.dart';

Future<void> performLogout(BuildContext context, WidgetRef ref) async {
  await ref.read(apiClientProvider).clearTokens();
  ref.invalidate(apiClientProvider); // cascades to every provider that watches it
  ref.read(appLockProvider.notifier).unlock();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
  }
}