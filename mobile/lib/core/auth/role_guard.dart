class RoleGuard {
  static String homeRouteFor(List<dynamic> roles) {
    if (roles.contains("superadmin")) return "/businesses";
    if (roles.contains("owner")) return "/owner-dashboard";
    if (roles.contains("bar_manager") || roles.contains("room_incharge")) {
      return "/staff-home";
    }
    return "/login";
  }
}