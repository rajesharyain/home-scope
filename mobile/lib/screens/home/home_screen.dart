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

                  // Feature highlights
                  if (history.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'What we analyze',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FeatureGrid(),
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

class _FeatureGrid extends StatelessWidget {
  final features = const [
    (icon: Icons.train_rounded, label: 'Transport', color: Color(0xFF2196F3)),
    (icon: Icons.school_rounded, label: 'Education', color: Color(0xFF4CAF50)),
    (icon: Icons.local_hospital_rounded, label: 'Healthcare', color: Color(0xFFF44336)),
    (icon: Icons.shopping_cart_rounded, label: 'Shopping', color: Color(0xFFFF9800)),
    (icon: Icons.park_rounded, label: 'Recreation', color: Color(0xFF00BCD4)),
    (icon: Icons.psychology_rounded, label: 'AI Summary', color: Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: features
          .map(
            (f) => Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: f.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.icon, color: f.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
