import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/item_providers.dart';
import '../domain/cart_provider.dart';
// Adjust this relative path to match this file's actual location under lib/.
import '../../../core/theme/app_colors.dart';

class SellItemScreen extends ConsumerStatefulWidget {
  const SellItemScreen({super.key});

  @override
  ConsumerState<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends ConsumerState<SellItemScreen> {
  String _query = "";

  /// Looks up the current cart's CartLine for [itemId], if any.
  CartLine? cartEntryFor(String itemId) {
    final cart = ref.read(cartProvider);
    for (final line in cart) {
      if (line.itemId == itemId) return line;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryOnLight,
        title: const Text(
          "Sell Item",
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed("/sale-confirm"),
              child: Text(
                "Cart (${cart.length}) →",
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimaryOnLight),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryOnLight),
                hintText: "Search item…",
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
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text("Failed: $e", style: const TextStyle(color: AppColors.error)),
              ),
              data: (items) {
                final filtered = items.where((i) => i["name"].toLowerCase().contains(_query)).toList();
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantitySheet(dynamic item) {
    final unitPrice = double.parse(item["selling_price"].toString());
    final stock = (item["current_stock"] as num).toInt();

    // Out of stock — short-circuit to a minimal "out of stock" sheet.
    if (stock <= 0) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondaryOnLight, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                item["name"],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Out of stock",
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: AppColors.textPrimaryOnLight, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Prefill quantity from whatever's already in the cart for this item.
    final existing = cartEntryFor(item["id"].toString());
    int quantity = existing?.quantity ?? 1;
    if (quantity > stock) quantity = stock; // stock may have shrunk since it was added
    bool applyDiscount = (existing?.discount ?? 0) > 0;
    double discount = existing?.discount ?? 0;
    final discountController = TextEditingController(
      text: discount > 0 ? discount.toStringAsFixed(0) : "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final subtotal = (unitPrice * quantity) - (applyDiscount ? discount : 0);

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderOnLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header: thumbnail, name, price/stock, close button
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        image: item["photo_url"] != null && item["photo_url"] != ""
                            ? DecorationImage(
                          image: NetworkImage(item["photo_url"]),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: (item["photo_url"] == null || item["photo_url"] == "")
                          ? const Icon(Icons.image_outlined, color: AppColors.textSecondaryOnLight, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["name"],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryOnLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "UGX ${unitPrice.toStringAsFixed(2)} each · $stock in stock",
                            style: TextStyle(
                              fontSize: 13,
                              color: quantity >= stock ? AppColors.warning : AppColors.textSecondaryOnLight,
                              fontWeight: quantity >= stock ? FontWeight.w600 : FontWeight.w400,
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
                        child: const Icon(Icons.close, size: 18, color: AppColors.textSecondaryOnLight),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  "QUANTITY",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondaryOnLight,
                  ),
                ),
                const SizedBox(height: 8),

                // Quantity stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      filled: false,
                      onTap: () => setSheetState(() => quantity = quantity > 1 ? quantity - 1 : 1),
                    ),
                    Text(
                      "$quantity",
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
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Max available: $stock",
                      style: const TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),

                const SizedBox(height: 20),
                const Divider(color: AppColors.borderOnLight, height: 1),
                const SizedBox(height: 16),

                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Subtotal",
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOnLight),
                    ),
                    Text(
                      "\$${(unitPrice * quantity).toStringAsFixed(2)}",
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

                // Discount toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_offer_outlined, size: 18, color: AppColors.textPrimaryOnLight),
                        SizedBox(width: 8),
                        Text(
                          "Apply discount",
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOnLight),
                        ),
                      ],
                    ),
                    Switch(
                      value: applyDiscount,
                      activeColor: AppColors.textOnPrimary,
                      activeTrackColor: AppColors.toggleActive,
                      inactiveTrackColor: AppColors.toggleInactive,
                      onChanged: (v) => setSheetState(() => applyDiscount = v),
                    ),
                  ],
                ),

                if (applyDiscount)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimaryOnLight),
                      decoration: InputDecoration(
                        labelText: "Discount amount",
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnLight),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setSheetState(() => discount = double.tryParse(v) ?? 0),
                    ),
                  ),

                const Divider(color: AppColors.borderOnLight, height: 1),
                const SizedBox(height: 12),

                // Transaction total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Transaction total · 1 line",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOnLight),
                    ),
                    Text(
                      "\$${subtotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOnLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Review Sale button
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
                        item["id"],
                        item["name"],
                        unitPrice,
                        quantity,
                      );
                      if (applyDiscount) {
                        ref.read(cartProvider.notifier).setDiscount(item["id"], discount);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Review Sale",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ItemGridCard extends StatelessWidget {
  final dynamic item;
  const _ItemGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final stock = item["current_stock"];
    final hasPhoto = item["photo_url"] != null && item["photo_url"] != "";

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
                    image: hasPhoto
                        ? DecorationImage(image: NetworkImage(item["photo_url"]), fit: BoxFit.cover)
                        : null,
                  ),
                  child: !hasPhoto
                      ? const Center(
                    child: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondaryOnLight, size: 32),
                  )
                      : null,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.stockBadge,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$stock left",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stockBadgeText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item["name"],
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
          "UGX ${item["selling_price"]}",
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryOnLight),
        ),
      ],
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
            color: filled ? AppColors.textOnPrimary : AppColors.textPrimaryOnLight,
          ),
        ),
      ),
    );
  }
}