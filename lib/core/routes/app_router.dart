import 'package:flutter/material.dart';

// Pages Acheteur
import '../../features/acheteur/recherche/presentation/pages/recherche_page.dart';
import '../../features/acheteur/favoris/presentation/pages/favoris_page.dart';
import '../../features/acheteur/details_vehicule/presentation/pages/details_vehicule_page.dart';
import '../../features/acheteur/alertes/presentation/pages/alertes_page.dart';
import '../../features/chat/presentation/pages/conversations_page.dart';

// Pages Vendeur
import '../../features/vendeur/presentation/pages/vendeur_home_page.dart';
import '../../features/vendeur/gestion_annonces/presentation/pages/mes_annonces_page.dart';
import '../../features/vendeur/gestion_annonces/presentation/pages/statistiques_page.dart';
import '../../features/vendeur/offres/presentation/pages/offres_recues_page.dart';
import '../../features/vendeur/publication/presentation/pages/create_annonce_page.dart';

/// Gestionnaire de routes pour l'application OccazCar
class AppRouter {
  // Routes Acheteur
  static const String home = '/';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String messages = '/messages';
  static const String alertes = '/alertes';
  static const String details = '/details';
  
  // Routes Vendeur
  static const String vendeur = '/vendeur';
  static const String vendeurAnnonces = '/vendeur/annonces';
  static const String vendeurOffres = '/vendeur/offres';
  static const String vendeurPublier = '/vendeur/publier';
  static const String vendeurStatistiques = '/vendeur/statistiques';

  /// Génère les routes nommées pour l'application
  static Map<String, WidgetBuilder> get routes => {
    search: (context) => const RecherchePage(),
    favorites: (context) => const FavorisPage(),
    messages: (context) => const ConversationsPage(),
    alertes: (context) => const AlertesPage(),
    vendeur: (context) => const VendeurHomePage(),
    vendeurAnnonces: (context) => const MesAnnoncesPage(),
    vendeurOffres: (context) => const OffresRecuesPage(),
    vendeurPublier: (context) => const CreateAnnoncePage(),
    vendeurStatistiques: (context) => const StatistiquesPage(),
  };

  /// Gère les routes dynamiques (avec paramètres)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Route pour les détails de véhicule avec ID
    if (settings.name?.startsWith('/details/') ?? false) {
      final annonceId = settings.name!.replaceFirst('/details/', '');
      return MaterialPageRoute(
        builder: (context) => DetailsVehiculePage(annonceId: annonceId),
        settings: settings,
      );
    }

    // Route 404
    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(
          child: Text('Page non trouvée'),
        ),
      ),
    );
  }

  /// Navigation vers les détails d'un véhicule
  static void goToDetails(BuildContext context, String annonceId) {
    Navigator.pushNamed(context, '/details/$annonceId');
  }

  /// Navigation vers l'espace vendeur
  static void goToVendeur(BuildContext context) {
    Navigator.pushNamed(context, vendeur);
  }

  /// Navigation vers la création d'annonce
  static void goToCreateAnnonce(BuildContext context) {
    Navigator.pushNamed(context, vendeurPublier);
  }

  /// Navigation vers les offres reçues
  static void goToOffres(BuildContext context) {
    Navigator.pushNamed(context, vendeurOffres);
  }

  /// Navigation vers les messages
  static void goToMessages(BuildContext context) {
    Navigator.pushNamed(context, messages);
  }

  /// Navigation vers les alertes
  static void goToAlertes(BuildContext context) {
    Navigator.pushNamed(context, alertes);
  }
}
