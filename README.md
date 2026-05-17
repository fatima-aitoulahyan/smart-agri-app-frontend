# Fellah Smart

Application mobile Flutter de gestion agricole avec détection de maladies des plantes par IA, suivi des cultures et alertes météo.

## Description

Fellah Smart est une application mobile Android/iOS destinée aux agriculteurs.  
Elle permet de suivre les cultures, analyser les maladies des plantes à partir d’images et recevoir des alertes personnalisées.

## Fonctionnalités

- Détection de maladies des plantes par IA
- Gestion des cultures
- Météo en temps réel
- Notifications (météo et irrigation)
- Tableau de bord
- Planning agricole
- Calculateur d’engrais
- Multilingue (FR / EN / AR)
- Paramètres utilisateur (ville, langue, notifications)

## Technologies

- Flutter (Dart)
- Provider
- EasyLocalization
- Firebase Cloud Messaging
- flutter_local_notifications
- SharedPreferences
- HTTP (REST API)
- Backend Django REST Framework

## Configuration
Modifier l’URL du backend dans :

static const String baseUrl = "https://votre-backend.com/api";

## Installation

```bash
git clone https://github.com/fatima-aitoulahyan/smart-agri-app-frontend.git
cd Agri_frontend
flutter pub get
flutter run
