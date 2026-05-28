import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_support_helpdesk/models/ticket.dart';
import 'package:it_support_helpdesk/models/user_profile.dart';
import 'package:it_support_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:it_support_helpdesk/features/tickets/presentation/providers/ticket_provider.dart';
import '../providers/technician_provider.dart';
import 'technician_ticket_detail_screen.dart';

class TechnicianJobsScreen extends ConsumerWidget {
  const TechnicianJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final ticketsAsync = ref.watch(technicianTicketsProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('งานของฉัน'),
                  Text(profile.fullName,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6))),
                ],
              ),
              bottom: TabBar(
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text('รอรับ'),
                        const SizedBox(width: 4),
                        _CountBadge(ref: ref, filter: _TicketFilter.pending),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.build_rounded, size: 16),
                        const SizedBox(width: 6),
                        const Text('กำลังซ่อม'),
                        const SizedBox(width: 4),
                        _CountBadge(ref: ref, filter: _TicketFilter.inProgress),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('เสร็จแล้ว'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(technicianTicketsProvider),
              ),
              data: (tickets) => TabBarView(
                children: [
                  // Tab 0: รอรับงาน (pending + ทุก ticket ที่ยังไม่มีคนรับ)
                  _TicketList(
                    tickets: tickets
                        .where((t) =>
                            t.status == TicketStatus.open &&
                            t.assignedTo == null)
                        .toList(),
                    profile: profile,
                    emptyIcon: Icons.inbox_rounded,
                    emptyText: 'ไม่มีงานรอรับ',
                    showAcceptButton: true,
                  ),
                  // Tab 1: งานที่รับแล้ว / กำลังซ่อม
                  _TicketList(
                    tickets: tickets
                        .where((t) =>
                            t.assignedTo == profile.id &&
                            t.status != TicketStatus.closed &&
                            t.status != TicketStatus.resolved)
                        .toList(),
                    profile: profile,
                    emptyIcon: Icons.build_circle_outlined,
                    emptyText: 'ยังไม่มีงานที่รับ',
                    showAcceptButton: false,
                  ),
                  // Tab 2: เสร็จแล้ว
                  _TicketList(
                    tickets: tickets
                        .where((t) =>
                            t.assignedTo == profile.id &&
                            (t.status == TicketStatus.resolved ||
                                t.status == TicketStatus.closed))
                        .toList(),
                    profile: profile,
                    emptyIcon: Icons.task_alt_rounded,
                    emptyText: 'ยังไม่มีงานที่เสร็จ',
                    showAcceptButton: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Count Badge ──────────────────────────────────────────────

enum _TicketFilter { pending, inProgress }

class _CountBadge extends ConsumerWidget {
  const _CountBadge({required this.ref, required this.filter});
  final WidgetRef ref;
  final _TicketFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(technicianTicketsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return ticketsAsync.maybeWhen(
      data: (tickets) => profileAsync.maybeWhen(
        data: (profile) {
          int count;
          if (filter == _TicketFilter.pending) {
            count = tickets
                .where((t) =>
                    t.status == TicketStatus.open && t.assignedTo == null)
                .length;
          } else {
            count = tickets
                .where((t) =>
                    t.assignedTo == profile?.id &&
                    t.status != TicketStatus.closed &&
                    t.status != TicketStatus.resolved)
                .length;
          }
          if (count == 0) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ─── Ticket List ──────────────────────────────────────────────

class _TicketList extends ConsumerWidget {
  const _TicketList({
    required this.tickets,
    required this.profile,
    required this.emptyIcon,
    required this.emptyText,
    required this.showAcceptButton,
  });

  final List<Ticket> tickets;
  final UserProfile profile;
  final IconData emptyIcon;
  final String emptyText;
  final bool showAcceptButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(emptyText,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(technicianTicketsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _TechTicketCard(
          ticket: tickets[i],
          profile: profile,
          showAcceptButton: showAcceptButton,
        ),
      ),
    );
  }
}

// ─── Ticket Card ──────────────────────────────────────────────

class _TechTicketCard extends ConsumerWidget {
  const _TechTicketCard({
    required this.ticket,
    required this.profile,
    required this.showAcceptButton,
  });

  final Ticket ticket;
  final UserProfile profile;
  final bool showAcceptButton;

  Color _priorityColor(TicketPriority p) => switch (p) {
        TicketPriority.low => Colors.blue,
        TicketPriority.medium => Colors.orange,
        TicketPriority.high => Colors.red,
        TicketPriority.urgent => Colors.purple,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(ticket.priority);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianTicketDetailScreen(
              ticketId: ticket.id,
              technicianId: profile.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority bar
              Container(
                width: double.infinity,
                height: 3,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.priority.label,
                      style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (ticket.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  ticket.description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (ticket.category != null) ...[
                    Icon(Icons.category_rounded,
                        size: 13, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(ticket.category!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(width: 12),
                  ],
                  if (ticket.location != null &&
                      ticket.location!.isNotEmpty) ...[
                    Icon(Icons.location_on_rounded,
                        size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.location!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              if (showAcceptButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _acceptTicket(context, ref),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('รับงาน'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _acceptTicket(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(ticketControllerProvider.notifier)
          .acceptTicket(ticket.id, profile.id);
      ref.invalidate(technicianTicketsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รับงานสำเร็จ!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }
}

// ─── Error View ───────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}


