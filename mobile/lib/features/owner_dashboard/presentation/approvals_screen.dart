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
        return 'Cash Shortfall';
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
        return Icons.money_off_csred_rounded;
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

  String _detailLine(Map<String, dynamic> item) {
    final type = item['type'];
    final detail = item['detail'];
    if (detail == null) return '';
    if (type == 'shortfall') {
      return 'Expected UGX ${detail['expected_amount']} — Collected UGX ${detail['collected_amount']} (variance UGX ${detail['variance']})';
    } else if (type == 'free_giveaway') {
      return '${detail['item_name']} → ${detail['recipient_name']} (value UGX ${detail['value']})';
    } else if (type == 'non_business_transaction') {
      final dir = detail['direction'] == 'out' ? 'Out' : 'In';
      return '$dir — UGX ${detail['amount']} — ${detail['description']}';
    }
    return '';
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
          // ── Status filter ───────────────────────────────────────────────
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
              onSelectionChanged: (s) =>
              ref.read(approvalsStatusFilterProvider.notifier).state = s.first,
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
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
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
                  return const Center(
                    child: Text(
                      'Nothing here',
                      style: TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(approvalsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final id = item['id'] as String;
                      final isProcessing = _processing.contains(id);
                      final typeColor = _typeColor(item['type']);

                      return Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type header
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _typeIcon(item['type']),
                                    size: 18,
                                    color: typeColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _typeLabel(item['type']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Detail
                            Text(
                              _detailLine(item),
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: AppColors.textPrimaryOnLight,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Meta
                            Text(
                              'Logged by ${item['requested_by_name'] ?? 'Unknown'}',
                              style: const TextStyle(
                                color: AppColors.textSecondaryOnLight,
                                fontSize: 12.5,
                              ),
                            ),
                            if (item['resolved_by_name'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Resolved by ${item['resolved_by_name']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondaryOnLight,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],

                            // Actions (pending only)
                            if (statusFilter == 'pending') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        onPressed:
                                        isProcessing ? null : () => _act(id, false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(
                                            color: AppColors.error,
                                            width: 1.3,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Reject',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed:
                                        isProcessing ? null : () => _act(id, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.textOnPrimary,
                                          disabledBackgroundColor:
                                          AppColors.primary.withOpacity(0.45),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: isProcessing
                                            ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.textOnPrimary,
                                          ),
                                        )
                                            : const Text(
                                          'Approve',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  Future<void> _act(String id, bool approve) async {
    setState(() => _processing.add(id));
    try {
      final repo = ref.read(approvalsRepositoryProvider);
      if (approve) {
        await repo.approve(id);
      } else {
        await repo.reject(id);
      }
      ref.invalidate(approvalsListProvider);
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