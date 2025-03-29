import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/domain/repositories/video_repository.dart';

class SavePlaylists {
  final VideoRepository repository;

  SavePlaylists(this.repository);

  void execute(List<Playlist> playlists) {
    repository.savePlaylists(playlists);
  }
}