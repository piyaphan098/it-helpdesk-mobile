class TicketReview {
  const TicketReview({
    required this.id,
    required this.ticketId,
    required this.reviewerId,
    required this.technicianId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String ticketId;
  final String reviewerId;
  final String technicianId;
  final int rating;       // 1–5
  final String? comment;
  final DateTime createdAt;

  factory TicketReview.fromJson(Map<String, dynamic> json) => TicketReview(
        id: json['id'] as String,
        ticketId: json['ticket_id'] as String,
        reviewerId: json['reviewer_id'] as String,
        technicianId: json['technician_id'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
