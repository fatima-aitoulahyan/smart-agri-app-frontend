import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:agri_frontend/dash/parametre.dart';
import 'package:agri_frontend/widgets/weather_widget.dart';
import 'package:agri_frontend/widgets/scan_iamges.dart';
import 'package:agri_frontend/widgets/ai_chat_page.dart';
import 'package:agri_frontend/widgets/PlanningPage.dart';
import 'package:agri_frontend/service/api_service.dart';
import 'package:http/http.dart';

import '../cultures/add_crop_page.dart';
import '../cultures/crop_detail_page.dart';
import '../cultures/cultures_page.dart';
import '../main.dart';
import '../service/api_crop_service.dart';
import '../service/location_update_service.dart';
import '../widgets/fertilizer_calculator_page.dart';
import '../widgets/notifications_page.dart';
import '../service/notification_service.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  bool _isLoadingLanguage = true;

  Future<void> _loadUnreadCount() async {
    final userId = context.read<UserProvider>().userId;
    final count = await NotificationService.getUnreadCount(userId);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
    _loadUnreadCount();
    _updateLocationAutomatically();
  }
  @override
  Widget build(BuildContext context) {
    final userId = context.read<UserProvider>().userId;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'AgriVision'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(),
                ),
              );

              _loadUnreadCount();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParametrePage(
                    userId: userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [

              () {
            switch (_selectedIndex) {
              case 1:
              return CulturesPage();
              case 2:
                return  ScanWidget(showAppBar: false,);
              case 3:
              return const FertilizerCalculatorPage();
              case 4:
                return ParametrePage(
                  userId: userId,

                );
              default:
                return _buildHomeContent();
            }
          }(),
          if (_selectedIndex == 0)
            Positioned(
              right: 16,
              bottom: 80,
              child: _buildAIFloatingButton(),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'dashboard'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass_outlined),
            activeIcon: Icon(Icons.grass),
            label: 'crops'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'scanner'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'fertilizer'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFloatingButton() {
    final userId = context.read<UserProvider>().userId;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiChatPage(),
          ),
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.deepPurple.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade300.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Effet de "pulse" (cercle derrière)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.purple.shade300.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            // Icône AI
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
  Future<Map<String, dynamic>> _calculateYield(String userId) async {
    try {
      final crops = await ApiCropService.fetchCrops(userId);

      if (crops.isEmpty) {
        return {'percentage': 0.0, 'value': '0', 'trend': 'neutral'};
      }

      // Compter les cultures saines
      int healthyCrops = crops.where((crop) =>
      crop['health_status'] == 'S' // Sain
      ).length;

      int warningCrops = crops.where((crop) =>
      crop['health_status'] == 'W' // Warning
      ).length;

      int criticalCrops = crops.where((crop) =>
      crop['health_status'] == 'C' // Critical
      ).length;

      // Calculer le score de santé global
      double healthScore = (healthyCrops * 100 + warningCrops * 60 + criticalCrops * 20) / crops.length;

      // Calculer le pourcentage de rendement (par rapport à 80% qui est la "normale")
      double baselineHealth = 80.0;
      double yieldPercentage = healthScore - baselineHealth;

      // Calculer le progrès moyen des cultures
      double totalProgress = 0;
      int countWithDate = 0;

      for (var crop in crops) {
        if (crop['planting_date'] != null) {
          double progress = _calculateGrowthProgress(
            crop['planting_date'],
            crop['stage'] ?? '',
          );
          totalProgress += progress;
          countWithDate++;
        }
      }

      double avgProgress = countWithDate > 0 ? (totalProgress / countWithDate) : 0.5;

      // Ajuster le rendement avec le progrès
      yieldPercentage = (yieldPercentage * 0.7) + ((avgProgress - 0.5) * 40);

      return {
        'percentage': yieldPercentage,
        'healthScore': healthScore,
        'avgProgress': avgProgress,
        'trend': yieldPercentage >= 0 ? 'positive' : 'negative',
        'healthy': healthyCrops,
        'warning': warningCrops,
        'critical': criticalCrops,
      };

    } catch (e) {
      print('Erreur calcul rendement: $e');
      return {'percentage': 0.0, 'trend': 'neutral'};
    }
  }


  Widget _buildStatsCards() {
    final userId = context.read<UserProvider>().userId;

    return Row(
      children: [
        // Nombre de cultures
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiCropService.fetchCrops(userId),
            builder: (context, snapshot) {
              String cropCount = '...';
              Color cardColor = Colors.green;

              if (snapshot.connectionState == ConnectionState.waiting) {
                cropCount = '...';
              } else if (snapshot.hasError) {
                cropCount = '0';
                cardColor = Colors.red;
              } else if (snapshot.hasData) {
                cropCount = snapshot.data!.length.toString();
              }

              return _buildStatCard(
                icon: Icons.grass,
                title: 'crops'.tr(),
                value: cropCount,
                color: cardColor,
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // Rendement
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _calculateYield(userId),
            builder: (context, snapshot) {
              String yieldValue = '...';
              Color cardColor = Colors.blue;

              if (snapshot.connectionState == ConnectionState.waiting) {
                yieldValue = '...';
              } else if (snapshot.hasError || !snapshot.hasData) {
                yieldValue = 'N/A';
                cardColor = Colors.grey;
              } else {
                final data = snapshot.data!;
                final percentage = data['percentage'] ?? 0.0;
                yieldValue = '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%';
                cardColor = percentage >= 0 ? Colors.blue : Colors.red;
              }

              return _buildStatCard(
                icon: Icons.trending_up,
                title: 'yield'.tr(),
                value: yieldValue,
                color: cardColor,
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // Alertes (existant)
        Expanded(
          child: FutureBuilder<int>(
            future: NotificationService.getUnreadCount(userId),
            builder: (context, snapshot) {
              String notificationCount = '...';
              Color cardColor = Colors.orange;

              if (snapshot.connectionState == ConnectionState.waiting) {
                notificationCount = '...';
              } else if (snapshot.hasError || !snapshot.hasData) {
                notificationCount = '0';
                cardColor = Colors.grey;
              } else {
                notificationCount = snapshot.data!.toString();
              }

              return _buildStatCard(
                icon: Icons.warning_amber_rounded,
                title: 'alerts'.tr(),
                value: notificationCount,
                color: cardColor,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // Cartes de statistiques
          _buildStatsCards(),
          const SizedBox(height: 24),

          // Météo du jour
          _buildWeatherCard(),
          const SizedBox(height: 24),

          // Actions rapides
          Text(
            'quick_actions'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Mes cultures
          Text(
            'my_crops'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCropsList(),
          const SizedBox(height: 24),

          // Alertes récentes
          Text(
            'recent_alerts'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildAlertsList(),
          const SizedBox(height: 80), // Espace pour le bouton AI
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const WeatherWidget(),
    );
  }

  Widget _buildQuickActions() {
    final userId = context.read<UserProvider>().userId;
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt,
            label: 'scanner_label'.tr(),
            color: Colors.green,
            onTap: () async {

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScanWidget(showAppBar: true,),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'add_label'.tr(),
            color: Colors.blue,
            onTap: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCropPage(),
                  ),
              );
              if (result == true) {
                // Rafraîchir la liste ou afficher un message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('crop_added_success'.tr())),
                );
                // tu peux aussi appeler ta fonction pour recharger les cultures
                // _loadCrops();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.calendar_today,
            label: 'planning'.tr(),
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanningPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropsList() {
    final crops = [
      {'name': 'Tomates', 'status': 'Sain', 'progress': 0.7, 'icon': '🍅'},
      {'name': 'Blé', 'status': 'Attention', 'progress': 0.5, 'icon': '🌾'},
      {'name': 'Maïs', 'status': 'Sain', 'progress': 0.8, 'icon': '🌽'},
    ];

    return Column(
      children: crops.map((crop) => _buildCropCard(crop)).toList(),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    // Récupérer les données du backend selon votre structure
    final id = crop['id'];
    final name = crop['name'] ?? 'Culture inconnue';
    final plantingDate = crop['planting_date']; // Format: "2024-01-15"
    final location = crop['location'] ?? '';
    final healthStatus = crop['health_status'] ?? 'S'; // S, W, C
    final healthStatusDisplay = crop['health_status_display'] ?? 'Healthy';
    final stage = crop['stage'] ?? '';

    // Données de la dernière analyse (si disponibles)
    final lastAnalysisDisease = crop['last_analysis_disease'];
    final lastAnalysisConfidence = crop['last_analysis_confidence'];
    final lastAnalysisDate = crop['last_analysis_date'];
    final lastAnalysisImage = crop['last_analysis_image'];

    // Mapper le statut de santé (S = Sain, W = Warning, C = Critical)
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (healthStatus) {
      case 'S': // Sain
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'healthy'.tr();
        break;
      case 'W': // Warning
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'warning'.tr();
        break;
      case 'C': // Critical
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'critical'.tr();
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'unknown'.tr();
    }

    // Calculer le progrès basé sur la date de plantation
    double progress = _calculateGrowthProgress(plantingDate, stage);

    // Obtenir l'emoji selon le nom de la culture
    String emoji = _getCropEmoji(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails de la culture

        },
        child: Row(
          children: [
            // Image ou Emoji de la culture
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: lastAnalysisImage != null && lastAnalysisImage.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  lastAnalysisImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Informations de la culture
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de la culture
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Localisation
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),

                  // Statut de santé
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        healthStatusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Afficher le stade si disponible
                      if (stage.isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          stage,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Barre de progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Info sur la progression
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% ${'growth'.tr()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (lastAnalysisDate != null)
                        Text(
                          _getTimeAgo(lastAnalysisDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Icône de navigation
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }


// Fonction pour calculer le progrès de croissance
  double _calculateGrowthProgress(String? plantingDate, String stage) {
    if (plantingDate == null || plantingDate.isEmpty) return 0.5;

    try {
      final planted = DateTime.parse(plantingDate);
      final now = DateTime.now();
      final daysSincePlanting = now.difference(planted).inDays;

      // Cycle de croissance moyen : 90 jours (ajustable selon la culture)
      int growthCycleDays = 90;

      // Ajuster selon le stage si disponible
      if (stage.toLowerCase().contains('germination')) {
        growthCycleDays = 120;
        return (daysSincePlanting / growthCycleDays * 0.2).clamp(0.0, 0.2);
      } else if (stage.toLowerCase().contains('croissance') ||
          stage.toLowerCase().contains('vegetative')) {
        return (0.2 + (daysSincePlanting / growthCycleDays * 0.5)).clamp(0.2, 0.7);
      } else if (stage.toLowerCase().contains('floraison') ||
          stage.toLowerCase().contains('flowering')) {
        return (0.7 + (daysSincePlanting / growthCycleDays * 0.2)).clamp(0.7, 0.9);
      } else if (stage.toLowerCase().contains('récolte') ||
          stage.toLowerCase().contains('harvest')) {
        return 1.0;
      }

      // Calcul par défaut basé sur le temps
      double progress = daysSincePlanting / growthCycleDays;
      return progress.clamp(0.0, 1.0);

    } catch (e) {
      print('Erreur calcul progression: $e');
      return 0.5;
    }
  }

// Fonction pour obtenir l'emoji selon le nom de la culture
  String _getCropEmoji(String cropName) {
    final name = cropName.toLowerCase();

    final Map<String, String> cropEmojis = {
      // Légumes
      'tomate': '🍅', 'tomato': '🍅',
      'carotte': '🥕', 'carrot': '🥕',
      'pomme de terre': '🥔', 'potato': '🥔', 'patate': '🥔',
      'laitue': '🥬', 'lettuce': '🥬', 'salade': '🥬',
      'poivron': '🫑', 'pepper': '🫑',
      'aubergine': '🍆', 'eggplant': '🍆',
      'brocoli': '🥦', 'broccoli': '🥦',
      'concombre': '🥒', 'cucumber': '🥒',
      'oignon': '🧅', 'onion': '🧅',
      'ail': '🧄', 'garlic': '🧄',
      'piment': '🌶️', 'chili': '🌶️',

      // Céréales
      'blé': '🌾', 'wheat': '🌾',
      'maïs': '🌽', 'corn': '🌽',
      'riz': '🌾', 'rice': '🌾',
      'orge': '🌾', 'barley': '🌾',
      'avoine': '🌾', 'oat': '🌾',

      // Fruits
      'fraise': '🍓', 'strawberry': '🍓',
      'pastèque': '🍉', 'watermelon': '🍉',
      'melon': '🍈',
      'raisin': '🍇', 'grape': '🍇',
      'orange': '🍊',
      'citron': '🍋', 'lemon': '🍋',
      'pomme': '🍎', 'apple': '🍎',
      'banane': '🍌', 'banana': '🍌',
      'ananas': '🍍', 'pineapple': '🍍',
      'pêche': '🍑', 'peach': '🍑',
      'cerise': '🍒', 'cherry': '🍒',

      // Arbres fruitiers
      'olive': '🫒', 'olivier': '🫒',
      'amande': '🌰', 'almond': '🌰',
      'noix': '🥜', 'nut': '🥜',

      // Légumineuses
      'haricot': '🫘', 'bean': '🫘',
      'pois': '🫛', 'pea': '🫛',
      'lentille': '🫘', 'lentil': '🫘',

      // Herbes aromatiques
      'basilic': '🌿', 'basil': '🌿',
      'menthe': '🌿', 'mint': '🌿',
      'persil': '🌿', 'parsley': '🌿',
    };

    // Recherche exacte
    if (cropEmojis.containsKey(name)) {
      return cropEmojis[name]!;
    }

    // Recherche partielle
    for (var entry in cropEmojis.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }

    // Emoji par défaut
    return '🌱';
  }

// Fonction pour calculer le temps écoulé
  String _getTimeAgo(String timestamp) {
    if (timestamp.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 30) {
        return 'Il y a ${(difference.inDays / 30).floor()}mois';
      } else if (difference.inDays > 0) {
        return 'Il y a ${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Il y a ${difference.inMinutes}min';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildAlertsList() {
    final alerts = [
      {'title': 'Arrosage recommandé', 'crop': 'Tomates', 'time': 'Il y a 2h'},
      {'title': 'Température élevée', 'crop': 'Blé', 'time': 'Il y a 5h'},
    ];

    return Column(
      children: alerts.map((alert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert['crop']} • ${alert['time']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  Future<void> _loadUserLanguage() async {
    final userId = context.read<UserProvider>().userId;
    try {
      print('🌐 Chargement de la langue préférée...');

      final result = await ApiService.getProfile(userId);

      if (result['success']) {
        final userData = result['data'];
        final userLanguage = userData['preferred_language'] ?? 'fr';

        print('✅ Langue chargée: $userLanguage');

        // Appliquer la langue
        if (mounted) {
          await context.setLocale(Locale(userLanguage));
        }
      }
    } catch (e) {
      print('❌ Erreur chargement langue: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLanguage = false;
        });
      }
    }
  }
  Future<void> _updateLocationAutomatically() async {
    final userId = context.read<UserProvider>().userId;
    try {
      print('📍 Mise à jour automatique de la localisation...');

      final result = await LocationUpdateService.updateUserLocation(userId);

      if (result['success']) {
        print('✅ Localisation mise à jour : ${result['city']}');

        // Optionnel : Afficher un message à l'utilisateur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Localisation mise à jour : ${result['city']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('⚠️ Erreur localisation: ${result['error']}');
      }
    } catch (e) {
      print('❌ Erreur _updateLocationAutomatically: $e');
    }
  }
}