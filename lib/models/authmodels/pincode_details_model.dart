class AreaModel {
  final int id;
  final String name;

  AreaModel({required this.id, required this.name});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(id: json['id'], name: json['name']);
  }
}

class PinCodeDetailsModel {
  final int? id;
  final String pincode;
  final String city;
  final String district;
  final String state;
  final String country;
  final List<AreaModel> areas;
  final String latitude;
  final String longitude;

  
  PinCodeDetailsModel({
     this.id,
    required this.pincode,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
    required this.areas,
    required this.latitude,
    required this.longitude,
  });

  factory PinCodeDetailsModel.fromJson(Map<String, dynamic> json) {
    return PinCodeDetailsModel(
      id: json['id'],
      pincode: json['pincode'],
      city: json['city'],
      district: json['district'],
      state: json['state'],
      country: json['country'],
      areas: (json['areas'] as List).map((e) => AreaModel.fromJson(e)).toList(),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
