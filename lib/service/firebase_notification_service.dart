import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:agri_frontend/service/notification_service.dart';
import 'package:flutter/material.dart';

// Handler pour les notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Message reçu en arrière-plan: ${message.messageId}');
  print('Titre: ${message.notification?.title}');
  print('Corps: ${message.notification?.body}');
}

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static String? _fcmToken;

  // Initialiser Firebase Messaging
  static Future<void> initialize(String userId) async {
    try {
      // Demander la permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('✅ Statut de permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permission accordée pour les notifications');

        // Initialiser les notifications locales
        await _initializeLocalNotifications();

        // Obtenir le token FCM
        await _getFCMToken(userId);

        // Configurer les handlers de messages
        _setupMessageHandlers(userId);

        // Handler pour les notifications en arrière-plan
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } else {
        print('❌ Permission refusée pour les notifications');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation Firebase: $e');
    }
  }

  // Initialiser les notifications locales
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Notification cliquée: ${response.payload}');
        // Gérer la navigation ici si nécessaire
      },
    );

    // Créer un canal de notification Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'agri_notifications', // ID
      'Notifications Agricoles', // Nom
      description: 'Notifications pour les alertes météo et agricoles',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Obtenir le token FCM et l'envoyer au backend
  static Future<void> _getFCMToken(String userId) async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        // Envoyer le token au backend
        await NotificationService.saveFCMToken(userId, _fcmToken!);
        print('✅ Token FCM sauvegardé sur le serveur');
      }

      // Écouter les rafraîchissements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 Token FCM rafraîchi: $newToken');
        _fcmToken = newToken;
        await NotificationService.saveFCMToken(userId, newToken);
      });
    } catch (e) {
      print('❌ Erreur lors de l\'obtention du token FCM: $e');
    }
  }

  // Configurer les handlers de messages
  static void _setupMessageHandlers(String userId) {
    // Messages reçus quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Message reçu au premier plan');
      print('Titre: ${message.notification?.title}');
      print('Corps: ${message.notification?.body}');
      print('Data: ${message.data}');

      // Afficher une notification locale
      _showLocalNotification(message);
    });

    // Messages reçus quand l'utilisateur clique sur la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Notification cliquée, app ouverte');
      print('Data: ${message.data}');

      // Gérer la navigation ici
      // Par exemple, naviguer vers la page des notifications
    });

    // Vérifier si l'app a été ouverte depuis une notification
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App ouverte depuis une notification');
        print('Data: ${message.data}');
        // Gérer la navigation initiale ici
      }
    });
  }

  // Afficher une notification locale
  static Future<void> _showLocalNotification(RemoteMessage message) async {
     AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'agri_notifications',
      'Notifications Agricoles',
      channelDescription: 'Notifications pour les alertes météo et agricoles',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50), // Vert
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // Obtenir le token FCM actuel
  static String? get fcmToken => _fcmToken;

  // Annuler l'abonnement (lors de la déconnexion)
  static Future<void> unsubscribe(String userId) async {
    try {
      if (_fcmToken != null) {
        await NotificationService.deleteFCMToken(userId, _fcmToken!);
        await _firebaseMessaging.deleteToken();
        _fcmToken = null;
        print('✅ Token FCM supprimé');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression du token: $e');
    }
  }

  // S'abonner à un topic (optionnel, pour les notifications de groupe)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Abonné au topic: $topic');
    } catch (e) {
      print('❌ Erreur d\'abonnement au topic: $e');
    }
  }

  // Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic: $topic');
    } catch (e) {
      print('❌ Erreur de désabonnement du topic: $e');
    }
  }
}