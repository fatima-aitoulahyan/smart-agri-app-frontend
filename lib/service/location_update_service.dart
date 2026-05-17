import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agri_frontend/service/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationUpdateService {
  static const String baseUrl = 'https://gallery-scurvy-send.ngrok-free.dev';

  /// ⚠️ Clé secrète de l'application (doit matcher le backend)
  static const String appSecret = "MaClefSecreteSuperLongue123!";

  /// 📍 Mettre à jour la localisation automatiquement
  static Future<Map<String, dynamic>> updateUserLocation(String userId) async {
    try {
      // 1️⃣ Obtenir la position actuelle
      final Position position = await LocationService.getCurrentLocation();

      // 2️⃣ Envoyer au backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/update-location/'),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': appSecret,  // 🔑 Secret dans les headers
          'X-User-ID': userId,
        },
        body: json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'city': data['city'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la mise à jour de la localisation',
        };
      }
    } catch (e) {
      print('❌ Erreur updateUserLocation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🏙️ Mettre à jour la ville manuellement
  static Future<Map<String, dynamic>> updateUserCity(
      String userId,
      String city,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update-city/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'appSecret': appSecret,
          'city': city,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'city': data['city'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Ville introuvable',
        };
      }
    } catch (e) {
      print('❌ Erreur updateUserCity: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
