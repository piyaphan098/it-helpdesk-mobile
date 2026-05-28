import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../models/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
            top: -80,
            left: -60,
            child: _GlowBlob(color: const Color(0xFF1565C0), size: 260),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: _GlowBlob(color: const Color(0xFF6A1B9A), size: 200),
          ),
          Positioned(
            bottom: 60,
            left: 40,
            child: _GlowBlob(color: const Color(0xFF00838F), size: 180),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF5E92F3),
              backgroundColor: const Color(0xFF1A1F2E),
              onRefresh: () async {
                ref.invalidate(currentProfileProvider);
                ref.invalidate(ticketsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: profileAsync.when(
                              loading: () => const SizedBox(height: 48),
                              error: (_, __) => const SizedBox(),
                              data: (profile) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile != null
                                        ? 'Hello, ${profile.fullName.split(' ').first} 👋'
                                        : 'Hello',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Here is your IT support overview',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Notification bell
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.notifications),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.12)),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Stats grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: ticketsAsync.when(
                        loading: () => GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                          children: List.generate(
                            4,
                            (_) => const _SkeletonCard(),
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text(e.toString(),
                              style: const TextStyle(color: Colors.white54)),
                        ),
                        data: (tickets) {
                          final total = tickets.length;
                          final open = tickets
                              .where((t) => t.status == TicketStatus.open)
                              .length;
                          final inProgress = tickets
                              .where((t) => t.status == TicketStatus.inProgress)
                              .length;
                          final resolved = tickets
                              .where((t) =>
                                  t.status == TicketStatus.resolved ||
                                  t.status == TicketStatus.closed)
                              .length;

                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _StatCard(
                                title: 'Total Tickets',
                                value: '$total',
                                icon: Icons.confirmation_number_outlined,
                                color: const Color(0xFF5E92F3),
                                delay: 200,
                              ),
                              _StatCard(
                                title: 'Pending',
                                value: '$open',
                                icon: Icons.pending_actions_outlined,
                                color: const Color(0xFFFFB74D),
                                delay: 300,
                              ),
                              _StatCard(
                                title: 'In Progress',
                                value: '$inProgress',
                                icon: Icons.engineering_outlined,
                                color: const Color(0xFFCE93D8),
                                delay: 400,
                              ),
                              _StatCard(
                                title: 'Completed',
                                value: '$resolved',
                                icon: Icons.check_circle_outline,
                                color: const Color(0xFF80CBC4),
                                delay: 500,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Recent tickets
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Tickets',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.tickets),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF5E92F3),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: ticketsAsync.when(
                      loading: () => SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: _SkeletonRow(),
                          ),
                          childCount: 3,
                        ),
                      ),
                      error: (_, __) =>
                          const SliverToBoxAdapter(child: SizedBox()),
                      data: (tickets) {
                        final recent = tickets.take(5).toList();
                        if (recent.isEmpty) {
                          return SliverToBoxAdapter(
                            child: _EmptyTickets(
                              onTap: () => context.push(AppRoutes.createTicket),
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecentTicketCard(
                                ticket: recent[index],
                                onTap: () => context.push(
                                  '/tickets/${recent[index].id}',
                                ),
                              ),
                            )
                                .animate(delay: (600 + index * 80).ms)
                                .fadeIn()
                                .slideY(begin: 0.1),
                            childCount: recent.length,
                          ),
                        );
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }
}

// ─── Recent Ticket Card ────────────────────────────────────────────────────────
class _RecentTicketCard extends StatelessWidget {
  const _RecentTicketCard({required this.ticket, required this.onTap});
  final Ticket ticket;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (ticket.status) {
      case TicketStatus.open:
        return const Color(0xFFFFB74D);
      case TicketStatus.inProgress:
        return const Color(0xFFCE93D8);
      case TicketStatus.resolved:
      case TicketStatus.closed:
        return const Color(0xFF80CBC4);
      case TicketStatus.cancelled:
        return const Color(0xFFB0BEC5);
    }
  }

  Color get _priorityColor {
    switch (ticket.priority) {
      case TicketPriority.urgent:
        return const Color(0xFFEF5350);
      case TicketPriority.high:
        return const Color(0xFFFFB74D);
      case TicketPriority.medium:
        return const Color(0xFF5E92F3);
      case TicketPriority.low:
        return const Color(0xFF80CBC4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _statusColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Badge(
                            label: ticket.status.label,
                            color: _statusColor,
                          ),
                          const SizedBox(width: 6),
                          _Badge(
                            label: ticket.priority.label,
                            color: _priorityColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'No tickets yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your first IT support ticket',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF5E92F3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '+ New Ticket',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton Widgets ──────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          color: Colors.white.withValues(alpha: 0.05),
          duration: 1200.ms,
        );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          color: Colors.white.withValues(alpha: 0.05),
          duration: 1200.ms,
        );
  }
}

// ─── Glow Blob ─────────────────────────────────────────────────────────────────
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


