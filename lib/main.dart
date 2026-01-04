import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math' show cos, sin;
import 'firebase_options.dart';

// Import du thème
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/routes/app_router.dart' as app_router;
import 'features/auth/presentation/pages/startup_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';

// Import du provider des annonces récentes
import 'features/acheteur/home/providers/annonces_recentes_provider.dart';

// Import du provider des notifications
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'features/notifications/services/alert_matching_service.dart';

// Import des pages de l'Interface Acheteur
import 'features/acheteur/recherche/presentation/pages/recherche_page.dart';
import 'features/acheteur/favoris/presentation/pages/favoris_page.dart';
import 'features/acheteur/details_vehicule/presentation/pages/details_vehicule_page.dart';
import 'features/acheteur/alertes/presentation/pages/alertes_page.dart';
import 'features/chat/presentation/pages/conversations_page.dart';

// Import des pages de notifications
import 'features/notifications/presentation/pages/notifications_page.dart';

// Import des pages de l'Interface Vendeur
import 'features/vendeur/presentation/pages/vendeur_home_page.dart';
import 'features/vendeur/gestion_annonces/presentation/pages/mes_annonces_page.dart';
import 'features/vendeur/offres/presentation/pages/offres_recues_page.dart';
import 'features/vendeur/publication/presentation/pages/create_annonce_page.dart';
import 'features/vendeur/gestion_annonces/presentation/pages/statistiques_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Firebase avec les options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Barre de statut transparente pour un look moderne
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Démarrer le service de matching des alertes
  AlertMatchingService().startMatching();

  runApp(const ProviderScope(child: OccazCarApp()));
}

class OccazCarApp extends StatelessWidget {
  const OccazCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OccazCar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const StartupPage(),
      routes: {
        // Merge core app routes (acheteur + vendeur)
        ...app_router.AppRouter.routes,
        // Auth routes (login/register/profile)
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/profile': (context) => const ProfilePage(),
        '/notifications': (context) => const NotificationsPage(),
        // Shortcut to main navigation after auth
        '/home': (context) => const MainNavigationPage(),
      },
      onGenerateRoute: (settings) {
        // Route pour les détails de véhicule
        if (settings.name?.startsWith('/details/') ?? false) {
          final annonceId = settings.name!.replaceFirst('/details/', '');
          return MaterialPageRoute(
            builder: (context) => DetailsVehiculePage(annonceId: annonceId),
          );
        }
        return null;
      },
    );
  }
}

