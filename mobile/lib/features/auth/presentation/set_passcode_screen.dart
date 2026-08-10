import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/app_lock_controller.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class SetPasscodeScreen extends ConsumerStatefulWidget {
  final bool isFirstSetup;
  const SetPasscodeScreen({super.key, this.isFirstSetup = false});

  @override
  ConsumerState<SetPasscodeScreen> createState() => _SetPasscodeScreenState();
}

class _SetPasscodeScreenState extends ConsumerState<SetPasscodeScreen> {
  final _passcodeController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _passcodeController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _passcodeController.text.trim();
    final confirm = _confirmController.text.trim();

    if (code.length < 4 || code.length > 6) {
      setState(() => _error = "Passcode must be 4–6 digits");
      return;
    }
    if (code != confirm) {
      setState(() => _error = "Passcodes don't match");
      return;
    }

    setState(() { _submitting = true; _error = null; });
    try {
      await ref.read(lockRepositoryProvider).setPasscode(code);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        if (widget.isFirstSetup) {
          Navigator.of(context).pushReplacementNamed("/home");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passcode updated")));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _error = "Failed to set passcode: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: widget.isFirstSetup
          ? null
          : AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Change Passcode", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                Text(
                  widget.isFirstSetup ? "Set Up Your Passcode" : "Choose a New Passcode",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "You'll use this to unlock the app. It follows your account, so it works even if you switch devices.",
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _passcodeController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 6),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "New passcode",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, letterSpacing: 0),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 6),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Confirm passcode",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, letterSpacing: 0),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                    ),
                    child: _submitting
                        ? const CircularProgressIndicator()
                        : Text(widget.isFirstSetup ? "Set Passcode" : "Update Passcode", style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (widget.isFirstSetup) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed("/home"),
                    child: Text("Skip for now", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}