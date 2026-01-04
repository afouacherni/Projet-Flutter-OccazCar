import '../datasources/remote/alerte_firestore_service.dart';
import '../models/alerte_recherche_model.dart';

abstract class AlerteRepository {
  Future<AlerteRechercheModel> createAlerte(AlerteRechercheModel alerte);
  Future<List<AlerteRechercheModel>> getAlertesByUser(String userId);
  Stream<List<AlerteRechercheModel>> watchAlertes(String userId);
  Future<void> updateAlerte(AlerteRechercheModel alerte);
  Future<void> toggleAlerte(String alerteId, bool actif);
  Future<void> deleteAlerte(String alerteId);
  Future<int> countMatchingAnnonces(AlerteRechercheModel alerte);
}

class AlerteRepositoryImpl implements AlerteRepository {
  final AlerteFirestoreService _firestoreService;

  AlerteRepositoryImpl({required AlerteFirestoreService firestoreService})
      : _firestoreService = firestoreService;

  @override
  Future<AlerteRechercheModel> createAlerte(AlerteRechercheModel alerte) {
    return _firestoreService.createAlerte(alerte);
  }

  @override
  Future<List<AlerteRechercheModel>> getAlertesByUser(String userId) {
    return _firestoreService.getAlertesByUser(userId);
  }

  @override
  Stream<List<AlerteRechercheModel>> watchAlertes(String userId) {
    return _firestoreService.watchAlertes(userId);
  }

  @override
  Future<void> updateAlerte(AlerteRechercheModel alerte) {
    return _firestoreService.updateAlerte(alerte);
  }

  @override
  Future<void> toggleAlerte(String alerteId, bool actif) {
    return _firestoreService.toggleAlerte(alerteId, actif);
  }

  @override
  Future<void> deleteAlerte(String alerteId) {
    return _firestoreService.deleteAlerte(alerteId);
  }

  @override
  Future<int> countMatchingAnnonces(AlerteRechercheModel alerte) {
    return _firestoreService.countMatchingAnnonces(alerte);
  }
}
