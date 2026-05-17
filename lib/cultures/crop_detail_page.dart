import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../service/api_crop_service.dart' hide Crop;
import '../service/plant_ai_service.dart';
import '../models/crop_models.dart';
import '../widgets/PlantAnalysis.dart';
import '../widgets/plant_diagnosis_page.dart';
import 'package:provider/provider.dart';

class CropDetailPage extends StatefulWidget {
  final Crop crop;
  final VoidCallback onUpdate;

  const CropDetailPage({
    super.key,
    required this.crop,
    required this.onUpdate,
  });

  @override
  State<CropDetailPage> createState() => _CropDetailPageState();
}

class _CropDetailPageState extends State<CropDetailPage> {
  late Crop _currentCrop;
  bool _isLoading = false;
  List<CropAnalysisHistoryItem> _analysisHistory = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedHistoryIds = {};
  static const String baseUrl = "https://unelaborate-transversally-katheryn.ngrok-free.dev";

  @override
  void initState() {
    super.initState();
    _currentCrop = widget.crop;
    _loadAnalysisHistory();
  }

  // --- LOGIQUE DE DONNÉES ---

  Future<void> _loadAnalysisHistory() async {
    final userId = context.read<UserProvider>().userId;
    setState(() => _isLoading = true);
    try {
      final history = await ApiCropService.getAnalysisHistory(userId, _currentCrop.id);
      setState(() {
        _analysisHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('error_loading_history'.tr(args: [e.toString()]));
    }
  }

  // --- ACTIONS DE SUPPRESSION ---

  Future<void> _deleteCrop() async {
    final userId = context.read<UserProvider>().userId;
    final confirmed = await _showConfirmDialog(
      'confirm_deletion'.tr(),
      'delete_crop_confirmation'.tr(args: [_currentCrop.name]),
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await ApiCropService.deleteCrop(userId, _currentCrop.id);
        widget.onUpdate();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _deleteSelectedAnalyses() async {
    final userId = context.read<UserProvider>().userId;
    setState(() => _isLoading = true);
    try {
      await ApiCropService.deleteMultipleAnalyses(
        userId,
        _currentCrop.id.toString(),
        _selectedHistoryIds.toList(),
      );
      setState(() {
        _analysisHistory.removeWhere((item) => _selectedHistoryIds.contains(item.id.toString()));
        _selectedHistoryIds.clear();
        _isSelectionMode = false;
        _isLoading = false;
      });
      _showSuccess('analyses_deleted'.tr());
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // --- ANALYSE IA ---

  Future<void> _pickImage(ImageSource source) async {
    final userId = context.read<UserProvider>().userId;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final imageFile = File(pickedFile.path);

        // Upload & Analyse
        await ApiCropService.uploadSensorImage(userId, _currentCrop.id, imageFile);
        final result = await PlantAIService().analyzeImage(imageFile, userId, context);

        // Sauvegarde historique
        await ApiCropService.saveAnalysisHistory(userId, _currentCrop.id, result, pickedFile.path);

        // Update UI
        await _loadAnalysisHistory();
        widget.onUpdate();

        setState(() => _isLoading = false);

        // Navigation automatique vers le résultat après scan
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDiagnosisPage(
                result: result,
                imagePath: pickedFile.path,
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  // --- NAVIGATION VERS L'HISTORIQUE ---

  void _navigateToDetails(CropAnalysisHistoryItem item) {
    // 1. Déterminer si la plante est saine
    final isHealthy = item.diseaseDetected == null ||
        item.diseaseDetected!.isEmpty ||
        item.diseaseDetected!.toLowerCase() == 'sain' ||
        item.diseaseDetected!.toLowerCase() == 'healthy' ||
        item.diseaseDetected!.toLowerCase() == 'سليم';

    // 2. Helper pour convertir en Map<String, String>
    Map<String, String> _ensureMap(dynamic value, String defaultValue) {
      if (value == null) return {'fr': defaultValue, 'ar': defaultValue, 'en': defaultValue};

      if (value is Map) {
        return value.map((key, val) => MapEntry(
            key.toString(),
            val?.toString() ?? defaultValue
        ));
      }

      if (value is String) {
        return {'fr': value, 'ar': value, 'en': value};
      }

      return {'fr': defaultValue, 'ar': defaultValue, 'en': defaultValue};
    }

    // 3. Helper pour convertir en Map<String, List<String>>
    Map<String, List<String>> _ensurePreventionMap(dynamic value) {
      if (value == null) return {'fr': [], 'ar': [], 'en': []};

      if (value is Map) {
        try {
          return value.map((key, val) {
            String keyStr = key.toString();
            List<String> listVal;

            if (val is List) {
              listVal = val.map((e) => e?.toString() ?? '').toList();
            } else if (val is String) {
              listVal = [val];
            } else {
              listVal = [];
            }

            return MapEntry(keyStr, listVal);
          });
        } catch (e) {
          print('⚠️ Erreur conversion prevention Map: $e');
          return {'fr': [], 'ar': [], 'en': []};
        }
      }

      if (value is List) {
        try {
          return {'fr': value.map((e) => e?.toString() ?? '').toList()};
        } catch (e) {
          print('⚠️ Erreur conversion prevention List: $e');
          return {'fr': [], 'ar': [], 'en': []};
        }
      }

      if (value is String) {
        return {'fr': [value], 'ar': [value], 'en': [value]};
      }

      return {'fr': [], 'ar': [], 'en': []};
    }

    // 4. Création de l'objet Result
    final result = PlantAnalysisResult(
      plant: _ensureMap(item.plant, _currentCrop.name),
      disease: _ensureMap(
          item.disease,
          isHealthy ? "healthy".tr() : "unknown".tr()
      ),
      description: _ensureMap(item.description, "no_description_available".tr()),

      confidence: item.confidence ?? 0.0,
      isHealthy: isHealthy,
      severity: item.severity,
      onssaTerm: item.onssaTerm,
      bioAggressorType: item.bioAggressorType,

      prevention: _ensurePreventionMap(item.prevention),
      onssaTreatments: item.onssaTreatments,
    );

    // 5. Navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantDiagnosisPage(
          result: result,
          imagePath: item.imageUrl != null
              ? (item.imageUrl!.startsWith('http')
              ? item.imageUrl!
              : "$baseUrl${item.imageUrl}")
              : null,
        ),
      ),
    );
  }

  // --- INTERFACE UTILISATEUR (UI) ---

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentCrop.healthStatus);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(statusColor),
          SliverToBoxAdapter(
            child: _isLoading
                ? const LinearProgressIndicator()
                : Column(
              children: [
                _buildQuickStats(statusColor),
                _buildHistoryHeader(),
                _buildHistoryList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(
        onPressed: () => _showPickImageOptions(),
        label: Text('scan'.tr(), style: const TextStyle(color: Colors.white)),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildAppBar(Color color) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_currentCrop.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Icon(Icons.grass, size: 80, color: Colors.white24),
        ),
      ),
      actions: [
        if (_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _selectedHistoryIds.isEmpty ? null : _deleteSelectedAnalyses,
          )
        else
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteCrop,
          ),
      ],
    );
  }

  Widget _buildQuickStats(Color statusColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statColumn(Icons.health_and_safety, _currentCrop.healthStatusDisplay, 'status'.tr(), statusColor),
          const VerticalDivider(),
          _statColumn(Icons.history, _analysisHistory.length.toString(), 'analyses'.tr(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'analysis_history'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_analysisHistory.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedHistoryIds.clear();
              }),
              child: Text(_isSelectionMode ? 'cancel'.tr() : 'select'.tr()),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_analysisHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text('no_history_yet'.tr(), style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _analysisHistory.length,
      itemBuilder: (context, index) {
        final item = _analysisHistory[index];
        final isSelected = _selectedHistoryIds.contains(item.id.toString());
        final isHealthy = item.diseaseDetected == null ||
            item.diseaseDetected!.isEmpty ||
            item.diseaseDetected!.toLowerCase() == 'healthy' ||
            item.diseaseDetected!.toLowerCase() == 'sain' ||
            item.diseaseDetected!.toLowerCase() == 'سليم';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? Colors.green : Colors.transparent, width: 2),
          ),
          child: ListTile(
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  isSelected ? _selectedHistoryIds.remove(item.id.toString()) : _selectedHistoryIds.add(item.id.toString());
                });
              } else {
                _navigateToDetails(item);
              }
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ? Image.network(
                  item.imageUrl!.startsWith('http')
                      ? item.imageUrl!
                      : "$baseUrl${item.imageUrl}",
                  fit: BoxFit.cover,
                )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            title: Text(
                isHealthy ? 'healthy'.tr() : item.diseaseDetected!,
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(item.analyzedAt)),
            trailing: _isSelectionMode
                ? Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: Colors.green)
                : Text(
                '${item.confidence?.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHealthy ? Colors.green : Colors.orange
                )
            ),
          ),
        );
      },
    );
  }

  // --- HELPERS ---

  Widget _statColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'S': return Colors.green;
      case 'A': return Colors.orange;
      case 'M': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red)
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green)
  );

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr())
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('confirm'.tr(), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;
  }

  void _showPickImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('gallery'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }
            ),
            ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('camera'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }
            ),
          ],
        ),
      ),
    );
  }
}