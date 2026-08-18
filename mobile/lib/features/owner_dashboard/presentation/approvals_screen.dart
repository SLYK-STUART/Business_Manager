import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/approvals_providers.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  final Set<String> _processing = {};

  String _typeLabel(String type) {
    switch (type) {
      case 'shortfall':
        return 'Money collected';
      case 'free_giveaway':
        return 'Free / Giveaway';
      case 'non_business_transaction':
        return 'Non-Business Txn';
      default:
        return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'shortfall':
        return Icons.payments_outlined;
      case 'free_giveaway':
        return Icons.card_giftcard_rounded;
      case 'non_business_transaction':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'shortfall':
        return AppColors.error;
      case 'free_giveaway':
        return AppColors.info;
      case 'non_business_transaction':
        return AppColors.warning;
      default:
        return AppColors.textSecondaryOnLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvalsAsync = ref.watch(approvalsListProvider);
    final statusFilter = ref.watch(approvalsStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Approvals',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pending',
                  label: Text('Pending'),
                  icon: Icon(Icons.hourglass_empty_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'approved',
                  label: Text('Approved'),
                  icon: Icon(Icons.check_circle_outline_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'rejected',
                  label: Text('Rejected'),
                  icon: Icon(Icons.cancel_outlined, size: 16),
                ),
              ],
              selected: {statusFilter},
              onSelectionChanged: (s) => ref
                  .read(approvalsStatusFilterProvider.notifier)
                  .state = s.first,
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
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          Expanded(
            child: approvalsAsync.when(
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusFilter == 'pending'
                              ? Icons.inbox_outlined
                              : Icons.check_circle_outline_rounded,
                          size: 40,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          statusFilter == 'pending'
                              ? 'No pending approvals'
                              : 'Nothing here',
                          style: const TextStyle(
                            color: AppColors.textSecondaryOnLight,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(approvalsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = items[i] as Map<String, dynamic>;
                      final id = item['id'] as String;
                      final isProcessing = _processing.contains(id);
                      final type = item['type']?.toString() ?? '';
                      final typeColor = _typeColor(type);
                      final isShortfall = type == 'shortfall';
                      final detail =
                      item['detail'] as Map<String, dynamic>?;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: AppColors.borderOnLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    _typeIcon(type),
                                    size: 17,
                                    color: typeColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _typeLabel(type),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                ),
                                if (statusFilter != 'pending')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusFilter == 'approved'
                                          ? AppColors.success
                                          .withOpacity(0.12)
                                          : AppColors.error
                                          .withOpacity(0.12),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusFilter == 'approved'
                                          ? 'APPROVED'
                                          : 'REJECTED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusFilter == 'approved'
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Detail block
                            if (isShortfall && detail != null)
                              _ShortfallBreakdown(detail: detail)
                            else
                              Text(
                                _simpleDetail(type, detail),
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: AppColors.textPrimaryOnLight,
                                ),
                              ),

                            const SizedBox(height: 10),
                            Text(
                              'Logged by ${item['requested_by_name'] ?? 'Unknown'}',
                              style: const TextStyle(
                                color: AppColors.textSecondaryOnLight,
                                fontSize: 12,
                              ),
                            ),
                            if (item['resolved_by_name'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Resolved by ${item['resolved_by_name']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondaryOnLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            // Actions
                            if (statusFilter == 'pending') ...[
                              const SizedBox(height: 14),
                              if (isShortfall) ...[
                                // Reject
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: OutlinedButton(
                                    onPressed: isProcessing
                                        ? null
                                        : () => _confirmAndAct(
                                      item: item,
                                      approve: false,
                                      title: 'Reject collection?',
                                      message:
                                      'This will reject the money-collected report. The manager may need to resubmit.',
                                      confirmLabel: 'Reject',
                                      isDestructive: true,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                          color: AppColors.error,
                                          width: 1.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(11),
                                      ),
                                    ),
                                    child: const Text(
                                      'Reject',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 42,
                                        child: OutlinedButton(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _confirmAndAct(
                                            item: item,
                                            approve: true,
                                            classification:
                                            'matched',
                                            title:
                                            'Mark as matched?',
                                            message:
                                            'You are confirming the difference was left in the business (matched). This is not treated as a loss.',
                                            confirmLabel:
                                            'Confirm matched',
                                            isDestructive: false,
                                            confirmColor:
                                            AppColors.success,
                                          ),
                                          style:
                                          OutlinedButton.styleFrom(
                                            foregroundColor:
                                            AppColors.success,
                                            side: const BorderSide(
                                                color: AppColors.success,
                                                width: 1.2),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  11),
                                            ),
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 8),
                                          ),
                                          child: const Text(
                                            'Matched / Left in',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 42,
                                        child: ElevatedButton(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _confirmAndAct(
                                            item: item,
                                            approve: true,
                                            classification:
                                            'shortfall',
                                            title:
                                            'Record genuine shortfall?',
                                            message:
                                            'This marks the variance as a real shortfall (loss). This affects reported profit and cannot be easily undone.',
                                            confirmLabel:
                                            'Confirm shortfall',
                                            isDestructive: true,
                                          ),
                                          style:
                                          ElevatedButton.styleFrom(
                                            backgroundColor:
                                            AppColors.error,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                            AppColors.error
                                                .withOpacity(0.45),
                                            elevation: 0,
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 8),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  11),
                                            ),
                                          ),
                                          child: isProcessing
                                              ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                              : const Text(
                                            'Genuine shortfall',
                                            style: TextStyle(
                                              fontWeight:
                                              FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                            textAlign:
                                            TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 42,
                                        child: OutlinedButton(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _confirmAndAct(
                                            item: item,
                                            approve: false,
                                            title: 'Reject?',
                                            message:
                                            'Reject this ${_typeLabel(type).toLowerCase()} request?',
                                            confirmLabel:
                                            'Reject',
                                            isDestructive: true,
                                          ),
                                          style:
                                          OutlinedButton.styleFrom(
                                            foregroundColor:
                                            AppColors.error,
                                            side: const BorderSide(
                                                color: AppColors.error,
                                                width: 1.2),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  11),
                                            ),
                                          ),
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SizedBox(
                                        height: 42,
                                        child: ElevatedButton(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _confirmAndAct(
                                            item: item,
                                            approve: true,
                                            title: 'Approve?',
                                            message:
                                            'Approve this ${_typeLabel(type).toLowerCase()}?',
                                            confirmLabel:
                                            'Approve',
                                            isDestructive: false,
                                          ),
                                          style:
                                          ElevatedButton.styleFrom(
                                            backgroundColor:
                                            AppColors.primary,
                                            foregroundColor:
                                            AppColors.textOnPrimary,
                                            disabledBackgroundColor:
                                            AppColors.primary
                                                .withOpacity(0.45),
                                            elevation: 0,
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  11),
                                            ),
                                          ),
                                          child: isProcessing
                                              ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors
                                                  .textOnPrimary,
                                            ),
                                          )
                                              : const Text(
                                            'Approve',
                                            style: TextStyle(
                                                fontWeight:
                                                FontWeight
                                                    .w700),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
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

  String _simpleDetail(String type, Map<String, dynamic>? detail) {
    if (detail == null) return '';
    if (type == 'free_giveaway') {
      return '${detail['item_name']} → ${detail['recipient_name']} (value UGX ${detail['value']})';
    }
    if (type == 'non_business_transaction') {
      final dir = detail['direction'] == 'out' ? 'Out' : 'In';
      return '$dir — UGX ${detail['amount']} — ${detail['description']}';
    }
    return '';
  }

  Future<void> _confirmAndAct({
    required Map<String, dynamic> item,
    required bool approve,
    String? classification,
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
    Color? confirmColor,
  }) async {
    final detail = item['detail'] as Map<String, dynamic>?;
    final isShortfall = item['type'] == 'shortfall';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondaryOnLight,
              ),
            ),
            if (isShortfall && detail != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogRow(
                        'Expected', 'UGX ${detail['expected_amount']}'),
                    _dialogRow(
                        'Collected', 'UGX ${detail['collected_amount']}'),
                    _dialogRow(
                        'Variance', 'UGX ${detail['variance']}',
                        emphasize: true),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDestructive
                    ? AppColors.error
                    : (confirmColor ?? AppColors.primaryDark),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _act(item['id'] as String, approve,
        classification: classification);
  }

  Widget _dialogRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: emphasize
                  ? AppColors.textPrimaryOnLight
                  : AppColors.textSecondaryOnLight,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: emphasize
                  ? AppColors.error
                  : AppColors.textPrimaryOnLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _act(String id, bool approve,
      {String? classification}) async {
    setState(() => _processing.add(id));
    try {
      final repo = ref.read(approvalsRepositoryProvider);
      if (approve) {
        await repo.approve(id, classification: classification);
      } else {
        await repo.reject(id);
      }
      ref.invalidate(approvalsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? (classification == 'shortfall'
                  ? 'Recorded as genuine shortfall'
                  : classification == 'matched'
                  ? 'Marked as matched / left in business'
                  : 'Approved')
                  : 'Rejected',
            ),
            backgroundColor:
            approve ? AppColors.success : AppColors.warning,
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
      if (mounted) setState(() => _processing.remove(id));
    }
  }
}

class _ShortfallBreakdown extends StatelessWidget {
  final Map<String, dynamic> detail;
  const _ShortfallBreakdown({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _row('Expected', 'UGX ${detail['expected_amount']}'),
          const SizedBox(height: 4),
          _row('Collected', 'UGX ${detail['collected_amount']}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: AppColors.borderOnLight),
          ),
          _row('Variance', 'UGX ${detail['variance']}', highlight: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: highlight
                ? AppColors.textPrimaryOnLight
                : AppColors.textSecondaryOnLight,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.error : AppColors.textPrimaryOnLight,
          ),
        ),
      ],
    );
  }
}