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

  String _dateLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final itemsAsync = ref.watch(itemListProvider);

    final lowStockItems = itemsAsync.maybeWhen(
      data: (items) => items
          .where((i) {
        final stock = (i['current_stock'] as num?) ?? 0;
        final threshold = (i['low_stock_threshold'] as num?) ?? 0;
        return stock <= threshold;
      })
          .toList(),
      orElse: () => <dynamic>[],
    );
    final lowStockCount = lowStockItems.length;
    final totalItems = itemsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(itemListProvider);
            ref.invalidate(currentUserProvider);
            await Future.wait([
              ref.read(itemListProvider.future),
              ref.read(currentUserProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: userAsync.when(
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 160,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryOnLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateLabel(),
                            style: const TextStyle(
                              color: AppColors.textSecondaryOnLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      data: (user) {
                        final name = user['name']?.toString() ?? '';
                        final initial = name.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}, $name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOnLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dateLabel(),
                              style: const TextStyle(
                                color: AppColors.textSecondaryOnLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/profile'),
                    child: userAsync.maybeWhen(
                      data: (user) {
                        final name = user['name']?.toString() ?? '';
                        final initial = name.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?';
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        );
                      },
                      orElse: () => Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Snapshot strip ──────────────────────────────────────────
              const SizedBox(height: 20),
              Row(
                children: [
                  _SnapshotChip(
                    label: 'Items',
                    value: '$totalItems',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  _SnapshotChip(
                    label: 'Low stock',
                    value: '$lowStockCount',
                    icon: Icons.warning_amber_rounded,
                    color: lowStockCount > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ],
              ),

              // ── Low stock alert ─────────────────────────────────────────
              if (lowStockCount > 0) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed('/restock'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$lowStockCount item${lowStockCount == 1 ? '' : 's'} low on stock',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Tap to restock quickly',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryOnLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                        if (lowStockItems.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: lowStockItems.take(4).map((item) {
                              final name =
                                  item['name']?.toString() ?? 'Item';
                              final stock =
                                  (item['current_stock'] as num?) ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                    AppColors.warning.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '$name · $stock left',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimaryOnLight,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (lowStockCount > 4)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '+${lowStockCount - 4} more',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning.withOpacity(0.8),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // ── BAR · Primary actions ───────────────────────────────────
              const SizedBox(height: 28),
              _SectionLabel('BAR · QUICK ACTIONS'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _ActionCard(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Sell Item',
                    color: AppColors.primary,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/sell'),
                  ),
                  _ActionCard(
                    icon: Icons.inventory_rounded,
                    label: 'Restock',
                    color: AppColors.info,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/restock'),
                  ),
                  _ActionCard(
                    icon: Icons.request_page_rounded,
                    label: 'New Loan',
                    color: AppColors.success,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/loan_create'),
                  ),
                  _ActionCard(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Giveaway',
                    color: AppColors.error,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/giveaway'),
                  ),
                ],
              ),

              // ── BAR · Manage ────────────────────────────────────────────
              const SizedBox(height: 20),
              _SectionLabel('MANAGE'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOnLight),
                ),
                child: Column(
                  children: [
                    _ManageTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Items',
                      subtitle: totalItems > 0 ? '$totalItems in catalog' : null,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/items'),
                    ),
                    const Divider(height: 1, color: AppColors.borderOnLight),
                    _ManageTile(
                      icon: Icons.request_page_outlined,
                      label: 'Loans',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/loans'),
                    ),
                    const Divider(height: 1, color: AppColors.borderOnLight),
                    _ManageTile(
                      icon: Icons.payments_outlined,
                      label: 'Cash collection',
                      onTap: () => Navigator.of(context)
                          .pushNamed('/cash_collection'),
                    ),
                    const Divider(height: 1, color: AppColors.borderOnLight),
                    _ManageTile(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Non-business',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/nbt'),
                    ),
                    const Divider(height: 1, color: AppColors.borderOnLight),
                    _ManageTile(
                      icon: Icons.add_box_outlined,
                      label: 'Add item',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/add_item'),
                    ),
                    const Divider(height: 1, color: AppColors.borderOnLight),
                    _ManageTile(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/categories'),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              // ── ROOMS ───────────────────────────────────────────────────
              const SizedBox(height: 28),
              _SectionLabel('ROOMS'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _ActionCard(
                    icon: Icons.bed_rounded,
                    label: 'Rooms',
                    color: AppColors.primary,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/rooms'),
                  ),
                  _ActionCard(
                    icon: Icons.payments_rounded,
                    label: 'Room cash',
                    color: AppColors.info,
                    onTap: () => Navigator.of(context)
                        .pushNamed('/rooms_cash_collection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondaryOnLight,
        letterSpacing: 1,
      ),
    );
  }
}

class _SnapshotChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SnapshotChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOnLight),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryOnLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderOnLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimaryOnLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _ManageTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondaryOnLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimaryOnLight,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}