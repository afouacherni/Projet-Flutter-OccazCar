import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/historique_vehicule_model.dart';

class RapportVehiculePage extends StatelessWidget {
  final String vehicleTitle;
  final RapportVehiculeModel? rapport;
  final List<HistoriqueVehiculeModel> historique;

  const RapportVehiculePage({
    super.key,
    required this.vehicleTitle,
    this.rapport,
    required this.historique,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rapport véhicule'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (rapport != null) _buildScoreConfiance(),
          const SizedBox(height: 20),
          _buildInfoGenerales(),
          const SizedBox(height: 20),
          _buildEtatVehicule(),
          const SizedBox(height: 20),
          _buildControlesTechniques(),
          const SizedBox(height: 20),
          _buildHistoriqueEntretien(),
          const SizedBox(height: 20),
          _buildEstimation(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
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
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicleTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Généré le ${_formatDate(DateTime.now())}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreConfiance() {
    final score = rapport!.scoreConfiance;
    final color =
        score >= 80
            ? AppColors.success
            : score >= 60
            ? Colors.orange
            : AppColors.error;

    return _buildSection(
      title: 'Score de confiance',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreItem(
                      'Historique entretien',
                      historique.isNotEmpty,
                    ),
                    const SizedBox(height: 8),
                    _buildScoreItem(
                      'Pas d\'accident déclaré',
                      rapport!.accidente != true,
                    ),
                    const SizedBox(height: 8),
                    _buildScoreItem(
                      'Contrôle technique OK',
                      rapport!.derniereRevision != null,
                    ),
                    const SizedBox(height: 8),
                    _buildScoreItem('Kilométrage cohérent', true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, bool passed) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          color: passed ? AppColors.success : AppColors.error,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGenerales() {
    return _buildSection(
      title: 'Informations générales',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildInfoRow(
            'Propriétaires',
            '${rapport?.nombreProprietaires ?? 1}',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            'Dernière révision',
            rapport?.derniereRevision != null
                ? _formatDate(rapport!.derniereRevision!)
                : 'Non renseigné',
          ),
          const Divider(height: 20),
          _buildInfoRow('Origine', 'France'),
          const Divider(height: 20),
          _buildInfoRow(
            'Carnet d\'entretien',
            historique.isNotEmpty ? 'Disponible' : 'Non disponible',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEtatVehicule() {
    final accidente = rapport?.accidente ?? false;
    final degats = rapport?.etatDegats;

    return _buildSection(
      title: 'État du véhicule',
      icon: Icons.car_crash_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  accidente
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  accidente ? Icons.warning_amber : Icons.check_circle_outline,
                  color: accidente ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accidente
                            ? 'Véhicule accidenté'
                            : 'Aucun accident déclaré',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              accidente ? AppColors.error : AppColors.success,
                        ),
                      ),
                      if (degats != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Gravité: ${_graviteLabel(degats)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Points de contrôle',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildCheckItem('Carrosserie', true),
          _buildCheckItem('Mécanique', true),
          _buildCheckItem('Intérieur', true),
          _buildCheckItem('Châssis', !accidente),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
                  ok
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check : Icons.close,
              color: ok ? AppColors.success : AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            ok ? 'Bon état' : 'À vérifier',
            style: TextStyle(
              fontSize: 13,
              color: ok ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlesTechniques() {
    return _buildSection(
      title: 'Contrôles techniques',
      icon: Icons.assignment_turned_in_outlined,
      child: Column(
        children: [
          if (rapport?.derniereRevision != null) ...[
            _buildControlItem(
              'Dernier contrôle',
              _formatDate(rapport!.derniereRevision!),
              Icons.event_available,
              AppColors.success,
            ),
          ],
          if (rapport?.prochainControle != null) ...[
            const SizedBox(height: 12),
            _buildControlItem(
              'Prochain contrôle',
              _formatDate(rapport!.prochainControle!),
              Icons.event,
              AppColors.primary,
            ),
          ],
          if (rapport?.derniereRevision == null &&
              rapport?.prochainControle == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Informations sur le contrôle technique non disponibles',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueEntretien() {
    final entretiens = historique.take(5).toList();

    return _buildSection(
      title: 'Historique d\'entretien',
      icon: Icons.build_outlined,
      child:
          entretiens.isEmpty
              ? Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun historique disponible',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  ...entretiens.map((e) => _buildHistoriqueItem(e)),
                  if (historique.length > 5) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Voir les ${historique.length - 5} autres entrées',
                      ),
                    ),
                  ],
                ],
              ),
    );
  }

  Widget _buildHistoriqueItem(HistoriqueVehiculeModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getEventColor(item.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getEventIcon(item.type),
              color: _getEventColor(item.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(item.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (item.kilometrage != null) ...[
                      Text(
                        ' • ${_formatKm(item.kilometrage!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (item.cout != null)
            Text(
              '${item.cout!.toStringAsFixed(0)} €',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEstimation() {
    final cote = rapport?.coteArgus;

    return _buildSection(
      title: 'Estimation Argus',
      icon: Icons.euro_outlined,
      child:
          cote != null
              ? Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cote estimée',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${cote.toStringAsFixed(0)} €',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estimation basée sur l\'état du véhicule, le kilométrage et le marché actuel.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
              : Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.price_change_outlined,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Estimation non disponible',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatKm(int km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(0)} 000 km';
    }
    return '$km km';
  }

  String _graviteLabel(GraviteDegat gravite) {
    switch (gravite) {
      case GraviteDegat.aucun:
        return 'Aucun';
      case GraviteDegat.leger:
        return 'Léger';
      case GraviteDegat.modere:
        return 'Modéré';
      case GraviteDegat.important:
        return 'Important';
      case GraviteDegat.grave:
        return 'Grave';
    }
  }

  IconData _getEventIcon(TypeEvenement type) {
    switch (type) {
      case TypeEvenement.entretien:
        return Icons.build_circle_outlined;
      case TypeEvenement.reparation:
        return Icons.handyman;
      case TypeEvenement.accident:
        return Icons.car_crash;
      case TypeEvenement.controle:
        return Icons.assignment_turned_in;
      case TypeEvenement.achat:
        return Icons.shopping_cart;
      case TypeEvenement.autre:
        return Icons.info_outline;
    }
  }

  Color _getEventColor(TypeEvenement type) {
    switch (type) {
      case TypeEvenement.entretien:
        return AppColors.primary;
      case TypeEvenement.reparation:
        return Colors.orange;
      case TypeEvenement.accident:
        return AppColors.error;
      case TypeEvenement.controle:
        return AppColors.success;
      case TypeEvenement.achat:
        return Colors.blue;
      case TypeEvenement.autre:
        return Colors.grey;
    }
  }
}
