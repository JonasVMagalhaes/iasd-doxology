import 'dart:typed_data';

class Video {
  final String label; // Nome personalizado
  final String? filePath; // Nome do arquivo (não o caminho completo no web)
  final Uint8List? thumbnail; // Frame do vídeo como imagem

  Video({required this.label, this.filePath, this.thumbnail});

  Map<String, dynamic> toJson() => {
        'label': label,
        'filePath': filePath,
        'thumbnail': thumbnail != null ? String.fromCharCodes(thumbnail!) : null,
      };
  factory Video.fromJson(Map<String, dynamic> json) => Video(
        label: json['label'],
        filePath: json['filePath'],
        thumbnail: json['thumbnail'] != null ? Uint8List.fromList(json['thumbnail'].codeUnits) : null,
      );
}