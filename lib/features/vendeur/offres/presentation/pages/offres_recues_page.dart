import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/offres_provider.dart';
import '../widgets/offre_card.dart';

/// Page des offres reçues par le vendeur
class OffresRecuesPage extends ConsumerStatefulWidget {
  const OffresRecuesPage({super.key});

  @override
  ConsumerState<OffresRecuesPage> createState() => _OffresRecuesPageState();
}

class _OffresRecuesPageState extends ConsumerState<OffresRecuesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les offres au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offresProvider.notifier).loadOffres();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offresProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offres Reçues'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('En attente'),
                  if (state.offresPendantes.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.offresPendantes.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Acceptées'),
            const Tab(text: 'Refusées'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(state.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOffresList(state.offresPendantes, isPending: true),
                    _buildOffresList(state.offresAcceptees),
                    _buildOffresList(state.offresRefusees),
                  ],
                ),
    );
  }

  Widget _buildOffresList(List<OffreModel> offres, {bool isPending = false}) {
    if (offres.isEmpty) {
      return _buildEmptyState(isPending);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(offresProvider.notifier).loadOffres();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offres.length,
        itemBuilder: (context, index) {
          final offre = offres[index];
          return OffreCard(
            offre: offre,
            showActions: isPending,
            onAccept: () => _accepterOffre(offre),
            onReject: () => _refuserOffre(offre),
            onContact: () => _contacterAcheteur(offre),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.inbox_outlined : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'Aucune offre en attente' : 'Aucune offre dans cette catégorie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Les offres des acheteurs apparaîtront ici'
                : 'Vos offres traitées apparaîtront ici',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
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
              ref.read(offresProvider.notifier).loadOffres();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _accepterOffre(OffreModel offre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter l\'offre'),
        content: Text(
          'Accepter l\'offre de ${offre.acheteurNom} pour ${offre.montant.toStringAsFixed(0)} € ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(offresProvider.notifier).accepterOffre(offre.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offre acceptée !'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  void _refuserOffre(OffreModel offre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser l\'offre'),
        content: Text('Refuser l\'offre de ${offre.acheteurNom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(offresProvider.notifier).refuserOffre(offre.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offre refusée')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _contacterAcheteur(OffreModel offre) {
    // TODO: Naviguer vers la page de chat avec l'acheteur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contacter ${offre.acheteurNom}')),
    );
  }
}
