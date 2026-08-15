import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cash_collection_repository.dart';

final cashCollectionRepositoryProvider = Provider(
      (ref) => CashCollectionRepository(ref.watch(apiClientProvider)),
);

final collectionSummaryProvider =
FutureProvider.family.autoDispose((ref, String module) async {
  return ref.watch(cashCollectionRepositoryProvider).getSummary(module);
});

class ExpectedCollectionsStatsScreen extends ConsumerStatefulWidget {
  const ExpectedCollectionsStatsScreen({super.key});

  @override
  ConsumerState<ExpectedCollectionsStatsScreen> createState() =>
      _ExpectedCollectionsStatsScreenState();
}

class _ExpectedCollectionsStatsScreenState
    extends ConsumerState<ExpectedCollectionsStatsScreen> {
  bool _barSalesExpanded = false;
  bool _barNbtExpanded = false;
  bool _roomsBookingsExpanded = false;

  int _selectedModule = 0;
  late final PageController _pageController =
  PageController(initialPage: _selectedModule);

  void _selectModule(int index) {
    if (index == _selectedModule) return;
    setState(() => _selectedModule = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barAsync = ref.watch(collectionSummaryProvider('bar'));
    final roomsAsync = ref.watch(collectionSummaryProvider('rooms'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Expected Collections',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              children: [
                _CombinedHero(barAsync: barAsync, roomsAsync: roomsAsync),
                const SizedBox(height: 12),
                _ModuleToggle(
                  selected: _selectedModule,
                  onChanged: _selectModule,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _selectedModule = i),
              children: [
                _ModulePage(
                  onRefresh: () async =>
                      ref.invalidate(collectionSummaryProvider('bar')),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ModuleHeader(
                        title: 'BAR',
                        icon: Icons.local_bar_rounded,
                        accent: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      _ModuleBody(
                        async: barAsync,
                        isRooms: false,
                        salesExpanded: _barSalesExpanded,
                        nbtExpanded: _barNbtExpanded,
                        onToggleSales: () => setState(
                                () => _barSalesExpanded = !_barSalesExpanded),
                        onToggleNbt: () => setState(
                                () => _barNbtExpanded = !_barNbtExpanded),
                      ),
                    ],
                  ),
                ),
                _ModulePage(
                  onRefresh: () async =>
                      ref.invalidate(collectionSummaryProvider('rooms')),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ModuleHeader(
                        title: 'ROOMS',
                        icon: Icons.hotel_rounded,
                        accent: AppColors.info,
                      ),
                      const SizedBox(height: 10),
                      _ModuleBody(
                        async: roomsAsync,
                        isRooms: true,
                        salesExpanded: _roomsBookingsExpanded,
                        nbtExpanded: false,
                        onToggleSales: () => setState(() =>
                        _roomsBookingsExpanded = !_roomsBookingsExpanded),
                        onToggleNbt: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Swipeable page ────────────────────────────────────────────────────────

class _ModulePage extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const _ModulePage({required this.child, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        // Clearance for floating bottom nav
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [child],
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────

class _CombinedHero extends StatelessWidget {
  final AsyncValue barAsync;
  final AsyncValue roomsAsync;

  const _CombinedHero({required this.barAsync, required this.roomsAsync});

  @override
  Widget build(BuildContext context) {
    num barExpected = 0;
    num roomsExpected = 0;

    barAsync.whenData((d) => barExpected = (d['expected_amount'] as num?) ?? 0);
    roomsAsync.whenData(
            (d) => roomsExpected = (d['expected_amount'] as num?) ?? 0);

    final total = barExpected + roomsExpected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: AppColors.goldSlab,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL EXPECTED',
            style: TextStyle(
              color: AppColors.textOnPrimary.withOpacity(0.65),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UGX $total',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroPill(label: 'Bar', value: 'UGX $barExpected'),
              const SizedBox(width: 8),
              _HeroPill(label: 'Rooms', value: 'UGX $roomsExpected'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.textOnPrimary.withOpacity(0.65),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle ────────────────────────────────────────────────────────────────

class _ModuleToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _ModuleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleTab(
              label: 'Bar',
              icon: Icons.local_bar_rounded,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _ToggleTab(
              label: 'Rooms',
              icon: Icons.hotel_rounded,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondaryOnLight,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.textPrimaryOnLight
                    : AppColors.textSecondaryOnLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Module header ─────────────────────────────────────────────────────────

class _ModuleHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;

  const _ModuleHeader({
    required this.title,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: accent),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Module body ───────────────────────────────────────────────────────────

class _ModuleBody extends StatelessWidget {
  final AsyncValue async;
  final bool isRooms;
  final bool salesExpanded;
  final bool nbtExpanded;
  final VoidCallback onToggleSales;
  final VoidCallback onToggleNbt;

  const _ModuleBody({
    required this.async,
    required this.isRooms,
    required this.salesExpanded,
    required this.nbtExpanded,
    required this.onToggleSales,
    required this.onToggleNbt,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Text(
          'Failed: $e',
          style: const TextStyle(color: AppColors.error, fontSize: 12.5),
        ),
      ),
      data: (summary) {
        final expected = summary['expected_amount'];
        final cashSales = summary['cash_sales_amount'];
        final loanAmount = summary['loan_amount'];
        final leftBehind =
            (summary['left_behind_from_last_collection'] as num?) ?? 0;
        final totalInclLoans = summary['total_sales_amount_including_loans'];
        final discounts = summary['total_discounts'];
        final giveawayCount = summary['giveaway_count'];
        final giveawayValue = summary['giveaway_value'];
        final sales = summary['sales'] as List? ?? [];
        final nbts = summary['non_business_transactions'] as List? ?? [];
        final pending = summary['pending_collection'] as Map<String, dynamic>?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: AppColors.warning.withOpacity(0.35)),
                ),
                child: const Text(
                  'Collection pending approval',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Expected
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expected to collect',
                    style: TextStyle(
                      color: AppColors.textSecondaryOnLight,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'UGX $expected',
                    style: const TextStyle(
                      color: AppColors.textPrimaryOnLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // KPI row
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    label: isRooms ? 'Room Payments' : 'Cash Sales',
                    value: 'UGX $cashSales',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KpiTile(
                    label: isRooms ? 'Total Revenue' : 'Incl. Loans',
                    value: 'UGX $totalInclLoans',
                    color: AppColors.textPrimaryOnLight,
                  ),
                ),
              ],
            ),
            if (!isRooms) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KpiTile(
                      label: 'On Loan',
                      value: 'UGX $loanAmount',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiTile(
                      label: 'Giveaways',
                      value: '$giveawayCount · UGX $giveawayValue',
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ],
            if (leftBehind > 0) ...[
              const SizedBox(height: 8),
              _KpiTile(
                label: 'Left from last collection',
                value: 'UGX $leftBehind',
                color: AppColors.info,
              ),
            ],
            if ((discounts as num? ?? 0) > 0) ...[
              const SizedBox(height: 8),
              _KpiTile(
                label: 'Total Discounts',
                value: 'UGX $discounts',
                color: AppColors.error,
              ),
            ],

            const SizedBox(height: 16),

            _ExpandableList(
              title: isRooms
                  ? 'BOOKINGS (${sales.length})'
                  : 'SALES (${sales.length})',
              items: sales,
              expanded: salesExpanded,
              onToggle: onToggleSales,
              emptyLabel: isRooms ? 'No bookings' : 'No sales',
              itemBuilder: (sale) =>
                  _SaleCard(sale: sale, isRooms: isRooms),
            ),

            if (!isRooms) ...[
              const SizedBox(height: 16),
              _ExpandableList(
                title: 'NON-BUSINESS (${nbts.length})',
                items: nbts,
                expanded: nbtExpanded,
                onToggle: onToggleNbt,
                emptyLabel: 'None recorded',
                itemBuilder: (n) => _NbtCard(nbt: n),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Expandable list ───────────────────────────────────────────────────────

class _ExpandableList extends StatelessWidget {
  final String title;
  final List items;
  final bool expanded;
  final VoidCallback onToggle;
  final String emptyLabel;
  final Widget Function(dynamic item) itemBuilder;

  const _ExpandableList({
    required this.title,
    required this.items,
    required this.expanded,
    required this.onToggle,
    required this.emptyLabel,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? items : items.take(3).toList();
    final hasMore = items.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondaryOnLight,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          _Card(
            child: Text(
              emptyLabel,
              style: const TextStyle(
                color: AppColors.textSecondaryOnLight,
                fontSize: 12.5,
              ),
            ),
          )
        else ...[
          ...visible.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: itemBuilder(item),
            ),
          ),
          if (hasMore)
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      expanded ? 'Show less' : 'Show all ${items.length}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOnLight,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textSecondaryOnLight,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── Sale / Booking card ───────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  final dynamic sale;
  final bool isRooms;

  const _SaleCard({required this.sale, required this.isRooms});

  @override
  Widget build(BuildContext context) {
    final items = sale['items'] as List? ?? [];
    final discount = (sale['discount_total'] as num?) ?? 0;
    final roomNumber = sale['room_number']?.toString() ??
        sale['room']?.toString() ??
        sale['room_name']?.toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'UGX ${sale['total_amount']}',
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (discount > 0)
                Text(
                  '−UGX $discount',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (isRooms && roomNumber != null && roomNumber.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined,
                    size: 13, color: AppColors.info),
                const SizedBox(width: 3),
                Text(
                  'Room $roomNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 2),
          Text(
            'by ${sale['sold_by'] ?? 'Unknown'}',
            style: const TextStyle(
              color: AppColors.textSecondaryOnLight,
              fontSize: 11.5,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.borderOnLight),
            const SizedBox(height: 6),
            ...items.map((item) {
              final name = item['name']?.toString() ?? 'Item';
              final qty = item['quantity'];
              final lineTotal = item['line_total'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                    ),
                    Text(
                      '×$qty',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 68,
                      child: Text(
                        'UGX $lineTotal',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── NBT card ──────────────────────────────────────────────────────────────

class _NbtCard extends StatelessWidget {
  final dynamic nbt;
  const _NbtCard({required this.nbt});

  @override
  Widget build(BuildContext context) {
    final isOut = nbt['direction'] == 'out';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: (isOut ? AppColors.error : AppColors.success)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              isOut
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: isOut ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nbt['description'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnLight,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (nbt['status'] != null)
                  Text(
                    nbt['status'].toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondaryOnLight,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'UGX ${nbt['amount']}',
            style: TextStyle(
              color: isOut ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: child,
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryOnLight,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}