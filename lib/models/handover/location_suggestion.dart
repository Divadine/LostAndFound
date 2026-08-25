// lib/models/handover/location_suggestion_model.dart
class LocationSuggestionModel {
  final int id;
  final String description;
  final double latitude;
  final double longitude;

  LocationSuggestionModel({
    required this.id,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory LocationSuggestionModel.fromJson(Map<String, dynamic> json) {
    return LocationSuggestionModel(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}