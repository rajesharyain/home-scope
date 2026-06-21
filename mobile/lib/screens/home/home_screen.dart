import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/validation_service.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/home/score_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  bool _isSearchFocused = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;
    final country = ref.read(selectedCountryProvider);
    final profile = ref.read(preferencesProvider).profile.name;
    await ref.read(analysisProvider.notifier).analyze(
          _addressController.text.trim(),
          countryCode: country?.code ?? 'PT',
          profile: profile,
        );
    if (mounted) {
      final state = ref.read(analysisProvider);
      if (state.status == AnalysisStatus.done) {
        context.pushNamed('dashboard', extra: state.address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = ref.watch(analysisProvider);
    final history = ref.watch(searchHistoryProvider);
    final country = ref.watch(selectedCountryProvider);

    ref.listen(analysisProvider, (_, next) {
      if (next.status == AnalysisStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: LoadingOverlay(
        isLoading: analysis.isLoading,
        message: analysis.statusMessage,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              floating: false,
              pinned: true,
              expandedHeight: 200,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => context.pushNamed('history'),
                  tooltip: 'Search history',
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => context.pushNamed('settings'),
                  tooltip: 'Settings',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'HomeScope',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                expandedTitleScale: 1.5,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer.withOpacity(0.3),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 60),
                    child: Text(
                      'Know your neighborhood\nbefore you move.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Search card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _countryFlag(country?.code ?? 'PT'),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        country?.name ?? 'Portugal',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Focus(
                              onFocusChange: (f) => setState(() => _isSearchFocused = f),
                              child: TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Rua Augusta 150, Lisboa',
                                  labelText: 'Enter Address',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _addressController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _addressController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                                textInputAction: TextInputAction.search,
                                onFieldSubmitted: (_) => _analyze(),
                                onChanged: (_) => setState(() {}),
                                validator: ref.read(validationServiceProvider).validateAddress,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _analyze,
                                    icon: const Icon(Icons.analytics_rounded),
                                    label: const Text('Analyze Address'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => context.pushNamed('advanced-search'),
                                  icon: const Icon(Icons.tune_rounded),
                                  label: const Text('Advanced'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Recent searches
                  if (history.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Searches',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...history.take(5).map((entry) => _HistoryTile(
                          entry: entry,
                          onTap: () {
                            _addressController.text = entry.address.displayAddress;
                            _analyze();
                          },
                          onRemove: () => ref.read(searchHistoryProvider.notifier).remove(entry.id),
                        )),
                  ],

                  // In-app landing experience (shown when no history)
                  if (history.isEmpty) ...[
                    const SizedBox(height: 8),
                    _WhatWeDoCard()
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),
                    _AppOutputPreview()
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 20),
                    _HowItWorksSection()
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    _LiveDataBanner()
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    _WhatWeAnalyzeSection()
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    _TestimonialsSection()
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 400.ms),
                  ],

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _countryFlag(String code) {
    final flags = {'PT': '🇵🇹', 'ES': '🇪🇸', 'GB': '🇬🇧', 'FR': '🇫🇷', 'DE': '🇩🇪'};
    return flags[code] ?? '🌍';
  }
}

class _HistoryTile extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = entry.score.overall.round();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ScoreBadge(score: score, size: 44),
        title: Text(
          entry.address.displayAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _timeAgo(entry.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onRemove,
            ),
          ],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── What We Do ────────────────────────────────────────────────────────────────

class _WhatWeDoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.5),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_work_rounded, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'What is HomeScope?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'HomeScope helps you make smarter home-buying and renting decisions by scoring any address across what truly matters — transport links, schools, hospitals, shops, parks, and more.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We pull real-time data from OpenStreetMap and combine it with AI-powered analysis to give you a clear, objective picture of life in that neighbourhood before you commit.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  static const _steps = [
    (
      icon: Icons.edit_location_alt_rounded,
      color: Color(0xFF6C63FF),
      title: 'Enter address',
      body: 'Type any street address. HomeScope supports Portugal and is expanding to more countries.',
    ),
    (
      icon: Icons.radar_rounded,
      color: Color(0xFF00BCD4),
      title: 'AI scans nearby',
      body: 'We fetch 100+ amenities within 2 km and weigh them by distance, type, and your life profile.',
    ),
    (
      icon: Icons.insights_rounded,
      color: Color(0xFF4CAF50),
      title: 'Get your score',
      body: 'Receive a 0–100 location score, category breakdown, AI summary, and interactive maps.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _steps.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _steps.length - 1 ? 10 : 0),
                child: _StepCard(step: i + 1, icon: s.icon, color: s.color, title: s.title, body: s.body),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _StepCard({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '$step',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

// ── What We Analyze ───────────────────────────────────────────────────────────

class _WhatWeAnalyzeSection extends StatelessWidget {
  static const _categories = [
    (
      icon: Icons.train_rounded,
      label: 'Transportation',
      color: Color(0xFF29B6F6),
      description: 'Bus stops, metro stations, tram lines, and rail connections within walking distance. We measure frequency, coverage, and how easily you can get around without a car.',
    ),
    (
      icon: Icons.school_rounded,
      label: 'Education',
      color: Color(0xFF66BB6A),
      description: 'Nurseries, primary schools, secondary schools, universities, and public libraries. Weighted by proximity and variety — critical for families and lifelong learners alike.',
    ),
    (
      icon: Icons.local_hospital_rounded,
      label: 'Healthcare',
      color: Color(0xFFEF5350),
      description: 'Hospitals, health centres, clinics, pharmacies, and dentists nearby. We score access to emergency care separately from routine healthcare availability.',
    ),
    (
      icon: Icons.shopping_bag_rounded,
      label: 'Shopping',
      color: Color(0xFFFFA726),
      description: 'Supermarkets, convenience stores, markets, bakeries, and retail shops for everyday needs. Covers both daily essentials and weekly grocery runs.',
    ),
    (
      icon: Icons.park_rounded,
      label: 'Recreation',
      color: Color(0xFF26C6DA),
      description: 'Parks, gardens, gyms, sports pitches, cafés, restaurants, cinemas, and cultural venues. Measures how vibrant and liveable a neighbourhood feels day-to-day.',
    ),
    (
      icon: Icons.shield_rounded,
      label: 'Safety',
      color: Color(0xFFAB47BC),
      description: 'Proximity to police stations, fire brigades, and emergency services. Combined with neighbourhood density signals to estimate how safe and well-served the area is.',
    ),
    (
      icon: Icons.church_rounded,
      label: 'Religion',
      color: Color(0xFF8D6E63),
      description: 'Churches, mosques, synagogues, temples, and other places of worship. Scored for those for whom community and spiritual life are part of choosing a home.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What we analyze',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '7 categories scored from real OpenStreetMap data',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ..._categories.map((c) => _CategoryCard(
              icon: c.icon,
              label: c.label,
              color: c.color,
              description: c.description,
            )),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String description;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Output Preview (Score + DNA teaser) ───────────────────────────────────

class _AppOutputPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What you\'ll get', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('A full neighbourhood picture, in seconds', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        _MockScoreCard(),
        const SizedBox(height: 12),
        _DNAPreviewCard(),
      ],
    );
  }
}

// Mock score card —————————————————————————————————————————————————————————————

class _MockScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_rounded, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Location Score', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .scaleXY(begin: 0.7, end: 1.3, duration: 900.ms, curve: Curves.easeInOut),
                      const SizedBox(width: 5),
                      Text('Sample result', style: theme.textTheme.labelSmall?.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 0.78),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CustomPaint(
                      painter: _ScoreRingPainter(v),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (v * 100).round().toString(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4CAF50), height: 1),
                            ),
                            const Text('/100', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: const Column(
                    children: [
                      _MiniScoreBar('Transport', 0.82, Color(0xFF29B6F6)),
                      _MiniScoreBar('Education', 0.91, Color(0xFF66BB6A)),
                      _MiniScoreBar('Healthcare', 0.65, Color(0xFFEF5350)),
                      _MiniScoreBar('Shopping', 0.78, Color(0xFFFFA726)),
                      _MiniScoreBar('Recreation', 0.70, Color(0xFF26C6DA)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double value;
  _ScoreRingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    final trackPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final progressPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.value != value;
}

class _MiniScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniScoreBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 24,
            child: Text('${(value * 100).round()}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

// DNA fingerprint preview ——————————————————————————————————————————————————————

class _DNAPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080E1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded, size: 15, color: Color(0xFF6C63FF)),
                const SizedBox(width: 6),
                const Text('Neighbourhood DNA', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Preview', style: TextStyle(color: Color(0xFF9C9AFF), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(painter: _DNAPreviewPainter(v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'Each address generates a unique radar fingerprint across 7 dimensions. Analyze an address to see yours.',
              style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _DNAPreviewPainter extends CustomPainter {
  final double animValue;
  static const _scores = [0.72, 0.85, 0.60, 0.78, 0.90, 0.65, 0.45];
  static const _colors = [
    Color(0xFF29B6F6), Color(0xFF66BB6A), Color(0xFFEF5350),
    Color(0xFFFFA726), Color(0xFF26C6DA), Color(0xFFAB47BC), Color(0xFF8D6E63),
  ];
  static const _labels = ['Transport', 'Education', 'Health', 'Shopping', 'Recreation', 'Safety', 'Religion'];

  _DNAPreviewPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const n = 7;
    final maxRadius = min(size.width, size.height) / 2 - 32;

    // Background rings
    for (var r = 1; r <= 4; r++) {
      canvas.drawCircle(center, maxRadius * r / 4,
        Paint()..color = Colors.white.withOpacity(0.05)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // Spokes
    for (var i = 0; i < n; i++) {
      final angle = (2 * pi * i / n) - pi / 2;
      canvas.drawLine(center, center + Offset(cos(angle) * maxRadius, sin(angle) * maxRadius),
        Paint()..color = Colors.white.withOpacity(0.07)..strokeWidth = 1);
    }

    // Score points
    final pts = List.generate(n, (i) {
      final angle = (2 * pi * i / n) - pi / 2;
      final r = maxRadius * _scores[i] * animValue;
      return center + Offset(cos(angle) * r, sin(angle) * r);
    });

    // Filled polygon
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < n; i++) { path.lineTo(pts[i].dx, pts[i].dy); }
    path.close();

    canvas.drawPath(path, Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF6C63FF).withOpacity(0.45),
        const Color(0xFF6C63FF).withOpacity(0.08),
      ]).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill);

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round);

    // Colored dots on vertices
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(pts[i], 4.5, Paint()..color = _colors[i]);
      canvas.drawCircle(pts[i], 4.5, Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Labels (fade in after polygon appears)
    if (animValue > 0.6) {
      final labelOpacity = ((animValue - 0.6) / 0.4).clamp(0.0, 1.0);
      for (var i = 0; i < n; i++) {
        final angle = (2 * pi * i / n) - pi / 2;
        final labelPos = center + Offset(cos(angle) * (maxRadius + 18), sin(angle) * (maxRadius + 18));
        final tp = TextPainter(
          text: TextSpan(text: _labels[i], style: TextStyle(color: _colors[i].withOpacity(labelOpacity), fontSize: 9, fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_DNAPreviewPainter old) => old.animValue != animValue;
}

// ── Live Data Banner ──────────────────────────────────────────────────────────

class _LiveDataBanner extends StatelessWidget {
  static const _points = [
    (icon: Icons.map_rounded,       text: 'OpenStreetMap — 100+ real amenities fetched live per address'),
    (icon: Icons.psychology_rounded, text: 'OpenAI — neighbourhood summary generated fresh, on demand'),
    (icon: Icons.update_rounded,    text: 'No caching — every score reflects what\'s on the map today'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(),
              const SizedBox(width: 10),
              Text('Powered by live data', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ..._points.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(p.icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(p.text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(_anim.value),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(_anim.value * 0.6), blurRadius: 6, spreadRadius: 1)],
        ),
      ),
    );
  }
}

// ── Testimonials ──────────────────────────────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  static const _testimonials = [
    (
      name: 'Sara M.',
      city: 'Lisbon',
      initial: 'S',
      color: Color(0xFF6C63FF),
      score: 94,
      text: 'We looked at 8 addresses before settling on Mouraria. HomeScope showed us the transport and safety scores we\'d never have found just by walking around. Made the decision easy.',
    ),
    (
      name: 'João F.',
      city: 'Porto',
      initial: 'J',
      color: Color(0xFF00BCD4),
      score: 88,
      text: 'As a property investor I screen multiple addresses each week. The AI summary gives me a fast read on each neighbourhood before I even visit. Saves me 3–4 hours per property.',
    ),
    (
      name: 'Ana & Tiago',
      city: 'Braga',
      initial: 'A',
      color: Color(0xFF4CAF50),
      score: 91,
      text: 'Education and safety were everything with two young kids. HomeScope surfaced a neighbourhood we\'d never have considered — it ended up being perfect for our family.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What people say', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('From families, investors, and first-time buyers in Portugal', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _testimonials.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = _testimonials[i];
              return _TestimonialCard(
                name: t.name, city: t.city, initial: t.initial,
                accentColor: t.color, score: t.score, text: t.text,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String city;
  final String initial;
  final Color accentColor;
  final int score;
  final String text;

  const _TestimonialCard({
    required this.name, required this.city, required this.initial,
    required this.accentColor, required this.score, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 258,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withOpacity(0.15),
                child: Text(initial, style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(city, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$score', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              '"$text"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFA726)))),
        ],
      ),
    );
  }
}
