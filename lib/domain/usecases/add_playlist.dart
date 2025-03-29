import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/domain/repositories/video_repository.dart';

class AddPlaylist {
  final VideoRepository repository;

  AddPlaylist(this.repository);

  void execute(Playlist playlist) {
    repository.addPlaylist(playlist);
  }
}