class ProfileScreenModel {
  final int? userId;
  final bool isFromEdit;
  final String? profileImageUrl;
  final String? name;
  final String? mobile;
  final String? altMobile;
  final bool altMobileVerified;
  final String? pincode;
  final String? country;
  final String? state;
  final String? city;
  final String? address;
  final String? landmark;
  final String? latitude;
  final String? longitude;
  final int? status;

  ProfileScreenModel({
    required this.isFromEdit,
    this.name,
    this.mobile,
    this.userId,
    this.altMobile,
    required this.altMobileVerified,
    this.pincode,
    this.country,
    this.state,
    this.city,
    this.address,
    this.landmark,
    this.latitude,
    this.longitude,
    this.profileImageUrl,
    this.status,
  });

  factory ProfileScreenModel.fromJson(Map<String, dynamic> json) {
    return ProfileScreenModel(
      isFromEdit: false,
      altMobileVerified: json['alt_status']?.toString() == '1',
      userId: json['id'],
      profileImageUrl: json['profile_image'],
      name: json['name'],
      mobile: json['phoneno'],
      altMobile: json['altno'],
      pincode: json['pincode']?.toString(),
      country: json['country'],
      state: json['state'],
      city: json['city'],
      address: json['full_address'],
      landmark: json['landmark'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      status: json['status'],
    );
  }

  ProfileScreenModel copyWith({bool? isFromEdit, int? status}) {
    return ProfileScreenModel(
      isFromEdit: isFromEdit ?? this.isFromEdit,
      userId: userId,
      name: name,
      mobile: mobile,
      altMobile: altMobile,
      altMobileVerified: altMobileVerified,
      pincode: pincode,
      country: country,
      state: state,
      city: city,
      address: address,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      profileImageUrl: profileImageUrl,
      status: status ?? this.status,
    );
  }
}