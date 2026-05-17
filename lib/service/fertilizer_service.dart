// service/fertilizer_service.dart

import 'dart:math';
import '../models/fertilizer_model.dart';

class FertilizerService {
  // Données de base pour différentes cultures (en kg/ha)
  static const Map<String, Map<String, double>> cropNutrientNeeds = {
    'blé': {'N': 150, 'P': 60, 'K': 80},
    'maïs': {'N': 180, 'P': 80, 'K': 120},
    'tomate': {'N': 120, 'P': 100, 'K': 200},
    'pomme_de_terre': {'N': 130, 'P': 70, 'K': 250},
    'riz': {'N': 100, 'P': 50, 'K': 60},
    'coton': {'N': 120, 'P': 60, 'K': 100},
    'soja': {'N': 40, 'P': 60, 'K': 80},
    'tournesol': {'N': 80, 'P': 80, 'K': 120},
    'colza': {'N': 180, 'P': 70, 'K': 100},
    'vigne': {'N': 60, 'P': 40, 'K': 120},
    'olivier': {'N': 80, 'P': 40, 'K': 150},
    'agrumes': {'N': 140, 'P': 60, 'K': 180},
  };

  // Coefficients selon le stade de développement
  static const Map<String, Map<String, double>> stageCoefficients = {
    'germination': {'N': 0.5, 'P': 1.2, 'K': 0.8},
    'croissance': {'N': 1.5, 'P': 0.8, 'K': 1.0},
    'floraison': {'N': 1.0, 'P': 1.5, 'K': 1.2},
    'fructification': {'N': 0.7, 'P': 1.2, 'K': 2.0},
    'maturation': {'N': 0.3, 'P': 0.5, 'K': 0.8},
  };

  // Types de sol prédéfinis
  static List<SoilType> getSoilTypes() {
    return [
      SoilType(
        id: 'argileux_riche',
        name: 'Sol argileux riche',
        nitrogenRichness: 80,
        phosphorusRichness: 70,
        potassiumRichness: 75,
        ph: 7.2,
        texture: 'argileux',
      ),
      SoilType(
        id: 'limoneux_fertile',
        name: 'Sol limoneux fertile',
        nitrogenRichness: 70,
        phosphorusRichness: 65,
        potassiumRichness: 70,
        ph: 7.0,
        texture: 'limoneux',
      ),
      SoilType(
        id: 'sableux_pauvre',
        name: 'Sol sableux pauvre',
        nitrogenRichness: 20,
        phosphorusRichness: 15,
        potassiumRichness: 25,
        ph: 6.3,
        texture: 'sableux',
      ),
      SoilType(
        id: 'calcaire',
        name: 'Sol calcaire',
        nitrogenRichness: 45,
        phosphorusRichness: 40,
        potassiumRichness: 50,
        ph: 8.2,
        texture: 'calcaire',
      ),
    ];
  }

  // Qualités d'eau prédéfinies
  static List<WaterQuality> getWaterQualities() {
    return [
      WaterQuality(
        id: 'pure',
        name: 'Eau de source pure',
        salinity: 0.2,
        nitrogenContent: 1.0,
        phosphorusContent: 0.5,
        potassiumContent: 2.0,
      ),
      WaterQuality(
        id: 'puits',
        name: 'Eau de puits',
        salinity: 0.5,
        nitrogenContent: 3.0,
        phosphorusContent: 1.0,
        potassiumContent: 5.0,
      ),
      WaterQuality(
        id: 'riviere',
        name: 'Eau de rivière',
        salinity: 0.3,
        nitrogenContent: 5.0,
        phosphorusContent: 2.0,
        potassiumContent: 8.0,
      ),
    ];
  }

