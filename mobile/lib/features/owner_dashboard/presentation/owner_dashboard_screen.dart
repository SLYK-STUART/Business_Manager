import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/dashboard_providers.dart';
import '../domain/pending_pricing_providers.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final pendingPricingAsync = ref.watch(pendingPricingListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(pendingPricingListProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: userAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (user) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, ${user["name"]}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryOnLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Here's what's happening today · ${_formatDate()}",
                            style: const TextStyle(
                              color: AppColors.textSecondaryOnLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Dashboard content ─────────────────────────────────────
              dashboardAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child:
                    CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'Failed: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (data) {
                  final pendingApprovals =
                      data['pending_approvals_preview'] as List? ?? [];
                  final pendingPricingCount = pendingPricingAsync.maybeWhen(
                    data: (items) => items.length,
                    orElse: () => 0,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── KPI cards ─────────────────────────────────────
                      // Row 1: two larger cards
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: AppColors.success,
                              label: 'Expected to Collect',
                              value:
                              'UGX ${data['expected_to_collect']}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.primaryDark,
                              label: "Today's Sales",
                              value: 'UGX ${data['today_sales']}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Row 2: three smaller cards
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              icon: Icons.hourglass_empty_rounded,
                              iconColor: AppColors.warning,
                              label: 'Pending Approvals',
                              value:
                              '${data['pending_approvals_count']}',
                              compact: true,
                              onTap: (data['pending_approvals_count']
                              as num? ??
                                  0) >
                                  0
                                  ? () => Navigator.of(context)
                                  .pushNamed('/approvals')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KpiCard(
                              icon: Icons.inventory_2_rounded,
                              iconColor: AppColors.error,
                              label: 'Low Stock',
                              value: '${data['low_stock_count']}',
                              compact: true,
                              onTap: (data['low_stock_count'] as num? ??
                                  0) >
                                  0
                                  ? () => Navigator.of(context)
                                  .pushNamed('/items')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KpiCard(
                              icon: Icons.price_change_rounded,
                              iconColor: AppColors.info,
                              label: 'Pending Prices',
                              value: '$pendingPricingCount',
                              compact: true,
                              onTap: pendingPricingCount > 0
                                  ? () => Navigator.of(context)
                                  .pushNamed('/pending_pricing')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Pending Approvals ─────────────────────────────
                      if (pendingApprovals.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'PENDING APPROVALS',
                          accent: AppColors.warning,
                          onViewAll: () => Navigator.of(context)
                              .pushNamed('/approvals'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 152,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: pendingApprovals.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                            itemBuilder: (context, i) =>
                                _ApprovalPreviewCard(
                                  approval: pendingApprovals[i],
                                ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // ── Pending Prices ────────────────────────────────
                      pendingPricingAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (items) {
                          if (items.isEmpty) return const SizedBox.shrink();
                          final latest = items.take(3).toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  title: 'PENDING PRICES',
                                  accent: AppColors.info,
                                  onViewAll: () => Navigator.of(context)
                                      .pushNamed('/pending_pricing'),
                                ),
                                const SizedBox(height: 12),
                                ...latest.map(
                                      (entry) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.borderOnLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: AppColors.info
                                                .withOpacity(0.12),
                                            borderRadius:
                                            BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.price_change_rounded,
                                            size: 16,
                                            color: AppColors.info,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry['item_name'] ?? '',
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.w600,
                                                  fontSize: 13.5,
                                                  color: AppColors
                                                      .textPrimaryOnLight,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '+${entry['quantity']} units · by ${entry['restocked_by'] ?? 'Unknown'}',
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
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AppColors
                                              .textSecondaryOnLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // ── Projected vs Actual ───────────────────────────
                      _ChartCard(
                        title: 'PROJECTED VS ACTUAL PROFIT',
                        accent: AppColors.primary,
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Daily profit, in UGX — bars compare what was expected against what actually happened.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryOnLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 170,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups:
                                  (data['profit_trend'] as List? ?? [])
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final i = entry.key;
                                    final d = entry.value;
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: (d['projected'] as num?)
                                              ?.toDouble() ??
                                              0,
                                          color: AppColors
                                              .textSecondaryOnLight,
                                          width: 7,
                                          borderRadius:
                                          BorderRadius.circular(3),
                                        ),
                                        BarChartRodData(
                                          toY: (d['actual'] as num?)
                                              ?.toDouble() ??
                                              0,
                                          color: AppColors.primaryDark,
                                          width: 7,
                                          borderRadius:
                                          BorderRadius.circular(3),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      axisNameWidget: const Text(
                                        'UGX',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors
                                              .textSecondaryOnLight,
                                        ),
                                      ),
                                      axisNameSize: 16,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (v, meta) => Text(
                                          v >= 1000
                                              ? '${(v / 1000).toStringAsFixed(0)}k'
                                              : v.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors
                                                .textSecondaryOnLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      axisNameWidget: const Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors
                                              .textSecondaryOnLight,
                                        ),
                                      ),
                                      axisNameSize: 16,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, meta) {
                                          final trend =
                                              data['profit_trend']
                                              as List? ??
                                                  [];
                                          if (v.toInt() >= trend.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = trend[v.toInt()]
                                          ['date']
                                              .toString()
                                              .substring(5);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 6),
                                            child: Text(
                                              date,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors
                                                    .textSecondaryOnLight,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles:
                                      SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles:
                                      SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _legendDot(
                                  AppColors.textSecondaryOnLight,
                                  'Proj.',
                                ),
                                const SizedBox(width: 16),
                                _legendDot(
                                    AppColors.primaryDark, 'Actual'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (data['profit_summary'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    _SummaryCell(
                                      label: 'PROJECTED',
                                      value:
                                      'UGX ${data['profit_summary']['projected_profit'] ?? '—'}',
                                    ),
                                    _SummaryCell(
                                      label: 'ACTUAL',
                                      value:
                                      'UGX ${data['profit_summary']['actual_profit'] ?? '—'}',
                                      color: AppColors.success,
                                    ),
                                    _SummaryCell(
                                      label: 'VARIANCE',
                                      value:
                                      'UGX ${data['profit_summary']['divergence'] ?? '—'}',
                                      isNegative: (data['profit_summary']
                                      ['divergence'] as num? ??
                                          0) <
                                          0,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Why the difference ────────────────────────────
                      if (data['profit_summary']?['breakdown'] != null)
                        _ChartCard(
                          title: 'WHY THE DIFFERENCE?',
                          accent: AppColors.info,
                          child: Column(
                            children: [
                              ...(data['profit_summary']['breakdown']
                              as Map<String, dynamic>)
                                  .entries
                                  .map((e) {
                                final isNeg = (e.value as num) < 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isNeg
                                              ? AppColors.error
                                              : AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e.key
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors
                                                .textSecondaryOnLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'UGX ${e.value}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isNeg
                                              ? AppColors.error
                                              : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(
                                height: 24,
                                color: AppColors.borderOnLight,
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Impact',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                  Text(
                                    'UGX ${data['profit_summary']['divergence']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: (data['profit_summary']
                                      ['divergence'] as num) <
                                          0
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (data['profit_summary']?['breakdown'] != null)
                        const SizedBox(height: 16),

                      // ── Profit Trend ──────────────────────────────────
                      _ChartCard(
                        title: 'PROFIT TREND',
                        accent: AppColors.success,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Actual profit over time, in UGX.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryOnLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 150,
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: (data['profit_trend']
                                      as List? ??
                                          [])
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => FlSpot(
                                          e.key.toDouble(),
                                          (e.value['actual'] as num?)
                                              ?.toDouble() ??
                                              0,
                                        ),
                                      )
                                          .toList(),
                                      isCurved: true,
                                      color: AppColors.success,
                                      barWidth: 3,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, bar,
                                            index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: AppColors.success,
                                              strokeWidth: 2,
                                              strokeColor: Colors.white,
                                            ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppColors.success
                                            .withOpacity(0.10),
                                      ),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      axisNameWidget: const Text(
                                        'UGX',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors
                                              .textSecondaryOnLight,
                                        ),
                                      ),
                                      axisNameSize: 16,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (v, meta) => Text(
                                          v >= 1000
                                              ? '${(v / 1000).toStringAsFixed(0)}k'
                                              : v.toStringAsFixed(0),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors
                                                .textSecondaryOnLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: const AxisTitles(
                                      sideTitles:
                                      SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles:
                                      SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles:
                                      SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Most / Least bought ───────────────────────────
                      if ((data['most_bought'] as List? ?? []).isNotEmpty ||
                          (data['least_bought'] as List? ?? [])
                              .isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _RankCard(
                                title: 'MOST BOUGHT',
                                items:
                                data['most_bought'] as List? ?? [],
                                accent: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RankCard(
                                title: 'LEAST BOUGHT',
                                items:
                                data['least_bought'] as List? ?? [],
                                accent: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      if ((data['most_bought'] as List? ?? []).isNotEmpty ||
                          (data['least_bought'] as List? ?? [])
                              .isNotEmpty)
                        const SizedBox(height: 28),

                      // ── Recent Activity ───────────────────────────────
                      if ((data['recent_activity'] as List? ?? [])
                          .isNotEmpty) ...[
                        _SectionHeader(
                          title: 'RECENT ACTIVITY',
                          accent: AppColors.info,
                          onViewAll: () => Navigator.of(context)
                              .pushNamed('/activity-log'),
                        ),
                        const SizedBox(height: 12),
                        ...(data['recent_activity'] as List? ?? [])
                            .take(5)
                            .map((log) {
                          final color = _activityColor(log['action_type']);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border(
                                left: BorderSide(color: color, width: 3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
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
                                    color: color.withOpacity(0.12),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _activityIcon(log['action_type']),
                                    size: 16,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['action_type']
                                            .toString()
                                            .replaceAll('_', ' '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                          color: AppColors
                                              .textPrimaryOnLight,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        log['actor_name'] ?? 'System',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                Text(
                                  log['timestamp']
                                      ?.toString()
                                      .substring(11, 16) ??
                                      '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                    AppColors.textSecondaryOnLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _activityColor(dynamic type) {
    final t = type?.toString() ?? '';
    if (t.contains('sale') || t.contains('completed')) {
      return AppColors.success;
    }
    if (t.contains('approval') || t.contains('pending')) {
      return AppColors.warning;
    }
    if (t.contains('stock') || t.contains('alert')) return AppColors.error;
    if (t.contains('price')) return AppColors.primaryDark;
    return AppColors.info;
  }

  IconData _activityIcon(dynamic type) {
    final t = type?.toString() ?? '';
    if (t.contains('sale')) return Icons.point_of_sale_rounded;
    if (t.contains('giveaway')) return Icons.card_giftcard_rounded;
    if (t.contains('price')) return Icons.sell_rounded;
    if (t.contains('stock') || t.contains('restock')) {
      return Icons.inventory_2_rounded;
    }
    if (t.contains('checkin') ||
        t.contains('checkout') ||
        t.contains('booking')) {
      return Icons.bed_rounded;
    }
    if (t.contains('approval')) return Icons.assignment_turned_in_rounded;
    return Icons.circle_notifications_rounded;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryOnLight,
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accent;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.accent,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOnLight,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool compact;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final clickable = onTap != null;

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: clickable
                  ? iconColor.withOpacity(0.35)
                  : AppColors.borderOnLight,
            ),
            boxShadow: clickable
                ? [
              BoxShadow(
                color: iconColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondaryOnLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimaryOnLight,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: clickable
                ? iconColor.withOpacity(0.35)
                : AppColors.borderOnLight,
          ),
          boxShadow: clickable
              ? [
            BoxShadow(
              color: iconColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryOnLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimaryOnLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (clickable)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: iconColor.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalPreviewCard extends StatelessWidget {
  final dynamic approval;

  const _ApprovalPreviewCard({required this.approval});

  @override
  Widget build(BuildContext context) {
    final type = approval['type']?.toString() ?? '';
    final detail = approval['detail'] ?? {};
    final isShortfall = type == 'shortfall';
    final accent = isShortfall ? AppColors.error : AppColors.warning;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isShortfall
                    ? Icons.warning_amber_rounded
                    : Icons.swap_horiz_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  type.replaceAll('_', ' ').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (detail['item_name'] ??
                detail['description'] ??
                'Bar Tab / Charge')
                .toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimaryOnLight,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UGX ${detail['amount'] ?? detail['variance'] ?? '—'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isShortfall
                  ? AppColors.error
                  : AppColors.textPrimaryOnLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'by ${approval['requested_by_name'] ?? 'Unknown'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryOnLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color accent;

  const _ChartCard({
    required this.title,
    required this.child,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(top: BorderSide(color: accent, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryOnLight,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isNegative;
  final Color? color;

  const _SummaryCell({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryOnLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isNegative
                  ? AppColors.error
                  : (color ?? AppColors.textPrimaryOnLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final String title;
  final List items;
  final Color accent;

  const _RankCard({
    required this.title,
    required this.items,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: accent, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryOnLight,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['item__name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryOnLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item['total_qty']}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}