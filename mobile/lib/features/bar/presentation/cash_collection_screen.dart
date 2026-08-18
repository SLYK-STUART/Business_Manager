import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cash_collection_repository.dart';

final cashCollectionRepositoryProvider = Provider(
      (ref) => CashCollectionRepository(ref.watch(apiClientProvider)),
);

final collectionSummaryProvider =
FutureProvider.family.autoDispose((ref, String module) async {
  return ref.watch(cashCollectionRepositoryProvider).getSummary(module);
});

class CashCollectionScreen extends ConsumerStatefulWidget {
  final String module; // "bar" or "rooms"
  const CashCollectionScreen({super.key, this.module = "bar"});

  @override
  ConsumerState<CashCollectionScreen> createState() =>
      _CashCollectionScreenState();
}

class _CashCollectionScreenState extends ConsumerState<CashCollectionScreen> {
  final _amountController = TextEditingController();
  bool _submitting = false;
  double? _maxAllowed; // expected amount (parsed)

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Clamp the typed value so it never exceeds the expected amount.
  void _onAmountChanged(String value) {
    if (_maxAllowed == null) return;

    final parsed = double.tryParse(value);
    if (parsed == null) return;

    if (parsed > _maxAllowed!) {
      // Force the text back to the max allowed value
      final clamped = _maxAllowed!.toStringAsFixed(
        _maxAllowed! == _maxAllowed!.truncateToDouble() ? 0 : 2,
      );
      _amountController.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(collectionSummaryProvider(widget.module));
    final isRooms = widget.module == "rooms";

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          isRooms ? 'Rooms Cash Collection' : 'Cash Collection',
          style: const TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: summaryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        data: (summary) {
          final sales = summary['sales'] as List? ?? [];
          final nbts = summary['non_business_transactions'] as List? ?? [];
          final expectedAmount = summary['expected_amount'];
          final pending =
          summary['pending_collection'] as Map<String, dynamic>?;
          final leftBehind =
              (summary['left_behind_from_last_collection'] as num?) ?? 0;

          // Parse expected amount once so we can clamp the input
          _maxAllowed = double.tryParse(expectedAmount.toString());

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ref.invalidate(collectionSummaryProvider(widget.module)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // ── Pending approval alert ─────────────────────────────────
                if (pending != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            color: AppColors.warning, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collection awaiting approval',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.warning),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Collected UGX ${pending['collected_amount']} of UGX ${pending['expected_amount']} expected — remaining will only be finalized once approved.',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryOnLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Expected to Collect (hero card) ───────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldSlab,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected to Collect',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'UGX $expectedAmount',
                        style: const TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      if (pending != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Provisional — pending approval',
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Record Collection (moved to top) ──────────────────────
                Container(
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
                        'Record Collection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Maximum allowed: UGX $expectedAmount',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _amountController,
                        enabled: pending == null,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        onChanged: _onAmountChanged,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryOnLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount actually collected (UGX)',
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          labelStyle: const TextStyle(
                            color: AppColors.textSecondaryOnLight,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
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
                                color: AppColors.primary, width: 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_submitting || pending != null)
                              ? null
                              : () => _submit(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.35),
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
                            pending != null
                                ? 'Awaiting Approval'
                                : 'Record Collection',
                            style: const TextStyle(
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

                // ── Money & Goods Distribution ────────────────────────────
                _sectionCard(
                  title: isRooms
                      ? 'Rooms Revenue Distribution'
                      : 'Money & Goods Distribution',
                  child: Column(
                    children: [
                      _distributionRow(
                        isRooms ? 'Room Payments' : 'Cash Sales',
                        'UGX ${summary['cash_sales_amount']}',
                        AppColors.success,
                      ),
                      if (!isRooms)
                        _distributionRow(
                          'On Loan (not yet collectable)',
                          'UGX ${summary['loan_amount']}',
                          AppColors.warning,
                        ),
                      if (leftBehind > 0)
                        _distributionRow(
                          'Left in Business (previous collection)',
                          'UGX $leftBehind',
                          AppColors.info,
                        ),
                      const Divider(
                          height: 24, color: AppColors.borderOnLight),
                      _distributionRow(
                        isRooms
                            ? 'Total Room Revenue'
                            : 'Total Goods Sold (incl. loans)',
                        'UGX ${summary['total_sales_amount_including_loans']}',
                        AppColors.textPrimaryOnLight,
                      ),
                      if (!isRooms) ...[
                        const SizedBox(height: 8),
                        _distributionRow(
                          'Giveaways',
                          '${summary['giveaway_count']} items — UGX ${summary['giveaway_value']}',
                          AppColors.info,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sales / Bookings ──────────────────────────────────────
                _sectionHeader(
                    isRooms ? 'Bookings (${sales.length})' : 'Sales (${sales.length})'),
                const SizedBox(height: 10),
                ...sales.map((sale) {
                  final hasDiscount =
                      (sale['discount_total'] as num? ?? 0) > 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        childrenPadding:
                        const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        title: Text(
                          'UGX ${sale['total_amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                        subtitle: Text(
                          'by ${sale['sold_by'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOnLight,
                          ),
                        ),
                        trailing: hasDiscount
                            ? Text(
                          '−UGX ${sale['discount_total']}',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        )
                            : null,
                        children:
                        (sale['items'] as List? ?? []).map<Widget>((item) {
                          return ListTile(
                            dense: true,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                            title: Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimaryOnLight,
                              ),
                            ),
                            trailing: Text(
                              '×${item['quantity']}  =  UGX ${item['line_total']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryOnLight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total Discounts: UGX ${summary['total_discounts']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Non-Business Transactions (bar only) ──────────────────
                if (!isRooms) ...[
                  _sectionHeader(
                      'Non-Business Transactions (${nbts.length})'),
                  const SizedBox(height: 10),
                  if (nbts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'None recorded',
                        style: TextStyle(
                            color: AppColors.textSecondaryOnLight
                                .withOpacity(0.7)),
                      ),
                    )
                  else
                    ...nbts.map((n) {
                      final isOut = n['direction'] == 'out';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: AppColors.borderOnLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isOut
                                    ? AppColors.error
                                    : AppColors.success)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isOut
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 18,
                                color: isOut
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['description'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status: ${n['status']}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color:
                                      AppColors.textSecondaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'UGX ${n['amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isOut
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryOnLight,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderOnLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOnLight,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _distributionRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryOnLight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final text = _amountController.text.trim();
    if (text.isEmpty) return;

    final amount = double.tryParse(text);
    if (amount == null) return;

    // Final safety check before submitting
    if (_maxAllowed != null && amount > _maxAllowed!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Amount cannot exceed UGX ${_maxAllowed!.toStringAsFixed(0)}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(cashCollectionRepositoryProvider)
          .collect(amount, widget.module);

      ref.invalidate(collectionSummaryProvider(widget.module));
      _amountController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection recorded — pending approval'),
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