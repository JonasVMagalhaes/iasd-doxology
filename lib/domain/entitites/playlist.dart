import 'dart:typed_data';
import 'video.dart';

class Playlist {
  final String name;
  final List<Video> videos;
  final Uint8List? thumbnail; // Thumbnail personalizada da playlist

  Playlist({required this.name, required this.videos, this.thumbnail});

  Map<String, dynamic> toJson() => {
        'name': name,
        'videos': videos.map((video) => video.toJson()).toList(),
        'thumbnail': thumbnail != null ? String.fromCharCodes(thumbnail!) : null,
      };
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        name: json['name'],
        videos: (json['videos'] as List).map((v) => Video.fromJson(v)).toList(),
        thumbnail: json['thumbnail'] != null ? Uint8List.fromList(json['thumbnail'].codeUnits) : null,
      );
}