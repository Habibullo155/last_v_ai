class DashboardStats {
  final int usersTotal;
  final int usersOnlineNow;
  final int usersAdmins;
  final int ticketsOpen;
  final int reportsOpen;
  final int documentsTotal;
  final int tokensUsedThisMonth;

  DashboardStats({
    required this.usersTotal,
    required this.usersOnlineNow,
    required this.usersAdmins,
    required this.ticketsOpen,
    required this.reportsOpen,
    required this.documentsTotal,
    required this.tokensUsedThisMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      usersTotal: json['users_total'] as int? ?? 0,
      usersOnlineNow: json['users_online_now'] as int? ?? 0,
      usersAdmins: json['users_admins'] as int? ?? 0,
      ticketsOpen: json['tickets_open'] as int? ?? 0,
      reportsOpen: json['reports_open'] as int? ?? 0,
      documentsTotal: json['documents_total'] as int? ?? 0,
      tokensUsedThisMonth: json['tokens_used_this_month'] as int? ?? 0,
    );
  }
}
