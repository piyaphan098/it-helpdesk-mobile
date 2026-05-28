import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/ticket.dart';
import '../services/supabase_service.dart';

class TicketRepository {
  TicketRepository(this._supabase);
  final SupabaseService _supabase;
  SupabaseClient get _client => _supabase.client;

  /// อัปโหลดรูปภาพไปยัง Supabase Storage แล้วคืน public URL
  Future<List<String>> uploadImages(List<XFile> images, String userId) async {
    final urls = <String>[];
    const uuid = Uuid();

    for (final image in images) {
      try {
        final bytes = await image.readAsBytes();
        final ext = image.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final fileName = '$userId/${uuid.v4()}.$ext';

        await _client.storage.from('ticket-images').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: false),
            );

        final url =
            _client.storage.from('ticket-images').getPublicUrl(fileName);
        urls.add(url);
      } catch (e) {
        throw AppException('Failed to upload image: $e');
      }
    }

    return urls;
  }

  /// ดึง tickets ทั้งหมด
  Future<List<Ticket>> getTickets({String? userId}) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ticketsTable)
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => Ticket.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException('Failed to load tickets: ${e.message}');
    } catch (e) {
      throw AppException('Failed to load tickets: $e');
    }
  }

  /// ดึง ticket เดียวตาม id
  Future<Ticket> getTicket(String id) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ticketsTable)
          .select()
          .eq('id', id)
          .single();
      return Ticket.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('Failed to load ticket: ${e.message}');
    } catch (e) {
      throw AppException('Failed to load ticket: $e');
    }
  }

  /// สร้าง ticket ใหม่ พร้อมรูปภาพและ location
  Future<Ticket> createTicket({
    required String title,
    required String description,
    required TicketPriority priority,
    required String createdBy,
    String? category,
    List<XFile> images = const [],
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    try {
      final imageUrls = images.isNotEmpty
          ? await uploadImages(images, createdBy)
          : <String>[];

      final data = await _client
          .from(SupabaseConstants.ticketsTable)
          .insert({
            'title': title,
            'description': description,
            'priority': priority.value,
            'status': TicketStatus.open.value,
            'created_by': createdBy,
            if (category != null) 'category': category,
            'image_urls': imageUrls,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (location != null && location.isNotEmpty) 'location': location,
          })
          .select()
          .single();
      return Ticket.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('Failed to create ticket: ${e.message}');
    } catch (e) {
      throw AppException('Failed to create ticket: $e');
    }
  }

  /// ช่างรับงาน: set assigned_to + เปลี่ยน status เป็น inProgress
  Future<Ticket> acceptTicket(String ticketId, String technicianId) async {
    try {
      await _client.from(SupabaseConstants.ticketsTable).update({
        'assigned_to': technicianId,
        'status': TicketStatus.inProgress.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);
      final result = await _client
          .from(SupabaseConstants.ticketsTable)
          .select()
          .eq('id', ticketId)
          .single();
      return Ticket.fromJson(result);
    } on PostgrestException catch (e) {
      throw AppException('Failed to accept ticket: ${e.message}');
    } catch (e) {
      throw AppException('Failed to accept ticket: $e');
    }
  }

  /// อัพเดท status ของ ticket
  Future<Ticket> updateTicketStatus(String id, TicketStatus status) async {
    try {
      final data = await _client
          .from(SupabaseConstants.ticketsTable)
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return Ticket.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('Failed to update ticket: ${e.message}');
    } catch (e) {
      throw AppException('Failed to update ticket: $e');
    }
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return TicketRepository(supabase);
});

extension TicketRepositoryCancel on TicketRepository {
  /// ยกเลิก ticket (user กดยกเลิก + ระบุเหตุผล)
  Future<void> cancelTicket(String id, {required String reason}) async {
    try {
      await _client.from(SupabaseConstants.ticketsTable).update({
        'status': TicketStatus.cancelled.value,
        'cancellation_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw AppException('Failed to cancel ticket: ${e.message}');
    } catch (e) {
      throw AppException('Failed to cancel ticket: $e');
    }
  }
}
