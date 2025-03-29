import 'package:flutter/material.dart';
import 'package:iasd_doxology/core/dependency_injection.dart';
import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/presentation/pages/playlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
    showDialog(
      context: context,
      builder: (context) {
        String newPlaylistName = '';
        return AlertDialog(
          title: const Text('Nova Playlist'),
          content: TextField(
            onChanged: (value) => newPlaylistName = value,
            decoration: const InputDecoration(hintText: 'Nome da playlist'),
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
                    DependencyInjection.addPlaylist
                        .execute(Playlist(name: newPlaylistName, videos: []));
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Video Player'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Escolha uma Playlist de Vídeos',
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          playlist.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistPage(playlist: playlist),
                            ),
                          ).then((_) {
                            setState(() {
                              playlists = DependencyInjection.getPlaylists.execute();
                            });
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPlaylist,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}