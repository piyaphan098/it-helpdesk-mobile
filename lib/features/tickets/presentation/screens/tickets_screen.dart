import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../models/ticket.dart';
import '../providers/ticket_provider.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTicket),
        icon: const Icon(Icons.add_rounded),
        label: const Text('แจ้งปัญหา'),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('โหลดข้อมูลไม่สำเร็จ', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$e',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(ticketsProvider),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('ยังไม่มี Ticket',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  Text('กด + เพื่อแจ้งปัญหา IT',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ticketsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.push('/tickets/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const SizedBox(width: 8),
                  _PriorityDot(ticket.priority),
                ],
              ),
              if (ticket.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatusBadge(ticket.status),
                  const Spacer(),
                  if (ticket.category != null) ...[
                    Icon(Icons.category_rounded,
                        size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(ticket.category!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(width: 8),
                  ],
                  if (ticket.imageUrls.isNotEmpty) ...[
                    Icon(Icons.photo_rounded,
                        size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 2),
                    Text('${ticket.imageUrls.length}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(width: 8),
                  ],
                  if (ticket.hasLocation)
                    Icon(Icons.location_on_rounded,
                        size: 12, color: theme.colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final TicketStatus status;

  Color _color(BuildContext context) => switch (status) {
        TicketStatus.open => Theme.of(context).colorScheme.primary,
        TicketStatus.inProgress => Colors.orange,
        TicketStatus.resolved => Colors.green,
        TicketStatus.closed => Theme.of(context).colorScheme.outline,
        TicketStatus.cancelled => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot(this.priority);
  final TicketPriority priority;

  Color _color() => switch (priority) {
        TicketPriority.low => Colors.blue,
        TicketPriority.medium => Colors.orange,
        TicketPriority.high => Colors.red,
        TicketPriority.urgent => Colors.purple,
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: priority.label,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _color(),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
