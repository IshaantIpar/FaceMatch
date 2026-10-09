
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/face_match_result.dart';
import '../services/camera_services.dart';
import '../services/face_match_api.dart';
import '../services/image_picker_services.dart';

class FaceMatchHomeScreen extends StatefulWidget {
  const FaceMatchHomeScreen({super.key});

  @override
  State<FaceMatchHomeScreen> createState() => _FaceMatchHomeScreenState();
}

class _FaceMatchHomeScreenState extends State<FaceMatchHomeScreen> {
  final CameraService _cameraService = CameraService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  final FaceMatchApi _faceMatchApi = FaceMatchApi();

  File? _selfie;
  File? _referenceImage;

  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isPickingReference = false;
  bool _isComparing = false;

  String? _cameraError;
  String? _matchError;
  FaceMatchResult? _matchResult;

  static const Color _backgroundColor = Color(0xFF0D111B);
  static const Color _cardColor = Color(0xFF171D29);
  static const Color _accentColor = Color(0xFFB7C7FF);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    setState(() {
      _isInitializing = true;
      _cameraError = null;
    });

    try {
      await _cameraService.initialize();

      if (!mounted) {
        await _cameraService.dispose();
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraError = _friendlyCameraError(error);
      });
    }
  }

  String _friendlyCameraError(Object error) {
    final message = error.toString();

    if (message.toLowerCase().contains('permission')) {
      return 'Camera access was denied. Please allow camera permission '
          'in your phone settings and try again.';
    }

    return 'Unable to start the camera. Please check camera permissions '
        'and try again.\n\n$message';
  }

  void _clearMatchResult() {
    _matchResult = null;
    _matchError = null;
  }

  Future<void> _captureSelfie() async {
    if (_isCapturing || _isInitializing || _cameraError != null) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      final capturedImage = await _cameraService.takePicture();

      if (!mounted) return;

      setState(() {
        _selfie = File(capturedImage.path);
        _isCapturing = false;
        _clearMatchResult();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selfie captured successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not capture selfie: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _retakeSelfie() {
    if (_isComparing) return;

    setState(() {
      _selfie = null;
      _clearMatchResult();
    });
  }

  Future<void> _pickReferenceImage() async {
    if (_isPickingReference || _isComparing) return;

    setState(() {
      _isPickingReference = true;
    });

    try {
      final pickedImage = await _imagePickerService.pickReferencePhoto();

      if (!mounted) return;

      if (pickedImage != null) {
        setState(() {
          _referenceImage = File(pickedImage.path);
          _clearMatchResult();
        });
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select photo: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingReference = false;
        });
      }
    }
  }

  Future<void> _compareFaces() async {
    if (_selfie == null ||
        _referenceImage == null ||
        _isComparing) {
      return;
    }

    setState(() {
      _isComparing = true;
      _clearMatchResult();
    });

    try {
      final result = await _faceMatchApi.compareFaces(
        selfie: _selfie!,
        reference: _referenceImage!,
      );

      if (!mounted) return;

      setState(() {
        _matchResult = result;
      });
    } catch (error) {
      if (!mounted) return;

      String message = error.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }

      setState(() {
        _matchError = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isComparing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildIntroduction(),
                  const SizedBox(height: 24),
                  _buildCameraSection(),
                  const SizedBox(height: 20),
                  _buildInstructions(),
                  const SizedBox(height: 24),
                  _buildCaptureButton(),
                  if (_selfie != null) ...[
                    const SizedBox(height: 12),
                    _buildRetakeButton(),
                  ],
                  const SizedBox(height: 32),
                  _buildReferenceSection(),
                  const SizedBox(height: 24),
                  _buildCompareButton(),
                  if (_isComparing || _matchResult != null ||
                      _matchError != null) ...[
                    const SizedBox(height: 20),
                    _buildMatchResultSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _accentColor.withOpacity(0.25),
            ),
          ),
          child: const Icon(
            Icons.face_retouching_natural,
            color: _accentColor,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FaceMatch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'FACE SIMILARITY CHECK',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntroduction() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capture your selfie',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Position your face inside the frame. Capture a selfie and '
          'select a reference photo to compare them.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraSection() {
    final controller = _cameraService.controller;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_selfie != null)
                Image.file(
                  _selfie!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildCameraMessage(
                      icon: Icons.broken_image_outlined,
                      message: 'Unable to display the captured photo.',
                    );
                  },
                )
              else if (_isInitializing)
                _buildCameraMessage(
                  loading: true,
                  message: 'Starting front camera...',
                )
              else if (_cameraError != null)
                _buildCameraMessage(
                  icon: Icons.no_photography_outlined,
                  message: _cameraError!,
                )
              else if (controller != null &&
                  controller.value.isInitialized)
                _buildLiveCameraPreview(controller)
              else
                _buildCameraMessage(
                  icon: Icons.camera_alt_outlined,
                  message: 'Camera is not ready.',
                ),
              if (_selfie == null &&
                  !_isInitializing &&
                  _cameraError == null &&
                  controller != null &&
                  controller.value.isInitialized)
                const _FaceGuideOverlay(),
              if (_selfie == null &&
                  !_isInitializing &&
                  _cameraError == null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: _statusLabel(
                    'FRONT CAMERA',
                    Icons.circle,
                    const Color(0xFF63D6A5),
                  ),
                ),
              if (_selfie != null)
                Positioned(
                  top: 14,
                  left: 14,
                  child: _statusLabel(
                    'SELFIE CAPTURED',
                    Icons.check_circle,
                    const Color(0xFF63D6A5),
                  ),
                ),
              if (_isCapturing)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: _accentColor,
                    ),
                  ),
                ),
              if (_cameraError != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: FilledButton.icon(
                    onPressed: _initializeCamera,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry camera'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: _backgroundColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLabel(String label, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCameraPreview(CameraController controller) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: CameraPreview(controller),
    );
  }

  Widget _buildCameraMessage({
    required String message,
    IconData? icon,
    bool loading = false,
  }) {
    return Container(
      color: const Color(0xFF111722),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(color: _accentColor)
            else
              Icon(
                icon ?? Icons.camera_alt_outlined,
                color: _accentColor,
                size: 38,
              ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _accentColor,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For the best result',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Keep your face centered, look toward the camera, '
                  'and use good lighting. Make sure only one face '
                  'is visible.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    final canCapture = !_isInitializing &&
        _cameraError == null &&
        !_isCapturing &&
        !_isComparing &&
        _selfie == null;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: canCapture ? _captureSelfie : null,
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(
          _isCapturing ? 'Capturing...' : 'Capture selfie',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: _backgroundColor,
          disabledBackgroundColor: _accentColor.withOpacity(0.25),
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildRetakeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isComparing ? null : _retakeSelfie,
        icon: const Icon(Icons.refresh),
        label: const Text('Retake selfie'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reference photo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose an existing photo to compare with your selfie.',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: (_isPickingReference || _isComparing)
                ? null
                : _pickReferenceImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _referenceImage == null
                          ? _buildReferencePlaceholder()
                          : Image.file(
                              _referenceImage!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildReferencePlaceholder(
                                  message: 'Unable to display this photo.',
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: _accentColor,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _referenceImage == null
                                  ? 'Select reference photo'
                                  : 'Change reference photo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _referenceImage == null
                                  ? 'Tap here to open your gallery'
                                  : 'Tap here to choose another photo',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isPickingReference)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _accentColor,
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white60,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferencePlaceholder({String? message}) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF111722),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: _accentColor,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'Select a photo from your gallery',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompareButton() {
    final canCompare = _selfie != null &&
        _referenceImage != null &&
        !_isComparing &&
        !_isCapturing &&
        !_isPickingReference;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: canCompare ? _compareFaces : null,
        icon: _isComparing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _backgroundColor,
                ),
              )
            : const Icon(Icons.face_retouching_natural),
        label: Text(
          _isComparing ? 'Comparing faces...' : 'Compare Faces',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: _backgroundColor,
          disabledBackgroundColor: _accentColor.withOpacity(0.22),
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchResultSection() {
    if (_isComparing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _accentColor.withOpacity(0.25),
          ),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: _accentColor),
            SizedBox(height: 18),
            Text(
              'Analyzing both faces',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Uploading photos and calculating face similarity...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_matchError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF8585).withOpacity(0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF8585),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comparison failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _matchError!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _compareFaces,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                    style: TextButton.styleFrom(
                      foregroundColor: _accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final result = _matchResult;
    if (result == null) return const SizedBox.shrink();

    final isMatch = result.isMatch;
    final resultColor = isMatch
        ? const Color(0xFF63D6A5)
        : const Color(0xFFFF8585);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: resultColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.cancel,
                color: resultColor,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comparison result',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMatch ? 'MATCH' : 'NO MATCH',
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Face similarity score',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  ' / 100',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (result.score / 100).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(resultColor),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cosine similarity',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  result.similarity.toStringAsFixed(4),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'This is a prototype similarity score, not a probability '
            'that the two photos belong to the same person.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isComparing
                  ? null
                  : () {
                      setState(_clearMatchResult);
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear result'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Face guide overlay drawn on top of the live camera preview.
class _FaceGuideOverlay extends StatelessWidget {
  const _FaceGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _FaceGuidePainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

// Draws the oval face guide and its four corner accents.
class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guideWidth = size.width * 0.64;
    final guideHeight = size.height * 0.56;

    final guideRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.49),
      width: guideWidth,
      height: guideHeight,
    );

    final guidePaint = Paint()
      ..color = const Color(0xFFB7C7FF).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(guideRect, guidePaint);

    final cornerPaint = Paint()
      ..color = const Color(0xFFB7C7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLength = 19.0;

    final corners = <List<Offset>>[
      [
        Offset(guideRect.left, guideRect.top + cornerLength),
        Offset(guideRect.left, guideRect.top),
        Offset(guideRect.left + cornerLength, guideRect.top),
      ],
      [
        Offset(guideRect.right - cornerLength, guideRect.top),
        Offset(guideRect.right, guideRect.top),
        Offset(guideRect.right, guideRect.top + cornerLength),
      ],
      [
        Offset(guideRect.left, guideRect.bottom - cornerLength),
        Offset(guideRect.left, guideRect.bottom),
        Offset(guideRect.left + cornerLength, guideRect.bottom),
      ],
      [
        Offset(guideRect.right - cornerLength, guideRect.bottom),
        Offset(guideRect.right, guideRect.bottom),
        Offset(guideRect.right, guideRect.bottom - cornerLength),
      ],
    ];

    for (final points in corners) {
      final path = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(points[2].dx, points[2].dy);

      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) => false;
}
