import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/models/annonce_model.dart';
import '../../../../data/datasources/remote/annonce_firestore_service.dart';

/// État des annonces récentes
class AnnoncesRecentesState {
  final List<AnnonceModel> annonces;
  final bool isLoading;
  final String? error;

  const AnnoncesRecentesState({
    this.annonces = const [],
    this.isLoading = false,
    this.error,
  });

  AnnoncesRecentesState copyWith({
    List<AnnonceModel>? annonces,
    bool? isLoading,
    String? error,
  }) {
    return AnnoncesRecentesState(
      annonces: annonces ?? this.annonces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer les annonces récentes avec synchronisation temps réel
class AnnoncesRecentesNotifier extends StateNotifier<AnnoncesRecentesState> {
  final AnnonceFirestoreService _service;
  StreamSubscription<List<AnnonceModel>>? _subscription;

  AnnoncesRecentesNotifier(this._service) : super(const AnnoncesRecentesState()) {
    _startWatching();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Démarre l'écoute en temps réel des annonces
  void _startWatching() {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('👀 Démarrage écoute temps réel des annonces...');

    _subscription?.cancel();
    _subscription = _service.watchAnnonces().listen(
      (annonces) {
        debugPrint('📥 ${annonces.length} annonces reçues en temps réel');
        // Prendre les 10 plus récentes
        final recentAnnonces = annonces.take(10).toList();
        state = AnnoncesRecentesState(annonces: recentAnnonces);
      },
      onError: (e) {
        debugPrint('❌ Erreur stream annonces: $e');
        // Fallback vers chargement unique
        loadAnnonces();
      },
    );
  }

  Future<void> loadAnnonces() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      debugPrint('🔄 Chargement des annonces récentes...');
      final annonces = await _service.getAllAnnonces();
      debugPrint('✅ ${annonces.length} annonces chargées');
      
      // Prendre les 10 plus récentes
      final recentAnnonces = annonces.take(10).toList();
      state = AnnoncesRecentesState(annonces: recentAnnonces);
    } catch (e) {
      debugPrint('❌ Erreur chargement annonces: $e');
      state = AnnoncesRecentesState(error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadAnnonces();
  }
}

/// Provider pour le service Firestore
final annonceFirestoreServiceProvider = Provider<AnnonceFirestoreService>((ref) {
  return AnnonceFirestoreService();
});

/// Provider pour les annonces récentes (temps réel)
final annoncesRecentesProvider = StateNotifierProvider<AnnoncesRecentesNotifier, AnnoncesRecentesState>((ref) {
  final service = ref.watch(annonceFirestoreServiceProvider);
  return AnnoncesRecentesNotifier(service);
});
