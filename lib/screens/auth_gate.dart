import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../theme/dynamic_theme_controller.dart';
import '../widgets/state_message.dart';
import 'onboarding_screen.dart';
import 'root_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.apiService,
    required this.dynamicThemeController,
    super.key,
  });

  final ApiService apiService;
  final DynamicThemeController dynamicThemeController;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AppUser? _profile;
  Object? _bootstrapError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return OnboardingScreen(
        apiService: widget.apiService,
        initialError: _bootstrapError?.toString(),
        onComplete: (user) => setState(() {
          _bootstrapError = null;
          _profile = user;
        }),
      );
    }

    if (profile.isBlocked) {
      return Scaffold(
        body: StateMessage(
          icon: Icons.block_rounded,
          title: 'Tài khoản đã bị khóa',
          message: 'Liên hệ admin để mở khóa tài khoản này.',
          action: FilledButton(
            onPressed: _signOut,
            child: const Text('Đăng xuất'),
          ),
        ),
      );
    }

    return RootScreen(
      profile: profile,
      apiService: widget.apiService,
      dynamicThemeController: widget.dynamicThemeController,
      onProfileChanged: (user) => setState(() => _profile = user),
      onSignOut: _signOut,
    );
  }

  Future<void> _restoreSession() async {
    try {
      final profile = await widget.apiService.restoreSession();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _bootstrapError = null;
        _loading = false;
      });
    } catch (error) {
      await widget.apiService.signOut();
      if (!mounted) return;
      setState(() {
        _bootstrapError = error;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await widget.apiService.signOut();
    if (!mounted) return;
    setState(() => _profile = null);
  }
}
