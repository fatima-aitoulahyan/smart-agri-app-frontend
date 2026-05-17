// models/fertilizer_model.dart

class FertilizerCalculation {
  final double nitrogen;      // Azote (N) en kg
  final double phosphorus;     // Phosphore (P2O5) en kg
  final double potassium;      // Potassium (K2O) en kg
  final double nitrogenPerHa;  // N par hectare
  final double phosphorusPerHa; // P par hectare
  final double potassiumPerHa;  // K par hectare
  final List<String> recommendations;
  final Map<String, dynamic> calculationDetails;

  FertilizerCalculation({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.nitrogenPerHa,
    required this.phosphorusPerHa,
    required this.potassiumPerHa,
    required this.recommendations,
    required this.calculationDetails,
  });

  factory FertilizerCalculation.fromJson(Map<String, dynamic> json) {
    return FertilizerCalculation(
      nitrogen: (json['azote_kg'] ?? 0).toDouble(),
      phosphorus: (json['phosphore_kg'] ?? 0).toDouble(),
      potassium: (json['potassium_kg'] ?? 0).toDouble(),
      nitrogenPerHa: (json['azote_par_ha'] ?? 0).toDouble(),
      phosphorusPerHa: (json['phosphore_par_ha'] ?? 0).toDouble(),
      potassiumPerHa: (json['potassium_par_ha'] ?? 0).toDouble(),
      recommendations: List<String>.from(json['recommandations'] ?? []),
      calculationDetails: json['details_calcul'] ?? {},
    );
  }
}

class CropStage {
  final String id;
  final String name;
  final double nitrogenCoeff;
  final double phosphorusCoeff;
  final double potassiumCoeff;

  CropStage({
    required this.id,
    required this.name,
    required this.nitrogenCoeff,
    required this.phosphorusCoeff,
    required this.potassiumCoeff,
  });
}

class SoilType {
  final String id;
  final String name;
  final int nitrogenRichness;    // 0-100
  final int phosphorusRichness;  // 0-100
  final int potassiumRichness;   // 0-100
  final double ph;
  final String texture;

  SoilType({
    required this.id,
    required this.name,
    required this.nitrogenRichness,
    required this.phosphorusRichness,
    required this.potassiumRichness,
    required this.ph,
    required this.texture,
  });
}

class WaterQuality {
  final String id;
  final String name;
  final double salinity;
  final double nitrogenContent;   // mg/L
  final double phosphorusContent; // mg/L
  final double potassiumContent;  // mg/L

  WaterQuality({
    required this.id,
    required this.name,
    required this.salinity,
    required this.nitrogenContent,
    required this.phosphorusContent,
    required this.potassiumContent,
  });
}