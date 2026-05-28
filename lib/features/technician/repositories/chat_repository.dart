import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/supabase_service.dart';

class ChatRepository {
  ChatRepository(this._supabase);
  final SupabaseService _supabase;
  SupabaseClient get _client => _supabase.client;

  /// ดึง messages ของ ticket (join profiles เพื่อได้ชื่อ)
  Future<List<ChatMessage>> getMessages(String ticketId) async {
    try {
      final data = await _client
          .from('ticket_comments')
          .select('*, profiles(full_name, avatar_url)')
          .eq('ticket_id', ticketId)
          .eq('is_internal', false)
          .order('created_at', ascending: true);
      return (data as List).map((e) => ChatMessage.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException('Failed to load messages: ${e.message}');
    }
  }

  /// ส่งข้อความใหม่
  Future<void> sendMessage({
    required String ticketId,
    required String authorId,
    required String content,
  }) async {
    try {
      await _client.from('ticket_comments').insert({
        'ticket_id': ticketId,
        'author_id': authorId,
        'content': content.trim(),
        'is_internal': false,
        'image_urls': <String>[],
      });
    } on PostgrestException catch (e) {
      throw AppException('Failed to send message: ${e.message}');
    }
  }

  /// Realtime stream ของ messages
  Stream<List<ChatMessage>> messagesStream(String ticketId) {
    return _client
        .from('ticket_comments')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .where((r) => r['is_internal'] == false)
            .map((r) => ChatMessage(
                  id: r['id'] as String,
                  ticketId: r['ticket_id'] as String,
                  authorId: r['author_id'] as String,
                  authorName: 'Loading...',
                  content: r['content'] as String,
                  createdAt: DateTime.parse(r['created_at'] as String),
                  imageUrls: (r['image_urls'] as List<dynamic>? ?? [])
                      .map((e) => e as String)
                      .toList(),
                  isInternal: false,
                ))
            .toList());
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ChatRepository(supabase);
});

/// Provider ที่ดึง messages พร้อม profile (initial load)
final chatMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, ticketId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(ticketId);
});


