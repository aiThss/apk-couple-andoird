import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/couple_photo.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme_controller.dart';
import '../widgets/glow_button.dart';
import '../widgets/state_message.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({
    required this.profile,
    required this.apiService,
    required this.dynamicThemeController,
    required this.refreshSeed,
    super.key,
  });

  final AppUser profile;
  final ApiService apiService;
  final DynamicThemeController dynamicThemeController;
  final int refreshSeed;

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  List<CouplePhoto> _photos = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MemoriesScreen oldWidget) {
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
        icon: Icons.grid_view_rounded,
        title: 'Đang tải memories',
        message: 'Ảnh kỷ niệm sẽ hiện thành lưới ở đây.',
      );
    }

    if (_error != null) {
      return StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Không tải được Memories',
        message: _error.toString(),
        action: GlowButton(
          onPressed: _load,
          icon: Icons.refresh_rounded,
          label: 'Thử lại',
        ),
      );
    }

    return _MemoriesBody(
      photos: _photos,
      dynamicThemeController: widget.dynamicThemeController,
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
      final photos = await widget.apiService.memories();
      if (!mounted) return;
      setState(() {
        _photos = photos;
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
}

class _MemoriesBody extends StatelessWidget {
  const _MemoriesBody({
    required this.photos,
    required this.dynamicThemeController,
    required this.onRefresh,
  });

  final List<CouplePhoto> photos;
  final DynamicThemeController dynamicThemeController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return StateMessage(
        icon: Icons.photo_album_rounded,
        title: 'Chưa có ảnh kỷ niệm',
        message: 'Gửi snap đầu tiên để Memories bắt đầu đầy lên.',
        action: GlowButton(
          onPressed: onRefresh,
          icon: Icons.refresh_rounded,
          label: 'Tải lại',
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: neonPink,
        backgroundColor: deepPurple,
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memories',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${photos.length} khoảnh khắc của hai người',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: softPink.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 118),
              sliver: SliverGrid.builder(
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  return _MemoryTile(photo: photos[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.photo});

  final CouplePhoto photo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 0.78,
              child: CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: neonPink.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: deepPurple,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: softPink,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      darkBg.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  photo.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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
