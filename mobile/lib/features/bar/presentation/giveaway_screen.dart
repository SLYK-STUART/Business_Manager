import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/giveaway_cart_provider.dart';
import '../domain/item_providers.dart';
import '../data/giveaway_repository.dart';

final giveawayRepositoryProvider = Provider(
      (ref) => GiveawayRepository(ref.watch(apiClientProvider)),
);

class GiveawayScreen extends ConsumerStatefulWidget {
  const GiveawayScreen({super.key});

  @override
  ConsumerState<GiveawayScreen> createState() => _GiveawayScreenState();
}

class _GiveawayScreenState extends ConsumerState<GiveawayScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _submitting = false;
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _stockOf(dynamic item) {
    final raw = item['current_stock'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);
    final cart = ref.watch(giveawayCartProvider);
    final selectedLines = cart.where((l) => l.quantity > 0).toList();
    final totalQty = selectedLines.fold<int>(0, (sum, l) => sum + l.quantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _searching
                        ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOnLight,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondaryOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    )
                        : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giveaway',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Free / unpaid items',
                          style: TextStyle(
                            color: AppColors.textSecondaryOnLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _searching
                          ? AppColors.error.withOpacity(0.12)
                          : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _searching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        color: _searching
                            ? AppColors.error
                            : AppColors.textSecondaryOnLight,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_searching) {
                            _searchController.clear();
                            _query = '';
                          }
                          _searching = !_searching;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Recipient (top) ──────────────────────────────────
                    const Text(
                      'RECIPIENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryOnLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderOnLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryOnLight,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Recipient name',
                          labelStyle: TextStyle(
                            color: AppColors.textSecondaryOnLight,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textSecondaryOnLight,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),

                    // ── Selected items (detailed) ───────────────────────
                    if (selectedLines.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            'SELECTED ITEMS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondaryOnLight,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${selectedLines.length} · Qty $totalQty',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => ref
                                .read(giveawayCartProvider.notifier)
                                .clear(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Clear all',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ...selectedLines.map((line) {
                        // Find full item for photo / stock / price
                        final items =
                            ref.read(itemListProvider).value ?? [];
                        final item = items.cast<dynamic>().firstWhere(
                              (it) => it['id'] == line.itemId,
                          orElse: () => null,
                        );
                        final stock = item != null ? _stockOf(item) : 0;
                        final price = item?['selling_price'];
                        final hasPhoto = item != null &&
                            item['photo_url'] != null &&
                            item['photo_url'].toString().isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: hasPhoto
                                      ? Image.network(
                                    item['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  )
                                      : _thumbPlaceholder(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimaryOnLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      price != null
                                          ? 'UGX $price  ·  Stock $stock'
                                          : 'Stock $stock',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors
                                            .textSecondaryOnLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                          Icons.remove_rounded,
                                          size: 18),
                                      color: AppColors.textPrimaryOnLight,
                                      onPressed: () => ref
                                          .read(giveawayCartProvider
                                          .notifier)
                                          .addOrUpdate(
                                        line.itemId,
                                        line.name,
                                        line.quantity - 1,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${line.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors
                                              .textPrimaryOnLight,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      color: line.quantity < stock
                                          ? AppColors.error
                                          : AppColors
                                          .textSecondaryOnLight
                                          .withOpacity(0.3),
                                      onPressed: line.quantity < stock
                                          ? () => ref
                                          .read(giveawayCartProvider
                                          .notifier)
                                          .addOrUpdate(
                                        line.itemId,
                                        line.name,
                                        line.quantity + 1,
                                      )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),

                    // ── Select items header ─────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SELECT ITEMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryOnLight,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Item grid ───────────────────────────────────────
                    itemsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Failed: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (items) {
                        final filtered = _query.isEmpty
                            ? items
                            : items
                            .where((it) => it['name']
                            .toString()
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                            .toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                _query.isEmpty
                                    ? 'No items available'
                                    : 'No items match "$_query"',
                                style: const TextStyle(
                                  color: AppColors.textSecondaryOnLight,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final itemId = item['id'];
                            final itemName =
                                item['name']?.toString() ?? '';
                            final stock = _stockOf(item);
                            final outOfStock = stock <= 0;

                            final inCart = cart.firstWhere(
                                  (l) => l.itemId == itemId,
                              orElse: () => GiveawayLine(
                                  itemId: '', name: '', quantity: 0),
                            );
                            final qty = inCart.quantity;
                            final selected = qty > 0;
                            final hasPhoto = item['photo_url'] != null &&
                                item['photo_url'].toString().isNotEmpty;

                            return GestureDetector(
                              onTap: outOfStock
                                  ? null
                                  : () => ref
                                  .read(giveawayCartProvider.notifier)
                                  .addOrUpdate(
                                  itemId, itemName, qty + 1),
                              child: Opacity(
                                opacity: outOfStock ? 0.5 : 1,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                AppColors.surfaceMuted,
                                                borderRadius:
                                                BorderRadius.circular(
                                                    14),
                                                border: selected
                                                    ? Border.all(
                                                  color:
                                                  AppColors.error,
                                                  width: 2,
                                                )
                                                    : null,
                                                image: hasPhoto
                                                    ? DecorationImage(
                                                  image: NetworkImage(
                                                      item[
                                                      'photo_url']),
                                                  fit: BoxFit.cover,
                                                )
                                                    : null,
                                              ),
                                              child: !hasPhoto
                                                  ? const Center(
                                                child: Icon(
                                                  Icons
                                                      .card_giftcard_rounded,
                                                  color: AppColors
                                                      .textSecondaryOnLight,
                                                  size: 28,
                                                ),
                                              )
                                                  : null,
                                            ),
                                          ),
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 6,
                                                  vertical: 3),
                                              decoration: BoxDecoration(
                                                color: outOfStock
                                                    ? AppColors.error
                                                    : AppColors.stockBadge,
                                                borderRadius:
                                                BorderRadius.circular(
                                                    20),
                                              ),
                                              child: Text(
                                                outOfStock
                                                    ? 'Out'
                                                    : '$stock',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                  FontWeight.w700,
                                                  color: outOfStock
                                                      ? Colors.white
                                                      : AppColors
                                                      .stockBadgeText,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (selected)
                                            Positioned(
                                              bottom: 6,
                                              left: 6,
                                              child: Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      20),
                                                ),
                                                child: Text(
                                                  '×$qty',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                    FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      itemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? AppColors.error
                                            : AppColors
                                            .textPrimaryOnLight,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'UGX ${item['selling_price']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors
                                            .textSecondaryOnLight,
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
                  ],
                ),
              ),
            ),

            // ── Bottom action bar ──────────────────────────────────────
            if (selectedLines.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'Give Away $totalQty item${totalQty == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(
          Icons.card_giftcard_rounded,
          size: 22,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a recipient name'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final cart = ref.read(giveawayCartProvider);
      final lineItems = cart
          .where((l) => l.quantity > 0)
          .map((l) => {'item_id': l.itemId, 'quantity': l.quantity})
          .toList();
      await ref
          .read(giveawayRepositoryProvider)
          .createGiveawayBatch(_nameController.text.trim(), lineItems);
      ref.read(giveawayCartProvider.notifier).clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            const Text('Giveaway logged — pending owner approval'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}