/// Model สำหรับ ticket_comments (ใช้เป็น chat)
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorAvatarUrl,
    this.imageUrls = const [],
    this.isInternal = false,
  });

  final String id;
  final String ticketId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final String? authorAvatarUrl;
  final List<String> imageUrls;
  final bool isInternal;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final author = json['profiles'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      authorId: json['author_id'] as String,
      authorName: author?['full_name'] as String? ?? 'Unknown',
      authorAvatarUrl: author?['avatar_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrls: (json['image_urls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      isInternal: json['is_internal'] as bool? ?? false,
    );
  }
}
