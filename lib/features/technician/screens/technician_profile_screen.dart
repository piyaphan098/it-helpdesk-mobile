import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:it_support_helpdesk/models/user_profile.dart';
import 'package:it_support_helpdesk/models/ticket.dart';
import 'package:it_support_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import '../models/technician_settings.dart';
import '../repositories/technician_settings_repository.dart';
import '../providers/technician_provider.dart';
import './manage_posts_screen.dart';

class TechnicianProfileScreen extends ConsumerStatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  ConsumerState<TechnicianProfileScreen> createState() =>
      _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState
    extends ConsumerState<TechnicianProfileScreen> {
  final _mapController = MapController();
  bool _mapReady = false;
  bool _isSaving = false;

  double _radius = 10.0;
  LatLng? _serviceCenter;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(
          () => _serviceCenter = LatLng(pos.latitude, pos.longitude));
      if (_mapReady) {
        _mapController.move(_serviceCenter!, 12);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _saveSettings(String technicianId) async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(technicianSettingsRepositoryProvider)
          .saveSettings(
            technicianId: technicianId,
            isAvailable: true,
            serviceLat: _serviceCenter?.latitude,
            serviceLng: _serviceCenter?.longitude,
            serviceRadiusKm: _radius,
          );
      ref.invalidate(technicianSettingsProvider(technicianId));
      ref.invalidate(technicianTicketsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกพื้นที่รับงานแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final settingsAsync =
            ref.watch(technicianSettingsProvider(profile.id));
        final reviewsAsync =
            ref.watch(_technicianReviewsProvider(profile.id));

        // sync slider/map จาก settings เมื่อโหลดครั้งแรก
        settingsAsync.whenData((s) {
          if (s != null && _serviceCenter == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _radius = s.serviceRadiusKm;
                if (s.hasServiceArea) {
                  _serviceCenter =
                      LatLng(s.serviceLat!, s.serviceLng!);
                }
              });
            });
          }
        });

        return Scaffold(
          appBar: AppBar(title: const Text('โปรไฟล์ช่าง')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar + ชื่อ ──
              _ProfileHeader(profile: profile, reviewsAsync: reviewsAsync),
              const SizedBox(height: 20),

              // ── Toggle รับงาน ──
              settingsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const SizedBox.shrink(),
                data: (settings) => _AvailabilityToggle(
                  profile: profile,
                  settings: settings,
                ),
              ),
              const SizedBox(height: 20),

              // ── สถิติ ──
              _StatsBanner(profile: profile),
              const SizedBox(height: 20),

              // ── พื้นที่รับงาน ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: theme.colorScheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('พื้นที่รับงาน',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'แตะแผนที่เพื่อตั้งศูนย์กลาง แล้วปรับ radius',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const SizedBox(height: 12),
                      // แผนที่
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 240,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _serviceCenter ??
                                  const LatLng(13.7563, 100.5018),
                              initialZoom: 11,
                              onMapReady: () =>
                                  setState(() => _mapReady = true),
                              onTap: (_, latLng) {
                                setState(() => _serviceCenter = latLng);
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.it_support_helpdesk',
                              ),
                              if (_serviceCenter != null) ...[
                                // วงกลมแสดง radius
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: _serviceCenter!,
                                      radius: _radius * 1000,
                                      useRadiusInMeter: true,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      borderColor:
                                          theme.colorScheme.primary,
                                      borderStrokeWidth: 2,
                                    ),
                                  ],
                                ),
                                MarkerLayer(markers: [
                                  Marker(
                                    point: _serviceCenter!,
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                        Icons.my_location_rounded,
                                        color:
                                            theme.colorScheme.primary,
                                        size: 32),
                                  ),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Radius slider
                      Row(
                        children: [
                          const Icon(Icons.radar_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                              'รัศมี: ${_radius.toStringAsFixed(0)} กม.',
                              style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _useCurrentLocation,
                            icon: const Icon(Icons.gps_fixed_rounded,
                                size: 16),
                            label: const Text('ตำแหน่งปัจจุบัน'),
                          ),
                        ],
                      ),
                      Slider(
                        value: _radius,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: '${_radius.toStringAsFixed(0)} กม.',
                        onChanged: (v) => setState(() => _radius = v),
                      ),
                      if (_serviceCenter == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '* แตะแผนที่เพื่อตั้งศูนย์กลางพื้นที่',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _serviceCenter == null || _isSaving
                              ? null
                              : () => _saveSettings(profile.id),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.save_rounded),
                          label: const Text('บันทึกพื้นที่รับงาน'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),


              // ── ปุ่มจัดการผลงาน ──
              Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('จัดการผลงาน (Portfolio)'),
                  subtitle: const Text('เพิ่ม/ลบรูปผลงานเพิ่มความน่าเชื่อถือ'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagePostsScreen(
                          technicianId: profile.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── รายการรีวิว ──
              reviewsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox.shrink(),
                data: (reviews) => _ReviewList(reviews: reviews),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader(
      {required this.profile, required this.reviewsAsync});
  final UserProfile profile;
  final AsyncValue<List<_ReviewItem>> reviewsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = reviewsAsync.valueOrNull ?? [];
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: profile.avatarUrl != null
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(profile.initials,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(profile.role.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline)),
                  if (profile.department != null)
                    Text(profile.department!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        avg > 0
                            ? '${avg.toStringAsFixed(1)} (${reviews.length} รีวิว)'
                            : 'ยังไม่มีรีวิว',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Availability Toggle ──────────────────────────────────────

class _AvailabilityToggle extends ConsumerWidget {
  const _AvailabilityToggle(
      {required this.profile, required this.settings});
  final UserProfile profile;
  final TechnicianSettings? settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = settings?.isAvailable ?? true;
    final theme = Theme.of(context);

    return Card(
      color: isAvailable
          ? Colors.green.withValues(alpha: 0.08)
          : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isAvailable
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.transparent,
          )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.green.withValues(alpha: 0.15)
                    : theme.colorScheme.outline.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAvailable
                    ? Icons.sensors_rounded
                    : Icons.sensors_off_rounded,
                color: isAvailable ? Colors.green : theme.colorScheme.outline,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvailable ? 'กำลังรับงาน' : 'ปิดรับงาน',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isAvailable
                          ? Colors.green[700]
                          : theme.colorScheme.outline,
                    ),
                  ),
                  Text(
                    isAvailable
                        ? 'ลูกค้าสามารถมอบหมายงานให้คุณได้'
                        : 'คุณจะไม่ปรากฏในรายชื่อช่าง',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            Switch(
              value: isAvailable,
              activeThumbColor: Colors.green,
              onChanged: (val) async {
                await ref
                    .read(technicianSettingsRepositoryProvider)
                    .toggleAvailability(profile.id, val);
                ref.invalidate(technicianSettingsProvider(profile.id));
                ref.invalidate(technicianTicketsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Banner ─────────────────────────────────────────────

class _StatsBanner extends ConsumerWidget {
  const _StatsBanner({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(technicianTicketsProvider);

    return ticketsAsync.maybeWhen(
      data: (tickets) {
        final myTickets =
            tickets.where((t) => t.assignedTo == profile.id).toList();
        final done = myTickets
            .where((t) =>
                t.status == TicketStatus.resolved ||
                t.status == TicketStatus.closed)
            .length;
        final active = myTickets
            .where((t) =>
                t.status == TicketStatus.inProgress)
            .length;

        return Row(
          children: [
            _StatCard(
                label: 'งานทั้งหมด', value: '${myTickets.length}',
                icon: Icons.work_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            _StatCard(
                label: 'กำลังดำเนินการ', value: '$active',
                icon: Icons.build_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            _StatCard(
                label: 'เสร็จแล้ว', value: '$done',
                icon: Icons.check_circle_rounded, color: Colors.green),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
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
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Review List ──────────────────────────────────────────────

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.reviews});
  final List<_ReviewItem> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.star_outline_rounded,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('ยังไม่มีรีวิว',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('รีวิวล่าสุด',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _ReviewItem review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment!,
                  style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Review data class ────────────────────────────────────────

class _ReviewItem {
  const _ReviewItem({
    required this.rating,
    required this.createdAt,
    this.comment,
  });
  final int rating;
  final String? comment;
  final DateTime createdAt;
}

/// Provider ดึง reviews ของช่างคนนี้
final _technicianReviewsProvider =
    FutureProvider.family<List<_ReviewItem>, String>((ref, techId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('ticket_reviews')
      .select('rating, comment, created_at')
      .eq('technician_id', techId)
      .order('created_at', ascending: false)
      .limit(20);
  return (data as List)
      .map((r) => _ReviewItem(
            rating: r['rating'] as int,
            comment: r['comment'] as String?,
            createdAt: DateTime.parse(r['created_at'] as String),
          ))
      .toList();
});


