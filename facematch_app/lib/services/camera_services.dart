import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  Future<void> initialize() async {
    if (isInitialized) return;

    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera is available on this device.');
    }

    CameraDescription? frontCamera;

    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera == null) {
      throw Exception('No front camera was found.');
    }

    final newController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = newController;

    try {
      await newController.initialize();
    } catch (_) {
      _controller = null;
      await newController.dispose();
      rethrow;
    }
  }

  Future<XFile> takePicture() async {
    final activeController = _controller;

    if (activeController == null || !activeController.value.isInitialized) {
      throw Exception('The camera is not ready.');
    }

    if (activeController.value.isTakingPicture) {
      throw Exception('A photo is already being captured.');
    }

    return activeController.takePicture();
  }

  Future<void> dispose() async {
    final activeController = _controller;
    _controller = null;

    if (activeController != null) {
      await activeController.dispose();
    }
  }
}
