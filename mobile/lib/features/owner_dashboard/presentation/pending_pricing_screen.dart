import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/pending_pricing_providers.dart';

class PendingPricingScreen extends ConsumerWidget {
  const PendingPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(pendingPricingListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Set Buying Prices"), backgroundColor: AppColors.background, elevation: 0),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed: $e")),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("Nothing pending — all restocks priced ✅", style: TextStyle(color: AppColors.textSecondaryOnLight)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingPricingListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final entry = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry["item_name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text("+${entry["quantity"]} units — by ${entry["restocked_by"] ?? "Unknown"}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _showPriceSheet(context, ref, entry),
                            child: const Text("Set Buying Price"),
                          ),
                        ),
                      ],
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

  void _showPriceSheet(BuildContext context, WidgetRef ref, dynamic entry) {
    String mode = "unit";
    final priceController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry["item_name"], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("${entry["quantity"]} units added", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: "unit", label: Text("Per unit")),
                  ButtonSegment(value: "bulk", label: Text("Total (crate)")),
                ],
                selected: {mode},
                onSelectionChanged: (s) => setSheetState(() => mode = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: mode == "unit" ? "Buying price per unit" : "Total price paid for ${entry["quantity"]} units",
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    setSheetState(() => submitting = true);
                    try {
                      await ref.read(pendingPricingRepositoryProvider).setPrice(
                        entry["restock_id"],
                        mode: mode,
                        unitPrice: mode == "unit" ? double.tryParse(priceController.text) : null,
                        totalPrice: mode == "bulk" ? double.tryParse(priceController.text) : null,
                      );
                      ref.invalidate(pendingPricingListProvider);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
                    } finally {
                      setSheetState(() => submitting = false);
                    }
                  },
                  child: submitting ? const CircularProgressIndicator() : const Text("Save Price"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}