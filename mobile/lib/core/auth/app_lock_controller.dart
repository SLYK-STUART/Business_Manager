import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'lock_repository.dart';
import 'auth_provider.dart';

final lockRepositoryProvider = Provider((ref) => LockRepository(ref.watch(apiClientProvider)));

enum AppLockState { unlocked, locked }

class AppLockController extends StateNotifier<AppLockState> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  static const _graceDuration = Duration(minutes: 2);
  final _storage = const FlutterSecureStorage();

  AppLockController() : super(AppLockState.locked) {
    WidgetsBinding.instance.addObserver(this);
    _initLockState();
  }

  Future<void> _initLockState() async {
    final token = await _storage.read(key: "access_token");
    state = token != null ? AppLockState.locked: AppLockState.unlocked;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused || lifecycleState == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        if (elapsed > _graceDuration) {
          state = AppLockState.locked;
        }
        _backgroundedAt = null;
      }
    }
  }

  void lockNow() => state = AppLockState.locked;
  void unlock() => state = AppLockState.unlocked;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final appLockProvider = StateNotifierProvider<AppLockController, AppLockState>((ref) => AppLockController());

final biometricSupportProvider = FutureProvider((ref) async {
  final auth = LocalAuthentication();
  final canCheck = await auth.canCheckBiometrics;
  final isSupported = await auth.isDeviceSupported();
  return canCheck && isSupported;
});