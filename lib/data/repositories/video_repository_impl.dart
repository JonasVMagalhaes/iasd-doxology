import 'dart:convert';

import 'package:iasd_doxology/domain/entitites/video.dart';
import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/domain/repositories/video_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoRepositoryImpl implements VideoRepository {
  static const String _playlistsKey = 'playlists';
  late List<Playlist> _playlists;

  VideoRepositoryImpl() {
    _playlists = [
      Playlist(name: 'Doxologia', videos: [Video(label: 'Doxologia 1'), Video(label: 'Doxologia 2')]),
      Playlist(name: 'Culto de Domingo', videos: [Video(label: 'Vídeo Domingo 1')]),
      Playlist(name: 'Vídeos Especiais', videos: [Video(label: 'Especial 1'), Video(label: 'Especial 2')]),
    ];
    _loadPlaylists();
  }

  @override
  List<Playlist> getPlaylists() {
    return _playlists;
  }

  @override
  void addPlaylist(Playlist playlist) {
    _playlists.add(playlist);
    _savePlaylists();
  }

  @override
  void savePlaylists(List<Playlist> playlists) {
    _playlists = playlists;
    _savePlaylists();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistJson = _playlists.map((p) => p.toJson()).toList();
    await prefs.setStringList(_playlistsKey, playlistJson.map((p) => jsonEncode(p)).toList());
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistStrings = prefs.getStringList(_playlistsKey);
    if (playlistStrings != null) {
      _playlists = playlistStrings.map((p) => Playlist.fromJson(jsonDecode(p))).toList();
    }
  }
}