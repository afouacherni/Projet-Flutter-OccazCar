import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/alerte_recherche_model.dart';

class AlerteFirestoreService {
  final FirebaseFirestore _firestore;

  AlerteFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _alertesRef =>
      _firestore.collection('alertes');

  Future<AlerteRechercheModel> createAlerte(AlerteRechercheModel alerte) async {
    try {
      final data = alerte.toJson();
      data.remove('id');
      data['createdAt'] = FieldValue.serverTimestamp();

      final docRef = await _alertesRef.add(data);
      return alerte.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Erreur création alerte: $e');
      throw Exception('Impossible de créer l\'alerte');
    }
  }

  Future<List<AlerteRechercheModel>> getAlertesByUser(String userId) async {
    try {
      debugPrint('🔍 getAlertesByUser: $userId');
      
      // DEBUG: D'abord afficher TOUTES les alertes pour voir ce qui existe
      final allSnapshot = await _alertesRef.get();
      debugPrint('📊 DEBUG - Total alertes dans Firebase: ${allSnapshot.docs.length}');
      for (final doc in allSnapshot.docs) {
        final data = doc.data();
        debugPrint('  📋 Doc ${doc.id}: userId=${data['userId']}, nom=${data['nom']}');
      }
      debugPrint('🔍 Recherche pour userId: $userId');
      
      // TEMPORAIRE: Retourner TOUTES les alertes pour debug
      // TODO: Remettre le filtre userId après correction
      final alertes = allSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('  - Alerte: ${data['nom']} (userId: ${data['userId']})');
        return AlerteRechercheModel.fromJson(data);
      }).toList();
      
      // Sort locally instead
      alertes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alertes;
    } catch (e) {
      debugPrint('❌ Erreur récupération alertes: $e');
      return [];
    }
  }

  Stream<List<AlerteRechercheModel>> watchAlertes(String userId) {
    debugPrint('🔍 watchAlertes for userId: $userId');
    // TEMPORAIRE: Retourner TOUTES les alertes pour debug
    return _alertesRef
        .snapshots()
        .map((snapshot) {
      debugPrint('📦 Snapshot received: ${snapshot.docs.length} docs');
      final alertes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('  - Alerte: ${data['nom']} (userId: ${data['userId']})');
        return AlerteRechercheModel.fromJson(data);
      }).toList();
      alertes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alertes;
    });
  }

  Future<void> updateAlerte(AlerteRechercheModel alerte) async {
    try {
      final data = alerte.toJson();
      data.remove('id');
      await _alertesRef.doc(alerte.id).update(data);
    } catch (e) {
      debugPrint('Erreur mise à jour alerte: $e');
      throw Exception('Impossible de mettre à jour l\'alerte');
    }
  }

  Future<void> toggleAlerte(String alerteId, bool actif) async {
    try {
      await _alertesRef.doc(alerteId).update({'actif': actif});
    } catch (e) {
      debugPrint('Erreur toggle alerte: $e');
    }
  }

  Future<void> deleteAlerte(String alerteId) async {
    try {
      await _alertesRef.doc(alerteId).delete();
    } catch (e) {
      debugPrint('Erreur suppression alerte: $e');
      throw Exception('Impossible de supprimer l\'alerte');
    }
  }

  Future<int> countMatchingAnnonces(AlerteRechercheModel alerte) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('annonces');

      final criteres = alerte.criteres;
      if (criteres['marque'] != null) {
        query = query.where('marque', isEqualTo: criteres['marque']);
      }
      if (criteres['carburant'] != null) {
        query = query.where('carburant', isEqualTo: criteres['carburant']);
      }

      final snapshot = await query.limit(100).get();

      return snapshot.docs.where((doc) {
        final data = doc.data();
        final prix = (data['prix'] as num?)?.toDouble() ?? 0;
        final annee = data['annee'] as int? ?? 0;
        final km = data['kilometrage'] as int? ?? 0;

        if (criteres['prixMin'] != null && prix < criteres['prixMin']) {
          return false;
        }
        if (criteres['prixMax'] != null && prix > criteres['prixMax']) {
          return false;
        }
        if (criteres['anneeMin'] != null && annee < criteres['anneeMin']) {
          return false;
        }
        if (criteres['anneeMax'] != null && annee > criteres['anneeMax']) {
          return false;
        }
        if (criteres['kilometrageMax'] != null && km > criteres['kilometrageMax']) {
          return false;
        }

        return true;
      }).length;
    } catch (e) {
      debugPrint('Erreur comptage annonces: $e');
      return 0;
    }
  }
}