  // Stades de développement disponibles
  static List<CropStage> getCropStages() {
    return [
      CropStage(
        id: 'germination',
        name: 'Germination',
        nitrogenCoeff: 0.5,
        phosphorusCoeff: 1.2,
        potassiumCoeff: 0.8,
      ),
      CropStage(
        id: 'croissance',
        name: 'Croissance végétative',
        nitrogenCoeff: 1.5,
        phosphorusCoeff: 0.8,
        potassiumCoeff: 1.0,
      ),
      CropStage(
        id: 'floraison',
        name: 'Floraison',
        nitrogenCoeff: 1.0,
        phosphorusCoeff: 1.5,
        potassiumCoeff: 1.2,
      ),
      CropStage(
        id: 'fructification',
        name: 'Fructification',
        nitrogenCoeff: 0.7,
        phosphorusCoeff: 1.2,
        potassiumCoeff: 2.0,
      ),
      CropStage(
        id: 'maturation',
        name: 'Maturation',
        nitrogenCoeff: 0.3,
        phosphorusCoeff: 0.5,
        potassiumCoeff: 0.8,
      ),
    ];
  }

  /// Calcule la quantité d'engrais nécessaire
  ///
  /// [cropType] : Type de culture (blé, maïs, tomate, etc.)
  /// [stage] : Stade de développement
  /// [soilType] : Type de sol
  /// [waterQuality] : Qualité de l'eau
  /// [areaHectares] : Surface en hectares
  FertilizerCalculation calculate({
    required String cropType,
    required CropStage stage,
    required SoilType soilType,
    required WaterQuality waterQuality,
    required double areaHectares,
  }) {
    // 1. Récupérer les besoins de base de la culture
    final baseNeeds = cropNutrientNeeds[cropType.toLowerCase()] ??
        cropNutrientNeeds['blé']!;

    double nitrogen = baseNeeds['N']!;
    double phosphorus = baseNeeds['P']!;
    double potassium = baseNeeds['K']!;

    // 2. Appliquer les coefficients du stade
    nitrogen *= stage.nitrogenCoeff;
    phosphorus *= stage.phosphorusCoeff;
    potassium *= stage.potassiumCoeff;

    // 3. Ajuster selon la richesse du sol
    // Plus le sol est riche, moins on ajoute d'engrais
    nitrogen *= (1 - soilType.nitrogenRichness / 200);
    phosphorus *= (1 - soilType.phosphorusRichness / 200);
    potassium *= (1 - soilType.potassiumRichness / 200);

    // 4. Soustraire l'apport de l'eau (conversion mg/L → kg/ha)
    const double waterVolume = 5000; // m³/ha estimé
    nitrogen -= max(0, (waterQuality.nitrogenContent * waterVolume) / 1000);
    phosphorus -= max(0, (waterQuality.phosphorusContent * waterVolume) / 1000);
    potassium -= max(0, (waterQuality.potassiumContent * waterVolume) / 1000);

    // 5. Ajuster selon la texture du sol
    if (soilType.texture == 'sableux') {
      // Sol sableux : augmenter de 20% (lessivage)
      nitrogen *= 1.2;
      potassium *= 1.2;
    } else if (soilType.texture == 'argileux') {
      // Sol argileux : réduire de 10% (meilleure rétention)
      nitrogen *= 0.9;
      potassium *= 0.9;
    }

    // 6. Ajuster selon le pH
    if (soilType.ph < 6.0) {
      // Sol acide : augmenter phosphore
      phosphorus *= 1.15;
    } else if (soilType.ph > 8.0) {
      // Sol alcalin : difficultés d'assimilation
      nitrogen *= 1.1;
    }

    // S'assurer que les valeurs sont positives
    nitrogen = max(0, nitrogen);
    phosphorus = max(0, phosphorus);
    potassium = max(0, potassium);

    // 7. Calculer pour la surface totale
    final nitrogenTotal = nitrogen * areaHectares;
    final phosphorusTotal = phosphorus * areaHectares;
    final potassiumTotal = potassium * areaHectares;

    // 8. Générer les recommandations
    final recommendations = _generateRecommendations(
      cropType: cropType,
      stage: stage,
      soilType: soilType,
      waterQuality: waterQuality,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
    );

    // 9. Préparer les détails du calcul
    final calculationDetails = {
      'besoins_base': {
        'N': baseNeeds['N'],
        'P': baseNeeds['P'],
        'K': baseNeeds['K'],
      },
      'coefficients_stade': {
        'N': stage.nitrogenCoeff,
        'P': stage.phosphorusCoeff,
        'K': stage.potassiumCoeff,
      },
      'richesse_sol': {
        'N': soilType.nitrogenRichness,
        'P': soilType.phosphorusRichness,
        'K': soilType.potassiumRichness,
      },
      'apport_eau': {
        'N': (waterQuality.nitrogenContent * waterVolume) / 1000,
        'P': (waterQuality.phosphorusContent * waterVolume) / 1000,
        'K': (waterQuality.potassiumContent * waterVolume) / 1000,
      },
    };

    return FertilizerCalculation(
      nitrogen: _round(nitrogenTotal),
      phosphorus: _round(phosphorusTotal),
      potassium: _round(potassiumTotal),
      nitrogenPerHa: _round(nitrogen),
      phosphorusPerHa: _round(phosphorus),
      potassiumPerHa: _round(potassium),
      recommendations: recommendations,
      calculationDetails: calculationDetails,
    );
  }

