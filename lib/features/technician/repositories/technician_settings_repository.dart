import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/technician_settings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/supabase_service.dart';

class TechnicianSettingsRepository {
  TechnicianSettingsRepository(this._supabase);
  final SupabaseService _supabase;
  SupabaseClient get _client => _supabase.client;

  Future<TechnicianSettings?> getSettings(String technicianId) async {
    try {
      final data = await _client
          .from('technician_settings')
          .select()
          .eq('technician_id', technicianId)
          .maybeSingle();
      if (data == null) return null;
      return TechnicianSettings.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('โหลด settings ไม่ได้: ${e.message}');
    }
  }

  /// upsert — สร้างใหม่หรืออัปเดต
  Future<TechnicianSettings> saveSettings({
    required String technicianId,
    required bool isAvailable,
    double? serviceLat,
    double? serviceLng,
    double serviceRadiusKm = 10.0,
  }) async {
    try {
      final data = await _client
          .from('technician_settings')
          .upsert({
            'technician_id': technicianId,
            'is_available': isAvailable,
            if (serviceLat != null) 'service_lat': serviceLat,
            if (serviceLng != null) 'service_lng': serviceLng,
            'service_radius_km': serviceRadiusKm,
          }, onConflict: 'technician_id')
          .select()
          .single();
      return TechnicianSettings.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('บันทึก settings ไม่ได้: ${e.message}');
    }
  }

  /// toggle เปิด/ปิดรับงาน
  Future<void> toggleAvailability(
      String technicianId, bool isAvailable) async {
    try {
      await _client
          .from('technician_settings')
          .upsert({
            'technician_id': technicianId,
            'is_available': isAvailable,
          }, onConflict: 'technician_id');
    } on PostgrestException catch (e) {
      throw AppException('อัปเดตสถานะไม่ได้: ${e.message}');
    }
  }
}

final technicianSettingsRepositoryProvider =
    Provider<TechnicianSettingsRepository>((ref) {
  return TechnicianSettingsRepository(ref.watch(supabaseServiceProvider));
});

final technicianSettingsProvider =
    FutureProvider.family<TechnicianSettings?, String>((ref, techId) {
  return ref.watch(technicianSettingsRepositoryProvider).getSettings(techId);
});
