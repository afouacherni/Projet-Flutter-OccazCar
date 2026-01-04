import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/models/photo_data.dart';
import '../providers/publication_provider.dart';
import '../widgets/vehicle_form_fields.dart';
import '../widgets/ai_description_button.dart';

/// Page de création d'une nouvelle annonce
class CreateAnnoncePage extends ConsumerStatefulWidget {
  const CreateAnnoncePage({super.key});

  @override
  ConsumerState<CreateAnnoncePage> createState() => _CreateAnnoncePageState();
}

class _CreateAnnoncePageState extends ConsumerState<CreateAnnoncePage> {
  final _formKey = GlobalKey<FormState>();
  final _marqueCtrl = TextEditingController();
  final _modeleCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _kilometrageCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _carburant;
  String? _transmission;
  final List<PhotoData> _photos = [];
  int _currentStep = 0;

  @override
  void dispose() {
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _anneeCtrl.dispose();
    _kilometrageCtrl.dispose();
    _prixCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicationState = ref.watch(publicationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle annonce'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          type: StepperType.horizontal,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: publicationState.isLoading 
                          ? null 
                          : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: publicationState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(_currentStep == 1 ? 'Publier' : 'Continuer'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Véhicule'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildVehicleInfoStep(),
            ),
            Step(
              title: const Text('Description'),
              isActive: _currentStep >= 1,
              state: StepState.indexed,
              content: _buildDescriptionStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          VehicleFormFields(
            marqueController: _marqueCtrl,
            modeleController: _modeleCtrl,
            anneeController: _anneeCtrl,
            kilometrageController: _kilometrageCtrl,
            prixController: _prixCtrl,
            carburantValue: _carburant,
            transmissionValue: _transmission,
            onCarburantChanged: (value) {
              setState(() => _carburant = value);
              _updateProvider();
            },
            onTransmissionChanged: (value) {
              setState(() => _transmission = value);
              _updateProvider();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final photo = PhotoData(name: image.name, bytes: bytes, path: image.path);
        setState(() => _photos.add(photo));
        ref.read(publicationProvider.notifier).addPhotoData(photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildPhotosStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Grille de photos
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _photos[index].bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _photos.removeAt(index));
                        ref.read(publicationProvider.notifier).removePhoto(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        // Bouton ajouter photo
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withAlpha(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                  SizedBox(height: 8),
                  Text(
                    'Ajouter des photos',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Conseils pour les photos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Conseils pour de bonnes photos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPhotoTip('📸', 'Prenez des photos en plein jour'),
              _buildPhotoTip('🚗', 'Photographiez tous les angles'),
              _buildPhotoTip('🔍', 'Montrez les détails importants'),
              _buildPhotoTip('✨', 'Nettoyez le véhicule avant'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.amber.shade900)),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Bouton génération IA
        AIDescriptionButton(
          descriptionController: _descriptionCtrl,
          onDescriptionGenerated: () {
            ref.read(publicationProvider.notifier)
                .updateDescription(_descriptionCtrl.text);
          },
        ),
        const SizedBox(height: 16),
        // Champ description
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 8,
          maxLength: 2000,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Décrivez votre véhicule en détail...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white,
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
            if (v == null || v.length < 50) {
              return 'La description doit contenir au moins 50 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Résumé de l'annonce
        _buildAnnonceSummary(),
      ],
    );
  }

  Widget _buildAnnonceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de votre annonce',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          _buildSummaryRow('Véhicule', '${_marqueCtrl.text} ${_modeleCtrl.text}'),
          _buildSummaryRow('Année', _anneeCtrl.text),
          _buildSummaryRow('Kilométrage', '${_kilometrageCtrl.text} km'),
          _buildSummaryRow('Prix', '${_prixCtrl.text} €'),
          _buildSummaryRow('Photos', '${_photos.length} photo(s)'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
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
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Valider les infos véhicule
      if (_marqueCtrl.text.isEmpty || _modeleCtrl.text.isEmpty ||
          _anneeCtrl.text.isEmpty || _prixCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
        );
        return;
      }
      _updateProvider();
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Publier l'annonce
      _publishAnnonce();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _publishAnnonce() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(publicationProvider.notifier).updateDescription(_descriptionCtrl.text);

    final success = await ref.read(publicationProvider.notifier).publishAnnonce();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce publiée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.read(publicationProvider.notifier).reset();
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = ref.read(publicationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Erreur lors de la publication'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
