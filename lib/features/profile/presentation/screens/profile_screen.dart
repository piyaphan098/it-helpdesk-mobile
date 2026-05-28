import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/user_role.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../technician/screens/technician_profile_screen.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Glow blobs
          Positioned(
            top: 0,
            left: -60,
            child: _GlowBlob(color: const Color(0xFF1565C0), size: 240),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: _GlowBlob(color: const Color(0xFF6A1B9A), size: 180),
          ),

          SafeArea(
            child: profileAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5E92F3),
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              data: (profile) {
                if (profile == null) return const SizedBox();
                final totalTickets = ticketsAsync.maybeWhen(
                  data: (t) => t.length,
                  orElse: () => 0,
                );
                final resolvedTickets = ticketsAsync.maybeWhen(
                  data: (t) =>
                      t.where((x) => x.status.name == 'resolved').length,
                  orElse: () => 0,
                );
                return _ProfileContent(
                  profile: profile,
                  totalTickets: totalTickets,
                  resolvedTickets: resolvedTickets,
                  ref: ref,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.totalTickets,
    required this.resolvedTickets,
    required this.ref,
  });

  final UserProfile profile;
  final int totalTickets;
  final int resolvedTickets;
  final WidgetRef ref;

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName = 'avatars/${profile.id}.$ext';
      final client = Supabase.instance.client;

      await client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);
      // Add cache-busting query param so Flutter reloads the image
      final cacheBustedUrl =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await ref.read(profileControllerProvider.notifier).updateProfile(
            userId: profile.id,
            avatarUrl: cacheBustedUrl,
          );
      ref.invalidate(currentProfileProvider);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('อัปเดตรูปโปรไฟล์แล้ว'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: const Color(0xFFEF5350),
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We\'ll send a password reset link to your email',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              profile.email,
              style: const TextStyle(
                color: Color(0xFF5E92F3),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(authControllerProvider.notifier)
                    .resetPassword(email: profile.email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Reset link sent! Check your email.'),
                        backgroundColor: Color(0xFF26A69A)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Color(0xFFEF5350)),
                  );
                }
              }
            },
            child: const Text('Send Link',
                style: TextStyle(
                    color: Color(0xFF5E92F3), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Avatar & Name
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _pickAndUploadAvatar(context),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF6A1B9A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profile.avatarUrl != null
                              ? Image.network(
                                  profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 88,
                                  height: 88,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      profile.initials,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    profile.initials,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5E92F3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),

                const SizedBox(height: 12),

                // Role badge
                _RoleBadge(role: profile.role),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        ),

        // Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Tickets',
                    value: totalTickets.toString(),
                    icon: Icons.confirmation_number_outlined,
                    color: const Color(0xFF5E92F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Resolved',
                    value: resolvedTickets.toString(),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF26A69A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Open',
                    value: (totalTickets - resolvedTickets).toString(),
                    icon: Icons.pending_outlined,
                    color: const Color(0xFFFFB74D),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Info card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Information',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: profile.fullName,
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: profile.email,
                  ),
                  if (profile.phone != null) ...[
                    _Divider(),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profile.phone!,
                    ),
                  ],
                  if (profile.department != null) ...[
                    _Divider(),
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Department',
                      value: profile.department!,
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _GlassCard(
              child: Column(
                children: [
                  // แสดงเฉพาะ technician / admin
                  if (profile.role == UserRole.technician ||
                      profile.role == UserRole.admin) ...[
                    _ActionRow(
                      icon: Icons.build_circle_outlined,
                      label: 'โปรไฟล์ช่าง & ผลงาน',
                      color: const Color(0xFF26A69A),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TechnicianProfileScreen(),
                        ),
                      ),
                    ),
                    _Divider(),
                  ],
                  _ActionRow(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    color: const Color(0xFF5E92F3),
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  _Divider(),
                  _ActionRow(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    color: const Color(0xFF26A69A),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _Divider(),
                  _ActionRow(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: const Color(0xFFEF5350),
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  Color get _color {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFFFB74D);
      case UserRole.technician:
        return const Color(0xFF26A69A);
      default:
        return const Color(0xFF5E92F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
