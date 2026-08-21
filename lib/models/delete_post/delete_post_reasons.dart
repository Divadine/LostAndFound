class DeletePostReasons {
  final int id;
  final String text;

  DeletePostReasons({required this.id, required this.text});

  factory DeletePostReasons.fromJson(Map<String,dynamic> json) {
    return DeletePostReasons(
        id: json['id'],
        text: json['text']
    );
  }
}