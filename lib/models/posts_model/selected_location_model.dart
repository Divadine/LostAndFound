class SelectedLocationModel {
  final String address;
  final double latitude;
  final double longitude;
  final String? pincode;
  final String? name;

  const SelectedLocationModel({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.pincode,
    this.name,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    if (pincode != null) 'pincode': pincode,
    if (name != null) 'name': name,
  };

  factory SelectedLocationModel.fromJson(Map<String, dynamic> json) =>
      SelectedLocationModel(
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        pincode: json['pincode'] as String?,
        name: json['name'] as String?,
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