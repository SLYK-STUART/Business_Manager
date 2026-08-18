import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/pending_pricing_providers.dart';

class PendingPricingScreen extends ConsumerStatefulWidget {
  const PendingPricingScreen({super.key});

  @override
  ConsumerState<PendingPricingScreen> createState() =>
      _PendingPricingScreenState();
}

class _PendingPricingScreenState extends ConsumerState<PendingPricingScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(pendingPricingListProvider);
    final bottomClearance = MediaQuery.of(context).padding.bottom + 90;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: listAsync.maybeWhen(
          data: (items) => Text(
            items.isEmpty
                ? 'Set Buying Prices'
                : 'Set Buying Prices · ${items.length}',
            style: const TextStyle(
              color: AppColors.textPrimaryOnLight,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
          orElse: () => const Text(
            'Set Buying Prices',
            style: TextStyle(
              color: AppColors.textPrimaryOnLight,
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: listAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: AppColors.success,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nothing pending',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOnLight,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All restocks are priced',
                      style: TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _query.isEmpty
              ? items
              : items.where((e) {
            final name =
            (e['item_name']?.toString() ?? '').toLowerCase();
            final by =
            (e['restocked_by']?.toString() ?? '').toLowerCase();
            final q = _query.toLowerCase();
            return name.contains(q) || by.contains(q);
          }).toList();

          return Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnLight,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search item or restocked by…',
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondaryOnLight,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(pendingPricingListProvider),
                  child: filtered.isEmpty
                      ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          'No matches for “$_query”',
                          style: const TextStyle(
                            color: AppColors.textSecondaryOnLight,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                      : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        20, 4, 20, bottomClearance),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      final qty = entry['quantity'];
                      final by = entry['restocked_by'] ?? 'Unknown';
                      final dateRaw = entry['created_at'] ??
                          entry['restocked_at'] ??
                          entry['date'];
                      final dateLabel = _formatDate(dateRaw);

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _showPriceSheet(context, ref, entry),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderOnLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withOpacity(0.12),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.sell_outlined,
                                    size: 18,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['item_name'] ??
                                            'Unknown item',
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors
                                              .textPrimaryOnLight,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        [
                                          '+$qty units',
                                          by.toString(),
                                          if (dateLabel != null)
                                            dateLabel,
                                        ].join('  ·  '),
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors
                                              .textSecondaryOnLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Set price',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showPriceSheet(
      BuildContext context,
      WidgetRef ref,
      dynamic entry,
      ) {
    String mode = 'unit';
    final priceController = TextEditingController();
    bool submitting = false;
    final qty = (entry['quantity'] as num?)?.toDouble() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final price = double.tryParse(priceController.text);
          String? preview;
          if (price != null && price > 0 && qty > 0) {
            if (mode == 'unit') {
              final total = price * qty;
              preview =
              'Total cost: UGX ${total.toStringAsFixed(total == total.truncateToDouble() ? 0 : 2)}';
            } else {
              final unit = price / qty;
              preview =
              '≈ UGX ${unit.toStringAsFixed(2)} per unit';
            }
          }

          final canSave =
              !submitting && price != null && price > 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderOnLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    entry['item_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOnLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry['quantity']} units added'
                        '${entry['restocked_by'] != null ? ' · by ${entry['restocked_by']}' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryOnLight,
                    ),
                  ),
                  const SizedBox(height: 18),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'unit',
                        label: Text('Per unit'),
                        icon: Icon(Icons.looks_one_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: 'bulk',
                        label: Text('Total (crate)'),
                        icon: Icon(Icons.inventory_outlined, size: 16),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) =>
                        setSheetState(() => mode = s.first),
                    style: ButtonStyle(
                      backgroundColor:
                      WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return AppColors.surfaceMuted;
                      }),
                      foregroundColor:
                      WidgetStateProperty.resolveWith((states) {
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
                  const SizedBox(height: 14),

                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setSheetState(() {}),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOnLight,
                    ),
                    decoration: InputDecoration(
                      labelText: mode == 'unit'
                          ? 'Buying price per unit'
                          : 'Total price paid for ${entry['quantity']} units',
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.borderOnLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.borderOnLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  if (preview != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      preview,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canSave
                          ? () async {
                        final p =
                        double.tryParse(priceController.text);
                        if (p == null || p <= 0) return;

                        setSheetState(() => submitting = true);
                        try {
                          await ref
                              .read(
                              pendingPricingRepositoryProvider)
                              .setPrice(
                            entry['restock_id'],
                            mode: mode,
                            unitPrice:
                            mode == 'unit' ? p : null,
                            totalPrice:
                            mode == 'bulk' ? p : null,
                          );
                          ref.invalidate(
                              pendingPricingListProvider);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Price set for ${entry['item_name'] ?? 'item'}',
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          setSheetState(() => submitting = false);
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                          : const Text(
                        'Save Price',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}