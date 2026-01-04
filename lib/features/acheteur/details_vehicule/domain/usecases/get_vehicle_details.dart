import '../../../../../data/models/annonce_model.dart';
import '../../../../../data/models/historique_vehicule_model.dart';
import '../../../../../data/models/vehicle_model.dart';

/// Détails complets d'un véhicule
class VehicleDetailsModel {
  final AnnonceModel annonce;
  final List<String> photoUrls;
  final List<HistoriqueVehiculeModel> historique;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final SellerInfo? seller;
  final VehicleFeatures? features;
  final DateTime? publishedAt;
  final int viewCount;
  final RapportVehiculeModel? rapport;

  const VehicleDetailsModel({
    required this.annonce,
    this.photoUrls = const [],
    this.historique = const [],
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.seller,
    this.features,
    this.publishedAt,
    this.viewCount = 0,
    this.rapport,
  });
}

/// Informations du vendeur
class SellerInfo {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? memberSince;
  final int totalAds;
  final double rating;

  const SellerInfo({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.memberSince,
    this.totalAds = 0,
    this.rating = 0.0,
  });
}

/// Caractéristiques du véhicule
class VehicleFeatures {
  final String? fuelType;
  final String? transmission;
  final String? color;
  final int? horsePower;
  final int? doors;
  final int? seats;
  final String? energy;
  final bool hasAirConditioning;
  final bool hasGPS;
  final bool hasParkingSensors;
  final bool hasBluetoothPhone;
  final List<String> otherFeatures;

  const VehicleFeatures({
    this.fuelType,
    this.transmission,
    this.color,
    this.horsePower,
    this.doors,
    this.seats,
    this.energy,
    this.hasAirConditioning = false,
    this.hasGPS = false,
    this.hasParkingSensors = false,
    this.hasBluetoothPhone = false,
    this.otherFeatures = const [],
  });
}

/// Résultat de la récupération des détails
class VehicleDetailsResult {
  final bool success;
  final VehicleDetailsModel? details;
  final String? errorMessage;

  const VehicleDetailsResult.success(this.details)
      : success = true,
        errorMessage = null;

  const VehicleDetailsResult.failure(this.errorMessage)
      : success = false,
        details = null;
}

class GetVehicleDetailsUseCase {
  GetVehicleDetailsUseCase();

