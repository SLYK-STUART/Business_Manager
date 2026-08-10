import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/auth/app_lock_controller.dart';
import '../../../core/theme/app_colors.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passcodeController = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final supported = await ref.read(biometricSupportProvider.future);
    if (!supported) return;
    final auth = LocalAuthentication();
    try {
      final didAuth = await auth.authenticate(
        localizedReason: "Unlock Business Manager",
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (didAuth) {
        ref.read(appLockProvider.notifier).unlock();
      }
    } catch (_) {
      // fall through to passcode entry
    }
  }

  Future<void> _submitPasscode() async {
    setState(() { _checking = true; _error = null; });
    final ok = await ref.read(lockRepositoryProvider).verifyPasscode(_passcodeController.text);
    if (ok) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      setState(() => _error = "Incorrect passcode");
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text("Locked", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: "••••",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checking ? null : _submitPasscode,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _checking ? const CircularProgressIndicator() : const Text("Unlock"),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _tryBiometric,
                child: const Text("Use biometrics", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}