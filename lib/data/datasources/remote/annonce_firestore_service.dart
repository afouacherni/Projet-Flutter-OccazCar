import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/annonce_model.dart';

class AnnonceFirestoreService {
  final FirebaseFirestore _firestore;
  
  AnnonceFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _annoncesRef =>
      _firestore.collection('annonces');

  // Récupérer toutes les annonces
  Future<List<AnnonceModel>> getAllAnnonces() async {
    try {
      debugPrint('🔄 Chargement de toutes les annonces...');
      
      // Essayer avec orderBy, sinon récupérer tout et trier localement
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _annoncesRef
            .orderBy('createdAt', descending: true)
            .get();
      } catch (indexError) {
        debugPrint('⚠️ Index non disponible, récupération sans tri: $indexError');
        snapshot = await _annoncesRef.get();
      }
      
      debugPrint('📦 ${snapshot.docs.length} annonces trouvées dans Firebase');
      
      final annonces = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('  📋 Annonce: ${data['make']} ${data['model']} - ${data['price']}€');
        return AnnonceModel.fromJson(data);
      }).toList();
      
      // Trier localement par date si nécessaire
      annonces.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      
      return annonces;
    } catch (e) {
      debugPrint('❌ Erreur récupération annonces: $e');
      throw Exception('Erreur lors de la récupération des annonces: $e');
    }
  }

  // Récupérer une annonce par ID
  Future<AnnonceModel?> getAnnonceById(String id) async {
    try {
      final doc = await _annoncesRef.doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return AnnonceModel.fromJson(data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'annonce: $e');
    }
  }

  // Recherche avec filtres
  Future<List<AnnonceModel>> searchAnnonces({
    String? query,
    String? make,
    String? model,
    double? minPrice,
    double? maxPrice,
    int? minYear,
    int? maxYear,
    int? maxMileage,
    String? fuelType,
    String? transmission,
    String? location,
  }) async {
    try {
      Query<Map<String, dynamic>> ref = _annoncesRef;

      // Filtre par marque
      if (make != null && make.isNotEmpty) {
        ref = ref.where('vehicle.make', isEqualTo: make);
      }

      // Filtre par prix
      if (minPrice != null) {
        ref = ref.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        ref = ref.where('price', isLessThanOrEqualTo: maxPrice);
      }

      final snapshot = await ref.get();
      
      var results = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AnnonceModel.fromJson(data);
      }).toList();

      // Filtres cote client (Firestore ne supporte pas tous les filtres combines)
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        results = results.where((a) {
          final vehicleText = '${a.vehicle.make} ${a.vehicle.model}'.toLowerCase();
          return vehicleText.contains(lowerQuery) ||
                 a.description.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      if (model != null && model.isNotEmpty) {
        final lowerModel = model.toLowerCase();
        results = results.where((a) => 
            a.vehicle.model.toLowerCase().contains(lowerModel)).toList();
      }

      if (minYear != null) {
        results = results.where((a) => a.vehicle.year >= minYear).toList();
      }
      if (maxYear != null) {
        results = results.where((a) => a.vehicle.year <= maxYear).toList();
      }
      if (maxMileage != null) {
        results = results.where((a) => a.vehicle.mileage <= maxMileage).toList();
      }

      return results;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Récupérer les annonces d'un vendeur
  Future<List<AnnonceModel>> getAnnoncesByOwner(String ownerId) async {
    try {
      final snapshot = await _annoncesRef
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AnnonceModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des annonces: $e');
    }
  }

  // Stream des annonces (temps réel)
  Stream<List<AnnonceModel>> watchAnnonces() {
    debugPrint('👀 Démarrage du stream des annonces...');
    return _annoncesRef
        .snapshots()
        .map((snapshot) {
          debugPrint('📥 Snapshot reçu: ${snapshot.docs.length} annonces');
          final annonces = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return AnnonceModel.fromJson(data);
          }).toList();
          
          // Trier par date de création (plus récent en premier)
          annonces.sort((a, b) {
            final aDate = a.createdAt ?? DateTime(2000);
            final bDate = b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });
          
          return annonces;
        });
  }
}
