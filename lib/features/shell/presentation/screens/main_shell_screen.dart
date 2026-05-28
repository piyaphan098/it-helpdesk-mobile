import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/theme_provider.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../technician/screens/technician_jobs_screen.dart';

/// Main shell with bottom navigation bar.
/// แสดง nav แตกต่างกันตาม role (employee vs technician/admin)
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    super.key,
    required this.child,
  });

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.tickets)) return 1;
    if (location.startsWith(AppRoutes.notifications)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.tickets);
      case 2:
        context.go(AppRoutes.notifications);
      case 3:
        context.go(AppRoutes.profile);
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
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
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: getErrorMessage(e),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = ref.watch(activeDarkThemeProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    final isTechnicianOrAdmin = profileAsync.maybeWhen(
      data: (p) => p?.role.canManageTickets ?? false,
      orElse: () => false,
    );

    return Scaffold(
      body: Stack(
        children: [
          child,
          // ── Technician FAB overlay ──
          if (isTechnicianOrAdmin)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'tech_jobs_fab',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TechnicianJobsScreen(),
                  ),
                ),
                icon: const Icon(Icons.build_rounded),
                label: const Text('งานของฉัน'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
              ),
            ),
        ],
      ),
      floatingActionButton: isTechnicianOrAdmin
          ? null
          : FloatingActionButton.extended(
              heroTag: 'new_ticket_fab',
              onPressed: () => context.push(AppRoutes.createTicket),
              icon: const Icon(Icons.add),
              label: const Text('New Ticket'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.support_agent, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'IT Support Helpdesk',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  profileAsync.maybeWhen(
                    data: (p) => p != null
                        ? Text(
                            '${p.fullName} · ${p.role.displayName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.8)),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (isTechnicianOrAdmin)
              ListTile(
                leading: const Icon(Icons.build_rounded),
                title: const Text('งานของฉัน'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TechnicianJobsScreen(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
              onTap: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}
