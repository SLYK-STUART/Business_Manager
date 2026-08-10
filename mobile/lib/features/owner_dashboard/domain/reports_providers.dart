import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider((ref) => ReportsRepository(ref.watch(apiClientProvider)));

class DateRange {
  final String start;
  final String end;
  DateRange(this.start, this.end);
}

final selectedRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  return DateRange(start.toIso8601String().substring(0, 10), now.toIso8601String().substring(0, 10));
});

final profitReportProvider = FutureProvider.autoDispose((ref) async {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(reportsRepositoryProvider).getProfitReport(range.start, range.end);
});

final revenueExpandedProvider = StateProvider<bool>((ref) => false);

final roomReportProvider = FutureProvider.autoDispose((ref) async {
  final range = ref.watch(selectedRangeProvider);
  final expanded = ref.watch(revenueExpandedProvider);
  return ref.watch(reportsRepositoryProvider).getRoomReport(range.start, range.end, revenueLimit: expanded ? 100 : 5);
});

final trendsProvider = FutureProvider.autoDispose((ref) async {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(reportsRepositoryProvider).getTrends(range.start, range.end);
});