import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/annonce_model.dart';

/// Page d'édition d'une annonce existante
class EditAnnoncePage extends ConsumerStatefulWidget {
  final AnnonceModel annonce;

  const EditAnnoncePage({super.key, required this.annonce});

  @override
  ConsumerState<EditAnnoncePage> createState() => _EditAnnoncePageState();
}

class _EditAnnoncePageState extends ConsumerState<EditAnnoncePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _marqueCtrl;
  late TextEditingController _modeleCtrl;
  late TextEditingController _anneeCtrl;
  late TextEditingController _kilometrageCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _descriptionCtrl;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _marqueCtrl = TextEditingController(text: widget.annonce.vehicle.make);
    _modeleCtrl = TextEditingController(text: widget.annonce.vehicle.model);
    _anneeCtrl = TextEditingController(text: widget.annonce.vehicle.year.toString());
    _kilometrageCtrl = TextEditingController(text: widget.annonce.vehicle.mileage.toString());
    _prixCtrl = TextEditingController(text: widget.annonce.price.toStringAsFixed(0));
    _descriptionCtrl = TextEditingController(text: widget.annonce.description);
  }

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implémenter la mise à jour dans Firebase
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce mise à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier l\'annonce'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos section
            _buildPhotosSection(),
            const SizedBox(height: 24),

            // Informations du véhicule
            _buildSectionTitle('Informations du véhicule'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _marqueCtrl,
              label: 'Marque',
              validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _modeleCtrl,
              label: 'Modèle',
              validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _anneeCtrl,
                    label: 'Année',
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Année invalide' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _kilometrageCtrl,
                    label: 'Kilométrage',
                    keyboardType: TextInputType.number,
                    suffix: 'km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prix
            _buildSectionTitle('Prix'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _prixCtrl,
              label: 'Prix de vente',
              keyboardType: TextInputType.number,
              suffix: '€',
              validator: (v) => double.tryParse(v ?? '') == null ? 'Prix invalide' : null,
            ),
            const SizedBox(height: 24),

            // Description
            _buildSectionTitle('Description'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionCtrl,
              label: 'Description détaillée',
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            // Bouton enregistrer
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Ajouter des photos
                },
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index == 4) {
                  return GestureDetector(
                    onTap: () {
                      // TODO: Ajouter photo
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey, size: 32),
                    ),
                  );
                }
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.directions_car, color: Colors.grey, size: 40),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Supprimer photo
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? suffix,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
