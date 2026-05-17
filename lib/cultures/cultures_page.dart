// dash/cultures_page.dart - Version avec style image comme la référence

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../models/crop_models.dart';
import '../service/api_crop_service.dart' hide Crop;
import 'add_crop_page.dart';
import 'crop_detail_page.dart' hide Crop;
import 'package:provider/provider.dart';


class CulturesPage extends StatefulWidget {
  const CulturesPage({super.key});

  @override
  State<CulturesPage> createState() => _CulturesPageState();
}

class _CulturesPageState extends State<CulturesPage> with SingleTickerProviderStateMixin {
  late Future<List<Crop>> _cropsFuture;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, S, A, M
  bool _showFilterMenu = false; // Pour afficher/masquer le menu de filtre
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _cropsFuture = _fetchCrops();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<List<Crop>> _fetchCrops() async {
    final userId = context.read<UserProvider>().userId;
    try {
      final List<Map<String, dynamic>> rawData =
      await ApiCropService.fetchCrops(userId);
      return rawData.map((data) => Crop.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to load crops: $e');
    }
  }

  void _refreshCrops() {
    setState(() {
      _cropsFuture = _fetchCrops();
    });
  }

  List<Crop> _filterCrops(List<Crop> crops) {
    return crops.where((crop) {
      final matchesSearch = crop.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          crop.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == 'all' || crop.healthStatus == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(),
          ),

          SliverToBoxAdapter(
            child: FutureBuilder<List<Crop>>(
              future: _cropsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return _buildStatsCards(snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          FutureBuilder<List<Crop>>(
            future: _cropsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _buildErrorState(snapshot.error.toString()),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(context),
                );
              } else {
                final filteredCrops = _filterCrops(snapshot.data!);

                if (filteredCrops.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildNoResultsState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return _buildImageStyleCropCard(context, filteredCrops[index], index);
                      },
                      childCount: filteredCrops.length,
                    ),
                  ),
                );
              }
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: _buildAnimatedFAB(),
    );
  }

  // 🎴 NOUVELLE CARTE AVEC IMAGE (Style référence)
  Widget _buildImageStyleCropCard(BuildContext context, Crop crop, int index) {


    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _openCropDetails(crop),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 📸 IMAGE À GAUCHE (ou icône par défaut)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: crop.lastAnalysisImage != null && crop.lastAnalysisImage!.isNotEmpty
                        ? Image.network(
                      crop.lastAnalysisImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultPlantIcon();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        );
                      },
                    )
                        : _buildDefaultPlantIcon(),
                  ),
                ),

                const SizedBox(width: 16),

                // 📝 INFORMATIONS À DROITE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de la plante
                      Text(
                        crop.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Nom scientifique (ou localisation)
                      Text(
                        crop.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Date de plantation
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMMM yyyy', 'fr').format(crop.plantingDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Menu options
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'details') {
                      _openCropDetails(crop);
                    } else if (value == 'delete') {
                      _showDeleteDialog(crop);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, size: 20),
                          const SizedBox(width: 12),
                          Text('view_details'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                          const SizedBox(width: 12),
                          Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Icône par défaut si pas d'image
  Widget _buildDefaultPlantIcon() {
    return Container(
      color: Colors.green[50],
      child: Icon(
        Icons.grass,
        size: 40,
        color: Colors.green[300],
      ),
    );
  }

  // 🔍 Barre de recherche avec bouton de filtre
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Barre de recherche
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'search_crops'.tr(),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.green.shade300, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton de filtre
          Builder(
            builder: (filterContext) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () async {
                    // Trouver la position exacte du bouton
                    final RenderBox button = filterContext.findRenderObject() as RenderBox;
                    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

                    // Afficher le menu flottant juste sous le bouton
                    final selected = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      items: [
                        _buildFilterMenuItem('all', 'Tous'),
                        _buildFilterMenuItem('S', 'Sain'),
                        _buildFilterMenuItem('A', 'Attention'),
                        _buildFilterMenuItem('M', 'Malade'),
                      ],
                    );

                    // Si l'utilisateur a choisi une option
                    if (selected != null) {
                      setState(() {
                        _filterStatus = selected;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      Icons.filter_list,
                      color: Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

// Menu item pour le filtre
  PopupMenuItem<String> _buildFilterMenuItem(String value, String label) {
    final isSelected = _filterStatus == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check,
              size: 20,
              color: Colors.black,
            ),
        ],
      ),
    );
  }




  // 📊 Cartes de statistiques sans icônes
  Widget _buildStatsCards(List<Crop> crops) {
    final healthyCount = crops.where((c) => c.healthStatus == 'S').length;
    final attentionCount = crops.where((c) => c.healthStatus == 'A').length;
    final diseasedCount = crops.where((c) => c.healthStatus == 'M').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('healthy'.tr(), healthyCount.toString(), Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('attention'.tr(), attentionCount.toString(), Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('diseased'.tr(), diseasedCount.toString(), Colors.red),
          ),
        ],
      ),
    );
  }

// Carte de statistiques épurée
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🚫 État vide
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.grass_outlined,
                size: 80,
                color: Colors.green.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_crops_yet'.tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'start_by_adding_crop'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'no_results_found'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_search'.tr(),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'error_loading_crops'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshCrops,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
      child: FloatingActionButton(
        onPressed: () => _openAddCropPage(),  // ✅ Retirer (context)
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }


  void _openAddCropPage() async {  // ✅ Retirer BuildContext context
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCropPage(),
      ),
    );

    // ✅ Rafraîchir UNIQUEMENT si une culture a été ajoutée
    if (result == true) {
      _refreshCrops();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('crop_added_successfully'.tr()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
    // ✅ Si result == false ou null, rien ne se passe (pas de rafraîchissement)
  }

  void _openCropDetails(Crop crop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropDetailPage(
          crop: crop,
          onUpdate: _refreshCrops,
        ),
      ),
    );
  }

  void _showDeleteDialog(Crop crop) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_crop'.tr()),
        content: Text('confirm_delete_crop'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    // ✅ Si l'utilisateur a confirmé la suppression
    if (confirmed == true) {
      try {
        final userId = context.read<UserProvider>().userId;

        // Afficher un loader
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('deleting_crop'.tr()),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // ✅ Appel API pour supprimer la culture
        await ApiCropService.deleteCrop(userId, crop.id);

        // ✅ Rafraîchir la liste
        _refreshCrops();

        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('crop_deleted_successfully'.tr()),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        // Afficher un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_deleting_crop'.tr() + ': ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }
}