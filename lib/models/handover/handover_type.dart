class TransferData {
  final String name;
  final String avatarUrl;
  final int? matchPercentage;
  final String? userId;

  final String policeStationName;
  final String policeStationAddress;

  final String phoneNumber;
  final String description;

  final List<String> proofPhotos;
  final String handoverDate;
  final String codeId;


  const TransferData({
    this.name = '',
    this.avatarUrl = '',
    this.matchPercentage,
    this.userId,
    this.policeStationName = '',
    this.policeStationAddress = '',
    this.phoneNumber = '',
    this.description = '',
    this.proofPhotos = const [],
    this.handoverDate = '',
    this.codeId = '',
  });

  factory TransferData.fromJson(Map<String, dynamic> json) {
    return TransferData(
      name: (json['name'] ?? json['poster_name'] ?? json['enquirer_name'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? json['profile_image'] ?? json['poster_avatar'] ?? json['enquirer_profile_img'] ?? '').toString(),
      matchPercentage: json['matchPercentage'] is int
          ? json['matchPercentage'] as int
          : (json['match_percentage'] is int
              ? json['match_percentage'] as int
              : int.tryParse((json['matchPercentage'] ?? json['match_percentage'] ?? '').toString())),
      userId: json['user_uid']?.toString() ?? json['userId']?.toString() ?? json['user_id']?.toString(),
      policeStationName: (json['police_station_name'] ?? json['station_name'] ?? json['policeStationName'] ?? '').toString(),
      policeStationAddress: (json['police_station_address'] ?? json['station_address'] ?? json['policeStationAddress'] ?? '').toString(),
      phoneNumber: json['handover_number']?.toString() ?? json['phoneNumber']?.toString() ?? json['phoneno']?.toString() ?? json['handover_phoneno']?.toString() ?? '',
      description: (json['description'] ?? json['handover_desc'] ?? json['handover_description'] ?? '').toString(),
      proofPhotos: (json['proof_photos'] ?? json['handover_images'] ?? json['proofPhotos']) is List
          ? List<String>.from((json['proof_photos'] ?? json['handover_images'] ?? json['proofPhotos']).map((x) => x.toString()))
          : const [],
      handoverDate: (json['handover_date'] ?? json['handoverDate'] ?? json['created_at'] ?? '').toString(),
      codeId: json['code_id']?.toString() ?? json['codeId']?.toString() ?? '',
    );
  }
}
