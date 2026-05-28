/// Application route path constants.
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main shell
  static const String dashboard = '/dashboard';
  static const String tickets = '/tickets';
  static const String createTicket = '/tickets/create';
  static const String ticketDetail = '/tickets/:id';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Technician
  static const String technicianRegister = '/technician-register';
  static const String technicianDashboard = '/technician';
  static const String technicianJobs = '/technician/jobs';
  static const String technicianProfile = '/technician/profile';

  // Admin
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminAnalytics = '/admin/analytics';
}
