import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../models/crop_models.dart';
import '../widgets/PlantAnalysis.dart';

class ApiCropService {

  static const String baseUrl ="https://gallery-scurvy-send.ngrok-free.dev/api";
  static const String APP_SECRET = "MaClefSecreteSuperLongue123!";


  static Map<String, String> _getHeaders(String userId) {
    return {
      'Content-Type': 'application/json',
      'X-User-ID': userId,
      'X-App-Secret': APP_SECRET,
    };
  }

  static Map<String, String> _getMultipartHeaders(String userId) {
    return {
      'X-User-ID': userId,
      'X-App-Secret': APP_SECRET,
    };
  }

  static Future<List<Map<String, dynamic>>> fetchCrops(String userId) async {
    print('📡 [fetchCrops] userId: $userId');

    final response = await http.get(
      Uri.parse('$baseUrl/crops/'),
      headers: _getHeaders(userId),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ ${data.length} cultures récupérées');
      return data.cast<Map<String, dynamic>>();
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to load crops: ${response.statusCode}');
    }
  }
  static Future<Map<String, dynamic>> createCrop({
    required String userId,
    required String name,
    required String plantingDate,
    required String location,
    String healthStatus = 'S',
    String stage = '',
  }) async {
    print('📡 [createCrop] userId: $userId, name: $name');

    final response = await http.post(
      Uri.parse('$baseUrl/crops/'),
      headers: _getHeaders(userId),
      body: json.encode({
        'name': name,
        'planting_date': plantingDate,
        'location': location,
        'health_status': healthStatus,
        'stage': stage,
      }),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 201) {
      print('✅ Culture créée avec succès');
      return json.decode(response.body);
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to create crop: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateCrop({
    required String userId,
    required int cropId,
    String? name,
    String? plantingDate,
    String? location,
    String? healthStatus,
    String? stage,
  }) async {
    print('📡 [updateCrop] cropId: $cropId');

    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (plantingDate != null) body['planting_date'] = plantingDate;
    if (location != null) body['location'] = location;
    if (healthStatus != null) body['health_status'] = healthStatus;
    if (stage != null) body['stage'] = stage;

    final response = await http.patch(
      Uri.parse('$baseUrl/crops/$cropId/'),
      headers: _getHeaders(userId),
      body: json.encode(body),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ Culture mise à jour');
      return json.decode(response.body);
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to update crop: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchCropsStats(String userId) async {
    print('📡 [fetchCropsStats] userId: $userId');

    final response = await http.get(
      Uri.parse('$baseUrl/crops/stats/'),
      headers: _getHeaders(userId),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ Stats récupérées');
      return json.decode(response.body);
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to load stats: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchCropDetails(
      String userId,
      int cropId,
      ) async {
    print('📡 [fetchCropDetails] cropId: $cropId');

    final response = await http.get(
      Uri.parse('$baseUrl/crops/$cropId/'),
      headers: _getHeaders(userId),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ Détails récupérés');
      return json.decode(response.body);
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to load crop details: ${response.statusCode}');
    }
  }

  static Future<void> deleteCrop(String userId, String cropId) async {
    print('📡 [deleteCrop] cropId: $cropId');

    final response = await http.delete(
      Uri.parse('$baseUrl/crops/$cropId/'),
      headers: _getHeaders(userId),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode != 204) {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to delete crop: ${response.body}');
    }

    print('✅ Culture supprimée');
  }

  static Future<void> updateCropHealth(
      String userId,
      int cropId,
      String healthStatus,
      ) async {
    print('📡 [updateCropHealth] cropId: $cropId, status: $healthStatus');

    final response = await http.patch(
      Uri.parse('$baseUrl/crops/$cropId/'),
      headers: _getHeaders(userId),
      body: jsonEncode({
        'health_status': healthStatus,
      }),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to update health status: ${response.body}');
    }

    print('✅ Statut de santé mis à jour');
  }

  static Future<void> uploadSensorImage(
      String userId,
      String cropId,
      File imageFile,
      ) async {
    print('📡 [uploadSensorImage] cropId: $cropId');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/crops/$cropId/upload_image/'),
    );

    request.headers.addAll(_getMultipartHeaders(userId));
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode != 201) {
      print('❌ Erreur: ${response.body}');
      throw Exception('Failed to upload image: ${response.body}');
    }

    print('✅ Image uploadée');
  }

  static Future<void> saveAnalysisHistory(
      String userId,
      String cropId,
      PlantAnalysisResult result,
      String imagePath,
      ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/crops/$cropId/save_analysis/'),
    );

    request.headers.addAll(_getMultipartHeaders(userId));

    request.fields['crop'] = cropId.toString();

    if (imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    request.fields['predicted_class'] = result.isHealthy ? 'healthy' : (result.disease?['fr'] ?? 'unknown');
    request.fields['confidence'] = result.confidence.toString();
    request.fields['bio_aggressor_type'] = result.bioAggressorType ?? '';
    request.fields['onssa_term'] = result.onssaTerm ?? '';

    if (result.plant != null) request.fields['plant'] = jsonEncode(result.plant);
    if (result.disease != null) request.fields['disease'] = jsonEncode(result.disease);
    if (result.description != null) request.fields['description'] = jsonEncode(result.description);
    if (result.prevention != null) request.fields['prevention'] = jsonEncode(result.prevention);

    if (result.onssaTreatments != null) {
      final treatmentsMap = result.onssaTreatments!.map((e) => e.toJson()).toList();
      request.fields['onssa_treatments'] = jsonEncode(treatmentsMap);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      print('❌ Erreur détaillée: ${response.body}');
      throw Exception('Failed to save analysis history');
    }
  }
  static Future<void> updateLastAnalysis(
      String userId,
      int cropId,
      PlantAnalysisResult result,
      String imagePath,
      ) async {
    print('📡 [updateLastAnalysis] cropId: $cropId');

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/crops/$cropId/'),
    );

    request.headers.addAll(_getMultipartHeaders(userId));

    if (imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('last_analysis_image', imagePath),
      );
    }

    request.fields['last_analysis_disease'] = result.isHealthy ? 'Sain' : (result.disease?['fr'] ?? 'Maladie');
    request.fields['last_analysis_confidence'] = result.confidence.toString();
    request.fields['last_analysis_date'] = DateTime.now().toIso8601String();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print('❌ Erreur update crop: ${response.body}');
      throw Exception('Failed to update last analysis');
    }
    print('✅ Culture mise à jour');
  }

  static Future<List<CropAnalysisHistoryItem>> getAnalysisHistory(
      String userId,
      String cropId,
      ) async {
    final url = '$baseUrl/crops/$cropId/analysis_history/';
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📖 RÉCUPÉRATION HISTORIQUE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 URL: $url');
    print('🌾 Crop ID: $cropId');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(userId),
      );

      print('📡 Status code: ${response.statusCode}');
      print('📥 Réponse brute: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Nombre d\'éléments: ${data.length}');

        if (data.isNotEmpty) {
          print('📄 Premier élément:');
          print(jsonEncode(data[0]));
        }

        final List<CropAnalysisHistoryItem> items = [];

        for (int i = 0; i < data.length; i++) {
          try {
            print('🔄 Parsing item $i...');
            final item = CropAnalysisHistoryItem.fromJson(data[i]);
            items.add(item);
            print('✅ Item $i parsé avec succès');
          } catch (e, stack) {
            print('❌ ERREUR parsing item $i:');
            print('   JSON: ${jsonEncode(data[i])}');
            print('   Erreur: $e');
            print('   Stack: $stack');

          }
        }

        print('✅ Total items parsés: ${items.length}/${data.length}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        return items;
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        throw Exception('Failed to load analysis history: ${response.body}');
      }
    } catch (e, stack) {
      print('❌ EXCEPTION dans getAnalysisHistory:');
      print('   Erreur: $e');
      print('   Stack: $stack');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      rethrow;
    }
  }

  static Future<void> deleteAnalysis(String userId, String cropId, String historyId) async {
    print('📡 [deleteAnalysis] historyId: $historyId');

    final url = Uri.parse('$baseUrl/crops/$cropId/analysis_history/$historyId/');

    final response = await http.delete(
      url,
      headers: _getHeaders(userId),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode != 204 && response.statusCode != 200) {
      print('❌ Erreur: ${response.body}');
      throw Exception('Échec de la suppression de l\'analyse: ${response.statusCode}');
    }

    print('✅ Analyse supprimée');
  }

  static Future<int> deleteMultipleAnalyses(
      String userId,
      String cropId,
      List<String> historyIds,
      ) async {
    print('📡 [deleteMultipleAnalyses] ${historyIds.length} analyses');

    final url = Uri.parse('$baseUrl/crops/$cropId/delete_multiple_analyses/');

    final response = await http.post(
      url,
      headers: _getHeaders(userId),
      body: jsonEncode({
        'history_ids': historyIds,
      }),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ ${historyIds.length} analyses supprimées');
      return historyIds.length;
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Échec de la suppression multiple: ${response.statusCode}');
    }
  }

  // ============================================================
  // SUPPRESSION TOTALE DE L'HISTORIQUE
  // ============================================================
  static Future<int> clearAnalysisHistory(String userId, String cropId) async {
    print('📡 [clearAnalysisHistory] cropId: $cropId');

    final url = Uri.parse('$baseUrl/crops/$cropId/clear_history/');

    final response = await http.delete(
      url,
      headers: _getHeaders(userId),
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String message = data['message'] ?? '';
      RegExp exp = RegExp(r'(\d+)');
      Match? match = exp.firstMatch(message);
      int count = match != null ? int.parse(match.group(1)!) : 0;
      print('✅ $count analyses supprimées');
      return count;
    } else {
      print('❌ Erreur: ${response.body}');
      throw Exception('Échec de la suppression totale: ${response.statusCode}');
    }
  }
}

