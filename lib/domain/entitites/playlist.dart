import 'video.dart';

class Playlist {
  final String name;
  final List<Video> videos;

  Playlist({required this.name, required this.videos});

  Map<String, dynamic> toJson() => {
        'name': name,
        'videos': videos.map((video) => video.toJson()).toList(),
      };
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        name: json['name'],
        videos: (json['videos'] as List).map((v) => Video.fromJson(v)).toList(),
      );
}