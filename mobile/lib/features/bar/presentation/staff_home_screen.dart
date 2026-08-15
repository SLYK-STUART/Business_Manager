import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(apiClientProvider).clearTokens();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil("/login", (route) => false);
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text("Failed to load")),
        data: (user) => Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text("Welcome, ${user["name"]}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => Navigator.of(context).pushNamed("/items"), child: const Text('Items')),
                  TextButton(onPressed: () => Navigator.of(context).pushNamed("/sell"), child: const Text('Sell')),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/restock"), 
                      child: const Text('Re stock')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/giveaway"),
                      child: const Text('Give away')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/add_item"),
                      child: const Text('Add Items')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/loan_create"),
                      child: const Text('Give Loan')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/loans"),
                      child: const Text('Loans')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/nbt"),
                      child: const Text('Non Business Transactions')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/cash_collection"),
                      child: const Text('Cash Collection')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/categories"),
                      child: const Text('Categories')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/reports"),
                      child: const Text('Reports')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/rooms"),
                      child: const Text('Rooms')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/room_reports"),
                      child: const Text('Room Reports')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/rooms_cash_collection"),
                      child: const Text('Room cash Collection')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/approvals"),
                      child: const Text('Approvals')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/salaries"),
                      child: const Text('Salaries')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/owner-dashboard"),
                      child: const Text('Owner Dashboard')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/manager_screen"),
                      child: const Text('Manager Home Screen')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/pending_pricing"),
                      child: const Text('Pending Prices')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/staff"),
                      child: const Text('Staff management')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/activity-log"),
                      child: const Text('Activity Logs')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/profile"),
                      child: const Text('Profile')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/room_management"),
                      child: const Text('Room Management')
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pushNamed("/stats"),
                      child: const Text('Stats')
                  ),
                  const SizedBox(height: 40,),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}