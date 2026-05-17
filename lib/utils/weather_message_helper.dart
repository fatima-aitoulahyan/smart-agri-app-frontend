// lib/utils/weather_message_helper.dart

import 'package:easy_localization/easy_localization.dart';

class WeatherMessageHelper {
  /// Parse et traduit un message de notification météo
  static String parseMessage(String rawMessage) {
    if (!rawMessage.contains('|')) {
      // Message déjà traduit ou format ancien
      return rawMessage;
    }

    final parts = rawMessage.split('|');
    final messageType = parts[0];

    switch (messageType) {
      case 'heavy_rain':
        if (parts.length > 1) {
          return 'weather.advice.heavy_rain_message'.tr(
            namedArgs: {'rain': parts[1]},
          );
        }
        break;

      case 'light_rain':
        if (parts.length > 1) {
          return 'weather.advice.light_rain_message'.tr(
            namedArgs: {'rain': parts[1]},
          );
        }
        break;

      case 'hot_weather':
        if (parts.length > 1) {
          return 'weather.advice.hot_weather_message'.tr(
            namedArgs: {'temp': parts[1]},
          );
        }
        break;

      case 'warm_dry':
        if (parts.length > 2) {
          return 'weather.advice.warm_dry_message'.tr(
            namedArgs: {
              'temp': parts[1],
              'humidity': parts[2],
            },
          );
        }
        break;

      case 'frost':
        if (parts.length > 1) {
          return 'weather.advice.frost_message'.tr(
            namedArgs: {'temp': parts[1]},
          );
        }
        break;

      case 'cold_weather':
        if (parts.length > 2) {
          return 'weather.advice.cold_weather_message'.tr(
            namedArgs: {
              'min': parts[1],
              'max': parts[2],
            },
          );
        }
        break;

      case 'high_humidity':
        if (parts.length > 1) {
          return 'weather.advice.high_humidity_message'.tr(
            namedArgs: {'humidity': parts[1]},
          );
        }
        break;

      case 'optimal_conditions':
        if (parts.length > 2) {
          return 'weather.advice.optimal_conditions_message'.tr(
            namedArgs: {
              'temp': parts[1],
              'humidity': parts[2],
            },
          );
        }
        break;

      case 'stable_weather':
        if (parts.length > 1) {
          return 'weather.advice.stable_weather_message'.tr(
            namedArgs: {'temp': parts[1]},
          );
        }
        break;

      case 'summary_header':
        return 'weather.advice.summary_header'.tr();
    }

    return rawMessage;
  }

  /// Parse et traduit un titre de notification météo
  static String parseTitle(String rawTitle) {
    // Enlever l'emoji si présent
    final titleWithoutEmoji = rawTitle.replaceAll(RegExp(r'[🌧️🌦️🔥☀️❄️🌡️💨✅🌤️📊]\s*'), '').trim();

    // Mapping des titres
    final titleMap = {
      'no_watering': 'weather.advice.no_watering',
      'light_watering': 'weather.advice.light_watering',
      'intensive_watering': 'weather.advice.intensive_watering',
      'watering_recommended': 'weather.advice.watering_recommended',
      'frost_alert': 'weather.advice.frost_alert',
      'minimal_watering': 'weather.advice.minimal_watering',
      'high_humidity': 'weather.advice.high_humidity',
      'favorable_conditions': 'weather.advice.favorable_conditions',
      'check_soil': 'weather.advice.check_soil',
      'irrigation_summary_3_days': 'weather.advice.irrigation_summary_3_days',
    };

    // Récupérer l'emoji original
    final emojiMatch = RegExp(r'^([🌧️🌦️🔥☀️❄️🌡️💨✅🌤️📊])\s*').firstMatch(rawTitle);
    final emoji = emojiMatch?.group(1) ?? '';

    // Chercher la traduction
    final translationKey = titleMap[titleWithoutEmoji];
    if (translationKey != null) {
      final translated = translationKey.tr();
      return emoji.isNotEmpty ? '$emoji $translated' : translated;
    }

    return rawTitle;
  }

  /// Parse un résumé multi-jours
  static String parseSummary(String rawSummary) {
    if (!rawSummary.contains('\n')) {
      return rawSummary;
    }

    final lines = rawSummary.split('\n');
    final translatedLines = <String>[];

    for (final line in lines) {
      if (line == 'summary_header') {
        translatedLines.add('weather.advice.summary_header'.tr());
      } else if (line.contains('|')) {
        final parts = line.split('|');
        if (parts.length >= 3) {
          final dayKey = parts[0];
          final titlePart = parts[1];
          final messagePart = parts[2];

          final day = _translateDay(dayKey);
          final title = parseTitle(titlePart);
          final message = parseMessage(messagePart);

          translatedLines.add('\n$day: $title - ${message.substring(0, message.length > 80 ? 80 : message.length)}...');
        }
      } else {
        translatedLines.add(line);
      }
    }

    return translatedLines.join('');
  }

  static String _translateDay(String dayKey) {
    final dayMap = {
      'tomorrow': 'weather.advice.tomorrow',
      'day_after_tomorrow': 'weather.advice.day_after_tomorrow',
      'in_3_days': 'weather.advice.in_3_days',
    };

    final translationKey = dayMap[dayKey];
    return translationKey != null ? translationKey.tr() : dayKey;
  }

  /// Détermine si un message est un résumé
  static bool isSummary(String message) {
    return message.contains('summary_header') ||
        (message.contains('\n') && message.split('\n').length > 2);
  }
}