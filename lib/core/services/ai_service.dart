class AIService {
  AIService();

  /// Génère une description automatique pour un véhicule
  Future<String> generateDescription({
    String? marque,
    String? modele,
    int? annee,
    int? kilometrage,
    Map<String, dynamic>? vehicleData,
  }) async {
    // Utiliser les paramètres nommés ou les données du map
    final make = marque ?? vehicleData?['make'] ?? '';
    final model = modele ?? vehicleData?['model'] ?? '';
    final year = annee ?? vehicleData?['year'] ?? '';
    final mileage = kilometrage ?? vehicleData?['mileage'] ?? 0;

    // Simulation de traitement
    await Future.delayed(const Duration(milliseconds: 500));

    return '''
Superbe $make $model de $year ! 

Ce véhicule en excellent état affiche seulement $mileage km au compteur. 
Entretenu avec soin, il vous garantit des années de conduite sans souci.

✅ Historique complet disponible
✅ Contrôle technique à jour  
✅ Première main
✅ Jamais accidenté

N'hésitez pas à me contacter pour plus d'informations ou organiser un essai !
'''.trim();
  }

  /// Génère un rapport de dégâts basé sur des photos
  Future<String> generateDamageReport(List<String> photoUrls) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return '''
📋 RAPPORT D'ÉTAT DU VÉHICULE

🟢 Carrosserie : Excellent état général
🟢 Peinture : Aucune rayure visible
🟢 Pare-brise : Intact, sans impact
🟡 Jantes : Légères traces d'usure normale
🟢 Intérieur : Très propre, bien entretenu

Note globale : ⭐⭐⭐⭐⭐ (5/5)

Véhicule recommandé pour l'achat.
'''.trim();
  }

  /// Analyse les préférences utilisateur pour des suggestions
  Future<List<String>> generateRecommendations(Map<String, dynamic> userPrefs) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return [
      'Renault Clio - Parfait pour la ville',
      'Peugeot 208 - Économique et fiable', 
      'Toyota Yaris - Très bonne revente',
      'Citroën C3 - Confort optimal'
    ];
  }
}
