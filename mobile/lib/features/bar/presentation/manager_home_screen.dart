import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/item_providers.dart';

class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final itemsAsync = ref.watch(itemListProvider);

    final lowStockCount = itemsAsync.maybeWhen(
      data: (items) => items.where((i) => i["current_stock"] <= i["low_stock_threshold"]).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(itemListProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: userAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (user) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, ${user["name"]}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOnLight),
                          ),
                          const SizedBox(height: 2),
                          const Text("Let's get to work", style: TextStyle(color: AppColors.textSecondaryOnLight, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: const BoxDecoration(color: AppColors.surfaceDark, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.person_outline),
                          color: Colors.white,
                          onPressed: () => Navigator.of(context).pushNamed("/profile"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (lowStockCount > 0) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed("/items"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "$lowStockCount item${lowStockCount == 1 ? '' : 's'} running low on stock",
                            style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text("BAR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOnLight, letterSpacing: 1)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _ActionCard(icon: Icons.point_of_sale_rounded, label: "Sell Item", color: AppColors.primary, onTap: () => Navigator.of(context).pushNamed("/sell")),
                  _ActionCard(icon: Icons.inventory_rounded, label: "Restock", color: AppColors.info, onTap: () => Navigator.of(context).pushNamed("/restock")),
                  _ActionCard(icon: Icons.request_page_rounded, label: "New Loan", color: AppColors.success, onTap: () => Navigator.of(context).pushNamed("/loan_create")),
                  _ActionCard(icon: Icons.card_giftcard_rounded, label: "Giveaway", color: AppColors.error, onTap: () => Navigator.of(context).pushNamed("/giveaway")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SmallLink(icon: Icons.inventory_2_outlined, label: "Items", onTap: () => Navigator.of(context).pushNamed("/items"))),
                  const SizedBox(width: 10),
                  Expanded(child: _SmallLink(icon: Icons.request_page_outlined, label: "Loans", onTap: () => Navigator.of(context).pushNamed("/loans"))),
                  const SizedBox(width: 10),
                  Expanded(child: _SmallLink(icon: Icons.swap_horiz, label: "Non-Business", onTap: () => Navigator.of(context).pushNamed("/nbt"))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _SmallLink(icon: Icons.payments_outlined, label: "Cash Collection", onTap: () => Navigator.of(context).pushNamed("/cash_collection"))),
                  const SizedBox(width: 10),
                  Expanded(child: _SmallLink(icon: Icons.add_box_outlined, label: "Add Item", onTap: () => Navigator.of(context).pushNamed("/add_item"))),
                  const SizedBox(width: 10),
                  Expanded(child: _SmallLink(icon: Icons.category_outlined, label: "Categories", onTap: () => Navigator.of(context).pushNamed("/categories"))),
                ],
              ),

              const SizedBox(height: 28),
              const Text("ROOMS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOnLight, letterSpacing: 1)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _ActionCard(icon: Icons.bed_rounded, label: "Rooms", color: AppColors.primary, onTap: () => Navigator.of(context).pushNamed("/rooms")),
                  _ActionCard(icon: Icons.payments_rounded, label: "Rooms Cash Collection", color: AppColors.info, onTap: () => Navigator.of(context).pushNamed("/rooms_cash_collection")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimaryOnLight)),
          ],
        ),
      ),
    );
  }
}

class _SmallLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOnLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondaryOnLight),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryOnLight, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}