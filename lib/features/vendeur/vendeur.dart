/// Module Vendeur - Exports pour l'interface vendeur OccazCar
library vendeur;

/// Ce module contient toutes les fonctionnalités pour les vendeurs:
/// - Publication et gestion des annonces
/// - Gestion des offres reçues
/// - Outils de marketing (IA)
/// - Statistiques et tableau de bord

// Pages principales
export 'presentation/pages/vendeur_home_page.dart';

// Gestion des annonces
export 'gestion_annonces/presentation/pages/mes_annonces_page.dart';
export 'gestion_annonces/presentation/pages/edit_annonce_page.dart';
export 'gestion_annonces/presentation/pages/statistiques_page.dart';
export 'gestion_annonces/presentation/providers/gestion_provider.dart';
export 'gestion_annonces/presentation/widgets/annonce_card.dart';
export 'gestion_annonces/presentation/widgets/stats_chart.dart';

// Publication
export 'publication/presentation/pages/create_annonce_page.dart';
export 'publication/presentation/providers/publication_provider.dart';
export 'publication/presentation/widgets/vehicle_form_fields.dart';
export 'publication/presentation/widgets/photo_picker_widget.dart';
export 'publication/presentation/widgets/ai_description_button.dart';

// Offres
export 'offres/presentation/pages/offres_recues_page.dart';
export 'offres/presentation/providers/offres_provider.dart';
export 'offres/presentation/widgets/offre_card.dart';
