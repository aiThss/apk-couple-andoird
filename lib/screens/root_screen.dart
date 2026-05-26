import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/couple_photo.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme_controller.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/pixel_sparkle.dart';
import 'home_screen.dart';
import 'memories_screen.dart';
import 'profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({
    required this.profile,
    required this.apiService,
    required this.dynamicThemeController,
    required this.onProfileChanged,
    required this.onSignOut,
    super.key,
  });

  final AppUser profile;
  final ApiService apiService;
  final DynamicThemeController dynamicThemeController;
  final ValueChanged<AppUser> onProfileChanged;
  final VoidCallback onSignOut;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  int _refreshSeed = 0;
  late AppUser _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant RootScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.loveStartDate != widget.profile.loveStartDate) {
      _profile = widget.profile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dynamicThemeController,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.62, -0.72),
                      radius: 1.35,
                      colors: [
                        neonPink.withValues(alpha: 0.24),
                        deepPurple,
                        darkBg,
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        darkBg.withValues(alpha: 0.86),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(child: PixelSparkle()),
              IndexedStack(
                index: _selectedIndex,
                children: [
                  HomeScreen(
                    profile: _profile,
                    apiService: widget.apiService,
                    dynamicThemeController: widget.dynamicThemeController,
                    refreshSeed: _refreshSeed,
                    onPhotoUploaded: _handlePhotoUploaded,
                  ),
                  MemoriesScreen(
                    profile: _profile,
                    apiService: widget.apiService,
                    dynamicThemeController: widget.dynamicThemeController,
                    refreshSeed: _refreshSeed,
                  ),
                  ProfileScreen(
                    profile: _profile,
                    apiService: widget.apiService,
                    dynamicThemeController: widget.dynamicThemeController,
                    onSignOut: widget.onSignOut,
                    onProfileChanged: _handleProfileChanged,
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: GlassNavBar(
            selectedIndex: _selectedIndex,
            accentColor: neonPink,
            onChanged: (index) => setState(() => _selectedIndex = index),
          ),
        );
      },
    );
  }

  void _handlePhotoUploaded(CouplePhoto photo) {
    setState(() => _refreshSeed++);
    widget.dynamicThemeController.updateFromUrl(photo.imageUrl);
  }

  void _handleProfileChanged(AppUser profile) {
    setState(() => _profile = profile);
    widget.onProfileChanged(profile);
  }
}
