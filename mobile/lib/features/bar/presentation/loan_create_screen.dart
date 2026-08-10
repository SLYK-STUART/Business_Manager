import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/item_providers.dart';
import '../domain/loan_providers.dart';
import '../domain/cart_provider.dart';

class LoanCreateScreen extends ConsumerStatefulWidget {
  const LoanCreateScreen({super.key});

  @override
  ConsumerState<LoanCreateScreen> createState() => _LoanCreateScreenState();
}

class _LoanCreateScreenState extends ConsumerState<LoanCreateScreen> {
  dynamic _selectedItem;
  final _qtyController = TextEditingController(text: '1');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _duplicateFlag = false;
  bool _submitting = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _duplicateFlag = false);
      return;
    }
    final dup = await ref
        .read(loanRepositoryProvider)
        .checkPhoneDuplicate(_phoneController.text.trim());
    if (mounted) setState(() => _duplicateFlag = dup);
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? errorText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
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
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOnLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? AppColors.error : AppColors.borderOnLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? AppColors.error : AppColors.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'New Loan',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Item selector ───────────────────────────────────
                    itemsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Failed to load items: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (items) => DropdownButtonFormField(
                        value: _selectedItem,
                        decoration: _fieldDecoration(
                          label: 'Item',
                          prefixIcon: Icons.inventory_2_outlined,
                        ),
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                        items: items
                            .map<DropdownMenuItem>(
                              (i) => DropdownMenuItem(
                            value: i,
                            child: Text(i['name'] ?? 'Unnamed'),
                          ),
                        )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedItem = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quantity ────────────────────────────────────────
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnLight,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Quantity',
                        hint: '1',
                        prefixIcon: Icons.numbers_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Customer section ────────────────────────────────
                    const Text(
                      'CUSTOMER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryOnLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnLight,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Customer name',
                        hint: 'Full name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnLight,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Phone',
                        hint: 'Required if no fingerprint',
                        errorText: _duplicateFlag
                            ? 'This number is already on the loans list — check before proceeding'
                            : null,
                        prefixIcon: Icons.phone_outlined,
                      ),
                      onEditingComplete: _checkPhone,
                      onChanged: (_) {
                        if (_duplicateFlag) {
                          setState(() => _duplicateFlag = false);
                        }
                      },
                    ),

                    if (_duplicateFlag) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.35),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Duplicate phone detected. Confirm this is intentional before creating the loan.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.warning,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Sticky bottom button ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderOnLight.withOpacity(0.6),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
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
                    'Create Loan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedItem == null || _nameController.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      final customer = await ref.read(loanRepositoryProvider).createCustomer(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      await ref.read(saleRepositoryProvider).createSale([
        {
          'item_id': _selectedItem['id'],
          'quantity': int.parse(_qtyController.text),
          'payment_status': 'loan',
          'customer_id': customer['id'],
        }
      ]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan created successfully'),
            backgroundColor: AppColors.success,
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