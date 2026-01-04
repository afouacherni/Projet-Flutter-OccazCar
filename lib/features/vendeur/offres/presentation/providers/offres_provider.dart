import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèle d'une offre reçue
class OffreModel {
  final String id;
  final String annonceId;
  final String acheteurId;
  final String acheteurNom;
  final double montant;
  final String? message;
  final DateTime createdAt;
  final String status; // pending, accepted, rejected

  OffreModel({
    required this.id,
    required this.annonceId,
    required this.acheteurId,
    required this.acheteurNom,
    required this.montant,
    this.message,
    required this.createdAt,
    this.status = 'pending',
  });

  factory OffreModel.fromJson(Map<String, dynamic> json) {
    return OffreModel(
      id: json['id'] as String,
      annonceId: json['annonceId'] as String,
      acheteurId: json['acheteurId'] as String,
      acheteurNom: json['acheteurNom'] as String? ?? 'Acheteur',
      montant: (json['montant'] as num).toDouble(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'annonceId': annonceId,
    'acheteurId': acheteurId,
    'acheteurNom': acheteurNom,
    'montant': montant,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  OffreModel copyWith({String? status}) {
    return OffreModel(
      id: id,
      annonceId: annonceId,
      acheteurId: acheteurId,
      acheteurNom: acheteurNom,
      montant: montant,
      message: message,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}

/// État des offres
class OffresState {
  final List<OffreModel> offres;
  final bool isLoading;
  final String? error;

  const OffresState({
    this.offres = const [],
    this.isLoading = false,
    this.error,
  });

  OffresState copyWith({
    List<OffreModel>? offres,
    bool? isLoading,
    String? error,
  }) {
    return OffresState(
      offres: offres ?? this.offres,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<OffreModel> get offresPendantes => 
      offres.where((o) => o.status == 'pending').toList();
  
  List<OffreModel> get offresAcceptees => 
      offres.where((o) => o.status == 'accepted').toList();
  
  List<OffreModel> get offresRefusees => 
      offres.where((o) => o.status == 'rejected').toList();
}

/// Provider pour la gestion des offres
class OffresNotifier extends StateNotifier<OffresState> {
  final Ref ref;

  OffresNotifier(this.ref) : super(const OffresState());

  /// Charge toutes les offres reçues
  Future<void> loadOffres() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implémenter la récupération des offres depuis Firebase
      // Simulation avec des données de test
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockOffres = [
        OffreModel(
          id: '1',
          annonceId: 'ann1',
          acheteurId: 'ach1',
          acheteurNom: 'Jean Dupont',
          montant: 22000,
          message: 'Je suis très intéressé par votre véhicule',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'pending',
        ),
        OffreModel(
          id: '2',
          annonceId: 'ann1',
          acheteurId: 'ach2',
          acheteurNom: 'Marie Martin',
          montant: 21500,
          message: 'Prix négociable ?',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: 'pending',
        ),
        OffreModel(
          id: '3',
          annonceId: 'ann2',
          acheteurId: 'ach3',
          acheteurNom: 'Pierre Durand',
          montant: 15000,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          status: 'accepted',
        ),
      ];

      state = state.copyWith(offres: mockOffres, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des offres: $e',
      );
    }
  }

  /// Accepte une offre
  Future<void> accepterOffre(String offreId) async {
    try {
      final updatedOffres = state.offres.map((o) {
        if (o.id == offreId) {
          return o.copyWith(status: 'accepted');
        }
        return o;
      }).toList();
      
      state = state.copyWith(offres: updatedOffres);
      // TODO: Mettre à jour dans Firebase
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  /// Refuse une offre
  Future<void> refuserOffre(String offreId) async {
    try {
      final updatedOffres = state.offres.map((o) {
        if (o.id == offreId) {
          return o.copyWith(status: 'rejected');
        }
        return o;
      }).toList();
      
      state = state.copyWith(offres: updatedOffres);
      // TODO: Mettre à jour dans Firebase
    } catch (e) {
      state = state.copyWith(error: 'Erreur: $e');
    }
  }

  /// Ouvre une conversation avec l'acheteur
  void contacterAcheteur(String acheteurId) {
    // TODO: Naviguer vers la page de chat
  }
}

/// Provider global pour les offres
final offresProvider =
    StateNotifierProvider<OffresNotifier, OffresState>((ref) {
  return OffresNotifier(ref);
});
