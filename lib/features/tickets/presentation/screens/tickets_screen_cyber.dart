import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../models/ticket.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../../../widgets/cyber/cyber_widgets.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  String _search = '';
  String _filter = 'All';
  final _filters = ['All', 'Open', 'Pending', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CyberBackground(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context, profileAsync),

            // Search + Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Search
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppColors.outline,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search tickets...',
                              hintStyle: TextStyle(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.tertiary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        final selected = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.tertiary
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? AppColors.tertiary
                                    : AppColors.outlineVariant
                                        .withValues(alpha: 0.3),
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.tertiary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.background
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Ticket List
            Expanded(
              child: ticketsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.tertiary,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
                data: (tickets) {
                  final filtered = tickets.where((t) {
                    final matchSearch = _search.isEmpty ||
                        t.title.toLowerCase().contains(_search.toLowerCase());
                    final matchFilter = _filter == 'All' ||
                        (_filter == 'Open' && t.status == TicketStatus.open) ||
                        (_filter == 'Pending' &&
                            t.status == TicketStatus.inProgress) ||
                        (_filter == 'Resolved' &&
                            (t.status == TicketStatus.resolved ||
                                t.status == TicketStatus.closed));
                    return matchSearch && matchFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tickets found',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _TicketCard(
                        ticket: filtered[index],
                        onTap: () => context.push(
                          '/tickets/${filtered[index].id}',
                        ),
                      )
                          .animate(delay: (index * 60).ms)
                          .fadeIn()
                          .slideY(begin: 0.06);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondaryContainer, AppColors.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          onPressed: () => context.push(AppRoutes.createTicket),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue profileAsync) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryContainer,
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    profileAsync.maybeWhen(
                      data: (p) => p?.initials ?? '?',
                      orElse: () => '?',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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
              LivePulseBadge(),
              const SizedBox(width: 12),
              Icon(
                Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ticket Card ───────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});
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
      case 'database':
        return Icons.storage_outlined;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              PriorityBadge(
                label: ticket.priority.label,
                color: _priorityColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon, color: _priorityColor, size: 18),
              ),
              Expanded(
                child: Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outline,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Center(
                  child: Text(
                    ticket.assignedTo != null ? 'T' : '?',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                size: 12,
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
    );
  }
}


