import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/category_provider.dart';
import '../domain/item_providers.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  final _nameController = TextEditingController();
  bool _submitting = false;
  String? _selectedCategoryId; // null = Uncategorized

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: Column(
        children: [
          // ── Add category ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryOnLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New category name',
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _addCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: _submitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                        : const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Category chips ──────────────────────────────────────────────
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Failed: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (categories) {
              final chips = <_CategoryChipData>[
                _CategoryChipData(id: null, name: 'Uncategorized'),
                ...categories.map((c) => _CategoryChipData(
                  id: c['id']?.toString(),
                  name: c['name']?.toString() ?? 'Unnamed',
                )),
              ];

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final chip = chips[i];
                    final selected = _selectedCategoryId == chip.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategoryId = chip.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.borderOnLight,
                          ),
                        ),
                        child: Text(
                          chip.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondaryOnLight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Items grid ──────────────────────────────────────────────────
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Failed: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (items) {
                final filtered = items.where((item) {
                  final cat = item['category']?.toString();
                  if (_selectedCategoryId == null) {
                    return cat == null || cat.isEmpty;
                  }
                  return cat == _selectedCategoryId;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedCategoryId == null
                          ? 'No uncategorized items'
                          : 'No items in this category',
                      style: const TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];

                    return GestureDetector(
                      onTap: () => _showChangeCategorySheet(context, item),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOnLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: (item['photo_url'] != null &&
                                    item['photo_url']
                                        .toString()
                                        .isNotEmpty)
                                    ? Image.network(
                                  item['photo_url'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      _photoPlaceholder(),
                                )
                                    : _photoPlaceholder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['name'] ?? 'Unnamed',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryOnLight,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to change',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 28,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(categoryRepositoryProvider).createCategory(name);
      ref.invalidate(categoryListProvider);
      _nameController.clear();
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showChangeCategorySheet(BuildContext context, dynamic item) {
    final categoriesAsync = ref.read(categoryListProvider);
    final currentCategoryId = item['category']?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderOnLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Change category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['name'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryOnLight,
                ),
              ),
              const SizedBox(height: 16),

              // Option: Remove from category
              if (currentCategoryId != null)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderOnLight),
                  ),
                  leading: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove from category',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _assignCategory(item['id'], null, clear: true);
                  },
                ),

              if (currentCategoryId != null) const SizedBox(height: 8),

              // Category list
              categoriesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Text('Failed: $e',
                    style: const TextStyle(color: AppColors.error)),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No categories yet. Create one first.',
                        style: TextStyle(color: AppColors.textSecondaryOnLight),
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final cat = categories[i];
                        final isCurrent =
                            cat['id']?.toString() == currentCategoryId;

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.borderOnLight,
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          title: Text(
                            cat['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.textPrimaryOnLight,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_rounded,
                              color: AppColors.primary)
                              : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondaryOnLight,
                          ),
                          onTap: isCurrent
                              ? null
                              : () async {
                            Navigator.pop(context);
                            await _assignCategory(
                              item['id'],
                              cat['id']?.toString(),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignCategory(
      String itemId,
      String? categoryId, {
        bool clear = false,
      }) async {
    try {
      await ref.read(itemRepositoryProvider).updateItem(
        itemId,
        categoryId: categoryId,
        clearCategory: clear,
      );
      ref.invalidate(itemListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              clear ? 'Removed from category' : 'Category updated',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    }
  }
}

class _CategoryChipData {
  final String? id;
  final String name;

  _CategoryChipData({required this.id, required this.name});
}