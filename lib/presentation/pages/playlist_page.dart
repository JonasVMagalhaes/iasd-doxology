import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iasd_doxology/domain/entitites/playlist.dart';
import 'package:iasd_doxology/domain/entitites/video.dart';
import 'dart:html' as html;
import '../../core/dependency_injection.dart';
import 'home_page.dart';

class PlaylistPage extends StatefulWidget {
  final Playlist playlist;
  final bool isAdminMode;

  const PlaylistPage({super.key, required this.playlist, required this.isAdminMode});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late List<Video> videos;
  final Map<Video, Uint8List> videoBytes = {};

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

    try {
      await videoElement.onLoadedMetadata.first;
      videoElement.currentTime = 1.0;
      await videoElement.onSeeked.first;

      final canvas = html.CanvasElement()
        ..width = (videoElement.videoWidth ~/ 2).toInt()
        ..height = (videoElement.videoHeight ~/ 2).toInt();
      final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D?;

      if (ctx == null) {
        debugPrint('Erro: Contexto 2D do canvas não disponível');
        videoElement.remove();
        return null;
      }

      ctx.drawImageScaled(videoElement, 0, 0, canvas.width!, canvas.height!);

      final dataUrl = canvas.toDataUrl('image/png');
      final bytes = UriData.parse(dataUrl).contentAsBytes();

      videoElement.remove();
      return bytes;
    } catch (e) {
      debugPrint('Erro ao gerar thumbnail: $e');
      videoElement.remove();
      return null;
    }
  }

  void _addVideo() {
    if (!widget.isAdminMode) return;

    String videoLabel = '';
    String? fileName;
    Uint8List? videoBytesData; // Renomeado para evitar confusão com o Map
    Uint8List? customThumbnail;
    bool isLoadingVideo = false;
    bool isGeneratingThumbnail = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar Vídeo'),
              content: SingleChildScrollView(
                child: Column(
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
                          ? null
                          : () async {
                              setDialogState(() {
                                isLoadingVideo = true;
                              });
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['mp4', 'avi', 'mkv'],
                                allowMultiple: false,
                              );
                              if (result != null) {
                                fileName = result.files.single.name;
                                videoBytesData = result.files.single.bytes;
                                debugPrint('Vídeo selecionado: $fileName, bytes: ${videoBytesData?.length}');
                              }
                              setDialogState(() {
                                isLoadingVideo = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                      child: isLoadingVideo
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(fileName == null ? 'Escolher Vídeo' : 'Vídeo Selecionado'),
                    ),
                    if (fileName != null) ...[
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'png'],
                            allowMultiple: false,
                          );
                          if (result != null) {
                            customThumbnail = result.files.single.bytes;
                            setDialogState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        child: const Text('Escolher Thumbnail Personalizada'),
                      ),
                      if (customThumbnail != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.memory(customThumbnail!, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                    ],
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
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: (videoLabel.isNotEmpty && fileName != null && videoBytesData != null && !isLoadingVideo && !isGeneratingThumbnail)
                      ? () async {
                          setDialogState(() {
                            isGeneratingThumbnail = true;
                          });
                          Uint8List? thumbnail = customThumbnail;
                          if (thumbnail == null) {
                            debugPrint('Gerando thumbnail automático para: $fileName');
                            thumbnail = await _generateThumbnail(videoBytesData!);
                          }
                          setDialogState(() {
                            isGeneratingThumbnail = false;
                          });
                          if (thumbnail != null) {
                            setState(() {
                              final newVideo = Video(label: videoLabel, filePath: fileName, thumbnail: thumbnail);
                              videos.add(newVideo);
                              videoBytes[newVideo] = videoBytesData!; // Armazena os bytes ao adicionar
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

  void _deleteVideo(Video video) {
    if (!widget.isAdminMode) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir o vídeo "${video.label}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  videoBytes.remove(video); // Remove os bytes associados
                  videos.remove(video);
                  _saveUpdatedPlaylist();
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

  void _playVideoFullScreen(Video video) {
    if (!videoBytes.containsKey(video)) {
      debugPrint('Erro: Bytes do vídeo "${video.label}" não encontrados');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vídeo não carregado. Por favor, adicione-o novamente.')),
      );
      return;
    }

    final videoUrl = html.Url.createObjectUrlFromBlob(html.Blob([videoBytes[video]!]));
    final videoElement = html.VideoElement()
      ..src = videoUrl
      ..controls = true
      ..autoplay = true;

    html.document.body?.append(videoElement);
    videoElement.requestFullscreen().then((_) {
      debugPrint('Vídeo "${video.label}" em tela cheia');
    }).catchError((e) {
      debugPrint('Erro ao entrar em tela cheia: $e');
    });

    videoElement.onEnded.listen((_) {
      videoElement.remove();
      html.Url.revokeObjectUrl(videoUrl);
    });
  }

  void _saveUpdatedPlaylist() {
    final updatedPlaylist = Playlist(name: widget.playlist.name, videos: videos, thumbnail: widget.playlist.thumbnail);
    final allPlaylists = DependencyInjection.getPlaylists.execute();
    final index = allPlaylists.indexWhere((p) => p.name == widget.playlist.name);
    if (index != -1) {
      allPlaylists[index] = updatedPlaylist;
      DependencyInjection.savePlaylists.execute(allPlaylists);
      debugPrint('Playlist salva: ${widget.playlist.name} com ${videos.length} vídeos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[800],
        elevation: 4,
        shadowColor: Colors.black45,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Volta para HomePage
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isAdminMode ? 'Gerenciar Vídeos' : 'Vídeos em ${widget.playlist.name}',
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
                child: videos.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum vídeo adicionado ainda.',
                          style: TextStyle(fontSize: 18, fontFamily: 'Lora', color: Colors.white70),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index]; // Acessa o vídeo pelo índice
                          return GestureDetector(
                            onDoubleTap: () => _playVideoFullScreen(video),
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: video.thumbnail != null
                                        ? Image.memory(
                                            video.thumbnail!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Container(
                                            color: Colors.blue[200],
                                            child: const Center(
                                              child: Icon(Icons.videocam, size: 30, color: Colors.white),
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
                                        video.label,
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
                                        onPressed: () => _deleteVideo(video),
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
              onPressed: _addVideo,
              backgroundColor: Colors.amber,
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}