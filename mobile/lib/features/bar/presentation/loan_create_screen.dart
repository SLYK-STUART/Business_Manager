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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();
  bool _duplicateFlag = false;
  bool _submitting = false;
  bool _searching = false;
  String _query = '';

  // Local cart for this screen: itemId → {item, quantity}
  final Map<String, Map<String, dynamic>> _selected = {};

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _stockOf(dynamic item) {
    final raw = item['current_stock'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  int _qtyOf(String itemId) => _selected[itemId]?['quantity'] as int? ?? 0;

  void _setQty(dynamic item, int qty) {
    final id = item['id'].toString();
    final stock = _stockOf(item);

    if (qty <= 0) {
      setState(() => _selected.remove(id));
      return;
    }

    final clamped = qty.clamp(1, stock);
    setState(() {
      _selected[id] = {
        'item': item,
        'quantity': clamped,
      };
    });
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
    final selectedCount = _selected.length;
    final totalQty = _selected.values
        .fold<int>(0, (sum, e) => sum + (e['quantity'] as int));

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
        actions: [
          IconButton(
            icon: Icon(
              _searching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textSecondaryOnLight,
            ),
            onPressed: () {
              setState(() {
                if (_searching) {
                  _searchController.clear();
                  _query = '';
                }
                _searching = !_searching;
              });
            },
          ),
        ],
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
                    // ── Search bar (when active) ────────────────────────
                    if (_searching) ...[
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Search items',
                          hint: 'Type item name...',
                          prefixIcon: Icons.search_rounded,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Selected summary ────────────────────────────────
                    if (selectedCount > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$selectedCount item${selectedCount == 1 ? '' : 's'} · Qty $totalQty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _selected.clear()),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Item list ───────────────────────────────────────
                    const Text(
                      'SELECT ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryOnLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),

                    itemsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
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
                      data: (items) {
                        final filtered = _query.isEmpty
                            ? items
                            : items
                            .where((it) => (it['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                            .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                _query.isEmpty
                                    ? 'No items available'
                                    : 'No items match "$_query"',
                                style: const TextStyle(
                                  color: AppColors.textSecondaryOnLight,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final id = item['id'].toString();
                            final name = item['name']?.toString() ?? 'Unnamed';
                            final stock = _stockOf(item);
                            final qty = _qtyOf(id);
                            final selected = qty > 0;
                            final canIncrease = qty < stock;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary.withOpacity(0.4)
                                      : AppColors.borderOnLight,
                                  width: selected ? 1.5 : 1,
                                ),
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
                                  // Icon
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary.withOpacity(0.12)
                                          : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textSecondaryOnLight,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name + stock
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppColors.textPrimaryOnLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Stock: $stock',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: stock == 0
                                                ? AppColors.error
                                                : AppColors.textSecondaryOnLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity controls
                                  if (stock > 0)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceMuted,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            visualDensity:
                                            VisualDensity.compact,
                                            icon: const Icon(
                                                Icons.remove_rounded,
                                                size: 18),
                                            color: qty > 0
                                                ? AppColors.textPrimaryOnLight
                                                : AppColors
                                                .textSecondaryOnLight
                                                .withOpacity(0.3),
                                            onPressed: qty > 0
                                                ? () =>
                                                _setQty(item, qty - 1)
                                                : null,
                                          ),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '$qty',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: AppColors
                                                    .textPrimaryOnLight,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity:
                                            VisualDensity.compact,
                                            icon: const Icon(Icons.add_rounded,
                                                size: 18),
                                            color: canIncrease
                                                ? AppColors.primary
                                                : AppColors
                                                .textSecondaryOnLight
                                                .withOpacity(0.3),
                                            onPressed: canIncrease
                                                ? () =>
                                                _setQty(item, qty + 1)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const Text(
                                      'Out of stock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 28),

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
                  onPressed: (_submitting || selectedCount == 0)
                      ? null
                      : _submit,
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
                      : Text(
                    selectedCount == 0
                        ? 'Select items'
                        : 'Create Loan · $totalQty item${totalQty == 1 ? '' : 's'}',
                    style: const TextStyle(
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
    if (_selected.isEmpty || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one item and enter customer name'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final customer = await ref.read(loanRepositoryProvider).createCustomer(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      final lineItems = _selected.values.map((e) {
        final item = e['item'];
        return {
          'item_id': item['id'],
          'quantity': e['quantity'],
          'payment_status': 'loan',
          'customer_id': customer['id'],
        };
      }).toList();

      await ref.read(saleRepositoryProvider).createSale(lineItems);

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