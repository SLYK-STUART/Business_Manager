import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/reports_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final profitAsync = ref.watch(profitReportProvider);
    final trendsAsync = ref.watch(trendsProvider);
    final range = ref.watch(selectedRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profitReportProvider);
          ref.invalidate(trendsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                _rangeChip(context, "This Month", () => _setThisMonth()),
                _rangeChip(context, "Last 30 Days", () => _setLastDays(30)),
                _rangeChip(context, "Last 3 Months", () => _setLastDays(90)),
              ],
            ),
            const SizedBox(height: 16),
            profitAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text("Failed: $e"),
              data: (data) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pushNamed("/debug_screen"),
                          child: const Text('Debug Screen')
                      ),
                      const Text("Projected vs Actual Profit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statColumn("Projected", data["projected_profit"], Colors.black),
                          _statColumn("Actual", data["actual_profit"], Colors.green),
                          _statColumn("Divergence", data["divergence"], data["divergence"] < 0 ? Colors.red : Colors.green),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text("Why the difference?", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...(data["breakdown"] as Map<String, dynamic>).entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(e.key), Text("UGX ${e.value}", style: const TextStyle(fontWeight: FontWeight.bold))],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            trendsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text("Failed: $e"),
              data: (data) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _trendList("Most Bought", data["most_bought"], Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _trendList("Least Bought", data["least_bought"], Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: _exporting ? const Text("Exporting...") : const Text("Export as PDF"),
                onPressed: _exporting ? null : _export,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(BuildContext context, String label, VoidCallback onTap) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }

  Widget _statColumn(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text("UGX $value", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _trendList(String title, List items, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(i["item__name"] ?? "", overflow: TextOverflow.ellipsis)),
                  Text("${i["total_qty"]}", style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _setThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    ref.read(selectedRangeProvider.notifier).state =
        DateRange(start.toIso8601String().substring(0, 10), now.toIso8601String().substring(0, 10));
  }

  void _setLastDays(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    ref.read(selectedRangeProvider.notifier).state =
        DateRange(start.toIso8601String().substring(0, 10), now.toIso8601String().substring(0, 10));
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final range = ref.read(selectedRangeProvider);
      final url = await ref.read(reportsRepositoryProvider).exportPdf(range.start, range.end);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exported: $url")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}