import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/alerte_recherche_model.dart';
import '../../../../../data/models/notification_model.dart';
import '../providers/alertes_provider.dart';
import '../../../../notifications/presentation/providers/notifications_provider.dart';
import 'creer_alerte_page.dart';

class AlertesPage extends ConsumerStatefulWidget {
  const AlertesPage({super.key});

  @override
  ConsumerState<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends ConsumerState<AlertesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alertesProvider.notifier).loadAlertes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes alertes'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton test notification
          IconButton(
            icon: const Icon(Icons.notification_add, color: Colors.orange),
            onPressed: () => _testerNotification(),
            tooltip: 'Tester notification',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _creerAlerte(),
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_alertes',
        onPressed: () => _creerAlerte(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert),
        label: const Text('Nouvelle alerte'),
      ),
    );
  }

  Widget _buildBody(AlertesState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(state.error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(alertesProvider.notifier).loadAlertes(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.alertes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(alertesProvider.notifier).loadAlertes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.alertes.length,
        itemBuilder: (context, index) {
          return _AlerteCard(
            alerte: state.alertes[index],
            onToggle: () => ref
                .read(alertesProvider.notifier)
                .toggleAlerte(state.alertes[index].id),
            onDelete: () => _confirmerSuppression(state.alertes[index]),
            onEdit: () => _modifierAlerte(state.alertes[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune alerte configurée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Créez des alertes pour être notifié dès qu\'un véhicule correspondant à vos critères est mis en vente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _creerAlerte(),
              icon: const Icon(Icons.add),
              label: const Text('Créer ma première alerte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _creerAlerte() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CreerAlertePage()),
    );

    if (result == true && mounted) {
      ref.read(alertesProvider.notifier).loadAlertes();
    }
  }

  Future<void> _modifierAlerte(AlerteRechercheModel alerte) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreerAlertePage(alerteExistante: alerte),
      ),
    );

    if (result == true && mounted) {
      ref.read(alertesProvider.notifier).loadAlertes();
    }
  }

  Future<void> _confirmerSuppression(AlerteRechercheModel alerte) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: Text('Voulez-vous vraiment supprimer l\'alerte "${alerte.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(alertesProvider.notifier).deleteAlerte(alerte.id);
    }
  }

  /// Méthode pour tester le système de notifications
  Future<void> _testerNotification() async {
    try {
      await ref.read(notificationsProvider.notifier).createNotification(
        userId: 'test_user', // À remplacer par l'ID utilisateur actuel
        title: '🧪 Test de notification',
        body: 'Cette notification confirme que le système fonctionne correctement!',
        type: NotificationType.system,
        data: {
          'testTime': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification de test envoyée!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AlerteCard extends StatelessWidget {
  final AlerteRechercheModel alerte;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AlerteCard({
    required this.alerte,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: alerte.actif
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      alerte.actif
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: alerte.actif ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alerte.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alerte.resumeCriteres,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: alerte.actif,
                    onChanged: (_) => onToggle(),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.schedule,
                    alerte.frequenceLabel,
                  ),
                  const SizedBox(width: 12),
                  if (alerte.matchCount > 0)
                    _buildInfoChip(
                      Icons.directions_car,
                      '${alerte.matchCount} véhicule${alerte.matchCount > 1 ? 's' : ''}',
                      color: AppColors.primary,
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: Colors.red[400],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
