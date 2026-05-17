import 'package:flutter/material.dart';
import '../models/fertilizer_model.dart';
import '../service/fertilizer_service.dart';

class FertilizerCalculatorPage extends StatefulWidget {
  const FertilizerCalculatorPage({super.key});

  @override
  State<FertilizerCalculatorPage> createState() => _FertilizerCalculatorPageState();
}

class _FertilizerCalculatorPageState extends State<FertilizerCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final FertilizerService _service = FertilizerService();

  String? _selectedCrop;
  String? _selectedStageName;
  String? _selectedSoilName;
  String? _selectedWaterName;

  FertilizerCalculation? _result;
  bool _isCalculating = false;

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final stages = FertilizerService.getCropStages();
    final soils = FertilizerService.getSoilTypes();
    final waters = FertilizerService.getWaterQualities();

    setState(() => _isCalculating = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      final result = _service.calculate(
        cropType: _selectedCrop!,
        stage: stages.firstWhere((s) => s.name == _selectedStageName),
        soilType: soils.firstWhere((s) => s.name == _selectedSoilName),
        waterQuality: waters.firstWhere((w) => w.name == _selectedWaterName),
        areaHectares: double.parse(_areaController.text),
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isCalculating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Calculateur d\'Engrais',
          style: TextStyle(
            fontWeight: FontWeight.w600,

          ),
        ),

        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header simple
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(

              ),
              child: Text(
                'Optimisez votre fertilisation',
                textAlign: TextAlign.center,
                style: TextStyle(

                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Formulaire
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card pour les inputs
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paramètres de culture',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildModernDropdown(
                            label: 'Type de culture',
                            value: _selectedCrop,
                            items: FertilizerService.getAvailableCrops(),
                            onChanged: (val) => setState(() => _selectedCrop = val),
                          ),
                          const SizedBox(height: 16),

                          _buildModernDropdown(
                            label: 'Stade de développement',
                            value: _selectedStageName,
                            items: FertilizerService.getCropStages()
                                .map((e) => e.name)
                                .toList(),
                            onChanged: (val) => setState(() => _selectedStageName = val),
                          ),
                          const SizedBox(height: 16),

                          _buildModernDropdown(
                            label: 'Type de sol',
                            value: _selectedSoilName,
                            items: FertilizerService.getSoilTypes()
                                .map((e) => e.name)
                                .toList(),
                            onChanged: (val) => setState(() => _selectedSoilName = val),
                          ),
                          const SizedBox(height: 16),

                          _buildModernDropdown(
                            label: 'Qualité de l\'eau',
                            value: _selectedWaterName,
                            items: FertilizerService.getWaterQualities()
                                .map((e) => e.name)
                                .toList(),
                            onChanged: (val) => setState(() => _selectedWaterName = val),
                          ),
                          const SizedBox(height: 16),

                          _buildModernTextField(
                            controller: _areaController,
                            label: 'Surface',
                            suffix: 'ha',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton calculer
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isCalculating ? null : _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isCalculating
                            ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Calcul en cours...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : const Text(
                          'CALCULER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    if (_result != null) ...[
                      const SizedBox(height: 24),
                      _buildResults(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ))
              .toList(),
          onChanged: (val) {
            onChanged(val);
            setState(() => _result = null);
          },
          validator: (v) => v == null ? 'Champ obligatoire' : null,
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header résultats
          const Text(
            'Résultats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 20),

          // Besoins nutritifs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Besoins nutritifs totaux',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNutrientRow('Azote (N)', _result!.nitrogen, const Color(0xFF1976D2)),
                const Divider(height: 24),
                _buildNutrientRow('Phosphore (P)', _result!.phosphorus, const Color(0xFFFF6F00)),
                const Divider(height: 24),
                _buildNutrientRow('Potassium (K)', _result!.potassium, const Color(0xFF7B1FA2)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recommandations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommandations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 12),
                ..._result!.recommendations.map(
                      (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF424242),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} kg',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}