import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../gestion_annonces/presentation/pages/mes_annonces_page.dart';
import '../../gestion_annonces/presentation/pages/statistiques_page.dart';
import '../../offres/presentation/pages/offres_recues_page.dart';
import '../../publication/presentation/pages/create_annonce_page.dart';
import '../../../chat/presentation/pages/conversations_page.dart';

/// Page principale de l'interface vendeur avec bottom navigation
class VendeurHomePage extends StatefulWidget {
  const VendeurHomePage({super.key});

  @override
  State<VendeurHomePage> createState() => _VendeurHomePageState();
}

class _VendeurHomePageState extends State<VendeurHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const VendeurDashboard(),
    const MesAnnoncesPage(),
    const OffresRecuesPage(),
    const ConversationsPage(),
    const VendeurProfilPage(),
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
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau'),
                _buildNavItem(1, Icons.directions_car_outlined, Icons.directions_car, 'Annonces'),
                _buildNavItem(2, Icons.local_offer_outlined, Icons.local_offer, 'Offres'),
                _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profil'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton de basculement vers l'interface acheteur
          FloatingActionButton(
            heroTag: 'switch_to_buyer',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MainNavigationPage(),
                ),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.search, color: Colors.white),
          ),
          if (_currentIndex == 0 || _currentIndex == 1) ...[
            const SizedBox(height: 16),
            // Bouton de publication
            FloatingActionButton.extended(
              heroTag: 'fab_vendeur_home',
              onPressed: () => _navigateToCreateAnnonce(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Publier'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
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

  void _navigateToCreateAnnonce() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAnnoncePage()),
    );
  }
}

/// Dashboard du vendeur
class VendeurDashboard extends StatelessWidget {
  const VendeurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, Vendeur 👋',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha((0.9 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Espace Vendeur',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.white),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Statistiques rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aperçu rapide',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickStat('3', 'Annonces\nactives', Icons.directions_car, Colors.blue),
                      const SizedBox(width: 12),
                      _buildQuickStat('5', 'Offres\nen attente', Icons.local_offer, Colors.orange),
                      const SizedBox(width: 12),
                      _buildQuickStat('12', 'Messages\nnon lus', Icons.chat_bubble, AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'Publier une annonce',
                          Icons.add_circle_outline,
                          AppColors.primary,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateAnnoncePage()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'Voir statistiques',
                          Icons.bar_chart,
                          AppColors.info,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StatistiquesPage()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Dernières activités
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dernières activités',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    'Nouvelle offre reçue',
                    'Jean D. a fait une offre de 22 000 €',
                    Icons.local_offer,
                    Colors.orange,
                    'Il y a 2h',
                  ),
                  _buildActivityItem(
                    'Nouveau message',
                    'Marie M. vous a envoyé un message',
                    Icons.chat_bubble,
                    AppColors.primary,
                    'Il y a 5h',
                  ),
                  _buildActivityItem(
                    'Annonce vue',
                    'Votre BMW Serie 3 a été vue 15 fois',
                    Icons.visibility,
                    Colors.blue,
                    'Aujourd\'hui',
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page profil vendeur
class VendeurProfilPage extends StatelessWidget {
  const VendeurProfilPage({super.key});

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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.store, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vendeur Pro',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'vendeur@example.com',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Compte Professionnel',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
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
                  _buildMenuItem(Icons.store_outlined, 'Mon entreprise', () {}),
                  _buildMenuItem(Icons.payment_outlined, 'Abonnement', () {}),
                  _buildMenuItem(Icons.bar_chart_outlined, 'Statistiques', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatistiquesPage()),
                    );
                  }),
                  _buildMenuItem(Icons.settings_outlined, 'Paramètres', () {}),
                  _buildMenuItem(Icons.help_outline, 'Aide & Support', () {}),
                  const SizedBox(height: 20),
                  _buildMenuItem(Icons.swap_horiz, 'Mode Acheteur', () {
                    // Retour au mode acheteur avec navigation consistante
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  }),
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
