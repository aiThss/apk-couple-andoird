import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../theme/dynamic_theme_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    required this.profile,
    required this.apiService,
    required this.dynamicThemeController,
    super.key,
  });

  final AppUser profile;
  final ApiService apiService;
  final DynamicThemeController dynamicThemeController;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();
  final _captionController = TextEditingController(text: 'Gui ban mot snap ne');

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  XFile? _capturedFile;
  bool _initializing = true;
  bool _uploading = false;
  bool _flashOn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captionController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 132),
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: _capturedFile == null ? _toggleFlash : null,
                        icon: Icon(
                          _flashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _capturedFile == null ? _switchCamera : null,
                        icon: const Icon(Icons.cameraswitch_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CameraFrame(
                    controller: _controller,
                    capturedFile: _capturedFile,
                    initializing: _initializing,
                    error: _error,
                    onRetry: _initCamera,
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Caption',
                        counterText: '',
                        prefixIcon: Icon(Icons.chat_bubble_rounded),
                      ),
                    ),
                  ),
                  if (_error != null && !_initializing) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: _CaptureDock(
                hasCapture: _capturedFile != null,
                uploading: _uploading,
                onGallery: _uploading ? null : _pickFromGallery,
                onCapture: _uploading ? null : _capture,
                onRetake: _uploading ? null : _retake,
                onSend: _uploading || _capturedFile == null
                    ? null
                    : _uploadPicked,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera found');
      }

      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      await _startController(camera);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Khong mo duoc camera: $error';
        _initializing = false;
      });
    }
  }

  Future<void> _startController(CameraDescription camera) async {
    await _controller?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;
    await controller.initialize();
    await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);

    if (!mounted) return;
    setState(() => _initializing = false);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _controller == null) return;
    final current = _controller!.description;
    final next = _cameras.firstWhere(
      (camera) => camera.name != current.name,
      orElse: () => _cameras.first,
    );
    await _startController(next);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _flashOn = !_flashOn);
    await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    try {
      final file = await controller.takePicture();
      setState(() {
        _capturedFile = file;
        _error = null;
      });
      await widget.dynamicThemeController.updateFromFile(File(file.path));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Chup anh that bai: $error');
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 84,
      maxWidth: 1600,
    );

    if (file == null) return;
    setState(() {
      _capturedFile = file;
      _error = null;
    });
    await widget.dynamicThemeController.updateFromFile(File(file.path));
  }

  void _retake() {
    setState(() {
      _capturedFile = null;
      _error = null;
    });
  }

  Future<void> _uploadPicked() async {
    final file = _capturedFile;
    if (file == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final caption = _captionController.text.trim().isEmpty
          ? 'Mot khoanh khac moi'
          : _captionController.text.trim();

      final photo = await widget.apiService.uploadPhoto(
        file: File(file.path),
        caption: caption,
      );

      if (mounted) {
        Navigator.of(context).pop(photo);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame({
    required this.controller,
    required this.capturedFile,
    required this.initializing,
    required this.error,
    required this.onRetry,
  });

  final CameraController? controller;
  final XFile? capturedFile;
  final bool initializing;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.58),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: AspectRatio(
          aspectRatio: 0.76,
          child: capturedFile != null
              ? Image.file(File(capturedFile!.path), fit: BoxFit.cover)
              : _buildPreview(context),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final camera = controller;
    if (initializing) {
      return const ColoredBox(
        color: Color(0xFF08080A),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null ||
        camera == null ||
        !camera.value.isInitialized ||
        camera.value.previewSize == null) {
      return ColoredBox(
        color: const Color(0xFF08080A),
        child: Center(
          child: GlowButton(
            onPressed: onRetry,
            icon: Icons.refresh_rounded,
            label: 'Mo lai camera',
          ),
        ),
      );
    }

    final size = camera.value.previewSize!;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(camera),
      ),
    );
  }
}

class _CaptureDock extends StatelessWidget {
  const _CaptureDock({
    required this.hasCapture,
    required this.uploading,
    required this.onGallery,
    required this.onCapture,
    required this.onRetake,
    required this.onSend,
  });

  final bool hasCapture;
  final bool uploading;
  final VoidCallback? onGallery;
  final VoidCallback? onCapture;
  final VoidCallback? onRetake;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: hasCapture
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetake,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Chup lai'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSend,
                    icon: Icon(
                      uploading
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                    ),
                    label: Text(uploading ? 'Dang gui' : 'Gui'),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                ),
                GestureDetector(
                  onTap: onCapture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.72),
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.34),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
    );
  }
}
