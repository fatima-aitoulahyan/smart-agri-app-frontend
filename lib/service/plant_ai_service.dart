import 'dart:io';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../widgets/PlantAnalysis.dart';

class PlantAIService {
  // 🔧 CONFIGUREZ VOTRE URL BACKEND ICI
  static const String baseUrl = 'https://gallery-scurvy-send.ngrok-free.dev';
  static const String analyzeEndpoint = '/api/ai/analyze-plant/';
  static const String APP_SECRET = "MaClefSecreteSuperLongue123!";

  Future<PlantAnalysisResult> analyzeImage(File imageFile, String userId,BuildContext context) async {
    final String fullUrl = '$baseUrl$analyzeEndpoint';
    final currentLocale = EasyLocalization.of(context)?.locale.languageCode ?? 'fr';


    try {
      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        throw Exception('Le fichier image n\'existe pas');
      }

      final fileSize = await imageFile.length();

      var request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      request.headers.addAll({
        'Accept': 'application/json',
        'X-App-Secret': APP_SECRET,
        'X-User-Id': userId,
        'X-Language': currentLocale,
      });



      // Ajouter l'image
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'plant_image.jpg',
      );
      request.files.add(multipartFile);

      // ✅ Augmenter le timeout à 60s
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('⏰ TIMEOUT - Le serveur ne répond pas après 60s');
          print('💡 Vérifiez:');
          print('   1. Le backend est lancé: python manage.py runserver 0.0.0.0:8000');
          print('   2. L\'IP est correcte (ipconfig sur Windows)');
          print('   3. Le pare-feu autorise le port 8000');
          print('   4. Le téléphone et le PC sont sur le même WiFi');
          throw Exception('Le serveur ne répond pas. Vérifiez la connexion réseau.');
        },
      );

      print('📥 Réponse reçue - Status: ${streamedResponse.statusCode}');

      var response = await http.Response.fromStream(streamedResponse);

      print('📄 Body de la réponse:');
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Analyse réussie');
        print('🌿 Plante détectée: ${data['plant']}');
        return PlantAnalysisResult.fromJson(data);
      } else if (response.statusCode == 401) {
        print('❌ Erreur d\'authentification');
        throw Exception('APP_SECRET invalide. Vérifiez la configuration.');
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Erreur serveur ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('🔌 Erreur de connexion réseau: $e');
      print('');
      print('💡 SOLUTIONS:');
      print('   1. Vérifiez l\'IP de votre PC:');
      print('      Windows: ipconfig');
      print('      Linux/Mac: ip addr ou ifconfig');
      print('   2. Lancez le serveur: python manage.py runserver 0.0.0.0:8000');
      print('   3. Autorisez le port 8000 dans le pare-feu');
      print('   4. Connectez le téléphone au même WiFi');
      throw Exception('Impossible de se connecter au serveur. Vérifiez la connexion réseau.');
    } on http.ClientException catch (e) {
      print('🌐 Erreur client HTTP: $e');
      throw Exception('Erreur de communication avec le serveur');
    } on FormatException catch (e) {
      print('📋 Erreur de parsing JSON: $e');
      throw Exception('Réponse invalide du serveur');
    } on TimeoutException catch (e) {
      print('⏰ Timeout: $e');
      throw Exception('Le serveur met trop de temps à répondre');
    } catch (e) {
      print('💥 Erreur inattendue: $e');
      throw Exception('Erreur: $e');
    }
  }

  // 🧪 Méthode de test de connexion
  Future<bool> testConnection() async {
    try {
      print('🧪 Test de connexion au backend...');
      print('📍 URL: $baseUrl/admin/');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/'),
      ).timeout(const Duration(seconds: 5));

      print('✅ Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print('❌ Test échoué: $e');
      return false;
    }
  }
}