import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/couple_photo.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme_controller.dart';
import '../widgets/adaptive_photo_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/state_message.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.profile,
    required this.apiService,
    required this.dynamicThemeController,
    required this.refreshSeed,
    required this.onPhotoUploaded,
    super.key,
  });

  final AppUser profile;
  final ApiService apiService;
  final DynamicThemeController dynamicThemeController;
  final int refreshSeed;
  final ValueChanged<CouplePhoto> onPhotoUploaded;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CouplePhoto? _photo;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed ||
        oldWidget.profile.uid != widget.profile.uid) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const StateMessage(
        icon: Icons.hourglass_top_rounded,
        title: 'Đang tải ảnh mới nhất',
        message: 'Couple Snap đang lấy khoảnh khắc gần nhất từ cloud.',
      );
    }

    if (_error != null) {
      return StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được Home',
        message: _error.toString(),
        action: GlowButton(
          onPressed: _load,
          icon: Icons.refresh_rounded,
          label: 'Thử lại',
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dynamicThemeController.updateFromUrl(_photo?.imageUrl);
    });

    return _HomeBody(
      profile: widget.profile,
      photo: _photo,
      dynamicThemeController: widget.dynamicThemeController,
      onCapture: _openCamera,
      onRefresh: _load,
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final photo = await widget.apiService.latestPhoto();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openCamera() async {
    final photo = await Navigator.of(context).push<CouplePhoto>(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          profile: widget.profile,
          apiService: widget.apiService,
          dynamicThemeController: widget.dynamicThemeController,
        ),
      ),
    );

    if (photo != null) {
      widget.onPhotoUploaded(photo);
      await _load();
    }
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.profile,
    required this.photo,
    required this.dynamicThemeController,
    required this.onCapture,
    required this.onRefresh,
  });

  final AppUser profile;
  final CouplePhoto? photo;
  final DynamicThemeController dynamicThemeController;
  final VoidCallback onCapture;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: neonPink,
        backgroundColor: deepPurple,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 118),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _PixelHeartLogo(),
                          const SizedBox(width: 10),
                          Text(
                            'Couple Snap',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photo == null
                            ? 'Chờ ảnh đầu tiên của hai người'
                            : 'Ảnh mới nhất từ ${photo!.ownerName}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: softPink.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(4),
                  glow: true,
                  child: IconButton(
                    tooltip: 'Tải lại ảnh mới nhất',
                    onPressed: () => onRefresh(),
                    icon: const Icon(Icons.refresh_rounded, color: softPink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            AdaptivePhotoCard(
              photo: photo,
              accentColor: neonPink,
              height: MediaQuery.sizeOf(context).height * 0.58,
            ),
            const SizedBox(height: 28),
            Center(
              child: GlowButton(
                circular: true,
                size: 104,
                icon: Icons.photo_camera_rounded,
                onPressed: onCapture,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelHeartLogo extends StatelessWidget {
  const _PixelHeartLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: neonPink.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: neonPink.withValues(alpha: 0.42), blurRadius: 18),
        ],
      ),
      child: const Icon(Icons.favorite_rounded, color: neonPink, size: 23),
    );
  }
}
