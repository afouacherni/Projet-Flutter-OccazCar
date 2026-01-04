import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/models/photo_data.dart';
import '../../../../../data/models/annonce_model.dart';
import '../../../../../data/models/vehicle_model.dart';

/// État de la publication d'annonce (cross-platform)
class PublicationState {
  final String? marque;
  final String? modele;
  final int? annee;
  final int? kilometrage;
  final double? prix;
  final String? description;
  final String? carburant;
  final String? transmission;
  final List<PhotoData> photos;
  final bool isLoading;
  final bool isPublished;
  final String? error;
  final int currentStep;

  const PublicationState({
    this.marque,
    this.modele,
    this.annee,
    this.kilometrage,
    this.prix,
    this.description,
    this.carburant,
    this.transmission,
    this.photos = const [],
    this.isLoading = false,
    this.isPublished = false,
    this.error,
    this.currentStep = 0,
  });

  PublicationState copyWith({
    String? marque,
    String? modele,
    int? annee,
    int? kilometrage,
    double? prix,
    String? description,
    String? carburant,
    String? transmission,
    List<PhotoData>? photos,
    bool? isLoading,
    bool? isPublished,
    String? error,
    int? currentStep,
  }) {
    return PublicationState(
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
      kilometrage: kilometrage ?? this.kilometrage,
      prix: prix ?? this.prix,
      description: description ?? this.description,
      carburant: carburant ?? this.carburant,
      transmission: transmission ?? this.transmission,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isPublished: isPublished ?? this.isPublished,
      error: error,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  bool get isValid {
    return marque != null &&
        marque!.isNotEmpty &&
        modele != null &&
        modele!.isNotEmpty &&
        annee != null &&
        prix != null &&
        prix! > 0;
  }
}

/// Provider pour la publication d'annonce
class PublicationNotifier extends StateNotifier<PublicationState> {
  final Ref ref;

  PublicationNotifier(this.ref) : super(const PublicationState());

  /// Met à jour les informations du véhicule
  void updateVehicleInfo({
    String? marque,
    String? modele,
    int? annee,
    int? kilometrage,
    String? carburant,
    String? transmission,
  }) {
    state = state.copyWith(
      marque: marque,
      modele: modele,
      annee: annee,
      kilometrage: kilometrage,
      carburant: carburant,
      transmission: transmission,
    );
  }

  /// Met à jour le prix
  void updatePrix(double prix) {
    state = state.copyWith(prix: prix);
  }

  /// Met à jour la description
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  /// Ajoute une photo (cross-platform avec bytes)
  void addPhotoData(PhotoData photo) {
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  /// Ajoute une photo depuis bytes
  void addPhotoFromBytes(String name, Uint8List bytes, {String? path}) {
    final photo = PhotoData(name: name, bytes: bytes, path: path);
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  /// Supprime une photo
  void removePhoto(int index) {
    final newPhotos = List<PhotoData>.from(state.photos);
    newPhotos.removeAt(index);
    state = state.copyWith(photos: newPhotos);
  }

  /// Passe à l'étape suivante
  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Revient à l'étape précédente
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Génère une description avec l'IA
  Future<String> generateAIDescription() async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final description = await aiService.generateDescription(
        marque: state.marque ?? '',
        modele: state.modele ?? '',
        annee: state.annee ?? 0,
        kilometrage: state.kilometrage ?? 0,
      );
      state = state.copyWith(description: description);
      return description;
    } catch (e) {
      return 'Erreur lors de la génération: $e';
    }
  }

  /// Publie l'annonce avec upload des photos
  Future<bool> publishAnnonce() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Veuillez remplir tous les champs obligatoires');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final alerteService = ref.read(alerteMatchingServiceProvider);
      
      // Obtenir l'ID de l'utilisateur actuel (utiliser le même que SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('chat_user_id');
      final currentUser = FirebaseAuth.instance.currentUser;
      final ownerId = currentUser?.uid ?? savedUserId ?? 'local_${DateTime.now().millisecondsSinceEpoch}';
      
      // Sauvegarder si nouveau
      if (savedUserId == null && currentUser == null) {
        await prefs.setString('chat_user_id', ownerId);
      }
      debugPrint('📝 Publication avec ownerId: $ownerId');
      
      // Préparer les données de l'annonce
      final annonceData = {
        'make': state.marque,
        'model': state.modele,
        'year': state.annee,
        'mileage': state.kilometrage ?? 0,
        'price': state.prix,
        'description': state.description ?? '',
        'carburant': state.carburant,
        'transmission': state.transmission,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'photoUrls': <String>[],
        'ownerId': ownerId,
      };

      // 1. Créer l'annonce SANS photos d'abord (rapide)
      debugPrint('📝 Création annonce dans Firestore...');
      final annonceId = await firebaseService.createAnnonce(annonceData);
      debugPrint('✅ Annonce créée avec ID: $annonceId');

      // 2. Déclencher les alertes IMMÉDIATEMENT (avant upload photos)
      debugPrint('🔔 Préparation du modèle pour alertes...');
      final annonceModel = AnnonceModel(
        id: annonceId,
        vehicle: VehicleModel(
          id: annonceId,
          make: state.marque ?? '',
          model: state.modele ?? '',
          year: state.annee ?? 0,
          mileage: state.kilometrage ?? 0,
        ),
        description: state.description ?? '',
        price: state.prix ?? 0,
        ownerId: ownerId,
        createdAt: DateTime.now(),
      );
      
      debugPrint('🚀 Démarrage triggerAlertes pour annonce $annonceId');
      debugPrint('   Annonce: ${state.marque} ${state.modele}, année: ${state.annee}, prix: ${state.prix}');
      try {
        await alerteService.triggerAlertes(annonceModel);
        debugPrint('✅ triggerAlertes terminé');
      } catch (e) {
        debugPrint('❌ Erreur triggerAlertes: $e');
      }

      // 3. Upload des photos désactivé pour le moment
      // TODO: Réactiver l'upload des photos plus tard
      /*
      if (state.photos.isNotEmpty) {
        debugPrint('📷 Upload de ${state.photos.length} photos en cours...');
        try {
          final photoUrls = await firebaseService.uploadImagesBytes(
            state.photos, 
            'annonces/$annonceId'
          );
          await firebaseService.updateAnnonce(annonceId, {'photoUrls': photoUrls});
          debugPrint('✅ ${photoUrls.length} photos uploadées et annonce mise à jour');
        } catch (e) {
          debugPrint('⚠️ Erreur upload photos (annonce créée quand même): $e');
        }
      }
      */

      state = state.copyWith(isLoading: false, isPublished: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la publication: $e',
      );
      return false;
    }
  }

  /// Réinitialise le formulaire
  void reset() {
    state = const PublicationState();
  }
}

/// Provider global pour la publication
final publicationProvider =
    StateNotifierProvider<PublicationNotifier, PublicationState>((ref) {
  return PublicationNotifier(ref);
});
