import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/couple_photo.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class AdaptivePhotoCard extends StatelessWidget {
  const AdaptivePhotoCard({
    required this.photo,
    required this.accentColor,
    this.height = 470,
    this.onTap,
    super.key,
  });

  final CouplePhoto? photo;
  final Color accentColor;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(28);
    final photo = this.photo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: neonPink.withValues(alpha: 0.28),
              blurRadius: 32,
              spreadRadius: 1,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo?.hasImage ?? false)
                CachedNetworkImage(
                  imageUrl: photo!.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      _SoftPlaceholder(color: accentColor),
                  errorWidget: (context, url, error) => _SoftPlaceholder(
                    color: accentColor,
                    icon: Icons.broken_image_rounded,
                  ),
                )
              else
                _SoftPlaceholder(color: accentColor),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      darkBg.withValues(alpha: 0.05),
                      darkBg.withValues(alpha: 0.18),
                      darkBg.withValues(alpha: 0.82),
                    ],
                    stops: const [0.25, 0.62, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GlassCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(16),
                  glow: true,
                  child: _PhotoCaption(photo: photo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoCaption extends StatelessWidget {
  const _PhotoCaption({required this.photo});

  final CouplePhoto? photo;

  @override
  Widget build(BuildContext context) {
    final title = photo == null ? 'Chưa có ảnh mới' : photo!.caption;
    final subtitle = photo == null
        ? 'Hãy gửi khoảnh khắc đầu tiên cho người ấy.'
        : photo!.ownerName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              photo == null
                  ? Icons.auto_awesome_rounded
                  : Icons.favorite_rounded,
              color: softPink,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SoftPlaceholder extends StatelessWidget {
  const _SoftPlaceholder({
    required this.color,
    this.icon = Icons.photo_camera_back_rounded,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepPurple, darkBg],
        ),
      ),
      child: Center(
        child: Icon(icon, color: softPink.withValues(alpha: 0.76), size: 72),
      ),
    );
  }
}
