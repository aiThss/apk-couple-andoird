import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/pixel_sparkle.dart';

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
  late final TextEditingController _apiUrlController;
  final _nameController = TextEditingController();
  final _partnerController = TextEditingController();
  final _coupleCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime _loveStartDate = DateTime.now().subtract(const Duration(days: 365));
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(text: widget.apiService.baseUrl);
    _error = widget.initialError;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _nameController.dispose();
    _partnerController.dispose();
    _coupleCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    neonPink.withValues(alpha: 0.18),
                    darkBg.withValues(alpha: 0.9),
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
                          color: softPink.withValues(alpha: 0.56),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: neonPink.withValues(alpha: 0.4),
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
                            'Private neon snaps for two.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: softPink.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'Setup couple của hai người',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập cùng một couple code trên hai máy để xem ảnh của nhau.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
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
                          controller: _apiUrlController,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'API URL',
                            helperText: 'VD: https://api.tenmiencuaban.com/api',
                            prefixIcon: Icon(Icons.cloud_rounded),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tên của bạn',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _partnerController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tên người ấy',
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
                            helperText:
                                'Mã này sẽ tự viết hoa và bỏ khoảng trắng.',
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
                              labelText: 'Ngày yêu nhau',
                              prefixIcon: Icon(Icons.calendar_month_rounded),
                            ),
                            child: Text(_formatDate(_loveStartDate)),
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email (tùy chọn)',
                            prefixIcon: Icon(Icons.mail_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu nếu dùng email',
                            prefixIcon: Icon(Icons.lock_rounded),
                          ),
                        ),
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
                  onPressed: _loading ? null : () => _submit(useEmail: false),
                  enabled: !_loading,
                  icon: _loading
                      ? Icons.hourglass_top_rounded
                      : Icons.auto_awesome_rounded,
                  label: _loading
                      ? 'Đang kết nối...'
                      : 'Vào app không cần email',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _submit(useEmail: true),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Đăng nhập / tạo tài khoản email'),
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
      return 'Không được để trống';
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

  Future<void> _submit({required bool useEmail}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.apiService.setBaseUrl(_apiUrlController.text);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (useEmail && (email.isEmpty || password.length < 6)) {
        throw const ApiException(
          'Email không được trống và mật khẩu cần ít nhất 6 ký tự.',
        );
      }

      final session = await widget.apiService.start(
        displayName: _nameController.text.trim(),
        partnerName: _partnerController.text.trim(),
        coupleCode: _normalizeCoupleCode(_coupleCodeController.text),
        loveStartDate: _loveStartDate,
        email: useEmail ? email : null,
        password: useEmail ? password : null,
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

  String _normalizeCoupleCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '-');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
