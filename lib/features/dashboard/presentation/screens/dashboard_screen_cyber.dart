import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../models/ticket.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../../widgets/cyber/cyber_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CyberBackground(
        child: SizedBox.expand(
            child: RefreshIndicator(
          color: AppColors.tertiary,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () async {
            ref.invalidate(currentProfileProvider);
            ref.invalidate(ticketsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 80,
                toolbarHeight: 80,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: _CyberSliverAppBar(
                  initials: profileAsync.maybeWhen(
                    data: (p) => p?.initials ?? '?',
                    orElse: () => '?',
                  ),
                  onNotificationTap: () => context.go(AppRoutes.notifications),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Header
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: profileAsync
                      .when(
                        loading: () => const SizedBox(height: 60),
                        error: (_, __) => const SizedBox(),
                        data: (profile) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SYSTEM OVERVIEW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hello, ${profile?.fullName.split(' ').first ?? 'User'}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.tertiary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.tertiary,
                                        ),
                                      )
                                          .animate(onPlay: (c) => c.repeat())
                                          .scaleXY(
                                              begin: 0.5,
                                              end: 1.8,
                                              duration: 1200.ms)
                                          .fadeOut(duration: 1200.ms),
                                      const SizedBox(width: 6),
                                      Text(
                                        profile?.role.displayName ==
                                                'Technician'
                                            ? 'Technician Online'
                                            : 'System Online',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Stats Grid
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
                      childAspectRatio: 1.4,
                      children: List.generate(2, (_) => _SkeletonCard()),
                    ),
                    error: (_, __) => const SizedBox(),
                    data: (tickets) {
                      final open = tickets
                          .where((t) => t.status == TicketStatus.open)
                          .length;
                      final resolved = tickets
                          .where((t) =>
                              t.status == TicketStatus.resolved ||
                              t.status == TicketStatus.closed)
                          .length;

                      return Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Open Tickets',
                              value: '$open',
                              delta:
                                  '+${tickets.where((t) => t.status == TicketStatus.inProgress).length}',
                              icon: Icons.confirmation_number_outlined,
                              delay: 200,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Resolved',
                              value: '$resolved',
                              delta:
                                  '↑ ${resolved > 0 ? (resolved * 12 ~/ 100 + 12) : 0}%',
                              icon: Icons.check_circle_outline,
                              isResolved: true,
                              delay: 300,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Avg response card
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: CyberCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avg. Response',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  '4.2m',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Optimal',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.84,
                                  backgroundColor:
                                      AppColors.surfaceContainerHigh,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.tertiary),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Within SLA threshold (5.0m)',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.timer_outlined,
                            color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // New Ticket CTA
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.createTicket),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0566D9), Color(0xFF1D4ED8)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryContainer
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Critical Action',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'New Ticket',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent Tickets header
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Tickets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.tickets),
                        child: const Text(
                          'VIEW ALL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 550.ms),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Ticket list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: ticketsAsync.when(
                  loading: () => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SkeletonCard(height: 80),
                      ),
                      childCount: 3,
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
                  data: (tickets) {
                    final recent = tickets.take(5).toList();
                    if (recent.isEmpty) {
                      return SliverToBoxAdapter(
                        child: CyberCard(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No tickets yet',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TicketRow(
                            ticket: recent[index],
                            onTap: () => context.push(
                              '/tickets/${recent[index].id}',
                            ),
                          ),
                        )
                            .animate(delay: (600 + index * 60).ms)
                            .fadeIn()
                            .slideY(begin: 0.08),
                        childCount: recent.length,
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        )),
      ),
    );
  }
}

// ─── Sliver App Bar ────────────────────────────────────────────────────────────
class _CyberSliverAppBar extends StatelessWidget {
  const _CyberSliverAppBar(
      {required this.initials, required this.onNotificationTap});
  final String initials;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.tertiary,
                          AppColors.secondaryContainer
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.tertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'IT Helpdesk',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Notification
                  GestureDetector(
                    onTap: onNotificationTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.onSurfaceVariant,
                            size: 22,
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.tertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.tertiary
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.delay,
    this.isResolved = false,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final int delay;
  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      cyanBorder: isResolved,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isResolved
                    ? AppColors.tertiary
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isResolved ? AppColors.tertiary : AppColors.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    color: isResolved ? AppColors.tertiary : AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini bar chart
          Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  height: 20,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: (8 + (i * 1.5)).clamp(4, 20),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? AppColors.tertiary
                                .withValues(alpha: 0.4 + i * 0.08)
                            : AppColors.onSurfaceVariant
                                .withValues(alpha: 0.2 + i * 0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }
}

// ─── Ticket Row ────────────────────────────────────────────────────────────────
class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.onTap});
  final Ticket ticket;
  final VoidCallback onTap;

  Color get _priorityColor {
    switch (ticket.priority) {
      case TicketPriority.urgent:
        return AppColors.priorityUrgent;
      case TicketPriority.high:
        return AppColors.priorityHigh;
      case TicketPriority.medium:
        return AppColors.priorityMedium;
      case TicketPriority.low:
        return AppColors.priorityLow;
    }
  }

  IconData get _categoryIcon {
    switch (ticket.category?.toLowerCase()) {
      case 'network':
        return Icons.wifi_outlined;
      case 'hardware':
        return Icons.computer_outlined;
      case 'software':
        return Icons.code_outlined;
      case 'security':
        return Icons.security_outlined;
      default:
        return Icons.confirmation_number_outlined;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final incId = ticket.id.length >= 4
        ? ticket.id.substring(0, 4).toUpperCase()
        : ticket.id.toUpperCase().padRight(4, '0');

    return CyberCard(
      onTap: onTap,
      child: Row(
        children: [
          // Category icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _priorityColor.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(_categoryIcon, color: _priorityColor, size: 20),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#INC-$incId',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        ticket.priority.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _priorityColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      ticket.assignedTo != null ? 'Assigned' : 'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        color: ticket.assignedTo != null
                            ? AppColors.onSurfaceVariant
                            : AppColors.outline,
                        fontStyle: ticket.assignedTo == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppColors.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(ticket.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.outline,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Card ─────────────────────────────────────────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(color: AppColors.glassBorder, duration: 1200.ms);
  }
}


