import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iasd_doxology/core/dependency_injection.dart';
import 'dart:html' as html;

import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/domain/entitites/video.dart'; // Para manipulação de vídeo no Flutter Web

class PlaylistPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late List<Video> videos;

  @override
  void initState() {
    super.initState();
    videos = widget.playlist.videos;
    debugPrint('Vídeos iniciais: ${videos.length}');
  }

  Future<Uint8List?> _generateThumbnail(Uint8List videoBytes) async {
    final videoElement = html.VideoElement()
      ..src = html.Url.createObjectUrlFromBlob(html.Blob([videoBytes]))
      ..autoplay = false
      ..muted = true;

    html.document.body?.append(videoElement);

    await videoElement.onLoadedMetadata.first;
    videoElement.currentTime = 1.0; // Pega o frame em 1 segundo
    await videoElement.onSeeked.first;

    final canvas = html.CanvasElement()
      ..width = videoElement.videoWidth
      ..height = videoElement.videoHeight;
    final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;
    ctx.drawImage(videoElement, 0, 0);

    final dataUrl = canvas.toDataUrl('image/png');
    final bytes = UriData.parse(dataUrl).contentAsBytes();

    videoElement.remove();

    return bytes;
  }

  void _addVideo() {
    String videoLabel = '';
    String? fileName;
    Uint8List? videoBytes;
    bool isLoadingVideo = false; // Para o loading do carregamento do vídeo
    bool isGeneratingThumbnail = false; // Para o loading do thumbnail

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar Vídeo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      videoLabel = value;
                      setDialogState(() {});
                    },
                    decoration: const InputDecoration(hintText: 'Nome do vídeo'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoadingVideo || isGeneratingThumbnail
                        ? null // Desabilita enquanto carrega
                        : () async {
                            setDialogState(() {
                              isLoadingVideo = true; // Inicia o loading
                            });
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['mp4', 'avi', 'mkv'],
                              allowMultiple: false,
                            );
                            if (result != null) {
                              fileName = result.files.single.name;
                              videoBytes = result.files.single.bytes;
                              debugPrint('Vídeo selecionado: $fileName, bytes: ${videoBytes?.length}');
                            }
                            setDialogState(() {
                              isLoadingVideo = false; // Termina o loading
                            });
                          },
                    child: isLoadingVideo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(fileName == null ? 'Escolher Vídeo' : 'Vídeo Selecionado'),
                  ),
                  if (fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Arquivo: $fileName',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  if (isGeneratingThumbnail)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 5),
                          Text('Gerando thumbnail...'),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: (videoLabel.isNotEmpty && fileName != null && videoBytes != null && !isLoadingVideo && !isGeneratingThumbnail)
                      ? () async {
                          setDialogState(() {
                            isGeneratingThumbnail = true; // Inicia o loading do thumbnail
                          });
                          debugPrint('Gerando thumbnail para: $fileName');
                          final thumbnail = await _generateThumbnail(videoBytes!);
                          setDialogState(() {
                            isGeneratingThumbnail = false; // Termina o loading do thumbnail
                          });
                          if (thumbnail != null) {
                            setState(() {
                              videos.add(Video(label: videoLabel, filePath: fileName, thumbnail: thumbnail));
                              _saveUpdatedPlaylist();
                            });
                            debugPrint('Vídeo adicionado: $videoLabel');
                            Navigator.pop(dialogContext);
                          }
                        }
                      : null,
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveUpdatedPlaylist() {
    final updatedPlaylist = Playlist(name: widget.playlist.name, videos: videos);
    final allPlaylists = DependencyInjection.getPlaylists.execute();
    final index = allPlaylists.indexWhere((p) => p.name == widget.playlist.name);
    if (index != -1) {
      allPlaylists[index] = updatedPlaylist;
      DependencyInjection.savePlaylists.execute(allPlaylists);
      debugPrint('Playlist salva: ${widget.playlist.name} com ${videos.length} vídeos');
    } else {
      debugPrint('Erro: Playlist não encontrada para atualização');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vídeos em ${widget.playlist.name}',
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: videos.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum vídeo adicionado ainda.',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: video.thumbnail != null
                                  ? Image.memory(
                                      video.thumbnail!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.videocam, size: 50),
                              title: Text(video.label),
                              subtitle: Text(video.filePath ?? 'Sem arquivo'),
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
        onPressed: _addVideo,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}