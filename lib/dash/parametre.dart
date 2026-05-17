import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:agri_frontend/service/api_service.dart';
import 'package:agri_frontend/service/city_service.dart';

class ParametrePage extends StatefulWidget {
  final String userId;

  const ParametrePage({super.key, required this.userId});

  @override
  State<ParametrePage> createState() => _ParametrePageState();
}

class _ParametrePageState extends State<ParametrePage> {
  String _language = 'fr';
  String _city = '';
  bool _isLoading = false;
  List<String> _cities = [];

  // Préférences notifications
  bool _notificationsEnabled = true;
  bool _weatherAlertsEnabled = true;
  bool _irrigationAlertsEnabled = true;

  List<String> _filteredCities = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCities();
    _loadNotificationPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final cities = await CityService.loadCities();
    setState(() {
      _cities = cities;
      _filteredCities = cities;
    });
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _cities;
      } else {
        _filteredCities = _cities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getProfile(widget.userId);

      if (result['success'] == true) {
        final data = result['data'] ?? {};

        setState(() {
          _language = data['preferred_language'] ?? 'fr';
          _city = data['city'] ?? '';
        });

        await context.setLocale(Locale(_language));
      }
    } catch (e) {
      debugPrint('❌ Erreur profil: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final result = await ApiService.getNotificationPreferences(widget.userId);

      if (result['success'] == true) {
        final prefs = result['preferences'] ?? {};
        setState(() {
          _notificationsEnabled = prefs['notifications_enabled'] ?? true;
          _weatherAlertsEnabled = prefs['weather_alerts_enabled'] ?? true;
          _irrigationAlertsEnabled = prefs['irrigation_alerts_enabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur préférences notifications: $e');
    }
  }

  Future<void> _updateNotificationPreference(String key, bool value) async {
    final success = await ApiService.updateNotificationPreferences(
      widget.userId,
      {key: value},
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('preferences_updated'.tr()),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'parameter'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // === SECTION GÉNÉRAL ===
            _buildSectionHeader('general_settings'.tr()),
            _buildCard(
              child: Column(
                children: [
                  _buildSettingTile(
                    title: 'language'.tr(),
                    value: _getLanguageLabel(_language),
                    onTap: _showLanguageDialog,
                  ),
                  _buildDivider(),
                  _buildSettingTile(
                    title: 'city'.tr(),
                    value: _city.isEmpty ? 'not_selected'.tr() : _city,
                    onTap: _showCityDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // === SECTION NOTIFICATIONS ===
            _buildSectionHeader('notifications_settings'.tr()),
            _buildCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'enable_notifications'.tr(),
                    subtitle: 'enable_notifications_desc'.tr(),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      _updateNotificationPreference(
                          'notifications_enabled', value);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'weather_alerts'.tr(),
                    subtitle: 'weather_alerts_desc'.tr(),
                    value: _weatherAlertsEnabled,
                    enabled: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _weatherAlertsEnabled = value);
                      _updateNotificationPreference(
                          'weather_alerts_enabled', value);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'irrigation_alerts'.tr(),
                    subtitle: 'irrigation_alerts_desc'.tr(),
                    value: _irrigationAlertsEnabled,
                    enabled: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _irrigationAlertsEnabled = value);
                      _updateNotificationPreference(
                          'irrigation_alerts_enabled', value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // === SECTION À PROPOS ===
            _buildSectionHeader('about_app'.tr()),
            _buildCard(
              child: _buildSettingTile(
                title: 'about'.tr(),
                onTap: _showAboutDialog,
                showArrow: true,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // === WIDGETS HELPERS ===

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? value,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                if (value != null)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: enabled ? Colors.black87 : Colors.grey[400],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: enabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return code.toUpperCase();
    }
  }

  // === DIALOGS ===

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'choose_language'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('Français', 'fr'),
            _buildLanguageOption('English', 'en'),
            _buildLanguageOption('العربية', 'ar'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code) {
    final isSelected = _language == code;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        setState(() => _language = code);
        await context.setLocale(Locale(code));
        await ApiService.updateLanguage(widget.userId, code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.green.shade700 : Colors.black87,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: Colors.green.shade700, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _showCityDialog() async {
    if (_cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('loading_cities'.tr())),
      );
      return;
    }

    // Réinitialisation de la recherche avant d'ouvrir
    _searchController.clear();
    setState(() {
      _filteredCities = List.from(_cities);
    });

    await showDialog(
      context: context,
      builder: (context) {
        // Le StatefulBuilder est indispensable pour mettre à jour le contenu du dialogue
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                height: 520,
                child: Column(
                  children: [
                    // --- HEADER ET BARRE DE RECHERCHE ---
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'choose_city'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            onChanged: (query) {
                              // On utilise setDialogState pour rafraîchir UNIQUEMENT le dialogue
                              setDialogState(() {
                                if (query.isEmpty) {
                                  _filteredCities = _cities;
                                } else {
                                  _filteredCities = _cities
                                      .where((city) => city
                                      .toLowerCase()
                                      .contains(query.toLowerCase()))
                                      .toList();
                                }
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'search_city_hint'.tr(),
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade600,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey[200]),

                    // --- LISTE DES VILLES FILTRÉES ---
                    Expanded(
                      child: _filteredCities.isEmpty
                          ? Center(
                        child: Text(
                          'Aucune ville trouvée',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                          : ListView.builder(
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = _filteredCities[index];
                          final isSelected = city == _city;

                          return InkWell(
                            onTap: () async {
                              Navigator.pop(context);
                              // Mise à jour de la page principale
                              setState(() => _city = city);

                              final success = await ApiService.updateCity(
                                widget.userId,
                                city,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? '${'city_updated'.tr()}: $city'
                                        : 'error_updating_city'.tr()),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green.shade50
                                    : Colors.transparent,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    city,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? Colors.green.shade700
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Fellah Smart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Application de détection des maladies des plantes par IA',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'close'.tr(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}