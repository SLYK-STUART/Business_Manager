import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    if (type.contains("shortfall") || type.contains("overage")) return Icons.warning_amber_rounded;
    if (type.contains("giveaway")) return Icons.card_giftcard_rounded;
    if (type.contains("approval")) return Icons.assignment_turned_in_rounded;
    if (type.contains("low_stock")) return Icons.inventory_2_rounded;
    if (type.contains("discount")) return Icons.sell_rounded;
    if (type.contains("overstay")) return Icons.bed_rounded;
    return Icons.notifications_rounded;
  }

  Color _colorFor(String type) {
    if (type.contains("shortfall") || type.contains("overage") || type.contains("overstay")) return AppColors.error;
    if (type.contains("approval") || type.contains("low_stock")) return AppColors.warning;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Notifications"), backgroundColor: AppColors.background, elevation: 0),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed: $e")),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("Nothing here", style: TextStyle(color: AppColors.textSecondaryOnLight)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                final dismissed = n["status"] == "dismissed";
                final color = _colorFor(n["type"] ?? "");

                return Dismissible(
                  key: ValueKey(n["id"]),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.close, color: AppColors.error),
                  ),
                  onDismissed: (_) async {
                    await ref.read(notificationsRepositoryProvider).dismiss(n["id"]);
                    ref.invalidate(notificationsListProvider);
                  },
                  child: Opacity(
                    opacity: dismissed ? 0.5 : 1,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOnLight)),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Icon(_iconFor(n["type"] ?? ""), size: 18, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n["message"] ?? "", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(n["created_at"]?.toString().substring(0, 16).replaceAll("T", " ") ?? "", style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryOnLight)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}