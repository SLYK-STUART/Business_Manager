import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/shell/main_shell.dart';
import 'package:mobile/core/shell/manager_shell.dart';
import 'package:mobile/features/bar/presentation/add_item_screen.dart';
import 'package:mobile/features/bar/presentation/cash_collection_screen.dart';
import 'package:mobile/features/bar/presentation/manage_categories_screen.dart';
import 'package:mobile/features/bar/presentation/manager_home_screen.dart';
import 'package:mobile/features/bar/presentation/non_business_transaction_screen.dart';
import 'package:mobile/features/bar/presentation/staff_home_screen.dart';
import 'package:mobile/features/owner_dashboard/presentation/approvals_screen.dart';
import 'package:mobile/features/owner_dashboard/presentation/pending_pricing_screen.dart';
import 'package:mobile/features/owner_dashboard/presentation/reports_screen.dart';
import 'package:mobile/features/owner_dashboard/presentation/salary_screen.dart';
import 'package:mobile/features/owner_dashboard/presentation/staff_management_screen.dart';
import 'package:mobile/features/rooms/presentation/room_grid_screen.dart';
import 'package:mobile/features/rooms/presentation/room_reports_screen.dart';
import 'package:mobile/features/shared/activity_log/presentation/activity_log_screen.dart';
import 'package:mobile/features/shared/notifications_feed/presentation/notifications_screen.dart';
import 'core/auth/app_lock_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/home_router.dart';
import 'features/auth/presentation/lock_screen.dart';
import 'features/auth/presentation/set_passcode_screen.dart';
import 'features/bar/presentation/giveaway_screen.dart';
import 'features/bar/presentation/item_detail_screen.dart';
import 'features/bar/presentation/item_list_screen.dart';
import 'features/bar/presentation/loan_create_screen.dart';
import 'features/bar/presentation/loans_screen.dart';
import 'features/bar/presentation/restock_screen.dart';
import 'features/bar/presentation/sale_confirm_screen.dart';
import 'features/bar/presentation/sell_item_screen.dart';
import 'features/owner_dashboard/presentation/owner_dashboard_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Business Manager",
      initialRoute: "/login",
      routes: <String, WidgetBuilder>{
        "/login": (context) => const LoginScreen(),
        "/home": (context) => const HomeRouter(),
        "/owner-dashboard": (context) => const MainShell(),
        "/staff-home": (context) => const ManagerShell(),
        "/debug_screen": (context) => const StaffHomeScreen(),
        "/items": (context) => const ItemListScreen(),
        "/sell": (context) => const SellItemScreen(),
        "/sale-confirm": (context) => const SaleConfirmScreen(),
        "/restock": (context) => const RestockScreen(),
        "/giveaway": (context) => const GiveawayScreen(),
        "/add_item": (context) => const AddItemScreen(),
        "/loans": (context) => const LoansScreen(),
        "/notifications": (context) => const NotificationsScreen(),
        "/activity-log": (context) => const ActivityLogScreen(),
        "/loan_create": (context) => const LoanCreateScreen(),
        "/nbt": (context) => const NonBusinessTransactionScreen(),
        "/cash_collection": (context) => const CashCollectionScreen(),
        "/categories": (context) => const ManageCategoriesScreen(),
        "/reports": (context) => const ReportsScreen(),
        "/rooms": (context) => const RoomGridScreen(),
        "/room_reports": (context) => const RoomReportsScreen(),
        "/approvals": (context) => const ApprovalsScreen(),
        "/pending_pricing": (context) => const PendingPricingScreen(),
        "/salaries": (context) => const SalaryScreen(),
        "/manager_screen": (context) => const ManagerHomeScreen(),
        "/staff": (context) => const StaffManagementScreen(),
        "/set_passcode": (context) => const SetPasscodeScreen(isFirstSetup: true),
        "/change_passcode": (context) => const SetPasscodeScreen(),
        "/rooms_cash_collection": (context) => const CashCollectionScreen(module: "rooms"),
        "/item_detail": (context) {
          final itemId = ModalRoute.of(context)!.settings.arguments as String;
          return ItemDetailScreen(itemId: itemId);
        },
      },
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (lockState == AppLockState.locked) const LockScreen(),
          ],
        );
      },
    );
  }
}