import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Widget avec les champs de formulaire pour un véhicule
class VehicleFormFields extends StatelessWidget {
  final TextEditingController marqueController;
  final TextEditingController modeleController;
  final TextEditingController anneeController;
  final TextEditingController kilometrageController;
  final TextEditingController prixController;
  final String? carburantValue;
  final String? transmissionValue;
  final ValueChanged<String?>? onCarburantChanged;
  final ValueChanged<String?>? onTransmissionChanged;

  const VehicleFormFields({
    super.key,
    required this.marqueController,
    required this.modeleController,
    required this.anneeController,
    required this.kilometrageController,
    required this.prixController,
    this.carburantValue,
    this.transmissionValue,
    this.onCarburantChanged,
    this.onTransmissionChanged,
  });

  static const List<String> carburants = [
    'Essence',
    'Diesel',
    'Électrique',
    'Hybride',
    'GPL',
    'Autre',
  ];

  static const List<String> transmissions = [
    'Manuelle',
    'Automatique',
    'Semi-automatique',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marque et Modèle
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: marqueController,
                label: 'Marque',
                hint: 'Ex: BMW, Audi...',
                prefixIcon: Icons.directions_car,
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: modeleController,
                label: 'Modèle',
                hint: 'Ex: Serie 3, A4...',
                prefixIcon: Icons.car_repair,
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Année et Kilométrage
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: anneeController,
                label: 'Année',
                hint: 'Ex: 2020',
                prefixIcon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final year = int.tryParse(v ?? '');
                  if (year == null) return 'Année invalide';
                  if (year < 1900 || year > DateTime.now().year + 1) {
                    return 'Année invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: kilometrageController,
                label: 'Kilométrage',
                hint: 'Ex: 50000',
                prefixIcon: Icons.speed,
                suffix: 'km',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carburant et Transmission
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Carburant',
                value: carburantValue,
                items: carburants,
                onChanged: onCarburantChanged,
                prefixIcon: Icons.local_gas_station,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                label: 'Transmission',
                value: transmissionValue,
                items: transmissions,
                onChanged: onTransmissionChanged,
                prefixIcon: Icons.settings,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Prix
        _buildTextField(
          controller: prixController,
          label: 'Prix de vente',
          hint: 'Ex: 25000',
          prefixIcon: Icons.euro,
          suffix: '€',
          keyboardType: TextInputType.number,
          validator: (v) {
            final price = double.tryParse(v ?? '');
            if (price == null || price <= 0) return 'Prix invalide';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    String? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    IconData? prefixIcon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
    );
  }
}

/// Widget de section de formulaire avec titre
class FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const FormSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
