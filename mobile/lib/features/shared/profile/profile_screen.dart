import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/logout_helper.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _roleLabel(String role) {
    switch (role) {
      case "superadmin":
        return "Superadmin";
      case "owner":
        return "Owner";
      case "bar_manager":
        return "Bar Manager";
      case "room_incharge":
        return "Room In-charge";
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Profile"), backgroundColor: AppColors.background, elevation: 0),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Failed to load: $e")),
        data: (user) {
          final roles = (user["roles"] as List).cast<String>();
          final isOwner = roles.contains("owner");

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        (user["name"] ?? "?").toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user["name"] ?? "", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user["phone"] ?? "", style: const TextStyle(color: AppColors.textSecondaryOnLight)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      alignment: WrapAlignment.center,
                      children: roles.map((r) => Chip(
                        label: Text(_roleLabel(r), style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (user["business_name"] != null) ...[
                _sectionLabel("Business"),
                _infoTile(Icons.storefront_outlined, "Business", user["business_name"]),
                const SizedBox(height: 20),
              ],

              _sectionLabel("Security"),
              _actionTile(
                icon: Icons.lock_outline_rounded,
                label: user["has_passcode"] == true ? "Change Passcode" : "Set Passcode",
                onTap: () => Navigator.of(context).pushNamed(user["has_passcode"] == true ? "/change_passcode" : "/set_passcode"),
              ),
              const SizedBox(height: 20),

              if (isOwner) ...[
                _sectionLabel("View"),
                _actionTile(
                  icon: Icons.swap_horiz_rounded,
                  label: "Switch to Manager View",
                  onTap: () => Navigator.of(context).pushReplacementNamed("/staff-home"),
                ),
                const SizedBox(height: 8,),
                _actionTile(
                  icon: Icons.pending_actions_rounded,
                  label: "Pending Prices",
                  onTap: () => Navigator.of(context).pushNamed("/pending_pricing"),
                ),
                const  SizedBox(height: 8,),
                _actionTile(
                  icon: Icons.approval_outlined,
                  label: "Approvals",
                  onTap: () => Navigator.of(context).pushNamed("/approvals"),
                ),
                const SizedBox(height: 8,),
                _actionTile(
                  icon: Icons.notifications_on_outlined,
                  label: "Notifications",
                  onTap: () => Navigator.of(context).pushNamed("/notifications"),
                ),
                const SizedBox(height: 20),

                _sectionLabel("Staff"),
                _actionTile(
                    icon: Icons.group,
                    label: "Manage staff",
                    onTap: () => Navigator.of(context).pushNamed("/staff")
                ),
                const SizedBox(height: 8,),
                _actionTile(
                    icon: Icons.attach_money,
                    label: "Salaries",
                    onTap: () => Navigator.of(context).pushNamed("/salaries")
                ),
                const SizedBox(height: 20),
              ],

              _sectionLabel("Account"),
              _actionTile(
                icon: Icons.logout_rounded,
                label: "Log Out",
                color: AppColors.error,
                onTap: () => performLogout(context, ref)
              ),
              const SizedBox(height: 100,),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOnLight, letterSpacing: 0.6)),
  );

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOnLight)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryOnLight),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOnLight)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textSecondaryOnLight),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
            Icon(Icons.chevron_right, size: 18, color: (color ?? AppColors.textSecondaryOnLight).withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}