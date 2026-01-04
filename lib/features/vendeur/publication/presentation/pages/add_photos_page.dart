import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/models/photo_data.dart';
import '../providers/publication_provider.dart';

/// Page dédiée à l'ajout de photos pour une annonce
class AddPhotosPage extends ConsumerStatefulWidget {
  const AddPhotosPage({super.key});

  @override
  ConsumerState<AddPhotosPage> createState() => _AddPhotosPageState();
}

class _AddPhotosPageState extends ConsumerState<AddPhotosPage> {
  final ImagePicker _picker = ImagePicker();
  final List<PhotoData> _photos = [];
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Récupérer les photos existantes du provider
    final existingPhotos = ref.read(publicationProvider).photos;
    _photos.addAll(existingPhotos);
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final photo = PhotoData(name: image.name, bytes: bytes, path: image.path);
        setState(() => _photos.add(photo));
        ref.read(publicationProvider.notifier).addPhotoData(photo);
      }
    } catch (e) {
      _showError('Erreur lors de la capture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      for (final image in images) {
        if (_photos.length < 10) {
          final bytes = await image.readAsBytes();
          final photo = PhotoData(name: image.name, bytes: bytes, path: image.path);
          setState(() => _photos.add(photo));
          ref.read(publicationProvider.notifier).addPhotoData(photo);
        }
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
    ref.read(publicationProvider.notifier).removePhoto(index);
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final photo = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, photo);
    });
    // TODO: Mettre à jour l'ordre dans le provider
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Photos du véhicule'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _photos.isEmpty ? null : () => Navigator.pop(context),
            child: const Text('Terminé'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _photos.length / 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_photos.length}/10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Grille de photos
          Expanded(
            child: _photos.isEmpty
                ? _buildEmptyState()
                : _buildPhotosGrid(),
          ),

          // Barre d'actions
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune photo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des photos pour votre annonce',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                Icons.camera_alt,
                'Appareil photo',
                _pickFromCamera,
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                Icons.photo_library,
                'Galerie',
                _pickFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _photos.length,
      onReorder: _reorderPhotos,
      itemBuilder: (context, index) {
        return _buildPhotoItem(index);
      },
    );
  }

  Widget _buildPhotoItem(int index) {
    final isMain = index == 0;
    
    return Container(
      key: ValueKey(_photos[index].name),
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: MemoryImage(_photos[index].bytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Badge photo principale
          if (isMain)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Photo principale',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bouton supprimer
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          // Indicateur de position
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}/${_photos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          // Icône de réorganisation
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drag_handle, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Conseils
            if (_photos.length < 3)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ajoutez au moins 3 photos pour un meilleur impact',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Boutons d'ajout
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _photos.length >= 10 ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Appareil photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _photos.length >= 10 ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
