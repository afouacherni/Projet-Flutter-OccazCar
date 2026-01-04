import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeEvenement {
  entretien,
  reparation,
  controle,
  accident,
  achat,
  autre,
}

enum GraviteDegat {
  aucun,
  leger,
  modere,
  important,
  grave,
}

class HistoriqueVehiculeModel {
  final String id;
  final String vehicleId;
  final String description;
  final DateTime date;
  final TypeEvenement type;
  final int? kilometrage;
  final double? cout;
  final String? garage;
  final List<String> photos;

  HistoriqueVehiculeModel({
    required this.id,
    required this.vehicleId,
    required this.description,
    required this.date,
    this.type = TypeEvenement.autre,
    this.kilometrage,
    this.cout,
    this.garage,
    this.photos = const [],
  });

  String get typeLabel {
    switch (type) {
      case TypeEvenement.entretien:
        return 'Entretien';
      case TypeEvenement.reparation:
        return 'Réparation';
      case TypeEvenement.controle:
        return 'Contrôle technique';
      case TypeEvenement.accident:
        return 'Accident';
      case TypeEvenement.achat:
        return 'Achat';
      case TypeEvenement.autre:
        return 'Autre';
    }
  }

  factory HistoriqueVehiculeModel.fromJson(Map<String, dynamic> json) =>
      HistoriqueVehiculeModel(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        description: json['description'] as String,
        date: json['date'] is Timestamp
            ? (json['date'] as Timestamp).toDate()
            : DateTime.parse(json['date'] as String),
        type: TypeEvenement.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TypeEvenement.autre,
        ),
        kilometrage: json['kilometrage'] as int?,
        cout: (json['cout'] as num?)?.toDouble(),
        garage: json['garage'] as String?,
        photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'description': description,
        'date': date.toIso8601String(),
        'type': type.name,
        'kilometrage': kilometrage,
        'cout': cout,
        'garage': garage,
        'photos': photos,
      };
}

class RapportVehiculeModel {
  final String vehicleId;
  final List<HistoriqueVehiculeModel> historique;
  final int nombreProprietaires;
  final bool accidente;
  final GraviteDegat etatDegats;
  final String? descriptionDegats;
  final DateTime? derniereRevision;
  final DateTime? prochainControle;
  final int? kilometrageActuel;
  final double? coteArgus;
  final int scoreConfiance;

  RapportVehiculeModel({
    required this.vehicleId,
    this.historique = const [],
    this.nombreProprietaires = 1,
    this.accidente = false,
    this.etatDegats = GraviteDegat.aucun,
    this.descriptionDegats,
    this.derniereRevision,
    this.prochainControle,
    this.kilometrageActuel,
    this.coteArgus,
    this.scoreConfiance = 0,
  });

  String get etatDegatsLabel {
    switch (etatDegats) {
      case GraviteDegat.aucun:
        return 'Aucun dégât';
      case GraviteDegat.leger:
        return 'Dégâts légers';
      case GraviteDegat.modere:
        return 'Dégâts modérés';
      case GraviteDegat.important:
        return 'Dégâts importants';
      case GraviteDegat.grave:
        return 'Dégâts graves';
    }
  }

  int get nombreEntretiens =>
      historique.where((h) => h.type == TypeEvenement.entretien).length;

  int get nombreReparations =>
      historique.where((h) => h.type == TypeEvenement.reparation).length;

  double get coutTotalEntretien => historique
      .where((h) => h.type == TypeEvenement.entretien && h.cout != null)
      .fold(0.0, (sum, h) => sum + h.cout!);

  bool get controleValide {
    if (prochainControle == null) return false;
    return prochainControle!.isAfter(DateTime.now());
  }

  factory RapportVehiculeModel.fromJson(Map<String, dynamic> json) {
    return RapportVehiculeModel(
      vehicleId: json['vehicleId'] as String,
      historique: (json['historique'] as List<dynamic>?)
              ?.map((e) =>
                  HistoriqueVehiculeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nombreProprietaires: json['nombreProprietaires'] as int? ?? 1,
      accidente: json['accidente'] as bool? ?? false,
      etatDegats: GraviteDegat.values.firstWhere(
        (e) => e.name == json['etatDegats'],
        orElse: () => GraviteDegat.aucun,
      ),
      descriptionDegats: json['descriptionDegats'] as String?,
      derniereRevision: json['derniereRevision'] != null
          ? (json['derniereRevision'] is Timestamp
              ? (json['derniereRevision'] as Timestamp).toDate()
              : DateTime.parse(json['derniereRevision'] as String))
          : null,
      prochainControle: json['prochainControle'] != null
          ? (json['prochainControle'] is Timestamp
              ? (json['prochainControle'] as Timestamp).toDate()
              : DateTime.parse(json['prochainControle'] as String))
          : null,
      kilometrageActuel: json['kilometrageActuel'] as int?,
      coteArgus: (json['coteArgus'] as num?)?.toDouble(),
      scoreConfiance: json['scoreConfiance'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'historique': historique.map((h) => h.toJson()).toList(),
        'nombreProprietaires': nombreProprietaires,
        'accidente': accidente,
        'etatDegats': etatDegats.name,
        'descriptionDegats': descriptionDegats,
        'derniereRevision': derniereRevision?.toIso8601String(),
        'prochainControle': prochainControle?.toIso8601String(),
        'kilometrageActuel': kilometrageActuel,
        'coteArgus': coteArgus,
        'scoreConfiance': scoreConfiance,
      };
}