/// Page principale avec navigation bottom bar
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const RecherchePage(),
    const FavorisPage(),
    const ConversationsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Accueil'),
                _buildNavItem(
                  1,
                  Icons.search_outlined,
                  Icons.search,
                  'Recherche',
                ),
                _buildNavItem(
                  2,
                  Icons.favorite_outline,
                  Icons.favorite,
                  'Favoris',
                ),
                _buildNavItem(
                  3,
                  Icons.chat_bubble_outline,
                  Icons.chat_bubble,
                  'Messages',
                ),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profil'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'switch_to_seller',
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const VendeurHomePage(),
            ),
          );
        },
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.sell, color: Colors.white),
        label: const Text(
          'Mode Vendeur',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withAlpha((0.1 * 255).round())
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page d'accueil moderne
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annoncesState = ref.watch(annoncesRecentesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec gradient
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salutation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour 👋',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha(
                                (0.9 * 255).round(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Trouvez votre voiture',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Icône notifications avec badge
                      _buildNotificationIcon(context, ref),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Barre de recherche
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/search');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400]),
                          const SizedBox(width: 12),
                          Text(
                            'Rechercher une voiture...',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Catégories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catégories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCategoryItem(
                        Icons.directions_car,
                        'Berline',
                        Colors.blue,
                      ),
                      _buildCategoryItem(
                        Icons.local_shipping,
                        'SUV',
                        Colors.orange,
                      ),
                      _buildCategoryItem(
                        Icons.electric_car,
                        'Électrique',
                        Colors.green,
                      ),
                      _buildCategoryItem(
                        Icons.sports_motorsports,
                        'Sport',
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Annonces récentes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Annonces récentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/search');
                    },
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),
          ),

          // Liste horizontale des annonces (depuis Firebase)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child:
                  annoncesState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : annoncesState.annonces.isEmpty
                      ? _buildEmptyAnnonces(ref)
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: annoncesState.annonces.length,
                        itemBuilder:
                            (context, index) => _buildAnnonceCard(
                              context,
                              annoncesState.annonces[index],
                            ),
                      ),
            ),
          ),

          // Section promotion
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha((0.8 * 255).round()),
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vendez votre voiture',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Publiez votre annonce gratuitement',
                            style: TextStyle(
                              color: Colors.white.withAlpha(
                                (0.9 * 255).round(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/vendeur');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Publier'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.sell, size: 60, color: Colors.white24),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Widget quand il n'y a pas d'annonces
  Widget _buildEmptyAnnonces(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune annonce pour le moment',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed:
                () => ref.read(annoncesRecentesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  /// Carte d'une annonce réelle depuis Firebase
  Widget _buildAnnonceCard(BuildContext context, dynamic annonce) {
    // Extraire les données de l'annonce
    final String make = annonce.vehicle?.make ?? annonce.make ?? 'Marque';
    final String model = annonce.vehicle?.model ?? annonce.model ?? 'Modèle';
    final int year = annonce.vehicle?.year ?? annonce.year ?? 2024;
    final int mileage = annonce.vehicle?.mileage ?? annonce.mileage ?? 0;
    final double price = annonce.price ?? 0;
    final String annonceId = annonce.id ?? '';

    // Récupérer les photos depuis le vehicle ou directement
    final List<String> photoUrls = annonce.vehicle?.photos ?? annonce.photos ?? [];
    
    // Générer une variation basée sur l'ID de l'annonce pour garantir la diversité
    final int variation = annonceId.isNotEmpty ? annonceId.hashCode.abs() % 10 : 0;
    
    // Toujours utiliser un placeholder généré pour éviter les problèmes d'images
    // Au lieu d'utiliser des URLs externes non fiables
    final String imageUrl = '';  // Force l'utilisation du placeholder

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/details/${annonce.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).round()),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _buildCarPlaceholder(make, model, annonceId, variation),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$make $model',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$year • ${_formatKilometrage(mileage)} km',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPrice(price)} €',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKilometrage(int km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(0)} 000';
    }
    return km.toString();
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  /// Icône de notification avec badge
  Widget _buildNotificationIcon(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);
    final unreadCount = notifState.unreadCount;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/notifications'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.2 * 255).round()),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Page de profil
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Utilisateur',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMenuItem(Icons.person_outline, 'Mon compte', () {}),
                  _buildMenuItem(Icons.history, 'Historique', () {}),
                  _buildMenuItem(
                    Icons.notifications_outlined,
                    'Mes alertes',
                    () => Navigator.of(context).pushNamed('/alertes'),
                  ),
                  _buildMenuItem(Icons.security, 'Sécurité', () {}),
                  _buildMenuItem(Icons.help_outline, 'Aide', () {}),
                  _buildMenuItem(Icons.info_outline, 'À propos', () {}),
                  const SizedBox(height: 20),
                  // Bouton Mode Vendeur
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(
                            (0.3 * 255).round(),
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.store, color: Colors.white),
                      title: const Text(
                        'Espace Vendeur',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Gérez vos annonces',
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.8 * 255).round()),
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                      onTap: () => Navigator.of(context).pushNamed('/vendeur'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.logout,
                    'Déconnexion',
                    () {},
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? Colors.red : AppColors.textLight,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Construit un placeholder coloré unique pour chaque voiture
Widget _buildCarPlaceholder(String make, String model, String annonceId, int variation) {
  // Générer une couleur unique basée sur l'ID de l'annonce
  final uniqueColor = _generateColorFromAnnonceId(annonceId, make);
  final icon = _getCarIconByBrand(make);
  final patternType = _getPatternTypeFromId(annonceId);
  
  // Utiliser l'ID pour créer des dégradés uniques
  final gradientDirection = (annonceId.hashCode % 4);
  final List<Color> gradientColors = [
    uniqueColor.withOpacity(0.8),
    uniqueColor.withOpacity(0.5),
    uniqueColor.withOpacity(0.3)
  ];
  
  Alignment beginAlignment;
  Alignment endAlignment;
  
  switch (gradientDirection) {
    case 0:
      beginAlignment = Alignment.topLeft;
      endAlignment = Alignment.bottomRight;
      break;
    case 1:
      beginAlignment = Alignment.topRight;
      endAlignment = Alignment.bottomLeft;
      break;
    case 2:
      beginAlignment = Alignment.topCenter;
      endAlignment = Alignment.bottomCenter;
      break;
    default:
      beginAlignment = Alignment.centerLeft;
      endAlignment = Alignment.centerRight;
  }
  
  return Container(
    height: 130,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: beginAlignment,
        end: endAlignment,
        colors: gradientColors,
      ),
    ),
    child: Stack(
      children: [
        // Pattern de fond unique basé sur l'ID
        Positioned.fill(
          child: CustomPaint(
            painter: UniqueCarPatternPainter(uniqueColor.withOpacity(0.15), patternType, annonceId),
          ),
        ),
        // Contenu principal
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: uniqueColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: uniqueColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: uniqueColor.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      make.toUpperCase(),
                      style: TextStyle(
                        color: uniqueColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (model.isNotEmpty && model != 'Modèle')
                      Text(
                        model.length > 10 ? '${model.substring(0, 10)}...' : model,
                        style: TextStyle(
                          color: uniqueColor.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Painter personnalisé pour créer des patterns uniques basés sur l'ID d'annonce
class UniqueCarPatternPainter extends CustomPainter {
  final Color color;
  final int patternType;
  final String annonceId;
  
  UniqueCarPatternPainter(this.color, this.patternType, this.annonceId);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Créer des patterns uniques selon l'ID de l'annonce
    switch (patternType % 6) {
      case 0:
        _drawDiagonalLines(canvas, size, paint);
        break;
      case 1:
        _drawConcentricCircles(canvas, size, paint);
        break;
      case 2:
        _drawHexagonalGrid(canvas, size, paint);
        break;
      case 3:
        _drawWavePattern(canvas, size, paint);
        break;
      case 4:
        _drawTrianglePattern(canvas, size, paint);
        break;
      case 5:
        _drawDiamondPattern(canvas, size, paint);
        break;
    }
  }
  
  void _drawDiagonalLines(Canvas canvas, Size size, Paint paint) {
    final spacing = 15 + (annonceId.hashCode.abs() % 10);
    for (int i = -10; i < (size.width + size.height) / spacing; i++) {
      canvas.drawLine(
        Offset(i * spacing.toDouble(), 0),
        Offset(i * spacing + size.height, size.height),
        paint,
      );
    }
  }
  
  void _drawConcentricCircles(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;
    final maxRadius = 60 + (annonceId.hashCode.abs() % 30);
    
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        (maxRadius / 4) * i,
        paint,
      );
    }
  }
  
  void _drawHexagonalGrid(Canvas canvas, Size size, Paint paint) {
    final spacing = 25 + (annonceId.hashCode.abs() % 15);
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing * 0.866) {
        _drawHexagon(canvas, Offset(x, y), spacing / 3, paint);
      }
    }
  }
  
  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawWavePattern(Canvas canvas, Size size, Paint paint) {
    final amplitude = 10 + (annonceId.hashCode.abs() % 10);
    final frequency = 0.02 + (annonceId.hashCode.abs() % 100) * 0.0001;
    
    for (int row = 0; row < 5; row++) {
      final y = (size.height / 6) * (row + 1);
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x <= size.width; x += 2) {
        final waveY = y + amplitude * sin(x * frequency + row);
        path.lineTo(x, waveY);
      }
      canvas.drawPath(path, paint);
    }
  }
  
  void _drawTrianglePattern(Canvas canvas, Size size, Paint paint) {
    final spacing = 30 + (annonceId.hashCode.abs() % 20);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        _drawTriangle(canvas, Offset(x, y), spacing / 3, paint);
      }
    }
  }
  
  void _drawTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx - size * 0.866, center.dy + size * 0.5);
    path.lineTo(center.dx + size * 0.866, center.dy + size * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawDiamondPattern(Canvas canvas, Size size, Paint paint) {
    final spacing = 25 + (annonceId.hashCode.abs() % 15);
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        _drawDiamond(canvas, Offset(x, y), spacing / 4, paint);
      }
    }
  }
  
  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Génère une couleur unique basée sur l'ID de l'annonce et la marque
