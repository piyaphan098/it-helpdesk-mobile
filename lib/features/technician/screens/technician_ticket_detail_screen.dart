import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:it_support_helpdesk/models/ticket.dart';
import 'package:it_support_helpdesk/features/tickets/presentation/providers/ticket_provider.dart';
import '../providers/technician_provider.dart';
import '../widgets/masked_call_button.dart';
import 'ticket_chat_screen.dart';

// ── Provider: ตำแหน่งช่างแบบ real-time ──────────────────────────
final technicianLocationProvider = StreamProvider.autoDispose<Position>((ref) {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update ทุก 10 เมตร
    ),
  );
});

class TechnicianTicketDetailScreen extends ConsumerStatefulWidget {
  const TechnicianTicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.technicianId,
  });

  final String ticketId;
  final String technicianId;

  @override
  ConsumerState<TechnicianTicketDetailScreen> createState() =>
      _TechnicianTicketDetailScreenState();
}

class _TechnicianTicketDetailScreenState
    extends ConsumerState<TechnicianTicketDetailScreen> {
  final _mapController = MapController();
  bool _isTracking = false;
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // นำทางผ่าน Google Maps / Apple Maps
  Future<void> _openNavigation(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิด Maps ได้')),
        );
      }
    }
  }

  void _centerOnTechnician(Position pos) {
    if (_mapReady) {
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        15,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final locationAsync = ref.watch(technicianLocationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดงาน'),
        actions: [
          ticketAsync.maybeWhen(
            data: (ticket) => IconButton(
              icon: const Icon(Icons.chat_rounded),
              tooltip: 'แชทกับผู้แจ้ง',
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
        data: (ticket) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header ──
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
                    if (ticket.location != null && ticket.location!.isNotEmpty)
                      _InfoRow('สถานที่', ticket.location!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── รูปภาพ ──
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
                  itemBuilder: (context, i) => ClipRRect(
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
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ══ GPS MAP SECTION ════════════════════════════════════
            if (ticket.hasLocation) ...[
              _SectionHeader(
                icon: Icons.map_rounded,
                label: 'แผนที่และการนำทาง',
              ),
              const SizedBox(height: 8),

              // แผนที่
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 260,
                  child: locationAsync.when(
                    loading: () => _buildMap(ticket, null),
                    error: (_, __) => _buildMap(ticket, null),
                    data: (pos) => _buildMap(ticket, pos),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── ระยะทาง ──
              locationAsync.maybeWhen(
                data: (pos) => _DistanceBanner(
                  techPos: pos,
                  targetLat: ticket.latitude!,
                  targetLng: ticket.longitude!,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),

              // ── ปุ่ม tracking + นำทาง ──
              Row(
                children: [
                  // ปุ่ม Tracking
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _isTracking = !_isTracking),
                      icon: Icon(_isTracking
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded),
                      label: Text(_isTracking ? 'Tracking ON' : 'Tracking OFF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isTracking ? Colors.green : null,
                        side: BorderSide(
                          color: _isTracking ? Colors.green : Colors.grey,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มนำทาง
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openNavigation(
                        ticket.latitude!,
                        ticket.longitude!,
                      ),
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('นำทาง'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // auto-center เมื่อ tracking เปิด
              locationAsync.maybeWhen(
                data: (pos) {
                  if (_isTracking) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _centerOnTechnician(pos);
                    });
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),
            ],
            // ══════════════════════════════════════════════════════

            // ── อัปเดตสถานะ ──
            Text('อัปเดตสถานะงาน', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatusUpdatePanel(
              ticket: ticket,
              technicianId: widget.technicianId,
            ),
            const SizedBox(height: 16),

            // ── ปุ่มโทร + แชท ──
            MaskedCallButton(
              ticketId: ticket.id,
              technicianId: widget.technicianId,
              userId: ticket.createdBy,
              direction: CallDirection.techToUser,
            ),
            const SizedBox(height: 10),
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
              label: const Text('แชทกับผู้แจ้งปัญหา'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(Ticket ticket, Position? techPos) {
    final customerLatLng = LatLng(ticket.latitude!, ticket.longitude!);
    final techLatLng =
        techPos != null ? LatLng(techPos.latitude, techPos.longitude) : null;

    // คำนวณ center ระหว่างสองจุด (ถ้ามีทั้งคู่)
    final center = (techLatLng != null)
        ? LatLng(
            (customerLatLng.latitude + techLatLng.latitude) / 2,
            (customerLatLng.longitude + techLatLng.longitude) / 2,
          )
        : customerLatLng;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        onMapReady: () => setState(() => _mapReady = true),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.it_support_helpdesk',
        ),

        // เส้นเชื่อมระหว่างช่างกับลูกค้า
        if (techLatLng != null)
          PolylineLayer<Object>(
            polylines: [
              Polyline(
                points: [techLatLng, customerLatLng],
                strokeWidth: 3,
                color: Colors.blue.withValues(alpha: 0.7),
                pattern: StrokePattern.dashed(segments: [12, 6]),
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            // หมุดลูกค้า (แดง)
            Marker(
              point: customerLatLng,
              width: 44,
              height: 44,
              child: const _MapPin(
                  color: Colors.red, icon: Icons.person_pin_circle_rounded),
            ),
            // หมุดช่าง (น้ำเงิน) — แสดงเฉพาะเมื่อมี GPS
            if (techLatLng != null)
              Marker(
                point: techLatLng,
                width: 44,
                height: 44,
                child: const _MapPin(
                    color: Colors.blue, icon: Icons.engineering_rounded),
              ),
          ],
        ),

        // Legend
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(color: Colors.red, label: 'จุดแจ้งปัญหา'),
                if (techLatLng != null)
                  _LegendItem(color: Colors.blue, label: 'ตำแหน่งฉัน'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Distance Banner ───────────────────────────────────────────

class _DistanceBanner extends StatelessWidget {
  const _DistanceBanner({
    required this.techPos,
    required this.targetLat,
    required this.targetLng,
  });

  final Position techPos;
  final double targetLat;
  final double targetLng;

  @override
  Widget build(BuildContext context) {
    final distanceM = Geolocator.distanceBetween(
      techPos.latitude,
      techPos.longitude,
      targetLat,
      targetLng,
    );

    final String distText = distanceM < 1000
        ? '${distanceM.toStringAsFixed(0)} ม.'
        : '${(distanceM / 1000).toStringAsFixed(1)} กม.';

    final Color color = distanceM < 200 ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.social_distance_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'ระยะห่างจากจุดแจ้งปัญหา: $distText',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Map Pin ───────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

// ── Legend Item ───────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ─── Status Update Panel ──────────────────────────────────────

class _StatusUpdatePanel extends ConsumerWidget {
  const _StatusUpdatePanel({
    required this.ticket,
    required this.technicianId,
  });

  final Ticket ticket;
  final String technicianId;

  static const _allowedStatuses = [
    TicketStatus.inProgress,
    TicketStatus.resolved,
    TicketStatus.closed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถานะปัจจุบัน: ${ticket.status.label}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allowedStatuses.map((s) {
                final isSelected = ticket.status == s;
                return _StatusButton(
                  status: s,
                  isSelected: isSelected,
                  onTap:
                      isSelected ? null : () => _updateStatus(context, ref, s),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, TicketStatus newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการเปลี่ยนสถานะ'),
        content: Text('เปลี่ยนเป็น "${newStatus.label}" ใช่ไหม?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(ticketControllerProvider.notifier)
          .updateStatus(ticket.id, newStatus);
      ref.invalidate(ticketDetailProvider(ticket.id));
      ref.invalidate(technicianTicketsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('อัปเดตสถานะเป็น "${newStatus.label}" สำเร็จ')),
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

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final TicketStatus status;
  final bool isSelected;
  final VoidCallback? onTap;

  Color _color(BuildContext context) => switch (status) {
        TicketStatus.inProgress => Colors.orange,
        TicketStatus.resolved => Colors.green,
        TicketStatus.closed => Theme.of(context).colorScheme.outline,
        _ => Theme.of(context).colorScheme.primary,
      };

  IconData _icon() => switch (status) {
        TicketStatus.inProgress => Icons.build_rounded,
        TicketStatus.resolved => Icons.check_circle_rounded,
        TicketStatus.closed => Icons.lock_rounded,
        _ => Icons.circle,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: isSelected ? color : color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(), size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────

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

// ─── Status / Priority Chips ──────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
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


