import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../../data/models/annonce_model.dart';
import '../../../../../core/di/injection.dart';

/// État de la gestion des annonces vendeur
class GestionAnnoncesState {
  final List<AnnonceModel> annonces;
  final bool isLoading;
  final String? error;
  final Map<String, int> stats;

  const GestionAnnoncesState({
    this.annonces = const [],
    this.isLoading = false,
    this.error,
    this.stats = const {},
  });

  GestionAnnoncesState copyWith({
    List<AnnonceModel>? annonces,
    bool? isLoading,
    String? error,
    Map<String, int>? stats,
  }) {
    return GestionAnnoncesState(
      annonces: annonces ?? this.annonces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }

  int get totalAnnonces => annonces.length;
  int get annoncesActives => annonces.where((a) => true).length; // TODO: ajouter statut
  int get totalVues => stats['vues'] ?? 0;
  int get totalFavoris => stats['favoris'] ?? 0;
}

/// Provider pour la gestion des annonces du vendeur
class GestionAnnoncesNotifier extends StateNotifier<GestionAnnoncesState> {
  final Ref ref;

  GestionAnnoncesNotifier(this.ref) : super(const GestionAnnoncesState());

  /// Charge les annonces du vendeur connecté
  Future<void> loadMesAnnonces() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final annoncesData = await firebaseService.getAnnonces();
      
      debugPrint('📦 Chargement de ${annoncesData.length} annonces vendeur');
      
      // Convertir les données en AnnonceModel via fromJson
      final annonces = annoncesData.map((data) {
        try {
          return AnnonceModel.fromJson(data);
        } catch (e) {
          debugPrint('❌ Erreur parsing annonce: $e');
          return null;
        }
      }).whereType<AnnonceModel>().toList();

      debugPrint('✅ ${annonces.length} annonces parsées avec succès');

      // Calcul des statistiques
      final stats = {
        'vues': annonces.length * 10, // Placeholder
        'favoris': annonces.length * 3, // Placeholder
        'messages': annonces.length * 2, // Placeholder
      };

      state = state.copyWith(
        annonces: annonces,
        isLoading: false,
        stats: stats,
      );
    } catch (e) {
      debugPrint('❌ Erreur chargement annonces vendeur: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  /// Supprime une annonce
  Future<void> deleteAnnonce(String annonceId) async {
    try {
      // TODO: Implémenter la suppression dans Firebase
      final updatedAnnonces = state.annonces
          .where((a) => a.id != annonceId)
          .toList();
      state = state.copyWith(annonces: updatedAnnonces);
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression: $e');
    }
  }

  /// Met à jour le statut d'une annonce (active/inactive)
  Future<void> toggleAnnonceStatus(String annonceId) async {
    // TODO: Implémenter le changement de statut
  }
}

/// Provider global pour la gestion des annonces
final gestionAnnoncesProvider =
    StateNotifierProvider<GestionAnnoncesNotifier, GestionAnnoncesState>((ref) {
  return GestionAnnoncesNotifier(ref);
});
