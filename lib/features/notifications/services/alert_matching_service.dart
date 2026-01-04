import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/alerte_recherche_model.dart';
import '../../../data/models/annonce_model.dart';
import '../../../data/models/notification_model.dart';

/// Service qui surveille les nouvelles annonces et vérifie les correspondances avec les alertes
class AlertMatchingService {
  static final AlertMatchingService _instance = AlertMatchingService._internal();
  factory AlertMatchingService() => _instance;
  AlertMatchingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _annoncesSubscription;
  StreamSubscription<QuerySnapshot>? _alertesSubscription;
  
  List<AlerteRechercheModel> _cachedAlertes = [];
  Set<String> _processedAnnonces = {};
  bool _isInitialized = false;

  /// Démarre le service de matching
  void startMatching() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    debugPrint('🎯 Démarrage du service de matching des alertes');
    _loadExistingAnnonces();
    _watchAlertes();
    _watchNewAnnonces();
  }

  /// Charge les annonces existantes pour éviter les notifications en double
  Future<void> _loadExistingAnnonces() async {
    try {
      final snapshot = await _firestore.collection('annonces').get();
      _processedAnnonces = snapshot.docs.map((doc) => doc.id).toSet();
      debugPrint('📝 ${_processedAnnonces.length} annonces existantes chargées');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des annonces existantes: $e');
    }
  }

  /// Surveille les alertes actives
  void _watchAlertes() {
    _alertesSubscription = _firestore
        .collection('alertes')
        .where('actif', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _cachedAlertes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AlerteRechercheModel.fromJson(data);
      }).toList();
      
      debugPrint('🚨 ${_cachedAlertes.length} alertes actives chargées');
    });
  }

  /// Surveille les nouvelles annonces
  void _watchNewAnnonces() {
    _annoncesSubscription = _firestore
        .collection('annonces')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final annonceId = change.doc.id;
          
          // Éviter de traiter les annonces déjà connues
          if (_processedAnnonces.contains(annonceId)) continue;
          _processedAnnonces.add(annonceId);
          
          try {
            final data = change.doc.data() as Map<String, dynamic>;
            data['id'] = annonceId;
            final annonce = AnnonceModel.fromJson(data);
            
            debugPrint('🆕 Nouvelle annonce détectée: ${annonce.vehicle.make} ${annonce.vehicle.model}');
            _checkAnnonceAgainstAlertes(annonce);
          } catch (e) {
            debugPrint('❌ Erreur lors du parsing de l\'annonce $annonceId: $e');
          }
        }
      }
    });
  }

  /// Vérifie si une annonce correspond aux alertes et envoie des notifications
  Future<void> _checkAnnonceAgainstAlertes(AnnonceModel annonce) async {
    for (final alerte in _cachedAlertes) {
      if (_isAnnonceMatchingAlerte(annonce, alerte)) {
        await _sendNotificationForMatch(annonce, alerte);
      }
    }
  }

  /// Vérifie si une annonce correspond aux critères d'une alerte
  bool _isAnnonceMatchingAlerte(AnnonceModel annonce, AlerteRechercheModel alerte) {
    // Vérifier la marque
    if (alerte.marque != null && alerte.marque!.isNotEmpty) {
      if (!annonce.vehicle.make.toLowerCase().contains(alerte.marque!.toLowerCase())) {
        return false;
      }
    }

    // Vérifier le modèle
    if (alerte.modele != null && alerte.modele!.isNotEmpty) {
      if (!annonce.vehicle.model.toLowerCase().contains(alerte.modele!.toLowerCase())) {
        return false;
      }
    }

    // Vérifier le prix maximum
    if (alerte.prixMax != null) {
      if (annonce.price > alerte.prixMax!) {
        return false;
      }
    }

    // Vérifier le prix minimum
    if (alerte.prixMin != null) {
      if (annonce.price < alerte.prixMin!) {
        return false;
      }
    }

    // Vérifier l'année minimum
    if (alerte.anneeMin != null) {
      if (annonce.vehicle.year < alerte.anneeMin!) {
        return false;
      }
    }

    // Vérifier l'année maximum
    if (alerte.anneeMax != null) {
      if (annonce.vehicle.year > alerte.anneeMax!) {
        return false;
      }
    }

    // Vérifier le kilométrage maximum
    if (alerte.kilometrageMax != null) {
      if (annonce.vehicle.mileage > alerte.kilometrageMax!) {
        return false;
      }
    }

    debugPrint('✅ Match trouvé: ${annonce.vehicle.make} ${annonce.vehicle.model} pour l\'alerte "${alerte.nom}"');
    return true;
  }

  /// Envoie une notification pour un match
  Future<void> _sendNotificationForMatch(AnnonceModel annonce, AlerteRechercheModel alerte) async {
    try {
      // Vérifier la fréquence de l'alerte
      if (!_shouldSendNotification(alerte)) {
        debugPrint('🚫 Notification ignorée pour l\'alerte "${alerte.nom}" (fréquence)');
        return;
      }

      final notification = NotificationModel(
        id: '', // Sera généré par Firestore
        userId: alerte.userId,
        title: '🎯 Nouvelle annonce correspondante !',
        body: '${annonce.vehicle.make} ${annonce.vehicle.model} (${annonce.vehicle.year}) - ${annonce.price.toStringAsFixed(0)}€',
        type: NotificationType.alerteMatch,
        data: {
          'annonceId': annonce.id,
          'alerteId': alerte.id,
          'alerteName': alerte.nom,
          'vehicleMake': annonce.vehicle.make,
          'vehicleModel': annonce.vehicle.model,
          'price': annonce.price,
        },
        read: false,
        createdAt: DateTime.now(),
      );

      // Sauvegarder la notification
      await _firestore.collection('notifications').add(notification.toJson());

      // Mettre à jour l'alerte avec la dernière date de déclenchement
      await _firestore.collection('alertes').doc(alerte.id).update({
        'lastTriggered': FieldValue.serverTimestamp(),
        'matchCount': FieldValue.increment(1),
      });

      debugPrint('📧 Notification envoyée à ${alerte.userId} pour l\'alerte "${alerte.nom}"');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de la notification: $e');
    }
  }

  /// Vérifie si une notification doit être envoyée selon la fréquence
  bool _shouldSendNotification(AlerteRechercheModel alerte) {
    if (alerte.lastTriggered == null) return true;

    final now = DateTime.now();
    final lastTriggered = alerte.lastTriggered!;

    switch (alerte.frequence) {
      case FrequenceAlerte.immediate:
        return true;
      case FrequenceAlerte.quotidienne:
        return now.difference(lastTriggered).inDays >= 1;
      case FrequenceAlerte.hebdomadaire:
        return now.difference(lastTriggered).inDays >= 7;
    }
  }

  /// Arrête le service
  void stopMatching() {
    debugPrint('🛑 Arrêt du service de matching des alertes');
    _annoncesSubscription?.cancel();
    _alertesSubscription?.cancel();
    _isInitialized = false;
  }

  /// Nettoie les ressources
  void dispose() {
    stopMatching();
  }
}