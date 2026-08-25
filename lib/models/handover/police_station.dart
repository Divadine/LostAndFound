// lib/models/handover/police_station_model.dart
class PoliceStationModel {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String phoneNumber;
  final String? imageUrl;

  PoliceStationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.phoneNumber,
    this.imageUrl,
  });

  bool get hasPhone => phoneNumber.trim().isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  factory PoliceStationModel.fromJson(Map<String, dynamic> json) {
    return PoliceStationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: (json['phoneNumber'] ?? '').toString().trim(),
      imageUrl: (json['imageUrl'] as String?)?.trim(),
    );
  }
}