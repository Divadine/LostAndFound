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

  final int profileStatus;

  final int? status;
  final String? message;

  final String? deviceId;
  final String? deviceType;
  final String? deviceToken;
  final String? appVersion;

  UpdateProfileForm({
    this.id,
    this.profileImg,
    required this.name,
    required this.phoneNo,
    this.altNo,
    required this.pinCode,
    required this.country,
    required this.state,
    required this.city,
    required this.address,
    required this.landMark,
    this.lat,
    this.log,
    this.status,
    this.message,
    required this.altVerified,
    required this.profileStatus,
    this.deviceId,
    this.deviceType,
    this.deviceToken,
    this.appVersion,
  });

  UpdateProfileForm copyWith({
    int? id,
    File? profileImg,
    String? name,
    String? phoneNo,
    String? altNo,
    bool? altVerified,
    String? pinCode,
    String? country,
    String? state,
    String? city,
    String? address,
    String? landMark,
    String? lat,
    String? log,
    int? profileStatus,
    int? status,
    String? message,
    String? deviceId,
    String? deviceType,
    String? deviceToken,
    String? appVersion,
  }) {
    return UpdateProfileForm(
      id: id ?? this.id,
      profileImg: profileImg ?? this.profileImg,
      name: name ?? this.name,
      phoneNo: phoneNo ?? this.phoneNo,
      altNo: altNo ?? this.altNo,
      altVerified: altVerified ?? this.altVerified,
      pinCode: pinCode ?? this.pinCode,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      address: address ?? this.address,
      landMark: landMark ?? this.landMark,
      lat: lat ?? this.lat,
      log: log ?? this.log,
      profileStatus: profileStatus ?? this.profileStatus,
      status: status ?? this.status,
      message: message ?? this.message,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceToken: deviceToken ?? this.deviceToken,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phoneno': phoneNo,
      if (altNo != null) 'altno': altNo,
      'alt_status': altVerified ? 1 : 0,
      'profile_status': profileStatus,
      'pincode': pinCode,
      'country': country,
      'state': state,
      'city': city,
      'full_address': address,
      'landmark': landMark,
      if (lat != null) 'latitude': lat,
      if (log != null) 'longitude': log,
      if (deviceId != null && deviceId!.isNotEmpty) 'device_id': deviceId,
      if (deviceType != null && deviceType!.isNotEmpty) 'device_type': deviceType,
      if (deviceToken != null && deviceToken!.isNotEmpty) 'device_token': deviceToken,
      if (appVersion != null && appVersion!.isNotEmpty) 'app_version': appVersion,
      'profileimg': profileImg,
    };
  }
}
