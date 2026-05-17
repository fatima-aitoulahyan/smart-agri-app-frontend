// dash/add_crop_page.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../service/api_crop_service.dart';
import 'package:provider/provider.dart';

class AddCropPage extends StatefulWidget {

  const AddCropPage({super.key});

  @override
  State<AddCropPage> createState() => _AddCropPageState();
}

class _AddCropPageState extends State<AddCropPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now());
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitCrop() async {
    final userId = context.read<UserProvider>().userId;
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() {
        _isLoading = true;
      });

      final cropData = {
        'name': _nameController.text,
        'planting_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'location': _locationController.text,
        'stage': 'Semis',
      };

      try {
        final result = await ApiCropService.createCrop(
          userId: userId,
          name: cropData['name']!,
          plantingDate: cropData['planting_date']!,
          location: cropData['location']!,
          stage: cropData['stage'] ?? '',
        );

        // Toujours vérifier la présence de 'success' avant d'afficher
        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('crop_added_success'.tr()),
                duration: const Duration(seconds: 2),
              ),
            );
            await Future.delayed(const Duration(seconds: 2));
            Navigator.pop(context, true);
          }
        } else {
          final error = result['error'] is Map
              ? result['error'].values.first[0]
              : 'Unknown error';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('crop_add_failure'.tr(args: [error])),
              ),
            );
          }
        }
      } catch (e) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('api_error'.tr(args: [e.toString()])),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('select_date_required'.tr())),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('add_new_crop'.tr()),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Champ Nom
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'crop_name'.tr(),
                  icon: const Icon(Icons.grass),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'required_field'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Champ Localisation
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'crop_location'.tr(),
                  icon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'required_field'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Sélecteur de Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _selectedDate == null
                      ? 'select_planting_date'.tr()
                      : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDate(context),
              ),
              const Divider(),
              const SizedBox(height: 50),

              // Bouton Soumettre
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitCrop,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.save),
                  label: Text('save_crop'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}