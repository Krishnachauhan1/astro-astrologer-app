class LiveStreamModel {
  final int id;
  final String title;
  final String astrologerName;
  final int viewers;
  final String? thumbnail;

  LiveStreamModel({
    required this.id,
    required this.title,
    required this.astrologerName,
    required this.viewers,
    this.thumbnail,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) => LiveStreamModel(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    astrologerName: json['astrologer_name'] ?? '',
    viewers: json['viewers'] ?? 0,
    thumbnail: json['thumbnail'],
  );
}
