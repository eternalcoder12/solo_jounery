import 'media.dart';

class Trip {
  final int id;
  final String title;
  final String description;
  final String location;
  final DateTime visitedAt;
  final bool verified;
  final List<MediaItem> media;
  final String author;
  final double score;

  Trip({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.visitedAt,
    required this.verified,
    required this.media,
    required this.author,
    required this.score,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      visitedAt: DateTime.tryParse(json['visited_at'] as String? ?? '') ?? DateTime.now(),
      verified: json['verified'] as bool? ?? false,
      media: (json['media'] as List<dynamic>? ?? [])
          .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      author: json['user']?['username'] as String? ?? 'Explorer',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}
