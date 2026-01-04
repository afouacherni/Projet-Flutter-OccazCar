import 'package:cloud_firestore/cloud_firestore.dart';

enum FrequenceAlerte { immediate, quotidienne, hebdomadaire }

class AlerteRechercheModel {
  final String id;
  final String userId;
  final String nom;
  final Map<String, dynamic> criteres;
  final FrequenceAlerte frequence;
  final bool actif;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final int matchCount;

  AlerteRechercheModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.criteres,
    this.frequence = FrequenceAlerte.immediate,
    this.actif = true,
    required this.createdAt,
    this.lastTriggered,
    this.matchCount = 0,
  });

  String? get marque => criteres['marque'] as String?;
  String? get modele => criteres['modele'] as String?;
  double? get prixMin => (criteres['prixMin'] as num?)?.toDouble();
  double? get prixMax => (criteres['prixMax'] as num?)?.toDouble();
  int? get anneeMin => criteres['anneeMin'] as int?;
  int? get anneeMax => criteres['anneeMax'] as int?;
  int? get kilometrageMax => criteres['kilometrageMax'] as int?;
  String? get carburant => criteres['carburant'] as String?;
  String? get transmission => criteres['transmission'] as String?;
  String? get localisation => criteres['localisation'] as String?;

  String get resumeCriteres {
    final parts = <String>[];
    if (marque != null) parts.add(marque!);
    if (modele != null) parts.add(modele!);
    if (prixMax != null) parts.add('< ${prixMax!.toStringAsFixed(0)} €');
    if (anneeMin != null) parts.add('> $anneeMin');
    if (carburant != null) parts.add(carburant!);
    return parts.isEmpty ? 'Tous les véhicules' : parts.join(' • ');
  }

  String get frequenceLabel {
    switch (frequence) {
      case FrequenceAlerte.immediate:
        return 'Immédiate';
      case FrequenceAlerte.quotidienne:
        return 'Quotidienne';
      case FrequenceAlerte.hebdomadaire:
        return 'Hebdomadaire';
    }
  }

  factory AlerteRechercheModel.fromJson(Map<String, dynamic> json) {
    // Parser createdAt de manière sécurisée
    DateTime parseCreatedAt() {
      final value = json['createdAt'];
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }
    
    return AlerteRechercheModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      nom: json['nom'] as String? ?? 'Sans nom',
      criteres: Map<String, dynamic>.from(json['criteres'] ?? {}),
      frequence: FrequenceAlerte.values.firstWhere(
        (e) => e.name == json['frequence'],
        orElse: () => FrequenceAlerte.immediate,
      ),
      actif: json['actif'] as bool? ?? true,
      createdAt: parseCreatedAt(),
      lastTriggered: json['lastTriggered'] != null
          ? (json['lastTriggered'] is Timestamp
              ? (json['lastTriggered'] as Timestamp).toDate()
              : DateTime.tryParse(json['lastTriggered'] as String? ?? ''))
          : null,
      matchCount: json['matchCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'nom': nom,
        'criteres': criteres,
        'frequence': frequence.name,
        'actif': actif,
        'createdAt': createdAt.toIso8601String(),
        'lastTriggered': lastTriggered?.toIso8601String(),
        'matchCount': matchCount,
      };

  AlerteRechercheModel copyWith({
    String? id,
    String? userId,
    String? nom,
    Map<String, dynamic>? criteres,
    FrequenceAlerte? frequence,
    bool? actif,
    DateTime? createdAt,
    DateTime? lastTriggered,
    int? matchCount,
  }) {
    return AlerteRechercheModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      criteres: criteres ?? this.criteres,
      frequence: frequence ?? this.frequence,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      matchCount: matchCount ?? this.matchCount,
    );
  }
}
