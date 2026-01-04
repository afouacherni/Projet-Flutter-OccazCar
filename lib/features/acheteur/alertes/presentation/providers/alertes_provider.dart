import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../data/models/alerte_recherche_model.dart';
import '../../../../../data/repositories/alerte_repository.dart';
import '../../../../../data/datasources/remote/alerte_firestore_service.dart';

class AlertesState {
  final List<AlerteRechercheModel> alertes;
  final bool isLoading;
  final String? error;

  const AlertesState({
    this.alertes = const [],
    this.isLoading = false,
    this.error,
  });

  AlertesState copyWith({
    List<AlerteRechercheModel>? alertes,
    bool? isLoading,
    String? error,
  }) {
    return AlertesState(
      alertes: alertes ?? this.alertes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AlertesNotifier extends StateNotifier<AlertesState> {
  final AlerteRepository? _repository;
  String? _currentUserId;
  StreamSubscription<List<AlerteRechercheModel>>? _subscription;

  AlertesNotifier(this._repository) : super(const AlertesState()) {
    _initUserId();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('chat_user_id');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      await prefs.setString('chat_user_id', _currentUserId!);
    } else if (savedUserId != null) {
      _currentUserId = savedUserId;
    } else {
      try {
        final result = await FirebaseAuth.instance.signInAnonymously();
        _currentUserId = result.user?.uid;
        if (_currentUserId != null) {
          await prefs.setString('chat_user_id', _currentUserId!);
        }
      } catch (e) {
        _currentUserId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('chat_user_id', _currentUserId!);
      }
    }
    _startWatching();
  }

  void _startWatching() {
    if (_currentUserId == null || _repository == null) {
      debugPrint('❌ Cannot watch alertes: userId=$_currentUserId, repo=$_repository');
      loadAlertes();
      return;
    }

    debugPrint('👀 Starting alertes watch for user: $_currentUserId');
    state = state.copyWith(isLoading: true);
    _subscription?.cancel();
    _subscription = _repository
        .watchAlertes(_currentUserId!)
        .listen(
          (alertes) {
            debugPrint('📥 Alertes reçues: ${alertes.length}');
            state = AlertesState(alertes: alertes);
          },
          onError: (e) {
            debugPrint('❌ Erreur watch alertes: $e');
            state = AlertesState(error: e.toString());
            // Fallback to one-time load
            loadAlertes();
          },
        );
  }

  Future<void> loadAlertes() async {
    if (_currentUserId == null) {
      debugPrint('❌ loadAlertes: userId is null');
      return;
    }

    debugPrint('🔄 Loading alertes for user: $_currentUserId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_repository != null) {
        final alertes = await _repository.getAlertesByUser(_currentUserId!);
        debugPrint('✅ Loaded ${alertes.length} alertes');
        state = AlertesState(alertes: alertes);
      }
    } catch (e) {
      debugPrint('❌ Error loading alertes: $e');
      state = AlertesState(error: e.toString());
    }
  }

  Future<bool> createAlerte({
    required String nom,
    required Map<String, dynamic> criteres,
    FrequenceAlerte frequence = FrequenceAlerte.immediate,
  }) async {
    if (_currentUserId == null || _repository == null) return false;

    try {
      final alerte = AlerteRechercheModel(
        id: '',
        userId: _currentUserId!,
        nom: nom,
        criteres: criteres,
        frequence: frequence,
        createdAt: DateTime.now(),
      );

      await _repository.createAlerte(alerte);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la création');
      return false;
    }
  }

  Future<bool> createAlerteFromFilters({
    required String nom,
    String? marque,
    String? modele,
    double? prixMin,
    double? prixMax,
    int? anneeMin,
    int? anneeMax,
    int? kilometrageMax,
    String? carburant,
    String? transmission,
    String? localisation,
    FrequenceAlerte frequence = FrequenceAlerte.immediate,
  }) async {
    final criteres = <String, dynamic>{};
    if (marque != null) criteres['marque'] = marque;
    if (modele != null) criteres['modele'] = modele;
    if (prixMin != null) criteres['prixMin'] = prixMin;
    if (prixMax != null) criteres['prixMax'] = prixMax;
    if (anneeMin != null) criteres['anneeMin'] = anneeMin;
    if (anneeMax != null) criteres['anneeMax'] = anneeMax;
    if (kilometrageMax != null) criteres['kilometrageMax'] = kilometrageMax;
    if (carburant != null) criteres['carburant'] = carburant;
    if (transmission != null) criteres['transmission'] = transmission;
    if (localisation != null) criteres['localisation'] = localisation;

    return createAlerte(nom: nom, criteres: criteres, frequence: frequence);
  }

  Future<void> toggleAlerte(String alerteId) async {
    final alerte = state.alertes.firstWhere((a) => a.id == alerteId);
    if (_repository != null) {
      await _repository.toggleAlerte(alerteId, !alerte.actif);
    }
  }

  Future<void> deleteAlerte(String alerteId) async {
    if (_repository != null) {
      await _repository.deleteAlerte(alerteId);
    }
  }

  Future<int> getMatchCount(AlerteRechercheModel alerte) async {
    if (_repository == null) return 0;
    return _repository.countMatchingAnnonces(alerte);
  }

  String? get currentUserId => _currentUserId;
}

final alerteFirestoreServiceProvider = Provider((ref) {
  return AlerteFirestoreService();
});

final alerteRepositoryProvider = Provider<AlerteRepository>((ref) {
  final service = ref.read(alerteFirestoreServiceProvider);
  return AlerteRepositoryImpl(firestoreService: service);
});

final alertesProvider = StateNotifierProvider<AlertesNotifier, AlertesState>((
  ref,
) {
  final repository = ref.read(alerteRepositoryProvider);
  return AlertesNotifier(repository);
});
