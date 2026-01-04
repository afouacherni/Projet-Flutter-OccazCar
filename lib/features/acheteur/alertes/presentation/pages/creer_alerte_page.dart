import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/alerte_recherche_model.dart';
import '../providers/alertes_provider.dart';

class CreerAlertePage extends ConsumerStatefulWidget {
  final AlerteRechercheModel? alerteExistante;

  const CreerAlertePage({super.key, this.alerteExistante});

  @override
  ConsumerState<CreerAlertePage> createState() => _CreerAlertePageState();
}

class _CreerAlertePageState extends ConsumerState<CreerAlertePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();

  String? _marque;
  String? _modele;
  RangeValues _prixRange = const RangeValues(0, 50000);
  RangeValues _anneeRange = const RangeValues(2015, 2024);
  int? _kilometrageMax;
  String? _carburant;
  String? _transmission;
  FrequenceAlerte _frequence = FrequenceAlerte.immediate;
  bool _isLoading = false;

  final _marques = [
    'Audi',
    'BMW',
    'Citroën',
    'Dacia',
    'Fiat',
    'Ford',
    'Honda',
    'Hyundai',
    'Kia',
    'Mercedes',
    'Nissan',
    'Opel',
    'Peugeot',
    'Renault',
    'Seat',
    'Skoda',
    'Toyota',
    'Volkswagen',
    'Volvo',
  ];

  final _carburants = ['Essence', 'Diesel', 'Hybride', 'Électrique', 'GPL'];
  final _transmissions = ['Manuelle', 'Automatique'];

  @override
  void initState() {
    super.initState();
    if (widget.alerteExistante != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final a = widget.alerteExistante!;
    _nomController.text = a.nom;
    _marque = a.marque;
    _modele = a.modele;
    _carburant = a.carburant;
    _transmission = a.transmission;
    _frequence = a.frequence;

    if (a.prixMin != null || a.prixMax != null) {
      _prixRange = RangeValues(a.prixMin ?? 0, a.prixMax ?? 100000);
    }
    if (a.anneeMin != null || a.anneeMax != null) {
      _anneeRange = RangeValues(
        (a.anneeMin ?? 2010).toDouble(),
        (a.anneeMax ?? 2024).toDouble(),
      );
    }
    _kilometrageMax = a.kilometrageMax;
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.alerteExistante != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier l\'alerte' : 'Nouvelle alerte'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNomSection(),
            const SizedBox(height: 24),
            _buildMarqueSection(),
            const SizedBox(height: 24),
            _buildBudgetSection(),
            const SizedBox(height: 24),
            _buildAnneeSection(),
            const SizedBox(height: 24),
            _buildKilometrageSection(),
            const SizedBox(height: 24),
            _buildCarburantSection(),
            const SizedBox(height: 24),
            _buildTransmissionSection(),
            const SizedBox(height: 24),
            _buildFrequenceSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(isEdit),
            const SizedBox(height: 24),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildNomSection() {
    return _buildSection(
      title: 'Nom de l\'alerte',
      icon: Icons.label_outline,
      child: TextFormField(
        controller: _nomController,
        decoration: InputDecoration(
          hintText: 'Ex: SUV familial économique',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez donner un nom à votre alerte';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMarqueSection() {
    return _buildSection(
      title: 'Marque',
      icon: Icons.directions_car_outlined,
      child: DropdownButtonFormField<String>(
        value: _marque,
        decoration: InputDecoration(
          hintText: 'Toutes les marques',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Toutes les marques'),
          ),
          ..._marques.map((m) => DropdownMenuItem(value: m, child: Text(m))),
        ],
        onChanged: (value) => setState(() => _marque = value),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return _buildSection(
      title: 'Budget',
      icon: Icons.euro_outlined,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_prixRange.start.toInt()} €',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${_prixRange.end.toInt()} €',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          RangeSlider(
            values: _prixRange,
            min: 0,
            max: 100000,
            divisions: 100,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              '${_prixRange.start.toInt()} €',
              '${_prixRange.end.toInt()} €',
            ),
            onChanged: (values) => setState(() => _prixRange = values),
          ),
        ],
      ),
    );
  }

  Widget _buildAnneeSection() {
    return _buildSection(
      title: 'Année',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_anneeRange.start.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${_anneeRange.end.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          RangeSlider(
            values: _anneeRange,
            min: 2000,
            max: 2024,
            divisions: 24,
            activeColor: AppColors.primary,
            labels: RangeLabels(
              '${_anneeRange.start.toInt()}',
              '${_anneeRange.end.toInt()}',
            ),
            onChanged: (values) => setState(() => _anneeRange = values),
          ),
        ],
      ),
    );
  }

  Widget _buildKilometrageSection() {
    return _buildSection(
      title: 'Kilométrage maximum',
      icon: Icons.speed_outlined,
      child: DropdownButtonFormField<int?>(
        value: _kilometrageMax,
        decoration: InputDecoration(
          hintText: 'Pas de limite',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Pas de limite')),
          const DropdownMenuItem(value: 50000, child: Text('< 50 000 km')),
          const DropdownMenuItem(value: 100000, child: Text('< 100 000 km')),
          const DropdownMenuItem(value: 150000, child: Text('< 150 000 km')),
          const DropdownMenuItem(value: 200000, child: Text('< 200 000 km')),
        ],
        onChanged: (value) => setState(() => _kilometrageMax = value),
      ),
    );
  }

  Widget _buildCarburantSection() {
    return _buildSection(
      title: 'Carburant',
      icon: Icons.local_gas_station_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            _carburants.map((c) {
              final selected = _carburant == c;
              return FilterChip(
                label: Text(c),
                selected: selected,
                onSelected: (val) {
                  setState(() => _carburant = val ? c : null);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTransmissionSection() {
    return _buildSection(
      title: 'Transmission',
      icon: Icons.settings_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            _transmissions.map((t) {
              final selected = _transmission == t;
              return FilterChip(
                label: Text(t),
                selected: selected,
                onSelected: (val) {
                  setState(() => _transmission = val ? t : null);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFrequenceSection() {
    return _buildSection(
      title: 'Fréquence des notifications',
      icon: Icons.notifications_outlined,
      child: Column(
        children:
            FrequenceAlerte.values.map((f) {
              return RadioListTile<FrequenceAlerte>(
                value: f,
                groupValue: _frequence,
                title: Text(_getFrequenceLabel(f)),
                subtitle: Text(
                  _getFrequenceDescription(f),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                onChanged: (val) => setState(() => _frequence = val!),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
      ),
    );
  }

  String _getFrequenceLabel(FrequenceAlerte f) {
    switch (f) {
      case FrequenceAlerte.immediate:
        return 'Immédiate';
      case FrequenceAlerte.quotidienne:
        return 'Quotidienne';
      case FrequenceAlerte.hebdomadaire:
        return 'Hebdomadaire';
    }
  }

  String _getFrequenceDescription(FrequenceAlerte f) {
    switch (f) {
      case FrequenceAlerte.immediate:
        return 'Notifié dès qu\'une annonce correspond';
      case FrequenceAlerte.quotidienne:
        return 'Résumé chaque jour à 9h';
      case FrequenceAlerte.hebdomadaire:
        return 'Résumé chaque lundi';
    }
  }

  Widget _buildSubmitButton(bool isEdit) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  isEdit ? 'Enregistrer les modifications' : 'Créer l\'alerte',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(alertesProvider.notifier)
        .createAlerteFromFilters(
          nom: _nomController.text.trim(),
          marque: _marque,
          modele: _modele,
          prixMin: _prixRange.start,
          prixMax: _prixRange.end,
          anneeMin: _anneeRange.start.toInt(),
          anneeMax: _anneeRange.end.toInt(),
          kilometrageMax: _kilometrageMax,
          carburant: _carburant,
          transmission: _transmission,
          frequence: _frequence,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerte créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
