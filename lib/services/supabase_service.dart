import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_constants.dart';

/// Singleton wrapper around Supabase client initialization and access.
class SupabaseService {
  SupabaseService._();

  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client => Supabase.instance.client;

  GoTrueClient get auth => client.auth;

  /// Initialize Supabase — call once in main() before runApp.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Current authenticated user ID, or null if not signed in.
  String? get currentUserId => client.auth.currentUser?.id;

  /// Whether a user session is currently active.
  bool get isAuthenticated => client.auth.currentSession != null;

  /// Stream of auth state changes (login, logout, token refresh).
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}

/// Riverpod provider for SupabaseService.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

/// Riverpod provider for SupabaseClient.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return ref.watch(supabaseServiceProvider).client;
});


