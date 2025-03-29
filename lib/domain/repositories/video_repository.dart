import 'package:iasd_doxology/domain/entitites/playlist.dart';

abstract class VideoRepository {
  List<Playlist> getPlaylists();
  void addPlaylist(Playlist playlist);
  void savePlaylists(List<Playlist> playlists);
}