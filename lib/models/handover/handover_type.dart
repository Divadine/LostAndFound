class TransferData {
  final String name;
  final String avatarUrl;
  final int? matchPercentage;

  final String policeStationName;
  final String policeStationAddress;

  final String phoneNumber;
  final String description;

  final List<String> proofPhotos;

  const TransferData({
    this.name = '',
    this.avatarUrl = '',
    this.matchPercentage,
    this.policeStationName = '',
    this.policeStationAddress = '',
    this.phoneNumber = '',
    this.description = '',
    this.proofPhotos = const [],
  });
}