// ============================================================
// MODÈLE CROP
// ============================================================
class Crop {
  final int id;
  final String name;
  final DateTime plantingDate;
  final String location;
  final String healthStatus;
  final String healthStatusDisplay;
  final String stage;

  Crop({
    required this.id,
    required this.name,
    required this.plantingDate,
    required this.location,
    required this.healthStatus,
    required this.healthStatusDisplay,
    required this.stage,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'],
      name: json['name'],
      plantingDate: DateTime.parse(json['planting_date']),
      location: json['location'] ?? '',
      healthStatus: json['health_status'] ?? 'S',
      healthStatusDisplay: json['health_status_display'] ?? 'Healthy',
      stage: json['stage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planting_date': plantingDate.toIso8601String().split('T')[0],
      'location': location,
      'health_status': healthStatus,
      'health_status_display': healthStatusDisplay,
      'stage': stage,
    };
  }

  Crop copyWith({
    int? id,
    String? name,
    DateTime? plantingDate,
    String? location,
    String? healthStatus,
    String? healthStatusDisplay,
    String? stage,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      plantingDate: plantingDate ?? this.plantingDate,
      location: location ?? this.location,
      healthStatus: healthStatus ?? this.healthStatus,
      healthStatusDisplay: healthStatusDisplay ?? this.healthStatusDisplay,
      stage: stage ?? this.stage,
    );
  }
}