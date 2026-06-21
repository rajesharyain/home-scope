import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_preferences_model.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/country_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionTitle('Profile'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: UserProfile.values.map((profile) {
                final isSelected = prefs.profile == profile;
                return RadioListTile<UserProfile>(
                  value: profile,
                  groupValue: prefs.profile,
                  title: Text(_profileLabel(profile)),
                  subtitle: Text(_profileDescription(profile)),
                  secondary: Icon(_profileIcon(profile), color: isSelected ? theme.colorScheme.primary : null),
                  onChanged: (v) {
                    if (v != null) ref.read(preferencesProvider.notifier).setProfile(v);
                  },
                );
              }).toList(),
            ),
          ),

          _SectionTitle('Default Country'),
          countriesAsync.when(
            data: (countries) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField(
                  value: selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                  items: countries.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(children: [Text(_flag(c.code)), const SizedBox(width: 8), Text(c.name)]),
                  )).toList(),
                  onChanged: (c) {
                    if (c != null) ref.read(selectedCountryProvider.notifier).select(c);
                  },
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),

          _SectionTitle('Search Radius'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(prefs.searchRadius / 1000).toStringAsFixed(1)} km',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: prefs.searchRadius,
                    min: 500,
                    max: 5000,
                    divisions: 9,
                    label: '${(prefs.searchRadius / 1000).toStringAsFixed(1)} km',
                    onChanged: (v) => ref.read(preferencesProvider.notifier).setSearchRadius(v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('500m', style: theme.textTheme.bodySmall),
                      Text('5km', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),

          _SectionTitle('Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_auto_rounded),
                  title: const Text('System theme'),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
                  ),
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded),
                  title: const Text('Light mode'),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
                  ),
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Dark mode'),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
                  ),
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),

          _SectionTitle('AI Summary'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: const Text('Show AI Neighborhood Summary'),
              subtitle: const Text('Uses OpenAI to generate insights'),
              value: prefs.showAiSummary,
              onChanged: (v) => ref.read(preferencesProvider.notifier).setShowAiSummary(v),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'HomeScope v1.0.0\nBuilt for Portugal and beyond.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _profileLabel(UserProfile p) => switch (p) {
        UserProfile.defaultProfile => 'General',
        UserProfile.family => 'Family',
        UserProfile.student => 'Student',
        UserProfile.professional => 'Professional',
        UserProfile.retired => 'Retired',
        UserProfile.investor => 'Investor',
      };

  String _profileDescription(UserProfile p) => switch (p) {
        UserProfile.defaultProfile => 'Balanced scoring across all categories',
        UserProfile.family => 'Prioritizes schools, parks, and safety',
        UserProfile.student => 'Emphasizes transport and education',
        UserProfile.professional => 'Focus on transport and safety',
        UserProfile.retired => 'Healthcare and safety weighted higher',
        UserProfile.investor => 'Broad scoring for investment potential',
      };

  IconData _profileIcon(UserProfile p) => switch (p) {
        UserProfile.defaultProfile => Icons.person_rounded,
        UserProfile.family => Icons.family_restroom_rounded,
        UserProfile.student => Icons.school_rounded,
        UserProfile.professional => Icons.work_rounded,
        UserProfile.retired => Icons.elderly_rounded,
        UserProfile.investor => Icons.trending_up_rounded,
      };

  String _flag(String code) {
    const flags = {'PT': '🇵🇹', 'ES': '🇪🇸', 'GB': '🇬🇧', 'FR': '🇫🇷', 'DE': '🇩🇪'};
    return flags[code] ?? '🌍';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
