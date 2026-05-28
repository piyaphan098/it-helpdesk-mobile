import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../models/ticket.dart';

// ─── Read State Provider ──────────────────────────────────────────────────────
final _readIdsProvider = StateNotifierProvider<_ReadIdsNotifier, Set<String>>(
  (ref) => _ReadIdsNotifier(),
);

class _ReadIdsNotifier extends StateNotifier<Set<String>> {
  _ReadIdsNotifier() : super({}) {
    _load();
  }

  static const _key = 'notif_read_ids';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    state = list.toSet();
  }

  Future<void> markRead(String id) async {
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  Future<void> markAllRead(List<String> ids) async {
    state = {...state, ...ids};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }
}

// ─── Filter Enum ─────────────────────────────────────────────────────────────
enum _Filter { all, unread, read }

final _filterProvider = StateProvider<_Filter>((ref) => _Filter.all);

// ─── Screen ───────────────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final readIds = ref.watch(_readIdsProvider);
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          Positioned(
            top: 60, right: -40,
            child: _GlowBlob(color: const Color(0xFF6A1B9A), size: 180),
          ),
          Positioned(
            bottom: 100, left: -30,
            child: _GlowBlob(color: const Color(0xFF1565C0), size: 160),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alerts',
                                style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w700,
                                  color: Colors.white, letterSpacing: -0.5,
                                )),
                              Text('อัปเดตสถานะ ticket ของคุณ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.45),
                                )),
                            ],
                          ),
                        ),
                        // Mark all read button
                        ticketsAsync.maybeWhen(
                          data: (tickets) {
                            final allIds = _buildNotifications(tickets, {})
                                .map((n) => n.id).toList();
                            return _GlassIconButton(
                              icon: Icons.done_all_rounded,
                              onTap: () => ref.read(_readIdsProvider.notifier)
                                  .markAllRead(allIds),
                              tooltip: 'Mark all read',
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // ── Filter Chips ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _Filter.values.map((f) {
                          final labels = {
                            _Filter.all: 'ทั้งหมด',
                            _Filter.unread: 'ยังไม่อ่าน',
                            _Filter.read: 'อ่านแล้ว',
                          };
                          final selected = filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => ref.read(_filterProvider.notifier).state = f,
                              child: AnimatedContainer(
                                duration: 200.ms,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF5E92F3)
                                      : Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF5E92F3)
                                        : Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  labels[f]!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ),

                // ── Content ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: ticketsAsync.when(
                    loading: () => SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: CircularProgressIndicator(
                              color: const Color(0xFF5E92F3), strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: _EmptyState(
                        icon: Icons.error_outline,
                        title: 'เกิดข้อผิดพลาด',
                        subtitle: e.toString(),
                      ),
                    ),
                    data: (tickets) {
                      final all = _buildNotifications(tickets, readIds);
                      final filtered = filter == _Filter.all
                          ? all
                          : filter == _Filter.unread
                              ? all.where((n) => !n.isRead).toList()
                              : all.where((n) => n.isRead).toList();

                      if (filtered.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: filter == _Filter.unread
                                ? 'ไม่มีการแจ้งเตือนที่ยังไม่ได้อ่าน'
                                : 'ยังไม่มีการแจ้งเตือน',
                            subtitle: 'อัปเดตสถานะ ticket จะแสดงที่นี่',
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NotificationCard(
                                item: item,
                                onTap: () {
                                  ref.read(_readIdsProvider.notifier)
                                      .markRead(item.id);
                                  if (item.ticketId != null) {
                                    context.push(
                                      AppRoutes.ticketDetail
                                          .replaceFirst(':id', item.ticketId!),
                                    );
                                  }
                                },
                              ),
                            )
                                .animate(delay: (index * 60).ms)
                                .fadeIn()
                                .slideX(begin: 0.05);
                          },
                          childCount: filtered.length,
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<_NotifItem> _buildNotifications(
      List<Ticket> tickets, Set<String> readIds) {
    final items = <_NotifItem>[];

    for (final t in tickets) {
      final createdId = 'created_${t.id}';
      items.add(_NotifItem(
        id: createdId,
        ticketId: t.id,
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFF5E92F3),
        title: 'Ticket ถูกสร้างแล้ว',
        subtitle: t.title,
        time: t.createdAt,
        isRead: readIds.contains(createdId),
      ));

      if (t.assignedTo != null) {
        final assignedId = 'assigned_${t.id}';
        items.add(_NotifItem(
          id: assignedId,
          ticketId: t.id,
          icon: Icons.person_add_outlined,
          color: const Color(0xFF26A69A),
          title: 'มีช่างรับงานแล้ว',
          subtitle: t.title,
          time: t.updatedAt ?? t.createdAt,
          isRead: readIds.contains(assignedId),
        ));
      }

      if (t.status == TicketStatus.resolved) {
        final resolvedId = 'resolved_${t.id}';
        items.add(_NotifItem(
          id: resolvedId,
          ticketId: t.id,
          icon: Icons.check_circle_outline,
          color: const Color(0xFF66BB6A),
          title: 'ช่างซ่อมเสร็จแล้ว รอการยืนยัน',
          subtitle: t.title,
          time: t.updatedAt ?? t.createdAt,
          isRead: readIds.contains(resolvedId),
        ));
      }

      if (t.status == TicketStatus.closed) {
        final closedId = 'closed_${t.id}';
        items.add(_NotifItem(
          id: closedId,
          ticketId: t.id,
          icon: Icons.task_alt_rounded,
          color: Colors.white54,
          title: 'ปิด Ticket แล้ว',
          subtitle: t.title,
          time: t.updatedAt ?? t.createdAt,
          isRead: readIds.contains(closedId),
        ));
      }
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class _NotifItem {
  const _NotifItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
    this.ticketId,
  });

  final String id;
  final String? ticketId;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime time;
  final bool isRead;
}

// ─── Card ─────────────────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});
  final _NotifItem item;
  final VoidCallback onTap;

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isRead
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.isRead
                    ? Colors.white.withValues(alpha: 0.07)
                    : item.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w400 : FontWeight.w600,
                                color: Colors.white.withValues(
                                    alpha: item.isRead ? 0.7 : 1.0),
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.color,
                                boxShadow: [BoxShadow(
                                  color: item.color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                )],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.4)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatTime(item.time),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          if (item.ticketId != null) ...[ 
                            const Spacer(),
                            Text(
                              'ดูรายละเอียด →',
                              style: TextStyle(
                                fontSize: 11,
                                color: item.color.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon, required this.title, required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 32, color: Colors.white30),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: Colors.white70, fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Glass Icon Button ────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon, required this.onTap, this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Glow Blob ────────────────────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 80, spreadRadius: 20,
        )],
      ),
    );
  }
}


