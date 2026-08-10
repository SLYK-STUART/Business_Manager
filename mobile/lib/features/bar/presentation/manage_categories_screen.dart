import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_provider.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> {
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "New category name"),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitting ? null : _addCategory,
                  child: _submitting ? const CircularProgressIndicator() : const Text("Add"),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Failed: $e")),
              data: (categories) => ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, i) => ListTile(title: Text(categories[i]["name"])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(categoryRepositoryProvider).createCategory(_nameController.text);
      ref.invalidate(categoryListProvider);
      _nameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}