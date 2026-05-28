enum TicketStatus { open, inProgress, resolved, closed, cancelled }

enum TicketPriority { low, medium, high, urgent }

extension TicketStatusX on TicketStatus {
  String get value => switch (this) {
        TicketStatus.open => 'open',
        TicketStatus.inProgress => 'in_progress',
        TicketStatus.resolved => 'resolved',
        TicketStatus.closed => 'closed',
        TicketStatus.cancelled => 'cancelled',
      };
  String get label => switch (this) {
        TicketStatus.open => 'Open',
        TicketStatus.inProgress => 'In Progress',
        TicketStatus.resolved => 'Resolved',
        TicketStatus.closed => 'Closed',
        TicketStatus.cancelled => 'Cancelled',
      };
}

extension TicketPriorityX on TicketPriority {
  String get value => name;
  String get label => switch (this) {
        TicketPriority.low => 'Low',
        TicketPriority.medium => 'Medium',
        TicketPriority.high => 'High',
        TicketPriority.urgent => 'Urgent',
      };
}

class Ticket {
  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.createdAt,
    this.category,
    this.assignedTo,
    this.updatedAt,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.location,
    this.cancellationReason,
  });

  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String createdBy;
  final DateTime createdAt;
  final String? category;
  final String? assignedTo;
  final DateTime? updatedAt;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? cancellationReason;

  bool get hasLocation => latitude != null && longitude != null;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: TicketStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.value == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] as String?,
      assignedTo: json['assigned_to'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      imageUrls: (json['image_urls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      location: json['location'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status.value,
        'priority': priority.value,
        'created_by': createdBy,
        if (category != null) 'category': category,
        if (assignedTo != null) 'assigned_to': assignedTo,
        'image_urls': imageUrls,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (location != null) 'location': location,
        if (cancellationReason != null) 'cancellation_reason': cancellationReason,
      };
}


