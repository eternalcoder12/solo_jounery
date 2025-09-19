class MediaItem {
  final int id;
  final String type;
  final String url;
  final bool verified;

  const MediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.verified = false,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'image',
      url: json['url'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
    );
  }
}
