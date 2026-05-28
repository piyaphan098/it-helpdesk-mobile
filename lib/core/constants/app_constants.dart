/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'IT Helpdesk';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String ticketImagesBucket = 'ticket-images';
  static const String repairImagesBucket = 'repair-images';

  // Deep link for auth callback
  static const String authRedirectUrl = 'io.supabase.ithelpdesk://login-callback/';

  // Shared preferences keys
  static const String themeModeKey = 'theme_mode';
  static const String localeKey = 'locale';
}


