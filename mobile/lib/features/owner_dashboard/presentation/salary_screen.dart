import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/salary_providers.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  Future<void> _pay(String salaryId, dynamic defaultAmount) async {
    final controller = TextEditingController(text: defaultAmount.toString());
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pay Salary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (UGX)")),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm Payment"),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(salaryRepositoryProvider).paySalary(salaryId, amount: double.tryParse(controller.text));
        ref.invalidate(salaryListProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salary paid")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salariesAsync = ref.watch(salaryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Salaries"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showSetSalarySheet(context)),
        ],
      ),
      body: salariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed: $e")),
        data: (salaries) {
          if (salaries.isEmpty) {
            return const Center(child: Text("No salaries set yet", style: TextStyle(color: Colors.grey)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(salaryListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: salaries.length,
              itemBuilder: (context, i) {
                final s = salaries[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(s["staff_name"] ?? "Staff"),
                    subtitle: Text("Rate: UGX ${s["amount"]}"),
                    trailing: TextButton(
                      onPressed: () => _pay(s["id"], s["amount"]),
                      child: const Text("Pay"),
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

  void _showSetSalarySheet(BuildContext context) {
    dynamic selectedStaff;
    final amountController = TextEditingController();
     bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Consumer(builder: (context, ref, _) {
            final staffAsync = ref.watch(staffListProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Set Salary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                staffAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text("Failed to load staff: $e"),
                  data: (staff) => DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: "Staff member"),
                    items: staff.map<DropdownMenuItem>((s) => DropdownMenuItem(value: s, child: Text(s["name"]))).toList(),
                    onChanged: (v) => setSheetState(() => selectedStaff = v),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount (UGX)"),
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : () async {
                      if (selectedStaff == null || amountController.text.isEmpty) return;
                      setSheetState(() => submitting = true);
                      try {
                        await ref.read(salaryRepositoryProvider).setSalary(
                          selectedStaff["id"], double.parse(amountController.text)
                        );
                        ref.invalidate(salaryListProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
                      } finally {
                        setSheetState(() => submitting = false);
                      }
                    },
                    child: submitting ? const CircularProgressIndicator() : const Text("Save Salary"),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}