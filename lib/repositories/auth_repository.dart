import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';

/// Repository for authentication and profile operations.
class AuthRepository {
  AuthRepository(this._supabase);

  final SupabaseService _supabase;

  SupabaseClient get _client => _supabase.client;

  /// Stream of auth state changes from Supabase.
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  /// Current session, if any.
  Session? get currentSession => _client.auth.currentSession;

  /// Current user, if any.
  User? get currentUser => _client.auth.currentUser;

  /// Sign in with email and password.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AppException('Sign in failed. Please try again.');
      }

      return await getProfile(user.id);
    } on AuthException catch (e) {
      throw AppException(mapAuthErrorMessage(e.message), code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Sign in failed: ${e.toString()}');
    }
  }

  /// Register a new user account.
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    String? department,
    String? phone,
    UserRole role = UserRole.employee,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role.value,
          if (department != null) 'department': department.trim(),
          if (phone != null) 'phone': phone.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AppException('Registration failed. Please try again.');
      }

      // Profile is auto-created by database trigger; fetch it
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return await getProfile(user.id);
    } on AuthException catch (e) {
      throw AppException(mapAuthErrorMessage(e.message), code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Registration failed: ${e.toString()}');
    }
  }

  /// Send password reset email.
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: null,
      );
    } on AuthException catch (e) {
      throw AppException(mapAuthErrorMessage(e.message), code: e.statusCode);
    } catch (e) {
      throw AppException('Password reset failed: ${e.toString()}');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AppException(mapAuthErrorMessage(e.message), code: e.statusCode);
    } catch (e) {
      throw AppException('Sign out failed: ${e.toString()}');
    }
  }

  /// Fetch user profile from database.
  /// Uses maybeSingle() to avoid PGRST116 when row doesn't exist yet,
  /// then upserts a default profile row if missing.
  Future<UserProfile> getProfile(String userId) async {
    try {
      var data = await _client
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Profile row missing (trigger may not have run yet) — create it
        final user = _client.auth.currentUser;
        final email = user?.email ?? '';
        final meta = user?.userMetadata ?? {};
        data = await _client
            .from(SupabaseConstants.profilesTable)
            .upsert({
              'id': userId,
              'email': email,
              'full_name': meta['full_name'] as String? ?? email.split('@').first,
              'role': meta['role'] as String? ?? 'employee',
            }, onConflict: 'id')
            .select()
            .single();
      }

      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('Failed to load profile: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load profile: ${e.toString()}');
    }
  }

  /// Update user profile fields.
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? department,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (department != null) updates['department'] = department.trim();
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        return await getProfile(userId);
      }

      final data = await _client
          .from(SupabaseConstants.profilesTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfile.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('Failed to update profile: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to update profile: ${e.toString()}');
    }
  }
}


