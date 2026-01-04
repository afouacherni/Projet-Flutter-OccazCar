import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../favoris/presentation/providers/favoris_provider.dart';
import '../../../../chat/presentation/pages/chat_page.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../domain/usecases/get_vehicle_details.dart';
import '../providers/details_provider.dart';
import 'book_test_drive_page.dart';
import 'rapport_vehicule_page.dart';

class VehicleDetailsModernPage extends ConsumerStatefulWidget {
  final String? annonceId;
  final VehicleDetailsModel? details;

  const VehicleDetailsModernPage({super.key, this.annonceId, this.details})
    : assert(
        annonceId != null || details != null,
        'Either annonceId or details must be provided',
      );

  @override
  ConsumerState<VehicleDetailsModernPage> createState() =>
      _VehicleDetailsModernPageState();
}

class _VehicleDetailsModernPageState
    extends ConsumerState<VehicleDetailsModernPage> {
  @override
  void initState() {
    super.initState();
    // Ne charger que si pas de details fournis et annonceId présent
    if (widget.details == null && widget.annonceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(detailsProvider(widget.annonceId!).notifier).loadDetails();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si details fourni directement, utiliser directement
    if (widget.details != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildContent(widget.details!),
      );
    }

    // Sinon, charger via provider
    final detailsState = ref.watch(detailsProvider(widget.annonceId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(detailsState),
    );
  }

  Widget _buildBody(DetailsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.details == null) {
      return _buildNotFoundState();
    }

    return _buildContent(state.details!);
  }

  Widget _buildContent(VehicleDetailsModel details) {
    final vehicle = details.annonce.vehicle;
    final isFavorite = ref.watch(isFavoriteProvider(vehicle.id));

    return CustomScrollView(
      slivers: [
        // Header avec image
        SliverToBoxAdapter(child: _buildImageHeader(details, isFavorite)),

        // Contenu
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Titre et rating
                _buildTitleSection(details),

                const SizedBox(height: 16),

                // Prix
                _buildPriceSection(details),

                const SizedBox(height: 20),

                // Boutons d'action
                _buildActionButtons(details),

                const SizedBox(height: 24),

                // Spécifications clés
                _buildKeySpecs(details),

                const SizedBox(height: 24),

                // Équipements
                if (details.features != null) _buildFeatures(details.features!),

                const SizedBox(height: 24),

                // Rapport véhicule
                _buildRapportSection(details),

                const SizedBox(height: 24),

                // Description
                _buildDescription(details),

                const SizedBox(height: 24),

                // Vendeur
                if (details.seller != null) _buildSellerCard(details.seller!),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageHeader(VehicleDetailsModel details, bool isFavorite) {
    final photoUrl =
        details.photoUrls.isNotEmpty ? details.photoUrls.first : null;

    return Stack(
      children: [
        // Image
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            image:
                photoUrl != null
                    ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              photoUrl == null
                  ? const Icon(
                    Icons.directions_car,
                    size: 100,
                    color: AppColors.textLight,
                  )
                  : null,
        ),

        // Gradient overlay
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha((0.3 * 255).round()),
                Colors.transparent,
                Colors.black.withAlpha((0.1 * 255).round()),
              ],
            ),
          ),
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bouton retour
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),

                // Localisation
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        details.locationAddress?.split(',').first ?? 'France',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Boutons droite
                Row(
                  children: [
                    _buildCircleButton(
                      icon: Icons.share,
                      onTap: () => _shareAnnonce(details),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      iconColor: isFavorite ? AppColors.primary : Colors.white,
                      onTap: () => _toggleFavorite(details),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
      ),
    );
  }

  Widget _buildTitleSection(VehicleDetailsModel details) {
    final vehicle = details.annonce.vehicle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.year} • ${_formatMileage(vehicle.mileage)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Rating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.starFilled, size: 18),
                const SizedBox(width: 4),
                Text(
                  details.seller?.rating.toStringAsFixed(1) ?? '4.5',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(VehicleDetailsModel details) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            _formatPrice(details.annonce.price),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Prix négociable',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(VehicleDetailsModel details) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Bouton Contacter
          Expanded(
            child: OutlinedButton(
              onPressed: () => _contactSeller(details),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Contacter',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Bouton Essai
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.buttonShadow,
              ),
              child: ElevatedButton(
                onPressed: () => _bookTestDrive(details),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Essai routier',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeySpecs(VehicleDetailsModel details) {
    final features = details.features;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Caractéristiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => _showAllSpecs(features!),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSpecCard(
                icon: Icons.local_gas_station,
                label: 'Carburant',
                value: features?.fuelType ?? 'Essence',
              ),
              _buildSpecCard(
                icon: Icons.speed,
                label: 'Puissance',
                value: '${features?.horsePower ?? 130} CV',
              ),
              _buildSpecCard(
                icon: Icons.settings,
                label: 'Boîte',
                value: features?.transmission ?? 'Manuelle',
              ),
              _buildSpecCard(
                icon: Icons.door_front_door,
                label: 'Portes',
                value: '${features?.doors ?? 5}',
              ),
              _buildSpecCard(
                icon: Icons.event_seat,
                label: 'Places',
                value: '${features?.seats ?? 5}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(VehicleFeatures features) {
    final equipments = <String>[];
    if (features.hasAirConditioning) equipments.add('Climatisation');
    if (features.hasGPS) equipments.add('GPS');
    if (features.hasParkingSensors) equipments.add('Radar de recul');
    if (features.hasBluetoothPhone) equipments.add('Bluetooth');
    equipments.addAll(features.otherFeatures);

    if (equipments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Équipements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                equipments
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(
                            (0.1 * 255).round(),
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.success.withAlpha(
                              (0.3 * 255).round(),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(VehicleDetailsModel details) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              details.annonce.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapportSection(VehicleDetailsModel details) {
    final scoreConfiance = details.rapport?.scoreConfiance ?? 85;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapport véhicule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _openRapportVehicule(details),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha((0.1 * 255).round()),
                    AppColors.secondary.withAlpha((0.05 * 255).round()),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withAlpha((0.2 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rapport complet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Historique, contrôle technique, estimation',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(scoreConfiance),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$scoreConfiance%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confiance',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return Colors.orange;
    return AppColors.error;
  }

  void _openRapportVehicule(VehicleDetailsModel details) {
    final vehicle = details.annonce.vehicle;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RapportVehiculePage(
              vehicleTitle: '${vehicle.make} ${vehicle.model} ${vehicle.year}',
              rapport: details.rapport,
              historique: details.historique,
            ),
      ),
    );
  }

  Widget _buildSellerCard(SellerInfo seller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendeur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withAlpha(
                    (0.1 * 255).round(),
                  ),
                  child: Text(
                    seller.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.starFilled,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${seller.rating.toStringAsFixed(1)} • ${seller.totalAds} annonces',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (seller.phoneNumber != null)
                  IconButton(
                    onPressed: () => _callSeller(seller.phoneNumber!),
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha((0.1 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                widget.annonceId != null
                    ? () =>
                        ref
                            .read(detailsProvider(widget.annonceId!).notifier)
                            .loadDetails()
                    : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('Annonce non trouvée'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  // Actions
  void _toggleFavorite(VehicleDetailsModel details) {
    ref.read(favorisProvider.notifier).toggleFavorite(details.annonce);
  }

  void _shareAnnonce(VehicleDetailsModel details) {
    final vehicle = details.annonce.vehicle;
    final shareText =
        '🚗 ${vehicle.make} ${vehicle.model} ${vehicle.year}\n'
        '💰 ${_formatPrice(details.annonce.price)}\n'
        '📍 ${details.locationAddress ?? "France"}\n'
        '🔗 https://occazcar.fr/annonce/${details.annonce.id}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Titre
                const Text(
                  'Partager cette annonce',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Options de partage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.copy,
                      label: 'Copier',
                      color: AppColors.primary,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shareText));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Lien copié dans le presse-papier'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.email,
                      label: 'Email',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email non disponible en mode démo'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.message,
                      label: 'SMS',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SMS non disponible en mode démo'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                    ),
                    _buildShareOption(
                      icon: Icons.link,
                      label: 'Lien',
                      color: Colors.blue,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'https://occazcar.fr/annonce/${details.annonce.id}',
                          ),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lien copié !'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _contactSeller(VehicleDetailsModel details) async {
    // Créer ou récupérer une conversation Firestore
    final sellerId = details.seller?.id ?? details.annonce.ownerId;
    final sellerName = details.seller?.name ?? 'Vendeur';
    final annonceId = details.annonce.id;
    final annonceTitre =
        '${details.annonce.vehicle.make} ${details.annonce.vehicle.model}';

    debugPrint('📞 _contactSeller called');
    debugPrint('  - sellerId: $sellerId');
    debugPrint('  - sellerName: $sellerName');
    debugPrint('  - annonceId: $annonceId');
    debugPrint('  - annonceTitre: $annonceTitre');
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
    );

    try {
      // Créer une vraie conversation dans Firestore
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .startConversation(
            sellerId: sellerId,
            annonceId: annonceId,
            annonceTitre: annonceTitre,
          );

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatPage(
                conversationId: conversation?.id,
                peerId: sellerId,
                currentUserId:
                    ref.read(conversationsProvider.notifier).currentUserId ??
                    'user',
                peerName: sellerName,
              ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ _contactSeller error: $e');
      debugPrint('📋 Stack: $stackTrace');
      
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _callSeller(String phone) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Appeler'),
            content: Text(phone),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Numéro copié !'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Copier'),
              ),
            ],
          ),
    );
  }

  void _bookTestDrive(VehicleDetailsModel details) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookTestDrivePage(details: details),
      ),
    );
  }

  void _showAllSpecs(VehicleFeatures features) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Titre
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toutes les caractéristiques',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Liste des caractéristiques
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSpecRow(
                        'Carburant',
                        features.fuelType ?? 'Essence',
                        Icons.local_gas_station,
                      ),
                      _buildSpecRow(
                        'Puissance',
                        '${features.horsePower ?? 130} CV',
                        Icons.speed,
                      ),
                      _buildSpecRow(
                        'Boîte de vitesses',
                        features.transmission ?? 'Manuelle',
                        Icons.settings,
                      ),
                      _buildSpecRow(
                        'Portes',
                        '${features.doors ?? 5} portes',
                        Icons.door_front_door,
                      ),
                      _buildSpecRow(
                        'Places',
                        '${features.seats ?? 5} places',
                        Icons.event_seat,
                      ),
                      _buildSpecRow(
                        'Couleur',
                        features.color ?? 'Non spécifié',
                        Icons.palette,
                      ),
                      _buildSpecRow(
                        'Énergie',
                        features.energy ?? 'C',
                        Icons.eco,
                      ),
                      _buildSpecRow(
                        'Climatisation',
                        features.hasAirConditioning ? 'Oui' : 'Non',
                        Icons.ac_unit,
                      ),
                      _buildSpecRow(
                        'GPS',
                        features.hasGPS ? 'Oui' : 'Non',
                        Icons.gps_fixed,
                      ),
                      _buildSpecRow(
                        'Radar de recul',
                        features.hasParkingSensors ? 'Oui' : 'Non',
                        Icons.sensors,
                      ),
                      _buildSpecRow(
                        'Bluetooth',
                        features.hasBluetoothPhone ? 'Oui' : 'Non',
                        Icons.bluetooth,
                      ),

                      if (features.otherFeatures.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Autres équipements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              features.otherFeatures
                                  .map(
                                    (feature) => Chip(
                                      label: Text(feature),
                                      backgroundColor: AppColors.primary
                                          .withAlpha((0.1 * 255).round()),
                                      labelStyle: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} €';
  }

  String _formatMileage(int mileage) {
    return '${mileage.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} km';
  }
}
