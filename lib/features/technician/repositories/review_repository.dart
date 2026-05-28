import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ticket_review.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/supabase_service.dart';

class ReviewRepository {
  ReviewRepository(this._supabase);
  final SupabaseService _supabase;
  SupabaseClient get _client => _supabase.client;

  /// ส่ง review ใหม่
  Future<TicketReview> submitReview({
    required String ticketId,
    required String reviewerId,
    required String technicianId,
    required int rating,
    String? comment,
  }) async {
    try {
      final data = await _client
          .from('ticket_reviews')
          .insert({
            'ticket_id': ticketId,
            'reviewer_id': reviewerId,
            'technician_id': technicianId,
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          })
          .select()
          .single();
      return TicketReview.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('ส่ง review ไม่สำเร็จ: ${e.message}');
    }
  }

  /// ตรวจว่า ticket นี้ถูก review แล้วหรือยัง
  Future<TicketReview?> getReview(String ticketId) async {
    try {
      final data = await _client
          .from('ticket_reviews')
          .select()
          .eq('ticket_id', ticketId)
          .maybeSingle();
      if (data == null) return null;
      return TicketReview.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppException('โหลด review ไม่สำเร็จ: ${e.message}');
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(supabaseServiceProvider));
});

/// ดึง review ของ ticket (null = ยังไม่มี)
final ticketReviewProvider =
    FutureProvider.family<TicketReview?, String>((ref, ticketId) {
  return ref.watch(reviewRepositoryProvider).getReview(ticketId);
});
