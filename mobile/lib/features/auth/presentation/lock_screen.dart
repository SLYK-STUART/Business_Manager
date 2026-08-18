import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _passcodeFocus = FocusNode();

  String? _error;
  bool _checking = false;
  bool _obscure = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricSupport();
      _tryBiometric();
    });
  }

  Future<void> _checkBiometricSupport() async {
    final supported = await ref.read(biometricSupportProvider.future);
    if (mounted) {
      setState(() => _biometricAvailable = supported);
    }
  }

  Future<void> _tryBiometric() async {
    if (!_biometricAvailable) return;

    final auth = LocalAuthentication();
    try {
      final didAuth = await auth.authenticate(
        localizedReason: 'Unlock Business Manager',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuth && mounted) {
        ref.read(appLockProvider.notifier).unlock();
      }
    } catch (_) {
      // Fall through to passcode entry
    }
  }

  Future<void> _submitPasscode() async {
    final code = _passcodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter your passcode');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final ok = await ref.read(lockRepositoryProvider).verifyPasscode(code);

      if (ok) {
        ref.read(appLockProvider.notifier).unlock();
      } else {
        _passcodeController.clear();
        _passcodeFocus.unfocus();
        setState(() => _error = 'Incorrect passcode');

        // Refocus on the next frame, after the IME has actually torn down —
        // fixes a known Samsung/Android keyboard bug where the old digits'
        // composing state survives a plain controller.clear().
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _passcodeFocus.requestFocus();
        });
      }
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    _passcodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surfaceDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceDark,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Brand header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.textOnPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'App Locked',
                      style: GoogleFonts.sora(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your passcode or use biometrics\nto unlock Business Manager',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textOnDark.withOpacity(0.65),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Form sheet ────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      36,
                      24,
                      24 + bottomInset + (keyboardInset > 0 ? 12 : 0),
                    ),
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PASSCODE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Passcode field
                        TextField(
                          controller: _passcodeController,
                          focusNode: _passcodeFocus,
                          obscureText: _obscure,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableIMEPersonalizedLearning: false,
                          onSubmitted: (_) => _submitPasscode(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 12,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.surface,
                            hintText: '••••',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textHint,
                              fontSize: 24,
                              letterSpacing: 12,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _obscure = !_obscure);
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                              const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                              const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Unlock button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _checking ? null : _submitPasscode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _checking
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                                : Text(
                              'Unlock',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        // Biometrics
                        if (_biometricAvailable) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton.icon(
                              onPressed: _checking ? null : _tryBiometric,
                              icon: const Icon(
                                Icons.fingerprint_rounded,
                                size: 22,
                              ),
                              label: Text(
                                'Use biometrics',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}