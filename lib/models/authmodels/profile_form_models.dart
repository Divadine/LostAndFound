import 'dart:io';

class UpdateProfileForm {
  final int? id;
  final File? profileImg;
  final String name;
  final String phoneNo;
  final String? altNo;
  final bool altVerified;
  final String pinCode;
  final String country;
  final String state;
  final String city;
  final String address;
  final String landMark;
  final String? lat;
  final String? log;

  final int? status;
  final String? message;

  UpdateProfileForm({ this.id,  this.profileImg, required this.name, required this.phoneNo, this.altNo, required this.pinCode, required this.country, required this.state, required this.city, required this.address, required this.landMark, this.lat, this.log, this.status, this.message, required this.altVerified});


  Map<String ,dynamic> toMap() {

    return {
      'id' : id,
      'name': name,
      'phoneno': phoneNo,
      'altno': altNo,
      //'alt_status': altVerified ? 1 : 0,
      'profile_status': 1,
      'pincode': pinCode,
      'country': country,
      'state': state,
      'city': city,
      'full_address': address,
      'landmark': landMark,
      'latitude': lat,
      'longitude': log,
      'profile_image':profileImg,

    };
  }
}