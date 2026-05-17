import 'dart:convert';

import '../models/crop_models.dart';

class PlantAnalysisResult {
  final Map<String, String>? plant;
  final Map<String, String>? disease;
  final Map<String, String>? description;
  final Map<String, List<String>>? prevention;

  final double confidence;
  final bool isHealthy;
  final String? bioAggressorType;
  final String? onssaTerm;
  final String? severity;

  final List<String>? symptoms;
  final List<String>? solutions;
  final List<String>? recommendations;
  final List<Top3Prediction>? top3Predictions;
  final List<OnssaTreatment>? onssaTreatments;

  PlantAnalysisResult({
    this.plant,
    this.disease,
    required this.confidence,
    required this.isHealthy,
    this.description,
    this.severity,
    this.symptoms,
    this.solutions,
    this.prevention,
    this.recommendations,
    this.top3Predictions,
    this.onssaTerm,
    this.bioAggressorType,
    this.onssaTreatments,
  });

  factory PlantAnalysisResult.fromJson(Map<String, dynamic> json) {
    // --- FONCTION DE NETTOYAGE INTERNE ---
    // Gère le cas où le JSON arrive en String au lieu d'un Objet (problème de base de données)
    dynamic cleanJson(dynamic field) {
      if (field == null) return null;
      if (field is String && field.startsWith('{')) {
        try { return jsonDecode(field); } catch (e) { return null; }
      }
      if (field is String && field.startsWith('[')) {
        try { return jsonDecode(field); } catch (e) { return null; }
      }
      // Nettoyage des doubles guillemets restants (ex: ""Pomme de terre"")
      if (field is String) {
        return field.replaceAll('"', '').trim();
      }
      return field;
    }

    // Extraction sécurisée pour les Maps multilingues
    Map<String, String>? parseMap(dynamic data) {
      final cleaned = cleanJson(data);
      if (cleaned is Map) {
        return cleaned.map((key, value) => MapEntry(key.toString(), value.toString()));
      } else if (cleaned is String && cleaned.isNotEmpty) {
        // Fallback si la base n'a qu'un String simple
        return {'fr': cleaned};
      }
      return null;
    }

    // Extraction sécurisée pour la prévention (Map de Listes)
    Map<String, List<String>>? parsePrevention(dynamic data) {
      final cleaned = cleanJson(data);
      if (cleaned is Map) {
        return cleaned.map((key, value) => MapEntry(
          key.toString(),
          List<String>.from(value is List ? value : []),
        ));
      } else if (cleaned is List) {
        // Fallback si c'est juste une liste simple
        return {'fr': List<String>.from(cleaned)};
      }
      return null;
    }

    return PlantAnalysisResult(
      plant: parseMap(json['plant']),
      disease: parseMap(json['disease']),
      description: parseMap(json['description']),
      prevention: parsePrevention(json['prevention']),

      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isHealthy: json['is_healthy'] ?? false,
      severity: json['severity']?.toString(),
      onssaTerm: json['onssa_term']?.toString(),
      bioAggressorType: json['bio_aggressor_type']?.toString(),

      symptoms: json['symptoms'] != null ? List<String>.from(json['symptoms']) : null,
      solutions: json['solutions'] != null ? List<String>.from(json['solutions']) : null,
      recommendations: json['recommendations'] != null ? List<String>.from(json['recommendations']) : null,

      top3Predictions: json['top_3'] != null
          ? (json['top_3'] as List).map((e) => Top3Prediction.fromJson(e)).toList()
          : null,

      onssaTreatments: json['onssa_treatments'] != null
          ? (cleanJson(json['onssa_treatments']) as List)
          .map((e) => OnssaTreatment.fromJson(e))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant': plant,
      'disease': disease,
      'confidence': confidence,
      'is_healthy': isHealthy,
      'description': description,
      'severity': severity,
      'symptoms': symptoms,
      'solutions': solutions,
      'prevention': prevention,
      'recommendations': recommendations,
      'top_3': top3Predictions?.map((e) => e.toJson()).toList(),
      'onssa_term': onssaTerm,
      'bio_aggressor_type': bioAggressorType,
      'onssa_treatments': onssaTreatments?.map((e) => e.toJson()).toList(),
    };
  }
}

// --- CLASSES SECONDAIRES (TOP3 ET ONSSA) ---

class Top3Prediction {
  final String className;
  final String plant;
  final String? disease;
  final double confidence;

  Top3Prediction({required this.className, required this.plant, this.disease, required this.confidence});

  factory Top3Prediction.fromJson(Map<String, dynamic> json) {
    final className = json['class'] ?? '';
    final parts = className.split('__');
    String plant = parts.isNotEmpty ? parts[0].replaceAll('_', ' ') : '';
    String? disease = (parts.length > 1 && parts[1] != 'Healthy') ? parts[1].replaceAll('_', ' ') : null;

    return Top3Prediction(
      className: className,
      plant: plant,
      disease: disease,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'class': className, 'plant': plant, 'disease': disease, 'confidence': confidence};
}