  /// Génère des recommandations personnalisées
  List<String> _generateRecommendations({
    required String cropType,
    required CropStage stage,
    required SoilType soilType,
    required WaterQuality waterQuality,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
  }) {
    List<String> recommendations = [];

    // Recommandations selon le stade
    switch (stage.id) {
      case 'germination':
        recommendations.add(
            '🌱 Germination : Privilégiez le phosphore pour favoriser l\'enracinement'
        );
        break;
      case 'croissance':
        recommendations.add(
            '🌿 Croissance : L\'azote est essentiel pour le développement végétatif'
        );
        break;
      case 'floraison':
        recommendations.add(
            '🌸 Floraison : Augmentez le phosphore pour une meilleure floraison'
        );
        break;
      case 'fructification':
        recommendations.add(
            '🍎 Fructification : Le potassium améliore la qualité des fruits'
        );
        break;
      case 'maturation':
        recommendations.add(
            '🌾 Maturation : Réduisez l\'azote, maintenez le potassium'
        );
        break;
    }

    // Recommandations selon le sol
    if (soilType.texture == 'sableux') {
      recommendations.add(
          '⚠️ Sol sableux : Fractionnez les apports pour limiter le lessivage'
      );
    } else if (soilType.texture == 'argileux') {
      recommendations.add(
          '💧 Sol argileux : Attention au drainage, évitez les excès d\'eau'
      );
    }

    if (soilType.ph < 6.0) {
      recommendations.add(
          '🔬 Sol acide (pH < 6) : Envisagez un chaulage pour améliorer l\'assimilation'
      );
    } else if (soilType.ph > 8.0) {
      recommendations.add(
          '🔬 Sol alcalin (pH > 8) : Surveillez les carences en fer et zinc'
      );
    }

    // Recommandations selon l'eau
    if (waterQuality.salinity > 1.5) {
      recommendations.add(
          '💦 Eau saline : Surveillez l\'accumulation de sels, prévoyez des lessivages'
      );
    }

    // Recommandations quantitatives
    recommendations.add(
        '📊 Azote (N) : ${_round(nitrogen)} kg/ha'
    );
    recommendations.add(
        '📊 Phosphore (P₂O₅) : ${_round(phosphorus)} kg/ha'
    );
    recommendations.add(
        '📊 Potassium (K₂O) : ${_round(potassium)} kg/ha'
    );

    // Conseil général
    recommendations.add(
        '💡 Conseil : Fractionnez les apports pour une meilleure efficacité'
    );

    return recommendations;
  }

  /// Arrondit à 2 décimales
  double _round(double value) {
    return (value * 100).round() / 100;
  }

  /// Liste des cultures disponibles
  static List<String> getAvailableCrops() {
    return cropNutrientNeeds.keys.toList();
  }
}