class SelectedLocationModel {
  final String address;
  final double latitude;
  final double longitude;

  const SelectedLocationModel({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory SelectedLocationModel.fromJson(Map<String, dynamic> json) =>
      SelectedLocationModel(
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SelectedLocationModel &&
              latitude == other.latitude &&
              longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}