import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/item_providers.dart';
import '../domain/cart_provider.dart';
import '../domain/category_provider.dart';
import '../../../core/theme/app_colors.dart';

class SellItemScreen extends ConsumerStatefulWidget {
  const SellItemScreen({super.key});

  @override
  ConsumerState<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends ConsumerState<SellItemScreen> {
  String _query = '';
  String? _selectedCategoryId; // null = All

  CartLine? cartEntryFor(String itemId) {
    final cart = ref.read(cartProvider);
    for (final line in cart) {
      if (line.itemId == itemId) return line;
    }
    return null;
  }

  Future<void> _refreshItems() async {
    ref.invalidate(itemListProvider);
    // Wait until the new data is available so the indicator dismisses cleanly
    await ref.read(itemListProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final cart = ref.watch(cartProvider);

    // id → name lookup
    final categoryMap = <String, String>{};
    categoriesAsync.whenData((cats) {
      for (final c in cats) {
        final id = c['id']?.toString();
        final name = c['name']?.toString();
        if (id != null && name != null && name.isNotEmpty) {
          categoryMap[id] = name;
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryOnLight,
        title: const Text(
          'Sell Item',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Manual refresh button
          IconButton(
            tooltip: 'Refresh stock',
            onPressed: _refreshItems,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (cart.isNotEmpty)
            IconButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed('/sale-confirm');
                // After a sale, force a fresh stock fetch
                if (mounted) await _refreshItems();
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${cart.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimaryOnLight),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondaryOnLight,
                ),
                hintText: 'Search item…',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),

          // ── Category chips ──────────────────────────────────────────
          categoriesAsync.when(
            loading: () => const SizedBox(height: 44),
            error: (_, __) => const SizedBox(height: 44),
            data: (categories) {
              final chips = <_CatChip>[
                const _CatChip(id: null, name: 'All'),
                ...categories.map(
                      (c) => _CatChip(
                    id: c['id']?.toString(),
                    name: c['name']?.toString() ?? 'Unnamed',
                  ),
                ),
              ];

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
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
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(20),
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
                                : AppColors.textPrimaryOnLight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Grid (now refreshable) ──────────────────────────────────
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _refreshItems,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                final filtered = items.where((i) {
                  final matchesQuery = i['name']
                      .toString()
                      .toLowerCase()
                      .contains(_query);

                  final itemCatId = i['category']?.toString();
                  final matchesCategory = _selectedCategoryId == null ||
                      itemCatId == _selectedCategoryId;

                  return matchesQuery && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _refreshItems,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(
                              color: AppColors.textSecondaryOnLight,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshItems,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 170),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return GestureDetector(
                        onTap: () => _showQuantitySheet(item),
                        child: _ItemGridCard(item: item),
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

  // ── Quantity bottom sheet ─────────────────────────────────────────────
  void _showQuantitySheet(dynamic item) {
    final unitPrice = double.parse(item['selling_price'].toString());
    final stock = (item['current_stock'] as num).toInt();

    if (stock <= 0) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOnLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.textSecondaryOnLight,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item['name'],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Out of stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderOnLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.textPrimaryOnLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final existing = cartEntryFor(item['id'].toString());
    int quantity = existing?.quantity ?? 1;
    if (quantity > stock) quantity = stock;
    bool applyDiscount = (existing?.discount ?? 0) > 0;
    double discount = existing?.discount ?? 0;
    final discountController = TextEditingController(
      text: discount > 0 ? discount.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final subtotal =
              (unitPrice * quantity) - (applyDiscount ? discount : 0);

          return Padding(
            // Keeps the sheet above the keyboard
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                // Never taller than ~90% of the screen
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderOnLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // … keep the rest of your sheet widgets unchanged
                    // (header, quantity, subtotal, discount toggle + field,
                    //  total, Add to cart button)

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            image: item['photo_url'] != null &&
                                item['photo_url'] != ''
                                ? DecorationImage(
                              image: NetworkImage(item['photo_url']),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: (item['photo_url'] == null ||
                              item['photo_url'] == '')
                              ? const Icon(
                            Icons.image_outlined,
                            color: AppColors.textSecondaryOnLight,
                            size: 20,
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryOnLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UGX ${unitPrice.toStringAsFixed(2)} each · $stock in stock',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: quantity >= stock
                                      ? AppColors.warning
                                      : AppColors.textSecondaryOnLight,
                                  fontWeight: quantity >= stock
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textSecondaryOnLight,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'QUANTITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StepperButton(
                          icon: Icons.remove,
                          filled: false,
                          onTap: () => setSheetState(
                                () => quantity = quantity > 1 ? quantity - 1 : 1,
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                        _StepperButton(
                          icon: Icons.add,
                          filled: true,
                          enabled: quantity < stock,
                          onTap: () => setSheetState(() {
                            if (quantity < stock) quantity++;
                          }),
                        ),
                      ],
                    ),
                    if (quantity >= stock)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Max available',
                          style:
                          TextStyle(fontSize: 12, color: AppColors.warning),
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Divider(color: AppColors.borderOnLight, height: 1),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryOnLight,
                          ),
                        ),
                        Text(
                          'UGX ${(unitPrice * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderOnLight, height: 1),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 18,
                              color: AppColors.textPrimaryOnLight,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Apply discount',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimaryOnLight,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: applyDiscount,
                          activeColor: AppColors.textOnPrimary,
                          activeTrackColor: AppColors.toggleActive,
                          inactiveTrackColor: AppColors.toggleInactive,
                          onChanged: (v) =>
                              setSheetState(() => applyDiscount = v),
                        ),
                      ],
                    ),

                    if (applyDiscount)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.textPrimaryOnLight,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Discount amount',
                            labelStyle: const TextStyle(
                              color: AppColors.textSecondaryOnLight,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) => setSheetState(
                                () => discount = double.tryParse(v) ?? 0,
                          ),
                        ),
                      ),

                    const Divider(color: AppColors.borderOnLight, height: 1),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction total · 1 line',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOnLight,
                          ),
                        ),
                        Text(
                          'UGX ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ref.read(cartProvider.notifier).addOrUpdate(
                            item['id'],
                            item['name'],
                            unitPrice,
                            quantity,
                          );
                          if (applyDiscount) {
                            ref
                                .read(cartProvider.notifier)
                                .setDiscount(item['id'], discount);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Add to cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────

class _CatChip {
  final String? id;
  final String name;
  const _CatChip({required this.id, required this.name});
}

class _ItemGridCard extends StatelessWidget {
  final dynamic item;
  const _ItemGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final stock = item['current_stock'];
    final hasPhoto = item['photo_url'] != null && item['photo_url'] != '';
    final isOutOfStock = (stock is num && stock <= 0);

    return Opacity(
      opacity: isOutOfStock ? 0.55 : 1,
      child: Column(
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? AppColors.error
                          : AppColors.stockBadge,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out' : '$stock left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOutOfStock
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
            item['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOnLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'UGX ${item['selling_price']}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryOnLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.filled,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.surfaceMuted,
          ),
          child: Icon(
            icon,
            color: filled
                ? AppColors.textOnPrimary
                : AppColors.textPrimaryOnLight,
          ),
        ),
      ),
    );
  }
}