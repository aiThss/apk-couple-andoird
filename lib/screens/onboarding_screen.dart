import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/pixel_sparkle.dart';

enum _AuthMode { setup, login }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.apiService,
    required this.onComplete,
    this.initialError,
    super.key,
  });

  final ApiService apiService;
  final ValueChanged<AppUser> onComplete;
  final String? initialError;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _partnerController = TextEditingController();
  final _coupleCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  DateTime _loveStartDate = DateTime.now().subtract(const Duration(days: 365));
  _AuthMode _mode = _AuthMode.setup;
  bool _loading = false;
  bool _needsCode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partnerController.dispose();
    _coupleCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == _AuthMode.login;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6, -0.8),
                  radius: 1.35,
                  colors: [Color(0x44FF1493), deepPurple, darkBg],
                  stops: [0, 0.44, 1],
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
                    neonPink.withValues(alpha: 0.14),
                    darkBg.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: PixelSparkle()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 34),
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: neonPink.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: softPink.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: neonPink.withValues(alpha: 0.3),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: neonPink,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Couple Snap',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Private snaps for two.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SegmentedButton<_AuthMode>(
                  segments: const [
                    ButtonSegment(
                      value: _AuthMode.setup,
                      label: Text('Tao tai khoan'),
                      icon: Icon(Icons.favorite_rounded),
                    ),
                    ButtonSegment(
                      value: _AuthMode.login,
                      label: Text('Dang nhap'),
                      icon: Icon(Icons.login_rounded),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: _loading
                      ? null
                      : (value) {
                          setState(() {
                            _mode = value.first;
                            _needsCode = false;
                            _codeController.clear();
                            _error = null;
                          });
                        },
                ),
                const SizedBox(height: 22),
                Text(
                  isLogin ? 'Dang nhap may nay' : 'Setup couple cua hai nguoi',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'May moi se can them ma xac thuc gui qua email.'
                      : 'Hai may dung cung couple code de thay snap cua nhau.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                GlassCard(
                  glow: true,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_rounded),
                          ),
                          validator: _requiredEmail,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Mat khau',
                            prefixIcon: Icon(Icons.lock_rounded),
                          ),
                          validator: _requiredPassword,
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Ten cua ban',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _partnerController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Ten nguoi ay',
                              prefixIcon: Icon(Icons.favorite_rounded),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _coupleCodeController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Couple code',
                              helperText: 'Nhap cung mot ma tren hai may.',
                              prefixIcon: Icon(Icons.key_rounded),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _pickLoveStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Ngay yeu nhau',
                                prefixIcon: Icon(Icons.calendar_month_rounded),
                              ),
                              child: Text(_formatDate(_loveStartDate)),
                            ),
                          ),
                        ],
                        if (_needsCode) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Ma xac thuc email',
                              helperText: 'Kiem tra hop thu den hoac spam.',
                              prefixIcon: Icon(Icons.verified_rounded),
                            ),
                            validator: _requiredCode,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GlowButton(
                  onPressed: _loading ? null : _submit,
                  enabled: !_loading,
                  icon: _loading
                      ? Icons.hourglass_top_rounded
                      : _needsCode
                      ? Icons.verified_user_rounded
                      : Icons.arrow_forward_rounded,
                  label: _loading
                      ? 'Dang ket noi...'
                      : _needsCode
                      ? 'Xac nhan ma'
                      : isLogin
                      ? 'Dang nhap'
                      : 'Tao tai khoan',
                ),
                if (!isLogin && !_needsCode) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _submitAnonymous,
                    icon: const Icon(Icons.phone_android_rounded),
                    label: const Text('Dung tam khong email'),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'API dang dung: ${widget.apiService.baseUrl}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Khong duoc de trong';
    }
    return null;
  }

  String? _requiredEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || !text.contains('@')) {
      return 'Nhap email hop le';
    }
    return null;
  }

  String? _requiredPassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Mat khau can it nhat 6 ky tu';
    }
    return null;
  }

  String? _requiredCode(String? value) {
    if (!_needsCode) return null;
    if (value == null || value.trim().length != 6) {
      return 'Nhap ma 6 so';
    }
    return null;
  }

  Future<void> _pickLoveStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loveStartDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _loveStartDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final emailCode = _needsCode ? _codeController.text.trim() : null;

      final session = _mode == _AuthMode.login
          ? await widget.apiService.login(
              email: email,
              password: password,
              emailCode: emailCode,
            )
          : await widget.apiService.start(
              displayName: _nameController.text.trim(),
              partnerName: _partnerController.text.trim(),
              coupleCode: _normalizeCoupleCode(_coupleCodeController.text),
              loveStartDate: _loveStartDate,
              email: email,
              password: password,
              emailCode: emailCode,
            );

      widget.onComplete(session.user);
    } on ApiException catch (error) {
      if (error.requiresEmailCode && !_needsCode) {
        await _sendCodeAfterRequirement();
        return;
      }
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitAnonymous() async {
    final name = _nameController.text.trim();
    final partner = _partnerController.text.trim();
    final coupleCode = _coupleCodeController.text.trim();
    if (name.isEmpty || partner.isEmpty || coupleCode.isEmpty) {
      setState(() => _error = 'Nhap ten va couple code truoc.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await widget.apiService.start(
        displayName: name,
        partnerName: partner,
        coupleCode: _normalizeCoupleCode(coupleCode),
        loveStartDate: _loveStartDate,
      );
      widget.onComplete(session.user);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendCodeAfterRequirement() async {
    try {
      await widget.apiService.requestAuthCode(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _needsCode = true;
        _error = 'Da gui ma xac thuc toi email cua ban.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  String _normalizeCoupleCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '-');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
