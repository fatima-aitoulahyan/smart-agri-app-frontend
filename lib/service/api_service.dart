import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  // ==================== BASE URL ====================
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "https://gallery-scurvy-send.ngrok-free.dev/api";;
    }
    return 'http://localhost:8000/api';
  }

  static const String APP_SECRET = "MaClefSecreteSuperLongue123!";

  static Map<String, String> getHeaders(String userId) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Secret': APP_SECRET,
      'X-User-Id': userId,
    };
  }

  Future<void> createUserOnBackend(String userId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/create_or_get_user/');
      final response = await http.post(
        url,
        headers: getHeaders(userId),
        body: jsonEncode({
          'city': 'Agadir',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ User créé/synchronisé sur le backend');
      } else {
        print('❌ Erreur backend: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Exception lors de la création user: $e');
    }
  }





  // ==================== PROFIL ANONYME ====================
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/?user_id=$userId'),
        headers: getHeaders(userId),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Erreur profil: $e'};
    }
  }

  // ==================== NOTIFICATIONS ====================
  static Future<int> getUnreadNotifications(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread/?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['unread_count'];
    }
    return 0;
  }

  // ==================== MÉTÉO ====================
  static Future<Map<String, dynamic>> getWeather({
    String? city,
    double? lat,
    double? lon,
    required String userId,
  }) async {
    Uri uri;

    if (lat != null && lon != null) {
      uri = Uri.parse('$baseUrl/weather/?lat=$lat&lon=$lon');
    } else if (city != null) {
      uri = Uri.parse('$baseUrl/weather/?city=$city');
    } else {
      throw Exception('city ou lat/lon requis');
    }

    final response = await http.get(uri , headers: getHeaders(userId),);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur serveur : ${response.statusCode}');
    }
  }

  // ==================== IA (ANONYME) ====================
  static Future<Map<String, dynamic>> getGeminiResponse({
    required String prompt,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat/'),
        headers: getHeaders(userId),
        body: jsonEncode({
          'prompt': prompt,
          'user_id': userId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur IA: $e'};
    }
  }

  // ==================== UTILITAIRE ====================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur parsing: $e',
        'statusCode': response.statusCode,
      };
    }
  }
  static Future<List<dynamic>> getConversation(
      String userId, String conversationId) async {
    try {
      final url = Uri.parse('$baseUrl/ai/history/$conversationId/?user_id=$userId');

      final response = await http.get(
        url,
        headers: getHeaders(userId),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Erreur serveur ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }
  static Future<List<dynamic>> getAllConversations(String userId) async {


    final response = await http.get(
      Uri.parse('$baseUrl/ai/conversations/'),
      headers: {
        "X-User-Id": userId,
        "X-App-Secret": APP_SECRET,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Vérifie si le backend renvoie directement la liste
      if (data is List) return data;
      if (data['success'] == true && data['data'] != null) return data['data'];

      return [];
    } else {
      throw Exception("Erreur serveur ${response.statusCode}");
    }
  }
  static Future<Map<String, dynamic>> sendMessage(
      String text, String userId, String conversationId) async {
    final url = Uri.parse('$baseUrl/ai/send/');

    final response = await http.post(
      url,
      headers: getHeaders(userId),
      body: jsonEncode({
        'user_id': userId,          // ✅ utilisateur anonyme
        'conversation_id': conversationId,
        'message': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // S'assurer que c'est bien un Map
      if (data is Map<String, dynamic>) return data;
      return {'success': false, 'message': 'Invalid response format'};
    } else {
      throw Exception("Erreur serveur ${response.statusCode}");
    }
  }
  static Future<Map<String, dynamic>> deleteConversation(
      String userId, String conversationId) async {
    try {
      // 🛑 Utiliser DELETE avec l'ID dans l'URL et l'userId en paramètre GET
      final url = Uri.parse('$baseUrl/ai/conversations/$conversationId/delete/?user_id=$userId');

      final response = await http.delete(
        url,
        headers: getHeaders(userId),
      );

      // Vérifier la réponse
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) return data;
        return {'success': false, 'message': 'Format de réponse invalide'};
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de suppression de conversation: $e'
      };
    }
  }
  static Future<bool> updateLanguage(String userId, String language) async {
    try {
      final url = Uri.parse('$baseUrl/update-language/');
      final response = await http.patch(
        url,
        headers: getHeaders(userId),
        body: jsonEncode({
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur updateLanguage: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updateLanguage: $e');
      return false;
    }
  }

  // ================= UPDATE CITY =================
  static Future<bool> updateCity(String userId, String city) async {
    try {
      final url = Uri.parse('$baseUrl/update_city/');
      final response = await http.post(
        url,
        headers: getHeaders(userId),
        body: jsonEncode({
          'city': city,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur updateCity: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updateCity: $e');
      return false;
    }
  }

  // ================= NOTIFICATION PREFERENCES =================
  static Future<Map<String, dynamic>> getNotificationPreferences(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/notification-preferences/');
      final response = await http.get(
        url,
        headers: getHeaders(userId),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Erreur ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception getNotificationPreferences: $e');
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<bool> updateNotificationPreferences(
      String userId,
      Map<String, bool> preferences,
      ) async {
    try {
      final url = Uri.parse('$baseUrl/notification-preferences/');
      final response = await http.patch(
        url,
        headers: getHeaders(userId),
        body: jsonEncode(preferences),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur updateNotificationPreferences: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updateNotificationPreferences: $e');
      return false;
    }
  }




}
