import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/ticket.dart';
import '../providers/ticket_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../technician/screens/ticket_chat_screen.dart';
import '../../../technician/repositories/review_repository.dart';
import '../../../technician/screens/review_dialog.dart';
import '../../../technician/widgets/masked_call_button.dart';
import '../../../technician/screens/technician_public_profile_screen.dart';

final userNameProvider =
    FutureProvider.family<String, String>((ref, userId) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .maybeSingle(); // ← เปลี่ยนตรงนี้
  return data?['full_name'] as String? ?? 'ไม่ระบุชื่อ'; // ← เพิ่ม ?
});

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final profileAsync = ref.watch(currentProfileProvider);
    final reviewAsync = ref.watch(ticketReviewProvider(ticketId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียด Ticket'),
        actions: [
          ticketAsync.maybeWhen(
            data: (ticket) => IconButton(
              icon: const Icon(Icons.chat_rounded),
              tooltip: 'แชทกับช่างซ่อม',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketChatScreen(
                    ticketId: ticket.id,
                    ticketTitle: ticket.title,
                  ),
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ticket) {
          final profile = profileAsync.valueOrNull;
          final isOwner = profile?.id == ticket.createdBy;
          final review = reviewAsync.valueOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── หัวข้อ + status ──
              Text(ticket.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusChip(ticket.status),
                  const SizedBox(width: 8),
                  _PriorityChip(ticket.priority),
                ],
              ),
              const SizedBox(height: 16),

              // ── รายละเอียด ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รายละเอียด', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Text(ticket.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── ข้อมูลทั่วไป ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (ticket.category != null)
                        _InfoRow('ประเภท', ticket.category!),
                      _InfoRow(
                        'วันที่แจ้ง',
                        '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                      ),
                      if (ticket.assignedTo != null)
                        Consumer(
                          builder: (context, ref, _) {
                            final nameAsync =
                                ref.watch(userNameProvider(ticket.assignedTo!));
                            return _InfoRow(
                              'ผู้รับผิดชอบ',
                              nameAsync.when(
                                data: (name) => name,
                                loading: () => 'กำลังโหลด...',
                                error: (_, __) => ticket.assignedTo!,
                              ),
                            );
                          },
                        )
                      else
                        const _InfoRow('ผู้รับผิดชอบ', 'ยังไม่ได้มอบหมาย'),
                      if (ticket.location != null &&
                          ticket.location!.isNotEmpty)
                        _InfoRow('สถานที่', ticket.location!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── รูปภาพแนบ ──
              if (ticket.imageUrls.isNotEmpty) ...[
                Text('รูปภาพแนบ (${ticket.imageUrls.length})',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ticket.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () =>
                          _showImageDialog(context, ticket.imageUrls, i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: ticket.imageUrls[i],
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 110,
                            height: 110,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── แผนที่ตำแหน่ง ──
              if (ticket.hasLocation) ...[
                Text('ตำแหน่งที่เกิดปัญหา',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                LatLng(ticket.latitude!, ticket.longitude!),
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.it_support_helpdesk',
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point:
                                    LatLng(ticket.latitude!, ticket.longitude!),
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_pin,
                                    color: Colors.red, size: 40),
                              ),
                            ]),
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white70,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: const Text('© OpenStreetMap contributors',
                                style: TextStyle(fontSize: 9)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ══ ACTION SECTION ════════════════════════════════

              // ── ปุ่มปิดงาน (แสดงเฉพาะ owner + status = resolved) ──
              if (isOwner && ticket.status == TicketStatus.resolved) ...[
                const Divider(),
                const SizedBox(height: 8),
                _CloseJobBanner(
                  ticket: ticket,
                  onClosed: (ref) async {
                    ref.invalidate(ticketDetailProvider(ticketId));
                    ref.invalidate(ticketsProvider);
                    // ถ้ามีช่าง → เปิด review dialog
                    if (ticket.assignedTo != null) {
                      if (context.mounted) {
                        await showReviewDialog(
                          context: context,
                          ref: ref,
                          ticketId: ticketId,
                          technicianId: ticket.assignedTo!,
                        );
                        ref.invalidate(ticketReviewProvider(ticketId));
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              // ── review summary (ถ้าให้แล้ว) ──
              if (review != null) ...[
                ReviewSummaryCard(
                  rating: review.rating,
                  comment: review.comment,
                ),
                const SizedBox(height: 12),
              ],

              // ── ปุ่มรีวิว (ถ้า closed + มีช่าง + ยังไม่ได้รีวิว) ──
              if (isOwner &&
                  ticket.status == TicketStatus.closed &&
                  ticket.assignedTo != null &&
                  review == null) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    await showReviewDialog(
                      context: context,
                      ref: ref,
                      ticketId: ticketId,
                      technicianId: ticket.assignedTo!,
                    );
                    ref.invalidate(ticketReviewProvider(ticketId));
                  },
                  icon: const Icon(Icons.star_rounded, color: Colors.amber),
                  label: const Text('ให้คะแนนการบริการ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                    side: const BorderSide(color: Colors.amber),
                    foregroundColor: Colors.amber[800],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── ดูโปรไฟล์ช่าง ──
              if (ticket.assignedTo != null) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TechnicianPublicProfileScreen(
                        technicianId: ticket.assignedTo!,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.person_rounded),
                  label: const Text('ดูโปรไฟล์ช่าง'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                    foregroundColor: const Color(0xFF26A69A),
                    side: const BorderSide(color: Color(0xFF26A69A)),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── ยกเลิก Ticket ──
              if (isOwner && ticket.status == TicketStatus.open) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, ref, ticket.id),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('ยกเลิก Ticket'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                    foregroundColor: Colors.red[400],
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── แสดง Cancelled State ──
              if (ticket.status == TicketStatus.cancelled) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text('Ticket ถูกยกเลิกแล้ว',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold)),
                      ]),
                      if (ticket.cancellationReason != null &&
                          ticket.cancellationReason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('เหตุผล: ${ticket.cancellationReason}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── ปุ่มโทร + แชท ──
              if (ticket.assignedTo != null) ...[
                MaskedCallButton(
                  ticketId: ticket.id,
                  technicianId: ticket.assignedTo!,
                  userId: ticket.createdBy,
                  direction: CallDirection.userToTech,
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketChatScreen(
                      ticketId: ticket.id,
                      ticketTitle: ticket.title,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('แชทกับช่างซ่อม'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String ticketId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยกเลิก Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรุณาระบุเหตุผลในการยกเลิก (ถ้ามี)'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'เช่น ปัญหาได้รับการแก้ไขแล้ว, เปลี่ยนใจ...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยังไม่'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(ticketControllerProvider.notifier)
                    .cancelTicket(ticketId, reason: reasonCtrl.text.trim());
                ref.invalidate(ticketDetailProvider(ticketId));
                ref.invalidate(ticketsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ยกเลิก Ticket เรียบร้อย'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                  );
                }
              }
            },
            child: const Text('ยืนยันยกเลิก'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, List<String> urls, int initial) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initial),
              itemCount: urls.length,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Close Job Banner ─────────────────────────────────────────

class _CloseJobBanner extends ConsumerWidget {
  const _CloseJobBanner({required this.ticket, required this.onClosed});
  final Ticket ticket;
  final Future<void> Function(WidgetRef ref) onClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'ช่างแจ้งว่าซ่อมเสร็จแล้ว!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green[700], fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'กรุณายืนยันและปิดงานหลังจากตรวจสอบเรียบร้อยแล้ว',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _closeTicket(context, ref),
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('ยืนยันและปิดงาน'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeTicket(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        // ✅ ตั้งชื่อ context ของ dialog ใหม่
        title: const Text('ยืนยันการปิดงาน'),
        content: const Text(
            'คุณได้ตรวจสอบงานเรียบร้อยแล้ว\nต้องการปิดงานนี้ใช่ไหม?'),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(dialogCtx, false), // ✅ ใช้ dialogCtx
              child: const Text('ยังไม่')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true), // ✅ ใช้ dialogCtx
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ปิดงาน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(ticketControllerProvider.notifier)
          .updateStatus(ticket.id, TicketStatus.closed);
      if (context.mounted) {
        await onClosed(ref);
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

// ─── Widgets ──────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final TicketStatus status;

  Color _color(BuildContext context) => switch (status) {
        TicketStatus.open => Theme.of(context).colorScheme.primary,
        TicketStatus.inProgress => Colors.orange,
        TicketStatus.resolved => Colors.green,
        TicketStatus.closed => Theme.of(context).colorScheme.outline,
        TicketStatus.cancelled => Colors.red[300]!,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip(this.priority);
  final TicketPriority priority;

  Color _color() => switch (priority) {
        TicketPriority.low => Colors.blue,
        TicketPriority.medium => Colors.orange,
        TicketPriority.high => Colors.red,
        TicketPriority.urgent => Colors.purple,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(priority.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
