import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/annonce_model.dart';
import '../../data/models/alerte_recherche_model.dart';

/// Service pour gérer les alertes quand une nouvelle annonce correspond aux critères
class AlerteMatchingService {
  final FirebaseFirestore _firestore;

  AlerteMatchingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Vérifie si une annonce correspond aux critères d'une alerte
  bool annonceMatchesAlerte(AnnonceModel annonce, AlerteRechercheModel alerte) {
    final criteres = alerte.criteres;
    debugPrint('🔍 Vérification alerte "${alerte.nom}" pour annonce ${annonce.id}');
    debugPrint('   Critères: $criteres');
    debugPrint('   Annonce: make=${annonce.vehicle.make}, model=${annonce.vehicle.model}, year=${annonce.vehicle.year}, price=${annonce.price}');

    // Vérifier la marque (case insensitive)
    if (criteres['marque'] != null && criteres['marque'].toString().isNotEmpty) {
      final marqueAlerte = criteres['marque'].toString().toLowerCase().trim();
      final marqueAnnonce = annonce.vehicle.make.toLowerCase().trim();
      debugPrint('   Comparaison marque: "$marqueAnnonce" vs "$marqueAlerte"');
      if (marqueAnnonce != marqueAlerte) {
        debugPrint('   ❌ Marque ne correspond pas');
        return false;
      }
    }

    // Vérifier le modèle (case insensitive, contains)
    if (criteres['modele'] != null && criteres['modele'].toString().isNotEmpty) {
      final modeleAlerte = criteres['modele'].toString().toLowerCase().trim();
      final modeleAnnonce = annonce.vehicle.model.toLowerCase().trim();
      debugPrint('   Comparaison modèle: "$modeleAnnonce" contains "$modeleAlerte"?');
      if (!modeleAnnonce.contains(modeleAlerte)) {
        debugPrint('   ❌ Modèle ne correspond pas');
        return false;
      }
    }

    // Vérifier le prix min
    if (criteres['prixMin'] != null) {
      final prixMin = (criteres['prixMin'] as num).toDouble();
      debugPrint('   Comparaison prixMin: ${annonce.price} >= $prixMin?');
      if (annonce.price < prixMin) {
        debugPrint('   ❌ Prix trop bas');
        return false;
      }
    }

    // Vérifier le prix max
    if (criteres['prixMax'] != null) {
      final prixMax = (criteres['prixMax'] as num).toDouble();
      debugPrint('   Comparaison prixMax: ${annonce.price} <= $prixMax?');
      if (annonce.price > prixMax) {
        debugPrint('   ❌ Prix trop élevé');
        return false;
      }
    }

    // Vérifier l'année min (seulement si l'annonce a une année > 0)
    if (criteres['anneeMin'] != null && annonce.vehicle.year > 0) {
      final anneeMin = criteres['anneeMin'] as int;
      debugPrint('   Comparaison anneeMin: ${annonce.vehicle.year} >= $anneeMin?');
      if (annonce.vehicle.year < anneeMin) {
        debugPrint('   ❌ Année trop ancienne');
        return false;
      }
    }

    // Vérifier l'année max (seulement si l'annonce a une année > 0)
    if (criteres['anneeMax'] != null && annonce.vehicle.year > 0) {
      final anneeMax = criteres['anneeMax'] as int;
      debugPrint('   Comparaison anneeMax: ${annonce.vehicle.year} <= $anneeMax?');
      if (annonce.vehicle.year > anneeMax) {
        debugPrint('   ❌ Année trop récente');
        return false;
      }
    }

    // Vérifier le kilométrage max
    if (criteres['kilometrageMax'] != null) {
      final kmMax = criteres['kilometrageMax'] as int;
      debugPrint('   Comparaison kmMax: ${annonce.vehicle.mileage} <= $kmMax?');
      if (annonce.vehicle.mileage > kmMax) {
        debugPrint('   ❌ Kilométrage trop élevé');
        return false;
      }
    }

    debugPrint('   ✅ Alerte "${alerte.nom}" CORRESPOND à l\'annonce!');
    return true;
  }

  /// Trouve toutes les alertes qui correspondent à une nouvelle annonce
  Future<List<AlerteRechercheModel>> findMatchingAlertes(AnnonceModel annonce) async {
    try {
      debugPrint('🔎 Recherche des alertes pour annonce: ${annonce.vehicle.make} ${annonce.vehicle.model}');
      debugPrint('   Prix: ${annonce.price}, Année: ${annonce.vehicle.year}, KM: ${annonce.vehicle.mileage}');
      
      // Récupérer TOUTES les alertes (actif ou non défini)
      final snapshot = await _firestore
          .collection('alertes')
          .get();

      debugPrint('📋 ${snapshot.docs.length} alertes trouvées dans Firebase');

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucune alerte dans la collection "alertes"');
        return [];
      }

      final alertes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('   - Alerte: ${data['nom']} (userId: ${data['userId']}, actif: ${data['actif']}, critères: ${data['criteres']})');
        return AlerteRechercheModel.fromJson(data);
      }).toList();
      
      final alertesActives = alertes.where((alerte) => alerte.actif).toList();
      debugPrint('📋 ${alertesActives.length} alertes actives sur ${alertes.length} total');

      // Filtrer celles qui correspondent à l'annonce
      final matching = alertesActives.where((alerte) => annonceMatchesAlerte(annonce, alerte)).toList();
      
      debugPrint('🎯 ${matching.length} alertes correspondent à l\'annonce');
      return matching;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la recherche d\'alertes: $e');
      debugPrint('📋 Stack: $stackTrace');
      return [];
    }
  }

  /// Déclenche les notifications pour les alertes correspondantes
  Future<void> triggerAlertes(AnnonceModel annonce) async {
    debugPrint('🚀 Déclenchement des alertes pour annonce ${annonce.id}');
    
    final matchingAlertes = await findMatchingAlertes(annonce);

    for (final alerte in matchingAlertes) {
      debugPrint('📬 Création notification pour alerte "${alerte.nom}"');
      
      // Créer une notification pour chaque alerte correspondante
      await _createNotification(alerte, annonce);

      // Mettre à jour le compteur de matchs et la date
      await _firestore.collection('alertes').doc(alerte.id).update({
        'matchCount': FieldValue.increment(1),
        'lastTriggered': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('✅ ${matchingAlertes.length} alertes déclenchées pour l\'annonce ${annonce.id}');
  }

  /// Crée une notification dans Firestore
  Future<void> _createNotification(AlerteRechercheModel alerte, AnnonceModel annonce) async {
    final notifData = {
      'userId': alerte.userId,
      'type': 'alerteMatch',
      'title': 'Nouvelle annonce correspondante !',
      'body': '${annonce.vehicle.make} ${annonce.vehicle.model} - ${annonce.price.toStringAsFixed(0)} €',
      'data': {
        'alerteId': alerte.id,
        'annonceId': annonce.id,
        'alerteNom': alerte.nom,
      },
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    debugPrint('📝 Création notification: $notifData');
    await _firestore.collection('notifications').add(notifData);
    debugPrint('✅ Notification créée avec succès');
  }
}
