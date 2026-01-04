import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/gestion_provider.dart';
import '../widgets/annonce_card.dart';
import 'edit_annonce_page.dart';
import '../../../publication/presentation/pages/create_annonce_page.dart';

/// Page "Mes Annonces" pour le vendeur
class MesAnnoncesPage extends ConsumerStatefulWidget {
  const MesAnnoncesPage({super.key});

  @override
  ConsumerState<MesAnnoncesPage> createState() => _MesAnnoncesPageState();
}

class _MesAnnoncesPageState extends ConsumerState<MesAnnoncesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les annonces au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gestionAnnoncesProvider.notifier).loadMesAnnonces();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gestionAnnoncesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Annonces'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Actives'),
            Tab(text: 'Inactives'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(gestionAnnoncesProvider.notifier).loadMesAnnonces();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(state.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnnoncesList(state.annonces),
                    _buildAnnoncesList(state.annonces), // TODO: filtrer actives
                    _buildAnnoncesList([]), // TODO: filtrer inactives
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_mes_annonces',
        onPressed: () => _navigateToCreateAnnonce(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle annonce'),
      ),
    );
  }

  Widget _buildAnnoncesList(List annonces) {
    if (annonces.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gestionAnnoncesProvider.notifier).loadMesAnnonces();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: annonces.length,
        itemBuilder: (context, index) {
          final annonce = annonces[index];
          return AnnonceVendeurCard(
            annonce: annonce,
            onEdit: () => _navigateToEdit(annonce),
            onDelete: () => _confirmDelete(annonce.id),
            onToggleStatus: () => _toggleStatus(annonce.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Publiez votre première annonce !',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateAnnonce(),
            icon: const Icon(Icons.add),
            label: const Text('Créer une annonce'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(error, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(gestionAnnoncesProvider.notifier).loadMesAnnonces();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateAnnonce() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAnnoncePage()),
    );
  }

  void _navigateToEdit(dynamic annonce) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAnnoncePage(annonce: annonce),
      ),
    );
  }

  void _confirmDelete(String annonceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette annonce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gestionAnnoncesProvider.notifier).deleteAnnonce(annonceId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Annonce supprimée')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(String annonceId) {
    ref.read(gestionAnnoncesProvider.notifier).toggleAnnonceStatus(annonceId);
  }
}
