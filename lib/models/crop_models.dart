import 'dart:convert';

import '../widgets/PlantAnalysis.dart';

class Crop {
  final String id;
  final String name;
  final DateTime plantingDate;
  final String location;
  final String healthStatus;
  final String healthStatusDisplay;
  final String stage;

  // Champs pour la dernière analyse IA
  final String? lastAnalysisDisease;
  final double? lastAnalysisConfidence;
  final DateTime? lastAnalysisDate;
  final String? lastAnalysisImage;

  Crop({
    required this.id,
    required this.name,
    required this.plantingDate,
    required this.location,
    required this.healthStatus,
    required this.healthStatusDisplay,
    required this.stage,
    this.lastAnalysisDisease,
    this.lastAnalysisConfidence,
    this.lastAnalysisDate,
    this.lastAnalysisImage,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastAnalysisConfidence: json['last_analysis_confidence'] != null
              ? (json['last_analysis_confidence'] as num).toDouble()
              : 0.0,
      plantingDate: DateTime.parse(json['planting_date']),
      location: json['location'] ?? '',
      healthStatus: json['health_status'],
      healthStatusDisplay: json['health_status_display']?.toString() ?? 'Sain',
      stage: json['stage'] ?? '',
      lastAnalysisDisease: json['last_analysis_disease']?.toString() ?? 'Aucune analyse',

      lastAnalysisDate: json['last_analysis_date'] != null
          ? DateTime.parse(json['last_analysis_date'])
          : null,
      lastAnalysisImage: json['last_analysis_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planting_date': plantingDate.toIso8601String(),
      'location': location,
      'health_status': healthStatus,
      'health_status_display': healthStatusDisplay,
      'stage': stage,
      'last_analysis_disease': lastAnalysisDisease,
      'last_analysis_confidence': lastAnalysisConfidence,
      'last_analysis_date': lastAnalysisDate?.toIso8601String(),
      'last_analysis_image': lastAnalysisImage,
    };
  }

  /// Crée une copie de Crop avec des champs modifiés
  Crop copyWith({
    String? id,
    String? name,
    DateTime? plantingDate,
    String? location,
    String? healthStatus,
    String? healthStatusDisplay,
    String? stage,
    String? lastAnalysisDisease,
    double? lastAnalysisConfidence,
    DateTime? lastAnalysisDate,
    String? lastAnalysisImage,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      plantingDate: plantingDate ?? this.plantingDate,
      location: location ?? this.location,
      healthStatus: healthStatus ?? this.healthStatus,
      healthStatusDisplay: healthStatusDisplay ?? this.healthStatusDisplay,
      stage: stage ?? this.stage,
      lastAnalysisDisease: lastAnalysisDisease ?? this.lastAnalysisDisease,
      lastAnalysisConfidence: lastAnalysisConfidence ?? this.lastAnalysisConfidence,
      lastAnalysisDate: lastAnalysisDate ?? this.lastAnalysisDate,
      lastAnalysisImage: lastAnalysisImage ?? this.lastAnalysisImage,
    );
  }
}

/// Représente un élément de l'historique des analyses IA
class CropAnalysisHistoryItem {
  final int id;
  final String? diseaseDetected;
  final double? confidence;
  final String? severity;
  final String? onssaTerm;
  final String? bioAggressorType;
  final dynamic plant;
  final dynamic disease;
  final dynamic description;
  final dynamic prevention;
  final List<OnssaTreatment>? onssaTreatments;  // ✅ Sans espace
  final String? imageUrl;
  final DateTime analyzedAt;

  CropAnalysisHistoryItem({
    required this.id,
    this.diseaseDetected,
    this.confidence,
    this.severity,
    this.onssaTerm,
    this.bioAggressorType,
    this.plant,
    this.disease,
    this.description,
    this.prevention,
    this.onssaTreatments,
    this.imageUrl,
    required this.analyzedAt,
  });

  factory CropAnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing CropAnalysisHistoryItem ID: ${json['id']}');

    // Helper pour parser des champs JSON flexibles
    dynamic _safeParseJson(dynamic value, String fieldName) {
      if (value == null) {
        print('   ℹ️ $fieldName est null');
        return null;
      }

      if (value is Map) {
        print('   ✅ $fieldName est déjà un Map');
        return value;
      }

      if (value is String) {
        print('   🔄 $fieldName est un String, tentative de parsing...');
        try {
          final parsed = jsonDecode(value);
          print('   ✅ $fieldName parsé avec succès');
          return parsed;
        } catch (e) {
          print('   ⚠️ $fieldName - Erreur parsing: $e, utilisation de la string brute');
          return {'fr': value};
        }
      }

      print('   ℹ️ $fieldName type inconnu: ${value.runtimeType}');
      return value;
    }

