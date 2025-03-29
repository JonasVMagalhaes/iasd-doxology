import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iasd_doxology/core/dependency_injection.dart';
import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/presentation/pages/playlist_page.dart';
import 'package:iasd_doxology/presentation/pages/welcome_page.dart';

class HomePage extends StatefulWidget {
  final bool isAdminMode;

  const HomePage({super.key, required this.isAdminMode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Playlist> playlists;

  @override
  void initState() {
    super.initState();
    playlists = DependencyInjection.getPlaylists.execute();
  }

  void _addNewPlaylist() {
    if (!widget.isAdminMode) return;

    String newPlaylistName = '';
    Uint8List? thumbnail;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova Playlist'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) => newPlaylistName = value,
                    decoration: const InputDecoration(hintText: 'Nome da playlist'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'png'],
                        allowMultiple: false,
                      );
                      if (result != null) {
                        thumbnail = result.files.single.bytes;
                        setDialogState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    child: const Text('Escolher Thumbnail'),
                  ),
                  if (thumbnail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.memory(thumbnail!, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (newPlaylistName.isNotEmpty) {
                      setState(() {
                        DependencyInjection.addPlaylist.execute(
                          Playlist(name: newPlaylistName, videos: [], thumbnail: thumbnail),
                        );
                        playlists = DependencyInjection.getPlaylists.execute();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deletePlaylist(String playlistName) {
    if (!widget.isAdminMode) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir a playlist "$playlistName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final allPlaylists = DependencyInjection.getPlaylists.execute();
                  allPlaylists.removeWhere((p) => p.name == playlistName);
                  DependencyInjection.savePlaylists.execute(allPlaylists);
                  playlists = allPlaylists;
                });
                Navigator.pop(context);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IASD Video Player', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[800],
        elevation: 4,
        shadowColor: Colors.black45,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFFFFF9C4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                widget.isAdminMode ? 'Gerenciar Playlists' : 'Playlists da Igreja',
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'Lora',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Mais itens por linha
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0, // Quadros menores e quadrados
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistPage(playlist: playlist, isAdminMode: widget.isAdminMode),
                            ),
                          ).then((_) {
                            if (widget.isAdminMode) {
                              setState(() {
                                playlists = DependencyInjection.getPlaylists.execute();
                              });
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: playlist.thumbnail != null
                                  ? Image.memory(
                                      playlist.thumbnail!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Container(
                                      color: Colors.blue[200],
                                      child: const Center(
                                        child: Icon(Icons.music_note, size: 30, color: Colors.white),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black54, Colors.transparent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                                child: Text(
                                  playlist.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            if (widget.isAdminMode)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  onPressed: () => _deletePlaylist(playlist.name),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isAdminMode
          ? FloatingActionButton(
              onPressed: _addNewPlaylist,
              backgroundColor: Colors.amber,
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}