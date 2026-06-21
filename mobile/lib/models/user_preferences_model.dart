enum UserProfile {
  defaultProfile,
  family,
  student,
  professional,
  retired,
  investor,
}

extension UserProfileJson on UserProfile {
  String get jsonValue => switch (this) {
        UserProfile.defaultProfile => 'default',
        UserProfile.family => 'family',
        UserProfile.student => 'student',
        UserProfile.professional => 'professional',
        UserProfile.retired => 'retired',
        UserProfile.investor => 'investor',
      };

  static UserProfile fromJson(String value) => switch (value) {
        'family' => UserProfile.family,
        'student' => UserProfile.student,
        'professional' => UserProfile.professional,
        'retired' => UserProfile.retired,
        'investor' => UserProfile.investor,
        _ => UserProfile.defaultProfile,
      };
}

class UserPreferences {
  final UserProfile profile;
  final String defaultCountry;
  final bool useDarkMode;
  final bool useSystemTheme;
  final bool showAiSummary;
  final double searchRadius;

  const UserPreferences({
    this.profile = UserProfile.defaultProfile,
    this.defaultCountry = 'PT',
    this.useDarkMode = false,
    this.useSystemTheme = true,
    this.showAiSummary = true,
    this.searchRadius = 2000.0,
  });

  UserPreferences copyWith({
    UserProfile? profile,
    String? defaultCountry,
    bool? useDarkMode,
    bool? useSystemTheme,
    bool? showAiSummary,
    double? searchRadius,
  }) =>
      UserPreferences(
        profile: profile ?? this.profile,
        defaultCountry: defaultCountry ?? this.defaultCountry,
        useDarkMode: useDarkMode ?? this.useDarkMode,
        useSystemTheme: useSystemTheme ?? this.useSystemTheme,
        showAiSummary: showAiSummary ?? this.showAiSummary,
        searchRadius: searchRadius ?? this.searchRadius,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        profile: UserProfileJson.fromJson(json['profile'] as String? ?? 'default'),
        defaultCountry: json['default_country'] as String? ?? 'PT',
        useDarkMode: json['use_dark_mode'] as bool? ?? false,
        useSystemTheme: json['use_system_theme'] as bool? ?? true,
        showAiSummary: json['show_ai_summary'] as bool? ?? true,
        searchRadius: (json['search_radius'] as num?)?.toDouble() ?? 2000.0,
      );

  Map<String, dynamic> toJson() => {
        'profile': profile.jsonValue,
        'default_country': defaultCountry,
        'use_dark_mode': useDarkMode,
        'use_system_theme': useSystemTheme,
        'show_ai_summary': showAiSummary,
        'search_radius': searchRadius,
      };
}