    // Parser les traitements ONSSA
    List<OnssaTreatment>? _parseTreatments(dynamic value) {  // ✅ Sans espace
      if (value == null) return null;

      try {
        List<dynamic> treatmentsList;

        if (value is String) {
          print('   🔄 onssa_treatments est un String, parsing...');
          treatmentsList = jsonDecode(value);
        } else if (value is List) {
          print('   ✅ onssa_treatments est déjà une List');
          treatmentsList = value;
        } else {
          print('   ⚠️ onssa_treatments type inattendu: ${value.runtimeType}');
          return null;
        }

        final treatments = treatmentsList
            .map((t) => OnssaTreatment.fromJson(t as Map<String, dynamic>))  // ✅ Sans espace
            .toList();

        print('   ✅ ${treatments.length} traitements parsés');
        return treatments;

      } catch (e) {
        print('   ❌ Erreur parsing traitements: $e');
        return null;
      }
    }

    try {
      // Parser les champs JSON
      final plantData = _safeParseJson(json['plant'], 'plant');
      final diseaseData = _safeParseJson(json['disease'], 'disease');
      final descriptionData = _safeParseJson(json['description'], 'description');
      final preventionData = _safeParseJson(json['prevention'], 'prevention');

      // Extraire le nom de la maladie
      String? diseaseName;
      if (diseaseData is Map && diseaseData.containsKey('fr')) {
        diseaseName = diseaseData['fr']?.toString();
      } else if (diseaseData is String) {
        diseaseName = diseaseData;
      } else {
        diseaseName = json['predicted_class']?.toString();
      }

      print('   🏷️ Disease name: $diseaseName');

      final item = CropAnalysisHistoryItem(
        id: json['id'] as int,
        diseaseDetected: diseaseName,
        confidence: (json['confidence'] as num?)?.toDouble(),
        severity: json['severity']?.toString(),
        onssaTerm: json['onssa_term']?.toString(),
        bioAggressorType: json['bio_aggressor_type']?.toString(),
        plant: plantData,
        disease: diseaseData,
        description: descriptionData,
        prevention: preventionData,
        onssaTreatments: _parseTreatments(json['onssa_treatments']),
        imageUrl: json['image']?.toString(),
        analyzedAt: DateTime.parse(json['analyzed_at']),
      );

      print('✅ Item parsé avec succès\n');
      return item;

    } catch (e, stack) {
      print('❌ ERREUR CRITIQUE dans fromJson:');
      print('   JSON complet: $json');
      print('   Erreur: $e');
      print('   Stack trace: $stack\n');
      rethrow;
    }
  }
}

/// Représente un traitement ONSSA
class OnssaTreatment {  // ✅ Sans espace
  final String productName;
  final String activeIngredient;
  final String dosage;
  final String dar;
  final String nbrApplication;

  OnssaTreatment({  // ✅ Sans espace
    required this.productName,
    required this.activeIngredient,
    required this.dosage,
    required this.dar,
    required this.nbrApplication,
  });

  factory OnssaTreatment.fromJson(Map<String, dynamic> json) {  // ✅ Sans espace
    try {
      return OnssaTreatment(  // ✅ Sans espace
        productName: json['product_name']?.toString() ?? '',
        activeIngredient: json['active_ingredient']?.toString() ?? '',
        dosage: json['dosage']?.toString() ?? '',
        dar: json['dar']?.toString() ?? '',
        nbrApplication: json['nbr_application']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Erreur parsing OnssaTreatment: $e');
      print('   JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'active_ingredient': activeIngredient,
      'dosage': dosage,
      'dar': dar,
      'nbr_application': nbrApplication,
    };
  }
}

/// Représente une image de capteur
class SensorImage {
  final int id;
  final int cropId;
  final String imageUrl;
  final DateTime capturedAt;

  SensorImage({
    required this.id,
    required this.cropId,
    required this.imageUrl,
    required this.capturedAt,
  });

  factory SensorImage.fromJson(Map<String, dynamic> json) {
    return SensorImage(
      id: json['id'],
      cropId: json['crop'],
      imageUrl: json['image'],
      capturedAt: DateTime.parse(json['captured_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop': cropId,
      'image': imageUrl,
      'captured_at': capturedAt.toIso8601String(),
    };
  }
}