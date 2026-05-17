import 'package:flutter/material.dart';
import 'package:agri_frontend/service/api_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class WeatherWidget extends StatefulWidget {
  final String? city;
  final double? lat;
  final double? lon;

  const WeatherWidget({
    Key? key,
    this.city,
    this.lat,
    this.lon,
  }) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? error;

  String? city;
  double? lat;
  double? lon;

  @override
  void initState() {
    super.initState();
    _loadCityAndWeather();
  }

  Future<void> _loadCityAndWeather() async {
    if (!mounted) return;
    final userId = context.read<UserProvider>().userId;

    String finalCity = widget.city ?? 'Casablanca';
    double? finalLat = widget.lat;
    double? finalLon = widget.lon;

    if (widget.city == null) {
      try {
        final profile = await ApiService.getProfile(userId);
        if (profile['success'] == true) {
          final data = profile['data'];
          finalCity = data['city'] ?? 'Agadir';
          finalLat = data['latitude'];
          finalLon = data['longitude'];
        }
      } catch (e) {
        debugPrint("Erreur profil météo: $e");
      }
    }

    if (mounted) {
      setState(() {
        city = finalCity;
        lat = finalLat;
        lon = finalLon;
      });
      await fetchWeather();
    }
  }

  Future<void> fetchWeather() async {
    if (city == null) return;
    final userId = context.read<UserProvider>().userId;

    if (mounted) setState(() { isLoading = true; error = null; });

    try {
      final data = await ApiService.getWeather(
        city: city!,
        lat: lat,
        lon: lon,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          weatherData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  String getWeatherIcon(String? main) {
    switch (main?.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '☁️';
      case 'rain': return '🌧️';
      case 'snow': return '❄️';
      default: return '🌤️';
    }
  }

  String getWeatherDescription(String? main) {
    switch (main?.toLowerCase()) {
      case 'clear': return 'weather_clear'.tr();
      case 'clouds': return 'weather_clouds'.tr();
      case 'rain': return 'weather_rain'.tr();
      case 'snow': return 'weather_snow'.tr();
      default: return 'weather_partial_clouds'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilisation de LayoutBuilder pour s'adapter à la largeur disponible
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLoading) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          );
        }

        if (error != null) {
          return _buildErrorState();
        }

        // Extraction des données
        final temp = weatherData?['main']?['temp']?.toInt() ?? 0;
        final humidity = weatherData?['main']?['humidity']?.toInt() ?? 0;
        final windSpeed = (weatherData?['wind']?['speed'] ?? 0) * 3.6;
        final cityName = weatherData?['name'] ?? city ?? 'Casablanca';
        final weatherMain = weatherData?['weather']?[0]?['main'];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône Météo avec taille adaptative
              Text(
                getWeatherIcon(weatherMain),
                style: TextStyle(fontSize: constraints.maxWidth < 300 ? 32 : 44),
              ),
              const SizedBox(width: 12),

              // Centre : Température et Ville
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$temp°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${getWeatherDescription(weatherMain)} • $cityName',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Droite : Humidité et Vent
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSmallInfoLine(Icons.water_drop, '$humidity%'),
                    const SizedBox(height: 4),
                    _buildSmallInfoLine(Icons.air, '${windSpeed.toStringAsFixed(0)} km/h'),
                    const SizedBox(height: 4),
                    // Petit bouton de rafraîchissement
                    GestureDetector(
                      onTap: fetchWeather,
                      child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallInfoLine(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.white54),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: Colors.white54),
          const SizedBox(width: 8),
          Text('error_loading'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
          IconButton(onPressed: fetchWeather, icon: const Icon(Icons.refresh, color: Colors.white, size: 18)),
        ],
      ),
    );
  }
}