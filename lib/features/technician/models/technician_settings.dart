class TechnicianSettings {
  const TechnicianSettings({
    required this.id,
    required this.technicianId,
    required this.isAvailable,
    required this.serviceRadiusKm,
    this.serviceLat,
    this.serviceLng,
    this.maskedPhone,
  });

  final String id;
  final String technicianId;
  final bool isAvailable;
  final double serviceRadiusKm;
  final double? serviceLat;
  final double? serviceLng;
  final String? maskedPhone;

  bool get hasServiceArea => serviceLat != null && serviceLng != null;

  factory TechnicianSettings.fromJson(Map<String, dynamic> json) =>
      TechnicianSettings(
        id: json['id'] as String,
        technicianId: json['technician_id'] as String,
        isAvailable: json['is_available'] as bool? ?? true,
        serviceRadiusKm:
            (json['service_radius_km'] as num?)?.toDouble() ?? 10.0,
        serviceLat: (json['service_lat'] as num?)?.toDouble(),
        serviceLng: (json['service_lng'] as num?)?.toDouble(),
        maskedPhone: json['masked_phone'] as String?,
      );

  TechnicianSettings copyWith({
    bool? isAvailable,
    double? serviceRadiusKm,
    double? serviceLat,
    double? serviceLng,
    String? maskedPhone,
  }) =>
      TechnicianSettings(
        id: id,
        technicianId: technicianId,
        isAvailable: isAvailable ?? this.isAvailable,
        serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
        serviceLat: serviceLat ?? this.serviceLat,
        serviceLng: serviceLng ?? this.serviceLng,
        maskedPhone: maskedPhone ?? this.maskedPhone,
      );
}
