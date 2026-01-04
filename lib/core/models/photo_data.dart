import 'dart:typed_data';

/// Modèle de photo cross-platform (fonctionne sur web et mobile)
class PhotoData {
  final String name;
  final Uint8List bytes;
  final String? path; // Disponible uniquement sur mobile

  PhotoData({
    required this.name,
    required this.bytes,
    this.path,
  });
}
