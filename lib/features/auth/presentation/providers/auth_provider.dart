import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/user_profile.dart';
import '../../../../models/user_role.dart';
import '../../../../repositories/auth_repository.dart';
import '../../../../services/supabase_service.dart';

/// Provides AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AuthRepository(supabase);
});

/// Watches Supabase auth state — null when logged out.
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.map((state) => state.session?.user);
});

/// Fetches the current user's profile when authenticated.
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  final repository = ref.watch(authRepositoryProvider);
  return repository.getProfile(user.id);
});

/// Auth controller for login, register, logout actions.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository) : super(const AsyncValue.data(null));

  final AuthRepository _repository;

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.signIn(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    String? department,
    String? phone,
    UserRole role = UserRole.employee,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        department: department,
        phone: phone,
        role: role,
      );
      state = const AsyncValue.data(null);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resetPassword(email: email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

// ── Profile update controller ──────────────────────────────────────────────
class ProfileController extends StateNotifier<AsyncValue<void>> {
  ProfileController(this._repository) : super(const AsyncValue.data(null));
  final AuthRepository _repository;

  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? department,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        department: department,
        avatarUrl: avatarUrl,
      );
      state = const AsyncValue.data(null);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ProfileController(repository);
});
