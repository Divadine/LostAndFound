class ProfileScreenModel {
  final int? userId;
  final String? userUid;
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
    this.userUid,
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
      altMobileVerified:
      json['alt_status']?.toString() == '1',
      userId: json['id'],
      userUid: json['user_uid'],
      profileImageUrl: _parseProfileImage(json['profile_image']),
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

  static String? _parseProfileImage(dynamic value) {
    if (value == null) return null;

    final imageUrl = value.toString().trim();

    if (imageUrl.isEmpty ||
        imageUrl.toLowerCase() == 'null' ||
        imageUrl.toLowerCase() == 'undefined') {
      return null;
    }

    return imageUrl;
  }

  ProfileScreenModel copyWith({
    bool? isFromEdit,
    int? status,
    String? profileImageUrl,
  }) {
    return ProfileScreenModel(
      isFromEdit: isFromEdit ?? this.isFromEdit,
      userId: userId,
      userUid: userUid,
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
      profileImageUrl:
      profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
    );
  }
}
