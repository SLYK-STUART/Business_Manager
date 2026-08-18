import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/loan_providers.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  String _filter = 'open'; // open | settled
  String _searchQuery = '';

  Color _statusColor(String? status) {
    switch (status) {
      case 'paid':
      case 'written_off':
        return AppColors.success;
      case 'partially_paid':
        return AppColors.warning;
      case 'active':
      default:
        return AppColors.info;
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Unknown';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  bool _isSettled(dynamic loan) {
    final status = loan['status']?.toString();
    return status == 'paid' || status == 'written_off';
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loanListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Loans',
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
          // ── Search ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimaryOnLight),
              decoration: InputDecoration(
                hintText: 'Search by name or item…',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondaryOnLight,
                ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Filter tabs ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _FilterTab(
                    label: 'Open',
                    selected: _filter == 'open',
                    onTap: () => setState(() => _filter = 'open'),
                  ),
                  _FilterTab(
                    label: 'Settled',
                    selected: _filter == 'settled',
                    onTap: () => setState(() => _filter = 'settled'),
                  ),
                ],
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: loansAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load loans:\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              data: (loans) {
                var filtered = loans.where((loan) {
                  final settled = _isSettled(loan);
                  final matchesFilter =
                  _filter == 'open' ? !settled : settled;

                  if (!matchesFilter) return false;

                  if (_searchQuery.isEmpty) return true;

                  final name =
                  (loan['customer_name']?.toString() ?? '').toLowerCase();
                  final item =
                  (loan['item_name']?.toString() ?? '').toLowerCase();
                  final phone =
                  (loan['customer_phone']?.toString() ?? '').toLowerCase();

                  return name.contains(_searchQuery) ||
                      item.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();

                if (_filter == 'open') {
                  filtered.sort((a, b) {
                    final aActive = a['status'] == 'active' ? 0 : 1;
                    final bActive = b['status'] == 'active' ? 0 : 1;
                    return aActive.compareTo(bActive);
                  });
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No loans match “$_searchQuery”'
                          : (_filter == 'open'
                          ? 'No open loans'
                          : 'No settled loans yet'),
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.refresh(loanListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final loan = filtered[i];
                      final status = loan['status']?.toString();
                      final isSettled = _isSettled(loan);
                      final statusColor = _statusColor(status);

                      final customerName =
                          loan['customer_name']?.toString().trim() ?? '—';
                      final customerPhone =
                      loan['customer_phone']?.toString().trim();
                      final itemName =
                          loan['item_name']?.toString().trim() ?? 'Unknown item';
                      final quantity = loan['quantity'];

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderOnLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'UGX ${loan['amount_remaining']}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimaryOnLight,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    quantity != null
                                        ? '$itemName  ·  Qty $quantity'
                                        : itemName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      customerName,
                                      if (customerPhone != null &&
                                          customerPhone.isNotEmpty)
                                        customerPhone,
                                      'Due ${loan['due_date'] ?? '—'}',
                                    ].join('  ·  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            isSettled
                                ? Text(
                              status == 'paid'
                                  ? 'Settled'
                                  : 'Written off',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryOnLight,
                              ),
                            )
                                : PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'repay') {
                                  _showRepaySheet(context, ref, loan);
                                } else if (action == 'write_off') {
                                  _confirmWriteOff(context, ref, loan);
                                } else if (action == 'reschedule') {
                                  _showRescheduleSheet(
                                      context, ref, loan);
                                }
                              },
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              color: Colors.white,
                              elevation: 8,
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'repay',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.payments_outlined,
                                          size: 17,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Repay',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reschedule',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.info
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.event_outlined,
                                          size: 17,
                                          color: AppColors.info,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Reschedule due date',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'write_off',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.error
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.block_rounded,
                                          size: 17,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Write off',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.more_horiz,
                                  size: 16,
                                  color: AppColors.textOnPrimary,
                                ),
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

  void _showRepaySheet(BuildContext context, WidgetRef ref, dynamic loan) {
    final controller = TextEditingController();
    final customerName = loan['customer_name']?.toString();
    final customerPhone = loan['customer_phone']?.toString();
    final itemName = loan['item_name']?.toString();
    final quantity = loan['quantity'];
    final maxAmount =
        double.tryParse(loan['amount_remaining']?.toString() ?? '') ?? 0;

    void clampAmount(String value) {
      final parsed = double.tryParse(value);
      if (parsed == null) return;
      if (parsed > maxAmount) {
        final clamped = maxAmount == maxAmount.truncateToDouble()
            ? maxAmount.toStringAsFixed(0)
            : maxAmount.toStringAsFixed(2);
        controller.value = TextEditingValue(
          text: clamped,
          selection: TextSelection.collapsed(offset: clamped.length),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 70),
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
                const SizedBox(height: 20),
                const Text(
                  'Repay Loan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOnLight,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (itemName != null)
                  Text(
                    quantity != null ? '$itemName · Qty $quantity' : itemName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOnLight,
                    ),
                  ),
                if (customerName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      customerName,
                      if (customerPhone != null) customerPhone,
                    ].join('  ·  '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryOnLight,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Remaining: UGX ${loan['amount_remaining']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOnLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Maximum: UGX ${loan['amount_remaining']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: clampAmount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOnLight,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (UGX)',
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    labelStyle: const TextStyle(
                      color: AppColors.textSecondaryOnLight,
                      fontWeight: FontWeight.w500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: AppColors.borderOnLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: AppColors.borderOnLight),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(controller.text);
                      if (amount == null || amount <= 0) return;

                      if (amount > maxAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Amount cannot exceed UGX ${loan['amount_remaining']}',
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      await ref
                          .read(loanRepositoryProvider)
                          .repayLoan(loan['id'], amount);
                      ref.invalidate(loanListProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm Repayment',
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
        );
      },
    );
  }

  void _confirmWriteOff(BuildContext context, WidgetRef ref, dynamic loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Write Off Loan'),
        content: Text(
          "Mark UGX ${loan['amount_remaining']} as a loss? This can't be undone and will reduce actual profit for this period.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(loanRepositoryProvider).writeOffLoan(loan['id']);
              ref.invalidate(loanListProvider);
            },
            child: const Text(
              'Write Off',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleSheet(
      BuildContext context, WidgetRef ref, dynamic loan) {
    DateTime newDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 70),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOnLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reschedule Due Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current due: ${loan['due_date'] ?? '—'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOnLight,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: AppColors.info,
                  ),
                ),
                title: Text(
                  newDate.toIso8601String().substring(0, 10),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                subtitle: const Text('Tap to change date'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setSheetState(() => newDate = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(loanRepositoryProvider).rescheduleLoan(
                      loan['id'],
                      newDate.toIso8601String().substring(0, 10),
                    );
                    ref.invalidate(loanListProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save new due date',
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
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondaryOnLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}