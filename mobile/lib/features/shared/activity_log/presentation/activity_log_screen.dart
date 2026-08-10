import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/data/../activity_log_repository.dart';

final activityLogRepositoryProvider = Provider((ref) => ActivityLogRepository(ref.watch(apiClientProvider)));

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  final List<dynamic> _logs = [];
  String? _nextCursor;
  bool _loading = false;
  bool _initialLoaded = false;
  String? _moduleFilter;

  @override
  void initState() {
    super.initState();
    _loadMore(reset: true);
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(activityLogRepositoryProvider).list(
        cursor: reset ? null : _nextCursor,
        module: _moduleFilter,
      );
      setState(() {
        if (reset) _logs.clear();
        _logs.addAll(result["results"] ?? []);
        _nextCursor = result["next"];
        _initialLoaded = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconFor(String action) {
    if (action.contains("sale")) return Icons.point_of_sale_rounded;
    if (action.contains("price")) return Icons.sell_rounded;
    if (action.contains("stock") || action.contains("restock")) return Icons.inventory_2_rounded;
    if (action.contains("giveaway")) return Icons.card_giftcard_rounded;
    if (action.contains("checkin") || action.contains("checkout") || action.contains("booking")) return Icons.bed_rounded;
    if (action.contains("approval")) return Icons.assignment_turned_in_rounded;
    return Icons.circle_notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Activity Log"), backgroundColor: AppColors.background, elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text("All")),
                ButtonSegment(value: "bar", label: Text("Bar")),
                ButtonSegment(value: "rooms", label: Text("Rooms")),
              ],
              selected: {_moduleFilter},
              onSelectionChanged: (s) {
                setState(() => _moduleFilter = s.first);
                _loadMore(reset: true);
              },
            ),
          ),
          Expanded(
            child: !_initialLoaded
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
              onNotification: (scroll) {
                if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200 && _nextCursor != null && !_loading) {
                  _loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _logs.length + (_nextCursor != null ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _logs.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final log = _logs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOnLight)),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconFor(log["action_type"] ?? ""), size: 16, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((log["action_type"] ?? "").toString().replaceAll("_", " "), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                              Text(log["actor_name"] ?? "System", style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryOnLight)),
                            ],
                          ),
                        ),
                        Text(log["timestamp"]?.toString().substring(11, 16) ?? "", style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryOnLight)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}