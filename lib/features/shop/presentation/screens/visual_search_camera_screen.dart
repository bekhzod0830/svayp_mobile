import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A Pinterest-style full-screen camera screen.
///
/// Returns an [XFile] (captured photo or gallery pick) via [Navigator.pop].
class VisualSearchCameraScreen extends StatefulWidget {
  const VisualSearchCameraScreen({super.key});

  @override
  State<VisualSearchCameraScreen> createState() =>
      _VisualSearchCameraScreenState();
}

class _VisualSearchCameraScreenState extends State<VisualSearchCameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0; // 0 = back, 1 = front
  bool _initialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _startCamera(_cameras[_cameraIndex]);
    } catch (_) {}
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final prev = _controller;
    if (prev != null) {
      await prev.dispose();
    }
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      setState(() => _initialized = false);
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(c.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    if (_isCapturing || _controller == null || !_initialized) return;
    setState(() => _isCapturing = true);
    try {
      final file = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, file);
    } catch (_) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _initialized = false);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _openGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file != null && mounted) Navigator.pop(context, file);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live camera preview (full-bleed, Pinterest-style)
          if (_initialized && _controller != null)
            _FullBleedPreview(controller: _controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),

          // Close button — top-left
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: _CircleIconButton(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom controls: [gallery] [capture] [flip]
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _GalleryButton(onTap: _openGallery),
                    _CaptureButton(onTap: _capture, busy: _isCapturing),
                    _FlipButton(
                      onTap: _cameras.length >= 2 ? _flipCamera : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview widget: scales to fill the screen without letterboxing
// ─────────────────────────────────────────────────────────────────────────────
class _FullBleedPreview extends StatelessWidget {
  const _FullBleedPreview({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Compute scale so that the preview always covers the entire screen
    var scale = controller.value.aspectRatio * size.aspectRatio;
    if (scale < 1.0) scale = 1.0 / scale;
    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(controller)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Gallery thumbnail / picker button — bottom-left
class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

/// Shutter button — center
class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap, required this.busy});
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: busy ? Colors.white.withOpacity(0.4) : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Flip-camera button — bottom-right
class _FlipButton extends StatelessWidget {
  const _FlipButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: const Icon(
          Icons.flip_camera_ios_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

/// Small frosted-glass icon button used in the top area
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.35),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
