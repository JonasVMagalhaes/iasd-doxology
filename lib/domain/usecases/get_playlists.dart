import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/domain/repositories/video_repository.dart';

class GetPlaylists {
  final VideoRepository repository;

  GetPlaylists(this.repository);

  List<Playlist> execute() {
    return repository.getPlaylists();
  }
}