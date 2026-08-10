import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/staff_providers.dart';

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffManagementListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Staff"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: () => _showAddStaffSheet(context, ref)),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed: $e")),
        data: (staff) {
          if (staff.isEmpty) {
            return const Center(child: Text("No staff added yet", style: TextStyle(color: AppColors.textSecondaryOnLight)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffManagementListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: staff.length,
              itemBuilder: (context, i) {
                final s = staff[i];
                final roles = (s["roles"] as List).cast<String>();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(s["name"] ?? ""),
                    subtitle: Text(s["phone"] ?? ""),
                    trailing: Wrap(
                      spacing: 4,
                      children: roles.map((r) => Chip(
                        label: Text(_roleLabel(r), style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
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

  String _roleLabel(String role) {
    switch (role) {
      case "bar_manager":
        return "Bar Manager";
      case "room_incharge":
        return "Room In-charge";
      case "owner":
        return "Owner";
      default:
        return role;
    }
  }

  void _showAddStaffSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final Set<String> selectedRoles = {};
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
              const Text("Add Staff", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full name")),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone number")),
              const SizedBox(height: 12),
              TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Temporary password")),
              const SizedBox(height: 16),
              const Text("Roles", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text("Bar Manager"),
                    selected: selectedRoles.contains("bar_manager"),
                    onSelected: (v) => setSheetState(() => v ? selectedRoles.add("bar_manager") : selectedRoles.remove("bar_manager")),
                  ),
                  FilterChip(
                    label: const Text("Room In-charge"),
                    selected: selectedRoles.contains("room_incharge"),
                    onSelected: (v) => setSheetState(() => v ? selectedRoles.add("room_incharge") : selectedRoles.remove("room_incharge")),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty || passwordController.text.isEmpty || selectedRoles.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields and select at least one role")));
                      return;
                    }
                    setSheetState(() => submitting = true);
                    try {
                      await ref.read(staffRepositoryProvider).createStaff(
                        nameController.text, phoneController.text, passwordController.text, selectedRoles.toList(),
                      );
                      ref.invalidate(staffManagementListProvider);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
                    } finally {
                      setSheetState(() => submitting = false);
                    }
                  },
                  child: submitting ? const CircularProgressIndicator() : const Text("Create Account"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}