import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/nbt_repository.dart';

final nbtRepositoryProvider = Provider(
      (ref) => NbtRepository(ref.watch(apiClientProvider)),
);

final nbtListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(nbtRepositoryProvider).list();
});

class NonBusinessTransactionScreen extends ConsumerStatefulWidget {
  const NonBusinessTransactionScreen({super.key});

  @override
  ConsumerState<NonBusinessTransactionScreen> createState() =>
      _NonBusinessTransactionScreenState();
}

class _NonBusinessTransactionScreenState
    extends ConsumerState<NonBusinessTransactionScreen> {
  String _direction = 'out';
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceMuted,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondaryOnLight, size: 20)
          : null,
      labelStyle: const TextStyle(
        color: AppColors.textSecondaryOnLight,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOnLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOnLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(nbtListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Non-Business Transaction',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: Column(
        children: [
          // ── Form section ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderOnLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOnLight,
                  ),
                ),
                const SizedBox(height: 16),

                // Direction selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'out',
                      label: Text('Money Out'),
                      icon: Icon(Icons.arrow_upward_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 'in',
                      label: Text('Money In'),
                      icon: Icon(Icons.arrow_downward_rounded, size: 18),
                    ),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (s) => setState(() => _direction = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return AppColors.surfaceMuted;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.textOnPrimary;
                      }
                      return AppColors.textSecondaryOnLight;
                    }),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: AppColors.borderOnLight),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOnLight,
                  ),
                  decoration: _fieldDecoration(
                    label: 'Amount (UGX)',
                    hint: '0.00',
                    prefixIcon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                TextField(
                  controller: _descController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryOnLight,
                  ),
                  decoration: _fieldDecoration(
                    label: 'Description',
                    hint: 'e.g. Staff lunch, Office supplies…',
                    prefixIcon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                        : const Text(
                      'Log Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Recent list header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOnLight,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                listAsync.maybeWhen(
                  data: (items) => Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOnLight,
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Transactions list ───────────────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(nbtListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final txn = items[i];
                      final isOut = txn['direction'] == 'out';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderOnLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Direction icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (isOut ? AppColors.error : AppColors.success)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isOut
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 20,
                                color: isOut ? AppColors.error : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Description + date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    txn['description'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    txn['created_at'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount
                            Text(
                              '${isOut ? '−' : '+'}UGX ${txn['amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isOut ? AppColors.error : AppColors.success,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_amountController.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(nbtRepositoryProvider).create(
        _direction,
        double.parse(_amountController.text),
        _descController.text.trim(),
      );
      ref.invalidate(nbtListProvider);
      _amountController.clear();
      _descController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged — pending owner approval'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}