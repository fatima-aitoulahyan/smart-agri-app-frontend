import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../service/plant_ai_service.dart';
import 'PlantAnalysis.dart';
import 'plant_diagnosis_page.dart'; // Import de la nouvelle page
import 'package:provider/provider.dart';

class ScanWidget extends StatefulWidget {
  final bool showAppBar;
  const ScanWidget({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<ScanWidget> createState() => _ScanWidgetState();
}

class _ScanWidgetState extends State<ScanWidget> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  File? _capturedImage;
  FlashMode _flashMode = FlashMode.off;
  int _selectedCameraIndex = 0;

  final PlantAIService _aiService = PlantAIService();
  PlantAnalysisResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _testBackendConnection();
  }

  Future<void> _testBackendConnection() async {
    final isConnected = await _aiService.testConnection();
    if (!mounted) return;

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Impossible de joindre le serveur'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      print('✅ Connexion au backend OK');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  // ============================================================
  // GESTION COMPLÈTE DU CYCLE DE VIE - CORRIGÉ ✅
  // ============================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = _cameraController;

    // Si la caméra n'est pas initialisée, on ne fait rien
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      // App en train de passer en arrière-plan
        await cameraController.pausePreview();
        break;

      case AppLifecycleState.paused:
      // App complètement en arrière-plan - libérer les ressources
        await _disposeCamera();
        break;

      case AppLifecycleState.resumed:
      // App de retour au premier plan
        if (!_isCameraInitialized && _capturedImage == null) {
          await _initializeCamera();
        } else if (_isCameraInitialized) {
          await cameraController.resumePreview();
        }
        break;

      case AppLifecycleState.detached:
      // App en train de se fermer
        await _disposeCamera();
        break;

      case AppLifecycleState.hidden:
      // État caché (nouveau dans Flutter 3.13+)
        break;
    }
  }

  // ============================================================
  // LIBÉRATION PROPRE DE LA CAMÉRA
  // ============================================================
  Future<void> _disposeCamera() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la libération de la caméra: $e');
    }
  }

  // ============================================================
  // INITIALISATION DE LA CAMÉRA - OPTIMISÉE ✅
  // ============================================================
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('❌ Aucune caméra disponible');
        return;
      }

      if (_selectedCameraIndex >= _cameras!.length) {
        _selectedCameraIndex = 0;
      }

      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) {
        await _cameraController?.dispose();
        return;
      }

      try {
        await _cameraController!.setFlashMode(FlashMode.off);
        _flashMode = FlashMode.off;
      } catch (e) {
        debugPrint('⚠️ Flash non supporté: $e');
      }

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ Erreur initialisation caméra: $e');

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur caméra: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // CHANGEMENT DE CAMÉRA - CORRIGÉ ✅
  // ============================================================
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty || _isScanning) return;

    try {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;

      await _cameraController?.dispose();
      _cameraController = null;

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
      });

      await _initializeCamera();
    } catch (e) {
      debugPrint('❌ Erreur changement caméra: $e');

      if (!mounted) return;
      await _initializeCamera();
    }
  }

  // ============================================================
  // TOGGLE FLASH - CORRIGÉ ✅
  // ============================================================
  Future<void> _toggleFlash() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isScanning) {
      return;
    }

    try {
      _flashMode = (_flashMode == FlashMode.off) ? FlashMode.torch : FlashMode.off;
      await _cameraController!.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('❌ Erreur toggle flash: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash non disponible sur cette caméra'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ============================================================
  // CAPTURE PHOTO - CORRIGÉE ✅
  // ============================================================
  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isScanning) {
      return;
    }

    try {
      final originalFlashMode = _flashMode;
      if (_flashMode == FlashMode.torch) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      final XFile image = await _cameraController!.takePicture();

      if (originalFlashMode == FlashMode.torch) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      if (!mounted) return;
      setState(() {
        _capturedImage = File(image.path);
      });
    } catch (e) {
      debugPrint('❌ Erreur capture photo: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la capture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // OUVERTURE GALERIE - CORRIGÉE ✅
  // ============================================================
  Future<void> _openGallery() async {
    if (_isScanning) return;

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.pausePreview();
        debugPrint("📷 Caméra mise en pause pour la galerie");
      }

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        debugPrint("📂 Image sélectionnée: ${pickedFile.path}");
        setState(() {
          _capturedImage = File(pickedFile.path);
        });
      } else {
        debugPrint("📷 Reprise de la caméra après annulation");
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          await _cameraController!.resumePreview();
        }
      }
    } catch (e, s) {
      debugPrint("❌ Erreur lors de l'ouverture de la galerie: $e");
      debugPrint("$s");

      if (!mounted) return;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.resumePreview();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ouverture de la galerie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ANALYSE IMAGE - CORRIGÉE ✅
  // ============================================================
  Future<void> _analyzeImage() async {
    final userId = context.read<UserProvider>().userId;

    if (_capturedImage == null || _isScanning) return;

    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _analysisResult = null;
    });

    try {
      print('🔬 [ScanWidget] Début de l\'analyse');
      print('📁 Image: ${_capturedImage!.path}');

      final result = await _aiService.analyzeImage(
        _capturedImage!,
        userId, context
      );

      print('✅ [ScanWidget] Analyse terminée avec succès');

      if (!mounted) return;
      setState(() {
        _analysisResult = result;
        _isScanning = false;
      });

      // ✅ Navigation vers la nouvelle page au lieu du dialog
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDiagnosisPage(
              result: result,
              imagePath: _capturedImage?.path,
            ),
          ),
        ).then((_) {
          // Reprendre la photo après fermeture de la page de diagnostic
          _retakePhoto();
        });
      }
    } catch (e, stackTrace) {
      print('❌ [ScanWidget] Erreur analyse: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _analyzeImage(),
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // REPRENDRE PHOTO - CORRIGÉE ✅
  // ============================================================
  void _retakePhoto() {
    if (_isScanning) return;

    if (!mounted) return;
    setState(() {
      _capturedImage = null;
      _analysisResult = null;
    });

    if (!_isCameraInitialized) {
      _initializeCamera();
    }
  }

  // ============================================================
  // BUILD - UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.showAppBar
          ? AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: Text('scanner_label'.tr()),
        centerTitle: true,
      )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_capturedImage != null) {
      return _buildPreviewMode();
    } else if (_isCameraInitialized && _cameraController != null) {
      return _buildCameraMode();
    } else {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // MODE CAMÉRA
  // ============================================================
  Widget _buildCameraMode() {
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        Positioned.fill(
          child: CustomPaint(painter: ScanFramePainter()),
        ),

        Positioned(
          top: 40,
          right: 16,
          child: SafeArea(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _isScanning ? null : _toggleFlash,
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _isScanning ? null : _switchCamera,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _isScanning ? null : _openGallery,
                  ),

                  GestureDetector(
                    onTap: _isScanning ? null : _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isScanning
                                ? Colors.grey
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: _isScanning
                        ? null
                        : () => Navigator.pop(context),
                    child: Text(
                      'Terminé',
                      style: TextStyle(
                        color: _isScanning
                            ? Colors.grey
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MODE PREVIEW
  // ============================================================
  Widget _buildPreviewMode() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(
            _capturedImage!,
            fit: BoxFit.contain,
          ),
        ),

        if (_isScanning)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analyse en cours...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!_isScanning)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _analyzeImage,
                        icon: const Icon(Icons.analytics),
                        label: Text('analyze_image'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _retakePhoto,
                        icon: const Icon(Icons.refresh),
                        label: Text('resume'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// PAINTER POUR LE CADRE DE SCAN
// ============================================================
class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final frameWidth = size.width * 0.75;
    final frameHeight = size.height * 0.4;
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = (size.height - frameHeight) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Coin supérieur gauche
    canvas.drawLine(
      Offset(frameLeft, frameTop + cornerLength),
      Offset(frameLeft, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop),
      Offset(frameLeft + cornerLength, frameTop),
      cornerPaint,
    );

    // Coin supérieur droit
    canvas.drawLine(
      Offset(frameLeft + frameWidth - cornerLength, frameTop),
      Offset(frameLeft + frameWidth, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop),
      Offset(frameLeft + frameWidth, frameTop + cornerLength),
      cornerPaint,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameHeight - cornerLength),
      Offset(frameLeft, frameTop + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop + frameHeight),
      Offset(frameLeft + cornerLength, frameTop + frameHeight),
      cornerPaint,
    );

    // Coin inférieur droit
    canvas.drawLine(
      Offset(frameLeft + frameWidth - cornerLength, frameTop + frameHeight),
      Offset(frameLeft + frameWidth, frameTop + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft + frameWidth, frameTop + frameHeight),
      Offset(frameLeft + frameWidth, frameTop + frameHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}