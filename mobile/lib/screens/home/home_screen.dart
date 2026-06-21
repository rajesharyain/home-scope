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
                    _HowItWorksSection()
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    _WhatWeAnalyzeSection()
                        .animate(delay: 300.ms)
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
