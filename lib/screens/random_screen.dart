import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/random_event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/state_message.dart';

class RandomScreen extends StatefulWidget {
  const RandomScreen({
    required this.profile,
    required this.apiService,
    required this.refreshSeed,
    super.key,
  });

  final AppUser profile;
  final ApiService apiService;
  final int refreshSeed;

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  List<RandomCategory> _categories = const [];
  List<RandomEvent> _history = const [];
  RandomEvent? _current;
  String _selectedCategory = 'question';
  Object? _error;
  bool _loading = true;
  bool _drawing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RandomScreen oldWidget) {
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
        icon: Icons.auto_awesome_rounded,
        title: 'Dang mo Random',
        message: 'Couple Snap dang lay tin hieu dau tien.',
      );
    }

    if (_error != null) {
      return StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Khong tai duoc Random',
        message: _error.toString(),
        action: GlowButton(
          onPressed: _load,
          icon: Icons.refresh_rounded,
          label: 'Thu lai',
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: Colors.white,
        backgroundColor: deepPurple,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 118),
          children: [
            Text(
              'Random',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cau hoi, thu thach snap va tin hieu nho cho hai nguoi.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.64),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in _categories)
                  ChoiceChip(
                    selected: _selectedCategory == category.key,
                    label: Text(category.label),
                    onSelected: _drawing
                        ? null
                        : (_) =>
                              setState(() => _selectedCategory = category.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            GlassCard(
              glow: true,
              padding: const EdgeInsets.all(22),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _current == null
                    ? _EmptyRandomCard(key: const ValueKey('empty'))
                    : _RandomResultCard(
                        key: ValueKey(_current!.id),
                        event: _current!,
                      ),
              ),
            ),
            const SizedBox(height: 18),
            GlowButton(
              onPressed: _drawing ? null : _draw,
              enabled: !_drawing,
              icon: _drawing
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_awesome_rounded,
              label: _drawing ? 'Dang boc tham...' : 'Random ngay',
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Gan day',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (final event in _history.take(8)) ...[
                _HistoryTile(event: event),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
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
      final categories = await widget.apiService.randomCategories();
      final history = await widget.apiService.randomHistory();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _history = history;
        _current = history.isEmpty ? null : history.first;
        if (categories.isNotEmpty &&
            !categories.any((category) => category.key == _selectedCategory)) {
          _selectedCategory = categories.first.key;
        }
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

  Future<void> _draw() async {
    setState(() {
      _drawing = true;
      _error = null;
    });

    try {
      final event = await widget.apiService.drawRandom(
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _current = event;
        _history = [event, ..._history.where((item) => item.id != event.id)];
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _drawing = false);
      }
    }
  }
}

class _EmptyRandomCard extends StatelessWidget {
  const _EmptyRandomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.76),
        ),
        const SizedBox(height: 12),
        Text(
          'Chua co tin hieu nao',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bam Random ngay de boc mot goi y cho hai nguoi.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.58),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RandomResultCard extends StatelessWidget {
  const _RandomResultCard({required this.event, super.key});

  final RandomEvent event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.blur_on_rounded,
          color: Colors.white.withValues(alpha: 0.72),
          size: 34,
        ),
        const SizedBox(height: 18),
        Text(
          event.prompt,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.14,
          ),
        ),
        if (event.detail != null) ...[
          const SizedBox(height: 12),
          Text(
            event.detail!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.event});

  final RandomEvent event;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.prompt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
