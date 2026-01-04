class VehicleModel {
  final String id;
  final String make;
  final String model;
  final int year;
  final int mileage;
  /// Liste des URLs des photos du véhicule
  final List<String> photos;

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    this.photos = const [],
  });

  /// Alias pour compatibilité
  List<String> get photoUrls => photos;

  /// Retourne la première photo ou null
  String? get mainPhoto => photos.isNotEmpty ? photos.first : null;

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'] as String,
    make: json['make'] as String,
    model: json['model'] as String,
    year: json['year'] as int,
    mileage: json['mileage'] as int,
    photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? 
            (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'year': year,
    'mileage': mileage,
    'photos': photos,
  };
}
