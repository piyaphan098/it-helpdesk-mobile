import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ticket.dart';
import '../../../repositories/ticket_repository.dart';
import '../repositories/technician_settings_repository.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// ดึง tickets ทั้งหมดสำหรับช่าง
final technicianTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final repository = ref.watch(ticketRepositoryProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return [];

  final allTickets = await repository.getTickets();

  // โหลด settings ของช่างคนนี้
  final settings = await ref
      .watch(technicianSettingsRepositoryProvider)
      .getSettings(profile.id);

  // ถ้าปิดรับงาน → แสดงเฉพาะงานที่รับอยู่แล้ว
  if (settings != null && !settings.isAvailable) {
    return allTickets
        .where((t) => t.assignedTo == profile.id)
        .toList();
  }

  // กรอง ticket นอก service area ออก
  if (settings != null && settings.hasServiceArea) {
    return allTickets.where((t) {
      // ticket ที่รับอยู่แล้ว แสดงเสมอ
      if (t.assignedTo == profile.id) return true;
      // ticket ที่ไม่มี GPS → แสดงเสมอ
      if (t.latitude == null || t.longitude == null) return true;
      final dist = _haversineKm(
        settings.serviceLat!,
        settings.serviceLng!,
        t.latitude!,
        t.longitude!,
      );
      return dist <= settings.serviceRadiusKm;
    }).toList();
  }

  return allTickets;
});

double _haversineKm(
    double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;


