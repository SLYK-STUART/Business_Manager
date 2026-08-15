import 'package:flutter/material.dart';
import 'package:mobile/features/bar/presentation/expected_collections_stats_screen.dart';
import '../../features/rooms/presentation/room_reports_screen.dart';
import '../theme/app_colors.dart';
import '../../widgets/floating_bottom_nav.dart';
import '../../features/owner_dashboard/presentation/owner_dashboard_screen.dart';
import '../../features/bar/presentation/item_list_screen.dart';
import '../../features/bar/presentation/loans_screen.dart';
import '../../features/owner_dashboard/presentation/reports_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    OwnerDashboardScreen(),
    ExpectedCollectionsStatsScreen(),
    RoomReportsScreen(),
    ReportsScreen(),
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
          NavItem(Icons.inventory_2_rounded, "Status"),
          NavItem(Icons.house, "Rooms"),
          NavItem(Icons.bar_chart_outlined, "Reports"),
        ],
      ),
    );
  }
}