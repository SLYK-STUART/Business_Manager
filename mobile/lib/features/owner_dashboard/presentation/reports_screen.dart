import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/reports_providers.dart';

// ── DEV-ONLY SWITCH ──────────────────────────────────────────────────────
const bool kShowDebugShortcut = false;

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;
  String _selectedRange = 'This Month';

  @override
  Widget build(BuildContext context) {
    final profitAsync = ref.watch(profitReportProvider);
    final trendsAsync = ref.watch(trendsProvider);
    final categoryAsync = ref.watch(categoryRevenueProvider);
    final salesOverTimeAsync = ref.watch(salesOverTimeProvider);
    final loansAsync = ref.watch(loansSummaryProvider);
    final reconciliationAsync = ref.watch(cashReconciliationProvider);
    final giveawaysAsync = ref.watch(giveawaysSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Reports',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(profitReportProvider);
            ref.invalidate(trendsProvider);
            ref.invalidate(categoryRevenueProvider);
            ref.invalidate(salesOverTimeProvider);
            ref.invalidate(loansSummaryProvider);
            ref.invalidate(cashReconciliationProvider);
            ref.invalidate(giveawaysSummaryProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // ── Date range chips ───────────────────────────────────────
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _rangeChip('This Month', () {
                      setState(() => _selectedRange = 'This Month');
                      _setThisMonth();
                    }),
                    const SizedBox(width: 8),
                    _rangeChip('Last 30 Days', () {
                      setState(() => _selectedRange = 'Last 30 Days');
                      _setLastDays(30);
                    }),
                    const SizedBox(width: 8),
                    _rangeChip('Last 3 Months', () {
                      setState(() => _selectedRange = 'Last 3 Months');
                      _setLastDays(90);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Projected vs Actual Profit ─────────────────────────────
              profitAsync.when(
                loading: () => _loadingCard(),
                error: (e, _) => _errorCard(e),
                data: (data) => _card(
                  title: 'Projected vs Actual Profit',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statColumn(
                              'Projected',
                              data['projected_profit'],
                              AppColors.textPrimaryOnLight,
                            ),
                          ),
                          Expanded(
                            child: _statColumn(
                              'Actual',
                              data['actual_profit'],
                              AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _statColumn(
                              'Divergence',
                              data['divergence'],
                              (data['divergence'] as num) < 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.borderOnLight),
                      const SizedBox(height: 14),
                      const Text(
                        'Why the difference?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...(data['breakdown'] as Map<String, dynamic>)
                          .entries
                          .map(
                            (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _breakdownLabel(e.key),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryOnLight,
                                ),
                              ),
                              Text(
                                'UGX ${e.value}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimaryOnLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Sales Over Time ────────────────────────────────────────
              _card(
                title: 'Sales Over Time',
                child: salesOverTimeAsync.when(
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(
                      child:
                      CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => _errorText(e),
                  data: (data) {
                    if (data.isEmpty) {
                      return const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            'No sales in this period',
                            style: TextStyle(
                              color: AppColors.textSecondaryOnLight,
                            ),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: data.asMap().entries.map((entry) {
                            final i = entry.key;
                            final d = entry.value;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: (d['total'] as num).toDouble(),
                                  color: AppColors.primary,
                                  width: 10,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, meta) {
                                  if (v.toInt() >= data.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = data[v.toInt()]['date']
                                      .toString()
                                      .substring(5);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      date,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textSecondaryOnLight,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Revenue by Category ────────────────────────────────────
              _card(
                title: 'Revenue by Category',
                child: categoryAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _errorText(e),
                  data: (data) {
                    if (data.isEmpty) {
                      return const Text(
                        'No sales in this period',
                        style: TextStyle(
                          color: AppColors.textSecondaryOnLight,
                        ),
                      );
                    }
                    final maxRevenue = data
                        .map((d) => (d['revenue'] as num).toDouble())
                        .reduce((a, b) => a > b ? a : b);
                    return Column(
                      children: data.map<Widget>((cat) {
                        final revenue = (cat['revenue'] as num).toDouble();
                        final fraction =
                        maxRevenue > 0 ? revenue / maxRevenue : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat['category'] ?? 'Uncategorized',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                  Text(
                                    'UGX $revenue',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fraction.clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor: AppColors.surfaceMuted,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Most / Least Bought ────────────────────────────────────
              trendsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => _errorCard(e),
                data: (data) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _trendList(
                        'Most Bought',
                        data['most_bought'],
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _trendList(
                        'Least Bought',
                        data['least_bought'],
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Loans Summary ──────────────────────────────────────────
              _card(
                title: 'Loans',
                child: loansAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _errorText(e),
                  data: (data) => Row(
                    children: [
                      _miniStat(
                        'Outstanding',
                        'UGX ${data['outstanding_balance']}',
                        AppColors.warning,
                      ),
                      _miniStat(
                        'Overdue',
                        '${data['overdue_count']}',
                        AppColors.error,
                      ),
                      _miniStat(
                        'Written Off',
                        'UGX ${data['written_off_total']}',
                        AppColors.textSecondaryOnLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Cash Reconciliation ────────────────────────────────────
              _card(
                title: 'Cash Reconciliation',
                child: reconciliationAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _errorText(e),
                  data: (data) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _miniStat(
                            'Matched',
                            '${data['matched_count'] ?? 0}',
                            AppColors.success,
                          ),
                          _miniStat(
                            'Shortfalls',
                            '${data['shortfall_count'] ?? 0}',
                            AppColors.error,
                          ),
                          _miniStat(
                            'Pending',
                            '${data['pending_count'] ?? 0}',
                            AppColors.warning,
                          ),
                          _miniStat(
                            'Rejected',
                            '${data['rejected_count'] ?? 0}',
                            AppColors.textSecondaryOnLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.borderOnLight),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shortfall Variance',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOnLight),
                          ),
                          Text(
                            'UGX ${data['shortfall_variance'] ?? 0}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: ((data['shortfall_variance'] as num?) ?? 0) < 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Giveaways ──────────────────────────────────────────────
              _card(
                title: 'Giveaways',
                child: giveawaysAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _errorText(e),
                  data: (data) => Row(
                    children: [
                      _miniStat(
                        'Items Given',
                        '${data['total_quantity']}',
                        AppColors.primary,
                      ),
                      _miniStat(
                        'Value',
                        'UGX ${data['total_value']}',
                        AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Export PDF ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _exporting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  label: Text(
                    _exporting ? 'Exporting…' : 'Export as PDF',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _exporting ? null : _export,
                ),
              ),

              // ── Debug shortcut (bottom, under export) ──────────────────
              if (kShowDebugShortcut) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/debug_screen'),
                    icon: const Icon(
                      Icons.bug_report_outlined,
                      size: 16,
                      color: AppColors.textSecondaryOnLight,
                    ),
                    label: const Text(
                      'Debug Screen',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _breakdownLabel(String key) {
    switch (key) {
      case 'discounts':
        return 'Discounts';
      case 'non_business_out':
        return 'Non-Business (Out)';
      case 'non_business_in':
        return 'Non-Business (In)';
      case 'salaries':
        return 'Salaries Paid';
      case 'approved_shortfalls':
        return 'Approved Shortfalls';
      case 'written_off_loans':
        return 'Written-Off Loans';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  Widget _rangeChip(String label, VoidCallback onTap) {
    final selected = _selectedRange == label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderOnLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.textOnPrimary
                : AppColors.textPrimaryOnLight,
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryOnLight,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'UGX $value',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimaryOnLight,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _errorCard(Object e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Text(
        'Failed: $e',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _errorText(Object e) {
    return Text(
      'Failed: $e',
      style: const TextStyle(color: AppColors.error, fontSize: 13),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryOnLight,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendList(String title, List items, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimaryOnLight,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'No data',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryOnLight,
              ),
            )
          else
            ...items.map(
                  (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        i['item__name'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                    ),
                    Text(
                      '${i['total_qty']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final range = ref.read(selectedRangeProvider);
      final repo = ref.read(reportsRepositoryProvider);
      final fileUrl = await repo.exportPdf(range.start, range.end);
      final bytes = await repo.downloadPdf(fileUrl);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'profit_report_${range.start}_${range.end}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        await OpenFilex.open(file.path);
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
      if (mounted) setState(() => _exporting = false);
    }
  }
}