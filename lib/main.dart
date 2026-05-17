import 'dart:io';

import 'package:agri_frontend/service/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:agri_frontend/dash/dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:agri_frontend/service/firebase_notification_service.dart'; // ← Firebase Notifications

class UserProvider extends ChangeNotifier {
  String _userId;

  UserProvider(this._userId);

  String get userId => _userId;

  void setUserId(String id) {
    _userId = id;
    notifyListeners();

    if (id.isNotEmpty && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseNotificationService.initialize(id);
    }
  }

  void clearUserId() {
    if (_userId.isNotEmpty && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseNotificationService.unsubscribe(_userId);
    }
    _userId = '';
    notifyListeners();
  }
}

// =======================
// 2️⃣ Firebase Options (à remplacer avec vos valeurs)
// =======================
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
    /*case TargetPlatform.iOS:
        return ios;*/
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXv-SXtwleL9zUiCJSBuOhu5sZ_enNPos',
    appId: '1:981258579305:android:7379340f3c90da9a5c21f8',
    messagingSenderId: '981258579305',
    projectId: 'agriapp-923a3',
    storageBucket: 'agriapp-923a3.firebasestorage.app',
  );

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');

  if (userId == null) {
    userId = const Uuid().v4();
    await prefs.setString('userId', userId);
    print('🆕 Nouveau userId créé: $userId');
  } else {
    print('♻️ userId récupéré: $userId');
  }

  return userId;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚡ Initialiser EasyLocalization
  await EasyLocalization.ensureInitialized();

  // ⚡ Initialiser Firebase uniquement sur Android/iOS
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation Firebase: $e');
    }
  } else {
    print('⚠️ Firebase non disponible sur cette plateforme (Windows, Web ou ARM64)');
  }

  // ⚡ Créer ou récupérer userId
  final String anonymousUserId = await getOrCreateUserId();

  // ⚡ Créer l'utilisateur sur le backend
  final apiService = ApiService();
  await apiService.createUserOnBackend(anonymousUserId);

  // ⚡ Initialiser Firebase Messaging IMMÉDIATEMENT après la création du user
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await FirebaseNotificationService.initialize(anonymousUserId);
      print('✅ Firebase Messaging initialisé pour user: ${anonymousUserId.substring(0, 20)}...');
    } catch (e) {
      print('❌ Erreur initialisation Firebase Messaging: $e');
    }
  }

  // Configurer l'UI système
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Lancer l'app avec Provider et EasyLocalization
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      saveLocale: true,
      child: ChangeNotifierProvider(
        create: (_) => UserProvider(anonymousUserId),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriVision',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green.shade700,
        scaffoldBackgroundColor: Colors.grey.shade50,
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: DashboardPage(),
    );
  }
}
