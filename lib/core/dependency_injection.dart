import 'package:iasd_doxology/data/repositories/video_repository_impl.dart';
import 'package:iasd_doxology/domain/repositories/video_repository.dart';
import 'package:iasd_doxology/domain/usecases/add_playlist.dart';
import 'package:iasd_doxology/domain/usecases/get_playlists.dart';
import 'package:iasd_doxology/domain/usecases/save_playlists.dart';

class DependencyInjection {
  static VideoRepository videoRepository = VideoRepositoryImpl();
  static GetPlaylists getPlaylists = GetPlaylists(videoRepository);
  static AddPlaylist addPlaylist = AddPlaylist(videoRepository);
  static SavePlaylists savePlaylists = SavePlaylists(videoRepository);
}