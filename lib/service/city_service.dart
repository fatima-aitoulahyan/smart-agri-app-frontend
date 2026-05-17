import 'dart:convert';
import 'package:flutter/services.dart';

class CityService {
  static List<String>? _cachedCities;

  /// Charge la liste des villes marocaines depuis le fichier JSON
  static Future<List<String>> loadCities() async {
    // Si déjà chargé, retourner le cache
    if (_cachedCities != null) {
      return _cachedCities!;
    }

    try {
      // Charger le fichier JSON
      final String response = await rootBundle.loadString(
        'assets/data/moroccan_cities.json',
      );

      // Parser le JSON
      final Map<String, dynamic> data = json.decode(response);

      // Extraire et trier les villes
      _cachedCities = List<String>.from(data['cities'])..sort();

      return _cachedCities!;
    } catch (e) {
      print('❌ Erreur chargement villes: $e');
      // Retourner une liste minimale en cas d'erreur
      return [
        'Casablanca',
        'Rabat',
        'Fès',
        'Marrakech',
        'Tanger',
        'Agadir',
        'Meknès',
        'Oujda',
      ];
    }
  }

  /// Rechercher des villes par nom
  static Future<List<String>> searchCities(String query) async {
    final cities = await loadCities();

    if (query.isEmpty) {
      return cities.take(20).toList(); // Affiche les 20 premières
    }

    final lowerQuery = query.toLowerCase();
    return cities
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .take(50) // Limite à 50 résultats
        .toList();
  }
}