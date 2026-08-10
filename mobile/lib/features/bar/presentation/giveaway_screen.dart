import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/item_providers.dart';
import '../data/giveaway_repository.dart';

final giveawayRepositoryProvider = Provider((ref) => GiveawayRepository(ref.watch(apiClientProvider)));

class GiveawayScreen extends ConsumerStatefulWidget {
  const GiveawayScreen({super.key});

  @override
  ConsumerState<GiveawayScreen> createState() => _GiveawayScreenState();
}

class _GiveawayScreenState extends ConsumerState<GiveawayScreen> {
  dynamic _selectedItem;
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedItem != null && _nameController.text.trim().isNotEmpty;

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
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Free / Unpaid Giveaway',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
                    // ── Heads-up banner ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.card_giftcard_rounded, size: 18, color: AppColors.warning),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'This logs stock leaving without payment. It will be recorded as a giveaway and needs owner approval.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.warning, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Item selector ─────────────────────────────────────
                    Text(
                      'Item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    itemsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Failed to load items: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (items) => DropdownButtonFormField(
                        value: _selectedItem,
                        decoration: _fieldDecoration(
                          label: 'Select item',
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

                    // ── Selected item preview ─────────────────────────────
                    if (_selectedItem != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOnLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                size: 17,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedItem['name'] ?? 'Unnamed',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimaryOnLight,
                                ),
                              ),
                            ),
                            if (_selectedItem['current_stock'] != null)
                              Text(
                                '${_selectedItem['current_stock']} in stock',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryOnLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Recipient name ────────────────────────────────────
                    Text(
                      'Recipient',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: AppColors.textPrimaryOnLight,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _fieldDecoration(
                        label: 'Recipient name',
                        hint: 'Who is this going to?',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom button ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(color: AppColors.borderOnLight.withOpacity(0.6)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_submitting || !_canSubmit) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
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
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.card_giftcard_rounded, size: 19),
                      SizedBox(width: 8),
                      Text(
                        'Give Away',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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
      await ref.read(giveawayRepositoryProvider).createGiveaway(
        _selectedItem['id'],
        _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giveaway logged — pending owner approval'),
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