Color _generateColorFromAnnonceId(String annonceId, String make) {
  // Commencer par la couleur de base de la marque
  final baseColor = _getColorForBrand(make);
  
  if (annonceId.isEmpty) {
    return baseColor;
  }
  
  // Utiliser le hash de l'ID pour créer des variations de couleur
  final hash = annonceId.hashCode.abs();
  final variation = hash % 5;
  
  switch (variation) {
    case 0:
      return baseColor; // Couleur de base
    case 1:
      return Color.lerp(baseColor, Colors.blue[700]!, 0.3) ?? baseColor;
    case 2:
      return Color.lerp(baseColor, Colors.purple[700]!, 0.3) ?? baseColor;
    case 3:
      return Color.lerp(baseColor, Colors.teal[700]!, 0.3) ?? baseColor;
    case 4:
      return Color.lerp(baseColor, Colors.indigo[700]!, 0.3) ?? baseColor;
    default:
      return baseColor;
  }
}

/// Génère un type de pattern basé sur l'ID de l'annonce
int _getPatternTypeFromId(String annonceId) {
  if (annonceId.isEmpty) return 0;
  return annonceId.hashCode.abs() % 6; // 6 types de patterns différents
}

/// Fonction utilitaire pour obtenir une couleur basée sur la marque
Color _getColorForBrand(String make) {
  final brandColors = {
    'Renault': const Color(0xFFFFD700), // Or
    'Peugeot': const Color(0xFF1E88E5), // Bleu
    'Citroën': const Color(0xFFE53935), // Rouge
    'BMW': const Color(0xFF0D47A1), // Bleu foncé
    'Mercedes': const Color(0xFF37474F), // Gris foncé
    'Audi': const Color(0xFFD32F2F), // Rouge foncé
    'Volkswagen': const Color(0xFF1976D2), // Bleu
    'Toyota': const Color(0xFFE53935), // Rouge
    'Ford': const Color(0xFF1565C0), // Bleu
    'Honda': const Color(0xFFD32F2F), // Rouge
    'Kia': const Color(0xFF388E3C), // Vert
    'Polo': const Color(0xFF5E35B1), // Violet
  };

  final normalizedMake = make.toLowerCase().trim();
  
  for (final brand in brandColors.keys) {
    if (normalizedMake.contains(brand.toLowerCase()) || 
        brand.toLowerCase().contains(normalizedMake)) {
      return brandColors[brand]!;
    }
  }
  
  // Couleur basée sur le hash du nom pour cohérence
  final colors = [
    const Color(0xFF2E7D32), // Vert
    const Color(0xFF1565C0), // Bleu
    const Color(0xFFE53935), // Rouge  
    const Color(0xFFFF6F00), // Orange
    const Color(0xFF6A1B9A), // Violet
    const Color(0xFF00695C), // Sarcelle
    const Color(0xFFBF360C), // Rouge profond
    const Color(0xFF4527A0), // Indigo
  ];
  
  return colors[make.hashCode.abs() % colors.length];
}

/// Fonction utilitaire pour obtenir une couleur basée sur la marque
/// Fonction utilitaire pour obtenir une icône de voiture basée sur la marque
IconData _getCarIconByBrand(String make) {
  final carIcons = {
    'BMW': Icons.electric_car,
    'Mercedes': Icons.drive_eta,
    'Audi': Icons.sports_motorsports,
    'Toyota': Icons.eco,
    'Tesla': Icons.electric_bolt,
    'Ford': Icons.local_shipping,
    'Honda': Icons.directions_car,
    'Kia': Icons.directions_car_filled,
    'Volkswagen': Icons.car_rental,
    'Renault': Icons.directions_car,
    'Peugeot': Icons.car_repair,
    'Citroën': Icons.directions_car_outlined,
  };
  
  final normalizedMake = make.toLowerCase().trim();
  for (final brand in carIcons.keys) {
    if (normalizedMake.contains(brand.toLowerCase()) || brand.toLowerCase().contains(normalizedMake)) {
      return carIcons[brand]!;
    }
  }
  
  return Icons.directions_car;
}
