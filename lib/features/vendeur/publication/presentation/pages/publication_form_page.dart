import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../providers/publication_provider.dart';
import '../widgets/vehicle_form_fields.dart';
import '../widgets/ai_description_button.dart';

/// Formulaire complet de publication d'annonce (alternative au stepper)
class PublicationFormPage extends ConsumerStatefulWidget {
  const PublicationFormPage({super.key});

  @override
  ConsumerState<PublicationFormPage> createState() => _PublicationFormPageState();
}

class _PublicationFormPageState extends ConsumerState<PublicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late TextEditingController _marqueCtrl;
  late TextEditingController _modeleCtrl;
  late TextEditingController _anneeCtrl;
  late TextEditingController _kilometrageCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _descriptionCtrl;
  
  String? _carburant;
  String? _transmission;

  @override
  void initState() {
    super.initState();
    final state = ref.read(publicationProvider);
    _marqueCtrl = TextEditingController(text: state.marque);
    _modeleCtrl = TextEditingController(text: state.modele);
    _anneeCtrl = TextEditingController(text: state.annee?.toString());
    _kilometrageCtrl = TextEditingController(text: state.kilometrage?.toString());
    _prixCtrl = TextEditingController(text: state.prix?.toStringAsFixed(0));
    _descriptionCtrl = TextEditingController(text: state.description);
    _carburant = state.carburant;
    _transmission = state.transmission;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _anneeCtrl.dispose();
    _kilometrageCtrl.dispose();
    _prixCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _updateProvider() {
    ref.read(publicationProvider.notifier).updateVehicleInfo(
      marque: _marqueCtrl.text,
      modele: _modeleCtrl.text,
      annee: int.tryParse(_anneeCtrl.text),
      kilometrage: int.tryParse(_kilometrageCtrl.text),
      carburant: _carburant,
      transmission: _transmission,
    );
    ref.read(publicationProvider.notifier).updatePrix(
      double.tryParse(_prixCtrl.text) ?? 0,
    );
    ref.read(publicationProvider.notifier).updateDescription(_descriptionCtrl.text);
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _updateProvider();
    
    // Aller directement à la publication (skip photos)
    Navigator.pushNamed(context, '/vendeur/preview');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informations du véhicule'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Section véhicule
            _buildSectionCard(
              title: 'Véhicule',
              icon: Icons.directions_car,
              child: VehicleFormFields(
                marqueController: _marqueCtrl,
                modeleController: _modeleCtrl,
                anneeController: _anneeCtrl,
                kilometrageController: _kilometrageCtrl,
                prixController: _prixCtrl,
                carburantValue: _carburant,
                transmissionValue: _transmission,
                onCarburantChanged: (v) => setState(() => _carburant = v),
                onTransmissionChanged: (v) => setState(() => _transmission = v),
              ),
            ),
            const SizedBox(height: 20),

            // Section description
            _buildSectionCard(
              title: 'Description',
              icon: Icons.description,
              child: Column(
                children: [
                  AIDescriptionButton(
                    descriptionController: _descriptionCtrl,
                    onDescriptionGenerated: () {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: 'Décrivez votre véhicule en détail...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 20) {
                        return 'Minimum 20 caractères';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options supplémentaires
            _buildSectionCard(
              title: 'Options',
              icon: Icons.tune,
              child: Column(
                children: [
                  _buildOptionTile(
                    'Négociable',
                    'Le prix est négociable',
                    Icons.handshake,
                    true,
                    (v) {},
                  ),
                  _buildOptionTile(
                    'Échange possible',
                    'Ouvert aux propositions d\'échange',
                    Icons.swap_horiz,
                    false,
                    (v) {},
                  ),
                  _buildOptionTile(
                    'Première main',
                    'Vous êtes le premier propriétaire',
                    Icons.person,
                    false,
                    (v) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        secondary: Icon(icon, color: AppColors.primary),
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveAndContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Aperçu et publication',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
