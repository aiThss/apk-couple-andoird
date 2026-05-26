import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/dynamic_theme_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 118),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _openEditSheet(context),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Sửa thông tin',
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassCard(
            glow: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(label: profile.displayName),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: neonPink.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: neonPink.withValues(alpha: 0.42),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: neonPink,
                        ),
                      ),
                    ),
                    _Avatar(label: profile.partnerName),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '${profile.displayName} & ${profile.partnerName}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã yêu nhau ${profile.daysInLove} ngày',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: softPink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.calendar_month_rounded,
            label: 'Ngày yêu nhau',
            value: _formatDate(profile.loveStartDate),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.key_rounded,
            label: 'Couple code',
            value: profile.coupleId,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.cloud_done_rounded,
            label: 'Cloud API',
            value: apiService.baseUrl,
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.email_rounded,
            label: 'Tài khoản',
            value: profile.email ?? 'Ẩn danh trên thiết bị này',
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final updated = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _EditProfileSheet(profile: profile, apiService: apiService),
    );

    if (updated != null) {
      onProfileChanged(updated);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.apiService});

  final AppUser profile;
  final ApiService apiService;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _partnerController;
  late DateTime _loveStartDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _partnerController = TextEditingController(
      text: widget.profile.partnerName,
    );
    _loveStartDate = widget.profile.loveStartDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: GlassCard(
          glow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sửa thông tin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tên của bạn',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _partnerController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Tên người ấy',
                  prefixIcon: Icon(Icons.favorite_rounded),
                ),
              ),
              const SizedBox(height: 12),
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: GlowButton(
                  onPressed: _saving ? null : _save,
                  enabled: !_saving,
                  icon: _saving
                      ? Icons.hourglass_top_rounded
                      : Icons.save_rounded,
                  label: _saving ? 'Đang lưu...' : 'Lưu',
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final partner = _partnerController.text.trim();
    if (name.isEmpty || partner.isEmpty) {
      setState(() => _error = 'Tên không được để trống.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await widget.apiService.updateProfile(
        displayName: name,
        partnerName: partner,
        loveStartDate: _loveStartDate,
      );
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: neonPink.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: softPink.withValues(alpha: 0.78),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: neonPink.withValues(alpha: 0.28),
                blurRadius: 24,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: softPink),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: softPink.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
