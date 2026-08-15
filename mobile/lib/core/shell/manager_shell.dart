import 'package:flutter/material.dart';
import 'package:mobile/features/bar/presentation/expected_collections_stats_screen.dart';
import '../theme/app_colors.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../../features/bar/presentation/manager_home_screen.dart';
import '../../features/bar/presentation/sell_item_screen.dart';
import '../../features/rooms/presentation/room_grid_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  static const _screens = [
    ManagerHomeScreen(),
    SellItemScreen(),
    RoomGridScreen(),
    ExpectedCollectionsStatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          NavItem(Icons.home_rounded, "Home"),
          NavItem(Icons.point_of_sale_rounded, "Sell"),
          NavItem(Icons.bed_rounded, "Rooms"),
          NavItem(Icons.request_page_rounded, "Reports"),
        ],
      ),
    );
  }
}