  /// Récupère les détails complets d'une annonce
  Future<VehicleDetailsResult> execute(String annonceId) async {
    try {
      if (annonceId.isEmpty) {
        return const VehicleDetailsResult.failure('ID d\'annonce invalide');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final details = _getMockDetails(annonceId);

      if (details == null) {
        return const VehicleDetailsResult.failure('Annonce non trouvée');
      }

      return VehicleDetailsResult.success(details);
    } catch (e) {
      return VehicleDetailsResult.failure(
        'Erreur lors du chargement des détails: ${e.toString()}',
      );
    }
  }

  /// Récupère l'historique du véhicule
  Future<List<HistoriqueVehiculeModel>> getVehicleHistory(String vehicleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _getMockHistory(vehicleId);
  }

  /// Données mock pour le développement
  VehicleDetailsModel? _getMockDetails(String annonceId) {
    final mockData = {
      '1': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '1',
          vehicle: VehicleModel(
            id: 'v1',
            make: 'Peugeot',
            model: '308',
            year: 2020,
            mileage: 45000,
            photos: [
              'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800',
              'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800',
              'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=800',
              'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
            ],
          ),
          description: '''
Peugeot 308 en excellent état, première main.
Entretien suivi chez Peugeot avec carnet à jour.
Véhicule non fumeur, intérieur très propre.

Équipements:
- GPS intégré avec mise à jour gratuite
- Caméra de recul
- Régulateur de vitesse adaptatif
- Feux LED
- Jantes alliage 17"

Contrôle technique OK, valable jusqu'en 2025.
Disponible immédiatement.
          ''',
          price: 18500,
          ownerId: 'user1',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800',
          'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800',
          'https://images.unsplash.com/photo-1502877338535-766e1452684a?w=800',
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
        ],
        historique: _getMockHistory('v1'),
        latitude: 48.8566,
        longitude: 2.3522,
        locationAddress: 'Paris 75001, France',
        seller: const SellerInfo(
          id: 'user1',
          name: 'Jean Dupont',
          phoneNumber: '06 12 34 56 78',
          memberSince: null,
          totalAds: 3,
          rating: 4.5,
        ),
        features: const VehicleFeatures(
          fuelType: 'Essence',
          transmission: 'Manuelle',
          color: 'Gris',
          horsePower: 130,
          doors: 5,
          seats: 5,
          energy: 'B',
          hasAirConditioning: true,
          hasGPS: true,
          hasParkingSensors: true,
          hasBluetoothPhone: true,
          otherFeatures: [
            'Régulateur de vitesse',
            'Feux LED',
            'Jantes alliage',
            'Vitres électriques',
            'Rétroviseurs électriques',
          ],
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        viewCount: 127,
      ),
      '2': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '2',
          vehicle: VehicleModel(
            id: 'v2',
            make: 'Renault',
            model: 'Clio',
            year: 2019,
            mileage: 62000,
            photos: [
              'https://images.unsplash.com/photo-1609521263047-f8f205293f24?w=800',
              'https://images.unsplash.com/photo-1606567595334-d39972c85dfd?w=800',
              'https://images.unsplash.com/photo-1590362891991-f776e747a588?w=800',
            ],
          ),
          description: 'Renault Clio 5, essence, boîte manuelle, GPS intégré.',
          price: 14900,
          ownerId: 'user2',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1609521263047-f8f205293f24?w=800',
          'https://images.unsplash.com/photo-1606567595334-d39972c85dfd?w=800',
          'https://images.unsplash.com/photo-1590362891991-f776e747a588?w=800',
        ],
        historique: _getMockHistory('v2'),
        latitude: 45.764,
        longitude: 4.8357,
        locationAddress: 'Lyon 69001, France',
        seller: const SellerInfo(
          id: 'user2',
          name: 'Marie Martin',
          totalAds: 1,
          rating: 5.0,
        ),
        features: const VehicleFeatures(
          fuelType: 'Essence',
          transmission: 'Manuelle',
          color: 'Blanc',
          horsePower: 100,
          doors: 5,
          seats: 5,
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 12)),
        viewCount: 89,
      ),
      '3': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '3',
          vehicle: VehicleModel(
            id: 'v3',
            make: 'Volkswagen',
            model: 'Golf',
            year: 2021,
            mileage: 28000,
            photos: [
              'https://images.unsplash.com/photo-1631295868223-63265b40d9e4?w=800',
              'https://images.unsplash.com/photo-1625231334168-22a7d8c5a553?w=800',
              'https://images.unsplash.com/photo-1622126807280-9b5b32b28e77?w=800',
            ],
          ),
          description: 'Golf 8 GTI, état neuf, full options. Véhicule jamais accidenté.',
          price: 32000,
          ownerId: 'user3',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1631295868223-63265b40d9e4?w=800',
          'https://images.unsplash.com/photo-1625231334168-22a7d8c5a553?w=800',
          'https://images.unsplash.com/photo-1622126807280-9b5b32b28e77?w=800',
        ],
        historique: _getMockHistory('v3'),
        latitude: 43.2965,
        longitude: 5.3698,
        locationAddress: 'Marseille 13001, France',
        seller: const SellerInfo(
          id: 'user3',
          name: 'Pierre Durand',
          phoneNumber: '06 98 76 54 32',
          totalAds: 2,
          rating: 4.8,
        ),
        features: const VehicleFeatures(
          fuelType: 'Essence',
          transmission: 'Automatique',
          color: 'Blanc',
          horsePower: 245,
          doors: 5,
          seats: 5,
          hasAirConditioning: true,
          hasGPS: true,
          hasParkingSensors: true,
          hasBluetoothPhone: true,
          otherFeatures: ['Toit ouvrant', 'Sièges sport', 'Mode Sport'],
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        viewCount: 234,
      ),
      '4': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '4',
          vehicle: VehicleModel(
            id: 'v4',
            make: 'BMW',
            model: 'Série 3',
            year: 2018,
            mileage: 85000,
            photos: [
              'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800',
              'https://images.unsplash.com/photo-1520050206757-275d049f30d8?w=800',
              'https://images.unsplash.com/photo-1556189250-72ba954cfc2b?w=800',
            ],
          ),
          description: 'BMW 320d, diesel, boîte automatique, intérieur cuir.',
          price: 25500,
          ownerId: 'user4',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800',
          'https://images.unsplash.com/photo-1520050206757-275d049f30d8?w=800',
          'https://images.unsplash.com/photo-1556189250-72ba954cfc2b?w=800',
        ],
        historique: _getMockHistory('v4'),
        latitude: 44.8378,
        longitude: -0.5792,
        locationAddress: 'Bordeaux 33000, France',
        seller: const SellerInfo(
          id: 'user4',
          name: 'Lucas Bernard',
          phoneNumber: '06 11 22 33 44',
          totalAds: 5,
          rating: 4.2,
        ),
        features: const VehicleFeatures(
          fuelType: 'Diesel',
          transmission: 'Automatique',
          color: 'Noir',
          horsePower: 190,
          doors: 4,
          seats: 5,
          hasAirConditioning: true,
          hasGPS: true,
          hasParkingSensors: true,
          hasBluetoothPhone: true,
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        viewCount: 156,
      ),
      '5': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '5',
          vehicle: VehicleModel(
            id: 'v5',
            make: 'Toyota',
            model: 'Yaris',
            year: 2022,
            mileage: 15000,
            photos: [
              'https://images.unsplash.com/photo-1629897048514-3dd7414fe72a?w=800',
              'https://images.unsplash.com/photo-1559416523-140ddc3d238c?w=800',
              'https://images.unsplash.com/photo-1621993202323-f438eec934ff?w=800',
            ],
          ),
          description: 'Toyota Yaris hybride, comme neuve, garantie constructeur.',
          price: 19800,
          ownerId: 'user5',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1629897048514-3dd7414fe72a?w=800',
          'https://images.unsplash.com/photo-1559416523-140ddc3d238c?w=800',
          'https://images.unsplash.com/photo-1621993202323-f438eec934ff?w=800',
        ],
        historique: _getMockHistory('v5'),
        latitude: 47.2184,
        longitude: -1.5536,
        locationAddress: 'Nantes 44000, France',
        seller: const SellerInfo(
          id: 'user5',
          name: 'Sophie Petit',
          totalAds: 1,
          rating: 5.0,
        ),
        features: const VehicleFeatures(
          fuelType: 'Hybride',
          transmission: 'Automatique',
          color: 'Rouge',
          horsePower: 116,
          doors: 5,
          seats: 5,
          hasAirConditioning: true,
          hasGPS: true,
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        viewCount: 98,
      ),
      '6': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '6',
          vehicle: VehicleModel(
            id: 'v6',
            make: 'Audi',
            model: 'A4',
            year: 2019,
            mileage: 72000,
            photos: [
              'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
              'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800',
              'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=800',
            ],
          ),
          description: 'Audi A4 Avant, break familial, toit panoramique.',
          price: 28900,
          ownerId: 'user6',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
          'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800',
          'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=800',
        ],
        historique: _getMockHistory('v6'),
        latitude: 48.5734,
        longitude: 7.7521,
        locationAddress: 'Strasbourg 67000, France',
        seller: const SellerInfo(
          id: 'user6',
          name: 'Thomas Roux',
          phoneNumber: '06 55 66 77 88',
          totalAds: 3,
          rating: 4.6,
        ),
        features: const VehicleFeatures(
          fuelType: 'Diesel',
          transmission: 'Automatique',
          color: 'Gris',
          horsePower: 150,
          doors: 5,
          seats: 5,
          hasAirConditioning: true,
          hasGPS: true,
          hasParkingSensors: true,
          hasBluetoothPhone: true,
          otherFeatures: ['Toit panoramique', 'Coffre XXL'],
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        viewCount: 112,
      ),
      '7': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '7',
          vehicle: VehicleModel(
            id: 'v7',
            make: 'Citroën',
            model: 'C3',
            year: 2020,
            mileage: 38000,
            photos: [
              'https://images.unsplash.com/photo-1612825173281-9a193378527e?w=800',
              'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800',
              'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
            ],
          ),
          description: 'Citroën C3 Shine, caméra de recul, aide au stationnement.',
          price: 13500,
          ownerId: 'user7',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1612825173281-9a193378527e?w=800',
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800',
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800',
        ],
        historique: _getMockHistory('v7'),
        latitude: 43.6047,
        longitude: 1.4442,
        locationAddress: 'Toulouse 31000, France',
        seller: const SellerInfo(
          id: 'user7',
          name: 'Emma Leroy',
          totalAds: 1,
          rating: 4.9,
        ),
        features: const VehicleFeatures(
          fuelType: 'Essence',
          transmission: 'Manuelle',
          color: 'Bleu',
          horsePower: 83,
          doors: 5,
          seats: 5,
          hasAirConditioning: true,
          hasParkingSensors: true,
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 10)),
        viewCount: 67,
      ),
      '8': VehicleDetailsModel(
        annonce: AnnonceModel(
          id: '8',
          vehicle: VehicleModel(
            id: 'v8',
            make: 'Mercedes',
            model: 'Classe A',
            year: 2021,
            mileage: 22000,
            photos: [
              'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
              'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
              'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=800',
            ],
          ),
          description: 'Mercedes Classe A 180, finition AMG Line.',
          price: 35000,
          ownerId: 'user8',
        ),
        photoUrls: [
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
          'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
          'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=800',
        ],
        historique: _getMockHistory('v8'),
        latitude: 48.8566,
        longitude: 2.3522,
        locationAddress: 'Paris 75008, France',
        seller: const SellerInfo(
          id: 'user8',
          name: 'Antoine Moreau',
          phoneNumber: '06 99 88 77 66',
          totalAds: 4,
          rating: 4.7,
        ),
        features: const VehicleFeatures(
          fuelType: 'Essence',
          transmission: 'Automatique',
          color: 'Blanc',
          horsePower: 136,
          doors: 5,
          seats: 5,
          hasAirConditioning: true,
          hasGPS: true,
          hasParkingSensors: true,
          hasBluetoothPhone: true,
          otherFeatures: ['Pack AMG', 'Jantes 18"', 'MBUX'],
        ),
        publishedAt: DateTime.now().subtract(const Duration(days: 4)),
        viewCount: 189,
      ),
    };

    return mockData[annonceId];
  }

  /// Historique mock
  List<HistoriqueVehiculeModel> _getMockHistory(String vehicleId) {
    return [
      HistoriqueVehiculeModel(
        id: 'h1',
        vehicleId: vehicleId,
        description: 'Contrôle technique - Favorable sans observations',
        date: DateTime(2024, 6, 15),
      ),
      HistoriqueVehiculeModel(
        id: 'h2',
        vehicleId: vehicleId,
        description: 'Révision complète - Vidange + filtres',
        date: DateTime(2024, 3, 20),
      ),
      HistoriqueVehiculeModel(
        id: 'h3',
        vehicleId: vehicleId,
        description: 'Remplacement des plaquettes de frein avant',
        date: DateTime(2023, 11, 5),
      ),
      HistoriqueVehiculeModel(
        id: 'h4',
        vehicleId: vehicleId,
        description: 'Révision intermédiaire - 30 000 km',
        date: DateTime(2023, 6, 10),
      ),
      HistoriqueVehiculeModel(
        id: 'h5',
        vehicleId: vehicleId,
        description: 'Première immatriculation',
        date: DateTime(2020, 3, 1),
      ),
    ];
  }
}
