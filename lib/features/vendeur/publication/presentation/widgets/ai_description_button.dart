import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/publication_provider.dart';

/// Bouton pour générer une description avec l'IA
class AIDescriptionButton extends ConsumerStatefulWidget {
  final TextEditingController descriptionController;
  final VoidCallback? onDescriptionGenerated;

  const AIDescriptionButton({
    super.key,
    required this.descriptionController,
    this.onDescriptionGenerated,
  });

  @override
  ConsumerState<AIDescriptionButton> createState() => _AIDescriptionButtonState();
}

class _AIDescriptionButtonState extends ConsumerState<AIDescriptionButton> {
  bool _isGenerating = false;

  Future<void> _generateDescription() async {
    setState(() => _isGenerating = true);

    try {
      final description = await ref.read(publicationProvider.notifier).generateAIDescription();
      widget.descriptionController.text = description;
      widget.onDescriptionGenerated?.call();
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.blue.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isGenerating ? null : _generateDescription,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Générer avec l\'IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isGenerating 
                        ? 'Génération en cours...'
                        : 'Créez une description attractive automatiquement',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.8 * 255).round()),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isGenerating)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withAlpha((0.8 * 255).round()),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher les outils marketing IA
class AIMarketingTools extends StatelessWidget {
  final VoidCallback? onGeneratePhotos;
  final VoidCallback? onGenerateDamageReport;
  final VoidCallback? onSuggestPrice;

  const AIMarketingTools({
    super.key,
    this.onGeneratePhotos,
    this.onGenerateDamageReport,
    this.onSuggestPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple.shade400),
              const SizedBox(width: 8),
              const Text(
                'Outils Marketing IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToolItem(
            Icons.camera_enhance,
            'Photos professionnelles',
            'Améliorez vos photos automatiquement',
            onGeneratePhotos,
          ),
          _buildToolItem(
            Icons.assessment,
            'Rapport de dégâts',
            'Analysez l\'état du véhicule',
            onGenerateDamageReport,
          ),
          _buildToolItem(
            Icons.price_check,
            'Estimation de prix',
            'Obtenez une suggestion de prix',
            onSuggestPrice,
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
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
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
