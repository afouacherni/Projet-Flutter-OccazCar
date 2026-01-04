import 'vehicle_model.dart';

class AnnonceModel {
  final String id;
  final VehicleModel vehicle;
  final String description;
  final double price;
  final String ownerId;
  /// Date de création de l'annonce (pour le tri par date)
  final DateTime? createdAt;

  AnnonceModel({
    required this.id,
    required this.vehicle,
    required this.description,
    required this.price,
    required this.ownerId,
    this.createdAt,
  });

  /// Factory qui gère les deux formats:
  /// - Format avec 'vehicle' imbriqué (ancien format)
  /// - Format avec make/model/year à la racine (format vendeur)
  factory AnnonceModel.fromJson(Map<String, dynamic> json) {
    VehicleModel vehicle;
    
    // Vérifier si le format est avec 'vehicle' imbriqué
    if (json['vehicle'] != null && json['vehicle'] is Map<String, dynamic>) {
      vehicle = VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>);
    } else {
      // Format avec make/model/year à la racine (format vendeur)
      vehicle = VehicleModel(
        id: json['id'] as String? ?? '',
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        mileage: (json['mileage'] as num?)?.toInt() ?? 0,
        photos: _parsePhotos(json),
      );
    }

    return AnnonceModel(
      id: json['id'] as String? ?? '',
      vehicle: vehicle,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      ownerId: json['ownerId'] as String? ?? json['vendeurId'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  /// Parse les photos depuis différents formats possibles
  static List<String> _parsePhotos(Map<String, dynamic> json) {
    // Essayer 'photoUrls' d'abord, puis 'photos'
    final photoUrls = json['photoUrls'];
    final photos = json['photos'];
    
    if (photoUrls is List) {
      return photoUrls.cast<String>();
    } else if (photos is List) {
      return photos.cast<String>();
    }
    return [];
  }

  /// Parse une date depuis String ou Timestamp
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Gérer Timestamp Firestore
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as int) * 1000,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicle': vehicle.toJson(),
    'description': description,
    'price': price,
    'ownerId': ownerId,
    'createdAt': createdAt?.toIso8601String(),
  };
}
