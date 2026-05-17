import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'PlantAnalysis.dart';

class PlantDiagnosisPage extends StatelessWidget {
  final PlantAnalysisResult result;
  final String? imagePath;

  const PlantDiagnosisPage({
    super.key,
    required this.result,
    this.imagePath,
  });

  static const String baseUrl = "https://unelaborate-transversally-katheryn.ngrok-free.dev";

  // --- Fonction Utilitaire de Traduction ---
  String _getText(dynamic data, BuildContext context) {
    if (data == null) return "not_available".tr();

    // Si c'est déjà une String (sécurité pour les anciennes données)
    if (data is String) return data;

    // Si c'est une Map (notre nouveau format)
    if (data is Map) {
      if (data.isEmpty) return "not_available".tr();
      String code = context.locale.languageCode; // 'fr', 'ar', 'en'
      return data[code]?.toString() ?? data['fr']?.toString() ?? data.values.first.toString();
    }

    return "not_available".tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildDiagnosisBadge(context),
              _buildSectionHeader("general_information".tr()),
              _buildMainInfoCard(context),

              // Vérification de la prévention (Map de Listes)
              if (result.prevention != null && result.prevention!.isNotEmpty) ...[
                _buildSectionHeader("prevention_advice".tr()),
                _buildPreventionCard(context),
              ],

              if (result.onssaTreatments != null && result.onssaTreatments!.isNotEmpty) ...[
                _buildSectionHeader("onssa_approved_treatments".tr()),
                _buildTreatmentsList(context),
              ],

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      backgroundColor: Colors.green.shade800,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null)
              imagePath!.startsWith('http')
                  ? Image.network(
                imagePath!,
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
                  : File(imagePath!).existsSync()
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : _buildDefaultPlantIcon()
            else
              _buildDefaultPlantIcon(),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black38, Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          _getText(result.plant, context),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildDefaultPlantIcon() {
    return Container(
      color: Colors.green.shade100,
      child: const Icon(Icons.eco, size: 100, color: Colors.green),
    );
  }

  Widget _buildDiagnosisBadge(BuildContext context) {
    final bool healthy = result.isHealthy;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: healthy ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: healthy ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: healthy ? Colors.green.shade700 : Colors.red.shade700,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthy
                      ? "diagnosis_healthy".tr()
                      : "${"alert".tr()} : ${_getText(result.disease, context)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: healthy ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
                Text(
                  "${"model_confidence".tr()} : ${(result.confidence).toStringAsFixed(1)}%",
                  style: TextStyle(color: healthy ? Colors.green.shade700 : Colors.red.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (result.description != null) ...[
            _buildDetailItem(
                Icons.info_outline,
                "description".tr(),
                _getText(result.description, context)
            ),
            const Divider(height: 30),
          ],
          Row(
            children: [
              Expanded(
                  child: _buildDetailItem(
                      Icons.science_outlined,
                      "agent".tr(),
                      result.bioAggressorType ?? "not_available".tr()
                  )
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                  child: _buildDetailItem(
                      Icons.straighten,
                      "severity".tr(),
                      result.severity ?? "not_available".tr(),
                      isSeverity: true
                  )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreventionCard(BuildContext context) {
    // Extraction de la liste de conseils selon la langue
    String code = context.locale.languageCode;
    List<String> advices = [];

    if (result.prevention != null) {
      advices = result.prevention![code] ?? result.prevention!['fr'] ?? result.prevention!.values.first;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: advices.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(m, style: const TextStyle(fontSize: 15, height: 1.4))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTreatmentsList(BuildContext context) {
    return Column(
      children: result.onssaTreatments!.map((t) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration().copyWith(
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blue)),
                ),
                const Icon(Icons.medication_liquid, color: Colors.blue),
              ],
            ),
            const Divider(height: 24),
            _buildSubDetail("active_ingredient".tr(), t.activeIngredient),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSubDetail("dosage".tr(), t.dosage)),
                Expanded(child: _buildSubDetail("dar_delay".tr(), "${t.dar} ${"days".tr()}")),
              ],
            ),
            if (t.nbrApplication.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildApplicationBadge(t.nbrApplication, context),
            ]
          ],
        ),
      )).toList(),
    );
  }

  // --- Méthodes d'aide (Helpers) ---
  Widget _buildApplicationBadge(String nbr, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat_rounded, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Text("${"max".tr()} : $nbr ${"applications".tr()}",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool isSeverity = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSeverity ? _getSeverityColor(value) : Colors.black87
          ),
        ),
      ],
    );
  }

  Widget _buildSubDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('élevée') || s.contains('high') || s.contains('عالية')) return Colors.red.shade700;
    if (s.contains('moyenne') || s.contains('medium') || s.contains('متوسطة')) return Colors.orange.shade700;
    return Colors.green.shade700;
  }
}