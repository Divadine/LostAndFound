class ReportReasonModel {
  final int id;
  final String text;

  ReportReasonModel({required this.id, required this.text});

  factory ReportReasonModel.fromJson(Map<String, dynamic> json) {
    return ReportReasonModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      text: json['text']?.toString() ?? '',
    );
  }
}