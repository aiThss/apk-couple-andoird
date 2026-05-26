import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  final _captionController = TextEditingController(text: 'Gửi bạn một snap nè');

  bool _uploading = false;
  String? _error;
  XFile? _pickedFile;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Camera')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: neonPink.withValues(alpha: 0.24),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  height: MediaQuery.sizeOf(context).height * 0.54,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [deepPurple, darkBg],
                    ),
                  ),
                  child: _pickedFile == null
                      ? const Icon(
                          Icons.photo_camera_rounded,
                          size: 78,
                          color: softPink,
                        )
                      : Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              child: TextField(
                controller: _captionController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  prefixIcon: Icon(Icons.chat_bubble_rounded),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlowButton(
              onPressed: _uploading || _pickedFile == null
                  ? null
                  : _uploadPicked,
              enabled: !_uploading && _pickedFile != null,
              icon: _uploading
                  ? Icons.hourglass_top_rounded
                  : Icons.send_rounded,
              label: _uploading ? 'Đang gửi...' : 'Gửi snap',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _error = null);
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1800,
    );

    if (file == null) {
      return;
    }

    setState(() => _pickedFile = file);
    await widget.dynamicThemeController.updateFromFile(File(file.path));
  }

  Future<void> _uploadPicked() async {
    final file = _pickedFile;
    if (file == null) {
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final caption = _captionController.text.trim().isEmpty
          ? 'Một khoảnh khắc mới'
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
