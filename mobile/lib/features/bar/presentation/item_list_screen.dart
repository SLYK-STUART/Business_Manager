import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/item_providers.dart';
import '../domain/category_provider.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  String? _selectedCategoryId;

  bool _isLowStock(dynamic item) {
    final stock = (item['current_stock'] as num?) ?? 0;
    final threshold = (item['low_stock_threshold'] as num?) ?? 0;
    return stock <= threshold;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Items',
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
          // ── Category chips ──────────────────────────────────────────
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategoryId == null,
                      onSelected: () =>
                          setState(() => _selectedCategoryId = null),
                    ),
                    ...categories.map(
                          (c) => _CategoryChip(
                        label: c['name'] ?? '',
                        selected: _selectedCategoryId == c['id'],
                        onSelected: () => setState(
                              () => _selectedCategoryId = c['id'],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Grid ────────────────────────────────────────────────────
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load items:\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
              data: (items) {
                var filtered = _selectedCategoryId == null
                    ? List<dynamic>.from(items)
                    : items
                    .where((i) => i['category'] == _selectedCategoryId)
                    .toList();

                // Low stock first, then by name
                filtered.sort((a, b) {
                  final aLow = _isLowStock(a);
                  final bLow = _isLowStock(b);
                  if (aLow && !bLow) return -1;
                  if (!aLow && bLow) return 1;
                  final aName = (a['name'] ?? '').toString().toLowerCase();
                  final bName = (b['name'] ?? '').toString().toLowerCase();
                  return aName.compareTo(bName);
                });

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(
                        color: AppColors.textSecondaryOnLight,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(itemListProvider),
                  child: GridView.builder(
                    // Clearance for bottom nav
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(
                          '/item_detail',
                          arguments: item['id'],
                        ),
                        child: _ItemGridCard(
                          item: item,
                          isLowStock: _isLowStock(item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid card (same visual language as Sell screen) ───────────────────

class _ItemGridCard extends StatelessWidget {
  final dynamic item;
  final bool isLowStock;

  const _ItemGridCard({
    required this.item,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final stock = item['current_stock'] ?? 0;
    final hasPhoto =
        item['photo_url'] != null && item['photo_url'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: isLowStock
                        ? Border.all(
                      color: AppColors.error.withOpacity(0.45),
                      width: 1.5,
                    )
                        : null,
                    image: hasPhoto
                        ? DecorationImage(
                      image: NetworkImage(item['photo_url']),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: !hasPhoto
                      ? const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textSecondaryOnLight,
                      size: 32,
                    ),
                  )
                      : null,
                ),
              ),

              // Stock badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? AppColors.error
                        : AppColors.stockBadge,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$stock left',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLowStock
                          ? Colors.white
                          : AppColors.stockBadgeText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item['name'] ?? 'Unnamed',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLowStock
                ? AppColors.error
                : AppColors.textPrimaryOnLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'UGX ${item['selling_price']}',
          style: TextStyle(
            fontSize: 12,
            color: isLowStock
                ? AppColors.error.withOpacity(0.8)
                : AppColors.textSecondaryOnLight,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceMuted,
        labelStyle: TextStyle(
          color: selected
              ? AppColors.textOnPrimary
              : AppColors.textSecondaryOnLight,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.borderOnLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }
}