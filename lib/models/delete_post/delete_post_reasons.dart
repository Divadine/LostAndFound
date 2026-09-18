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


final List<DeletePostReasons> deletePostReasons = [
  DeletePostReasons(
    id: 1,
    text: 'Item has been found',
  ),
   DeletePostReasons(
    id: 2,
    text: 'Item has been returned to the owner',
  ),
   DeletePostReasons(
    id: 3,
    text: 'Post was created by mistake',
  ),
   DeletePostReasons(
    id: 4,
    text: 'Duplicate post',
  ),
   DeletePostReasons(
    id: 5,
    text: 'Item is no longer available',
  ),
   DeletePostReasons(
    id: 6,
    text: 'Privacy concern',
  ),
];