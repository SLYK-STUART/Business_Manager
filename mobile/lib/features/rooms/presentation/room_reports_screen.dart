import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../owner_dashboard/domain/reports_providers.dart';

class RoomReportsScreen extends ConsumerStatefulWidget {
  const RoomReportsScreen({super.key});

  @override
  ConsumerState<RoomReportsScreen> createState() => _RoomReportsScreenState();
}

class _RoomReportsScreenState extends ConsumerState<RoomReportsScreen> {
  bool _statusExpanded = true;
  bool _revenueExpanded = true;

  String _formatDuration(DateTime checkin) {
    final diff = DateTime.now().difference(checkin);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(roomReportProvider);
    final showAllRevenue = ref.watch(revenueExpandedProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Room Reports',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: reportAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Failed: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (data) {
          final roomStatus = data['room_status'] as List? ?? [];
          final byRoom = data['by_room'] as List? ?? [];
          final byRoomTotal = data['by_room_total_count'] as int? ?? byRoom.length;

          final displayedRevenue = showAllRevenue || byRoomTotal <= 5
              ? byRoom
              : byRoom.take(5).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(roomReportProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // ── KPI Cards ─────────────────────────────────────────────
                _buildKpiGrid(data),
                const SizedBox(height: 28),

                // ── Room Status (collapsible) ─────────────────────────────
                _CollapsibleSection(
                  title: 'Room Status',
                  count: roomStatus.length,
                  expanded: _statusExpanded,
                  onToggle: () => setState(() => _statusExpanded = !_statusExpanded),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.95,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: roomStatus.length,
                    itemBuilder: (context, i) {
                      final room = roomStatus[i];
                      final occupied = room['status'] == 'occupied';
                      final checkinTime = room['checkin_time'] != null
                          ? DateTime.tryParse(room['checkin_time'].toString())
                          : null;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: occupied ? const Color(0xFF1A1A1A) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: occupied
                                ? const Color(0xFF2A2A2A)
                                : AppColors.borderOnLight,
                          ),
                          boxShadow: occupied
                              ? null
                              : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${room['name']}',
                              style: TextStyle(
                                color: occupied
                                    ? Colors.white
                                    : AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'UGX ${room['nightly_rate']}/night',
                              style: TextStyle(
                                color: occupied
                                    ? Colors.white38
                                    : AppColors.textSecondaryOnLight,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            if (occupied && checkinTime != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatDuration(checkinTime),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'FREE',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
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
                ),
                const SizedBox(height: 28),

                // ── Revenue by Room (collapsible) ─────────────────────────
                _CollapsibleSection(
                  title: 'Revenue by Room',
                  count: byRoomTotal,
                  expanded: _revenueExpanded,
                  onToggle: () => setState(() => _revenueExpanded = !_revenueExpanded),
                  trailing: byRoomTotal > 5
                      ? GestureDetector(
                    onTap: () => ref
                        .read(revenueExpandedProvider.notifier)
                        .state = !showAllRevenue,
                    child: Text(
                      showAllRevenue
                          ? 'Show less'
                          : 'Expand (${byRoomTotal - 5} more)',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : null,
                  child: Column(
                    children: displayedRevenue.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOnLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${r['room__name'] ?? '?'}'[0],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['room__name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r['bookings']} booking${(r['bookings'] as num) == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'UGX ${r['revenue']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimaryOnLight,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            _KpiCard(
              label: 'Total Revenue',
              value: 'UGX ${data['total_revenue']}',
              accent: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _KpiCard(
              label: 'Discounts',
              value: 'UGX ${data['total_discounts']}',
              accent: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _KpiCard(
              label: 'Bookings',
              value: '${data['booking_count']}',
              accent: AppColors.textPrimaryOnLight,
            ),
            const SizedBox(width: 12),
            _KpiCard(
              label: 'Avg Nights',
              value: '${data['average_nights']}',
              accent: AppColors.textPrimaryOnLight,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _KpiCard(
              label: 'Completed',
              value: '${data['completed_count']}',
              accent: AppColors.success,
            ),
            const SizedBox(width: 12),
            _KpiCard(
              label: 'Active Now',
              value: '${data['active_count']}',
              accent: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Collapsible Section ─────────────────────────────────────────────────────
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? trailing;

  const _CollapsibleSection({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOnLight,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOnLight,
                  ),
                ),
              ),
              const Spacer(),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondaryOnLight,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: child,
          ),
          crossFadeState:
          expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

// ── KPI Card ────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryOnLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: accent,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}