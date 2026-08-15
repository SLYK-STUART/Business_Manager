import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/superadmin_providers.dart';

class CreateBusinessScreen extends ConsumerStatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  ConsumerState<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends ConsumerState<CreateBusinessScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final Set<String> _modules = {};
  bool _submitting = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _modules.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final business = await ref.read(superadminRepositoryProvider).createBusiness(
        _nameController.text, _addressController.text, _modules.toList(),
      );
      ref.invalidate(businessListProvider);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed("/business-detail", arguments: business["id"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("New Business"), backgroundColor: AppColors.background, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Business name")),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Address (optional)")),
            const SizedBox(height: 20),
            const Text("Modules", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("Bar"),
                  selected: _modules.contains("bar"),
                  onSelected: (v) => setState(() => v ? _modules.add("bar") : _modules.remove("bar")),
                ),
                FilterChip(
                  label: const Text("Rooms"),
                  selected: _modules.contains("rooms"),
                  onSelected: (v) => setState(() => v ? _modules.add("rooms") : _modules.remove("rooms")),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: _submitting ? const CircularProgressIndicator() : const Text("Create Business"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}