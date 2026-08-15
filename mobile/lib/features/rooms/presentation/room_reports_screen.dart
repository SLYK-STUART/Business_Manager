import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../owner_dashboard/domain/reports_providers.dart';
import '../../bar/presentation/cash_collection_screen.dart'
    show collectionSummaryProvider;

class RoomReportsScreen extends ConsumerStatefulWidget {
  const RoomReportsScreen({super.key});

  @override
  ConsumerState<RoomReportsScreen> createState() => _RoomReportsScreenState();
}

class _RoomReportsScreenState extends ConsumerState<RoomReportsScreen> {
  String _formatDuration(DateTime checkin) {
    final diff = DateTime.now().difference(checkin);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    return '${minutes}m';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  void _setThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    ref.read(selectedRangeProvider.notifier).state = DateRange(
      start.toIso8601String().substring(0, 10),
      now.toIso8601String().substring(0, 10),
    );
  }

  void _setLastDays(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    ref.read(selectedRangeProvider.notifier).state = DateRange(
      start.toIso8601String().substring(0, 10),
      now.toIso8601String().substring(0, 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(roomReportProvider);
    final showAllRevenue = ref.watch(revenueExpandedProvider);
    final range = ref.watch(selectedRangeProvider);
    final roomsCollectionAsync =
    ref.watch(collectionSummaryProvider('rooms'));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Manage Rooms',
            onPressed: () =>
                Navigator.of(context).pushNamed('/room_management'),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (data) {
          final roomStatus = data['room_status'] as List? ?? [];
          final byRoom = data['by_room'] as List? ?? [];
          final byRoomTotal =
              data['by_room_total_count'] as int? ?? byRoom.length;

          final displayedRevenue = showAllRevenue || byRoomTotal <= 5
              ? byRoom
              : byRoom.take(5).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(roomReportProvider);
              ref.invalidate(collectionSummaryProvider('rooms'));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 150),
              children: [
                // ── Date range ──────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _rangeChip('This Month', _setThisMonth),
                    _rangeChip('Last 30 Days', () => _setLastDays(30)),
                    _rangeChip('Last 3 Months', () => _setLastDays(90)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${range.start}  →  ${range.end}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryOnLight,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Expected to Collect ─────────────────────────────
                roomsCollectionAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (summary) {
                    final expected = summary['expected_amount'];
                    final pending = summary['pending_collection'];
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldSlab,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expected to Collect (Rooms)',
                                  style: TextStyle(
                                    color: AppColors.textOnPrimary
                                        .withOpacity(0.8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'UGX $expected',
                                  style: const TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pending != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textOnPrimary
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // ── 1. Room Status (horizontal) ─────────────────────
                _sectionHeader('Room Status', roomStatus.length),
                const SizedBox(height: 10),
                SizedBox(
                  height: 118,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: roomStatus.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final room = roomStatus[i];
                      final occupied = room['status'] == 'occupied';
                      final checkinTime = room['checkin_time'] != null
                          ? DateTime.tryParse(
                          room['checkin_time'].toString())
                          : null;

                      return Container(
                        width: 130,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        decoration: BoxDecoration(
                          color: occupied
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: occupied
                                ? const Color(0xFF2A2A2A)
                                : AppColors.borderOnLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${room['name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: occupied
                                    ? Colors.white
                                    : AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'UGX ${room['nightly_rate']}',
                              style: TextStyle(
                                color: occupied
                                    ? Colors.white38
                                    : AppColors.textSecondaryOnLight,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            if (occupied && checkinTime != null) ...[
                              Text(
                                _formatTime(checkinTime),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatDuration(checkinTime),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
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
                                  const SizedBox(width: 5),
                                  const Text(
                                    'FREE',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
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

                const SizedBox(height: 24),

                // ── 2. Stats + Revenue (horizontal scroll section) ──
                _sectionHeader('Performance', null),
                const SizedBox(height: 10),

                // KPI row (horizontal)
                SizedBox(
                  height: 78,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _KpiCard(
                        label: 'Revenue',
                        value: 'UGX ${data['total_revenue']}',
                        accent: AppColors.primary,
                        width: 140,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'Discounts',
                        value: 'UGX ${data['total_discounts']}',
                        accent: AppColors.error,
                        width: 120,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'Bookings',
                        value: '${data['booking_count']}',
                        accent: AppColors.textPrimaryOnLight,
                        width: 90,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'Avg Nights',
                        value: '${data['average_nights']}',
                        accent: AppColors.textPrimaryOnLight,
                        width: 90,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'Done',
                        value: '${data['completed_count']}',
                        accent: AppColors.success,
                        width: 80,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'Active',
                        value: '${data['active_count']}',
                        accent: AppColors.warning,
                        width: 80,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Revenue by Room header + expand
                Row(
                  children: [
                    const Text(
                      'Revenue by Room',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOnLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$byRoomTotal',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (byRoomTotal > 5)
                      GestureDetector(
                        onTap: () => ref
                            .read(revenueExpandedProvider.notifier)
                            .state = !showAllRevenue,
                        child: Text(
                          showAllRevenue
                              ? 'Show less'
                              : 'Expand (${byRoomTotal - 5} more)',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Revenue bars (horizontal cards)
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayedRevenue.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final r = displayedRevenue[i];
                      return Container(
                        width: 160,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: AppColors.borderOnLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                    AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${r['room__name'] ?? '?'}'[0],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textOnPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r['room__name'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'UGX ${r['revenue']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textPrimaryOnLight,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${r['bookings']} booking${(r['bookings'] as num) == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryOnLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, int? count) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOnLight,
            letterSpacing: -0.2,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOnLight,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _rangeChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ── Compact KPI Card ──────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final double width;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.accent,
    this.width = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryOnLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: accent,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}