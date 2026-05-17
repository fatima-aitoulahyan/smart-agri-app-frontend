import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agri_frontend/models/notification_model.dart';

class NotificationService {
  static const String baseUrl = 'https://gallery-scurvy-send.ngrok-free.dev'; // À remplacer par votre URL
  static const String APP_SECRET = "MaClefSecreteSuperLongue123!";

  static Map<String, String> getHeaders(String userId) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Secret': APP_SECRET,
      'X-User-Id': userId,
    };
  }

  // Récupérer les notifications
  static Future<Map<String, dynamic>> getNotifications(String userId) async {
    try {
      print('📡 GET /api/notifications/');
      print('   Headers: ${getHeaders(userId)}');

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/'),
        headers: getHeaders(userId),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Le backend retourne maintenant { success: true, notifications: [...] }
        if (data['success'] == true && data['notifications'] != null) {
          final List<NotificationModel> notifications = (data['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          return {
            'success': true,
            'notifications': notifications,
          };
        }
      }

      return {
        'success': false,
        'error': 'Erreur lors du chargement des notifications (${response.statusCode})',
      };
    } catch (e) {
      print('❌ Erreur getNotifications: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
      };
    }
  }

  // Marquer comme lue
  static Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      print('📡 PATCH /api/notifications/$notificationId/mark_read/');
      print('🔑 Notification ID avant API: ${notificationId}');
      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/mark_read/'), // ID comme String
        headers: getHeaders(userId),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Marquer toutes comme lues
  static Future<bool> markAllAsRead(String userId) async {
    try {
      print('📡 PUT /api/notifications/read_all/');

      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/read_all/'),
        headers: getHeaders(userId),
      );

      print('📥 Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
      return false;
    }
  }

  // Supprimer une notification
  static Future<bool> deleteNotification(String userId, String notificationId) async {
    try {
      print('📡 DELETE /api/notifications/$notificationId/');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId/'),
        headers: getHeaders(userId),
      );

      print('📥 Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Erreur deleteNotification: $e');
      return false;
    }
  }

  // Sauvegarder le token FCM sur le serveur
  static Future<bool> saveFCMToken(String userId, String fcmToken) async {
    try {
      print('📡 POST /api/fcm/register/');
      print('   User ID: ${userId.substring(0, 20)}...');
      print('   FCM Token: ${fcmToken.substring(0, 30)}...');

      final body = json.encode({
        'fcm_token': fcmToken,
        'platform': 'flutter',
      });

      print('   Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/fcm/register/'),
        headers: getHeaders(userId),
        body: body,
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token FCM sauvegardé avec succès');
        return true;
      } else {
        print('❌ Erreur sauvegarde token: ${response.statusCode}');
        print('❌ Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du token FCM: $e');
      return false;
    }
  }

  // Supprimer le token FCM du serveur
  static Future<bool> deleteFCMToken(String userId, String fcmToken) async {
    try {
      print('📡 DELETE /api/fcm/unregister/');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/fcm/unregister/'),
        headers: getHeaders(userId),
        body: json.encode({
          'fcm_token': fcmToken,
        }),
      );

      print('📥 Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur lors de la suppression du token FCM: $e');
      return false;
    }
  }

  // Compter les notifications non lues
  static Future<int> getUnreadCount(String userId) async {
    try {
      final result = await getNotifications(userId);
      if (result['success']) {
        final notifications = result['notifications'] as List<NotificationModel>;
        return notifications.where((n) => !n.isRead).length;
      }
      return 0;
    } catch (e) {
      print('❌ Erreur getUnreadCount: $e');
      return 0;
    }
  }
}