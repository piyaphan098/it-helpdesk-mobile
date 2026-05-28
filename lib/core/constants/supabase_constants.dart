/// Supabase configuration constants.
///
/// Replace these values with your Supabase project credentials.
/// Find them at: Supabase Dashboard > Project Settings > API
class SupabaseConstants {
  SupabaseConstants._();

  /// Your Supabase project URL
  static const String supabaseUrl = 'https://rqzbshzzjetabxqwbakk.supabase.co';

  /// Your Supabase anon (public) key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxemJzaHp6amV0YWJ4cXdiYWtrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1NzM1MzQsImV4cCI6MjA5NTE0OTUzNH0.HEN61_mEzrmSAmxzBZYtlinMLuIr1tehKWvC4yxT5oU';

  // Table names
  static const String profilesTable = 'profiles';
  static const String ticketsTable = 'tickets';
  static const String ticketCommentsTable = 'ticket_comments';
  static const String ticketHistoryTable = 'ticket_history';
  static const String categoriesTable = 'categories';
  static const String techniciansTable = 'technicians';
  static const String notificationsTable = 'notifications';
}
