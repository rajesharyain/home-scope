import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_constants.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/shell_provider.dart';
import '../../services/validation_service.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/home/score_badge.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF060B14);
const _kSurface  = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kAccent   = Color(0xFF3B82F6);
const _kBorder   = Color(0xFF1A2845);

// ── Suggestion model ──────────────────────────────────────────────────────────

class _Suggestion {
  final String display;
  final String primary;
  final String secondary;

  const _Suggestion({
    required this.display,
    required this.primary,
    required this.secondary,
  });

  factory _Suggestion.fromJson(Map<String, dynamic> json) {
    final raw = json['display_name'] as String? ?? '';
    final parts = raw.split(', ');
    return _Suggestion(
      display: raw,
      primary: parts.take(2).join(', '),
      secondary: parts.length > 2 ? parts.skip(2).take(2).join(', ') : '',
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _scrollController  = ScrollController();
  final _focusNode         = FocusNode();
  final _dio               = Dio();

  Timer? _debounce;
  List<_Suggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _scrollController.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _dio.close();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Small delay so tap-on-suggestion fires before we hide the list
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showSuggestions = false);
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _fetching = false;
      });
      return;
    }
    setState(() => _fetching = true);
    _debounce = Timer(const Duration(milliseconds: 420), () => _fetchSuggestions(value));
  }

  Future<void> _fetchSuggestions(String query) async {
    final country = ref.read(selectedCountryProvider);
    final cc = (country?.code ?? 'PT').toLowerCase();
    try {
      final resp = await _dio.get<List<dynamic>>(
        '${AppConstants.nominatimBaseUrl}/search',
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'limit': 5,
          'addressdetails': 1,
          'countrycodes': cc,
        },
        options: Options(
          headers: {'User-Agent': 'HomeScope/1.0 (mobile)'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final list = (resp.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_Suggestion.fromJson)
          .toList();
      setState(() {
        _suggestions = list;
        _showSuggestions = list.isNotEmpty && _focusNode.hasFocus;
        _fetching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _pickSuggestion(_Suggestion s) {
    _addressController.text = s.display;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    _analyze();
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
    if (!mounted) return;
    if (ref.read(analysisProvider).status == AnalysisStatus.done) {
      ref.read(shellTabProvider.notifier).state = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    final history  = ref.watch(searchHistoryProvider);
    final country  = ref.watch(selectedCountryProvider);
    final top      = MediaQuery.of(context).padding.top;

    ref.listen(analysisProvider, (_, next) {
      if (next.status == AnalysisStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _kBg,
        colorScheme:
            const ColorScheme.dark(primary: _kAccent, surface: _kSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _kSurface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: LoadingOverlay(
          isLoading: analysis.isLoading,
          message: analysis.statusMessage,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Top bar ────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.only(top: top + 16),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _Logo(),
                        const SizedBox(width: 10),
                        const Text(
                          'HomeScope',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Know your\nneighbourhood.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              height: 1.08,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.08, end: 0),
                          const SizedBox(height: 10),
                          Text(
                            'Transport · Schools · Health · Safety · Shops · Parks',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Search card ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.07)),
                          boxShadow: [
                            BoxShadow(
                              color: _kAccent.withOpacity(0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Country chip
                              GestureDetector(
                                onTap: () => ref
                                    .read(shellTabProvider.notifier)
                                    .state = 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _flag(country?.code ?? 'PT'),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        country?.name ?? 'Portugal',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.expand_more_rounded,
                                          size: 14,
                                          color:
                                              Colors.white.withOpacity(0.3)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Address input
                              TextFormField(
                                controller: _addressController,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Rua Augusta 150, Lisboa',
                                  prefixIcon: _fetching
                                      ? Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.8,
                                              color: Colors.white
                                                  .withOpacity(0.4),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.search_rounded,
                                          color: Colors.white.withOpacity(0.3),
                                          size: 20,
                                        ),
                                  suffixIcon: _addressController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear_rounded,
                                              color: Colors.white
                                                  .withOpacity(0.3),
                                              size: 17),
                                          onPressed: () {
                                            _addressController.clear();
                                            setState(() {
                                              _suggestions = [];
                                              _showSuggestions = false;
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                textInputAction: TextInputAction.search,
                                onFieldSubmitted: (_) {
                                  setState(() => _showSuggestions = false);
                                  _analyze();
                                },
                                onChanged: (v) {
                                  setState(() {});
                                  _onChanged(v);
                                },
                                validator: ref
                                    .read(validationServiceProvider)
                                    .validateAddress,
                              ),

                              // ── Suggestion dropdown ───────────────────
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: _showSuggestions && _suggestions.isNotEmpty
                                    ? Column(
                                        children: [
                                          const SizedBox(height: 6),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: _kSurface2,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: _kBorder),
                                            ),
                                            child: Column(
                                              children: [
                                                for (int i = 0;
                                                    i < _suggestions.length;
                                                    i++) ...[
                                                  if (i > 0)
                                                    Divider(
                                                      height: 1,
                                                      color: Colors.white
                                                          .withOpacity(0.05),
                                                    ),
                                                  _SuggestionTile(
                                                    suggestion:
                                                        _suggestions[i],
                                                    onTap: () =>
                                                        _pickSuggestion(
                                                            _suggestions[i]),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              const SizedBox(height: 14),

                              // Scope It button
                              FilledButton.icon(
                                onPressed: _analyze,
                                icon: const Icon(Icons.radar_rounded, size: 18),
                                label: const Text('Scope It'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: 160.ms).fadeIn(duration: 500.ms),

                    // ── Recent searches ────────────────────────────────────
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(searchHistoryProvider.notifier)
                                  .clear(),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...history.take(6).map((entry) => _HistoryTile(
                            entry: entry,
                            onTap: () {
                              _addressController.text =
                                  entry.address.displayAddress;
                              _analyze();
                            },
                            onRemove: () => ref
                                .read(searchHistoryProvider.notifier)
                                .remove(entry.id),
                          )),
                    ],

                    const SizedBox(height: 32),

                    // ── Dimension pills ────────────────────────────────────
                    const _DimensionRow(),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _flag(String code) {
    const flags = {
      'PT': '🇵🇹',
      'ES': '🇪🇸',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
    };
    return flags[code] ?? '🌍';
  }
}

// ── Suggestion tile ───────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final _Suggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.location_on_rounded,
                size: 15,
                color: _kAccent.withOpacity(0.65),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (suggestion.secondary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini logo (7-segment donut) ───────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    const colors = [
      Color(0xFF29B6F6),
      Color(0xFF66BB6A),
      Color(0xFFEF5350),
      Color(0xFFFFA726),
      Color(0xFFAB47BC),
      Color(0xFF8D6E63),
      Color(0xFF26C6DA),
    ];
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DonutPainter(colors)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Color> colors;
  _DonutPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 7;
    const gapRad = 0.08;
    const sweepRad = (2 * 3.14159265 / segments) - gapRad;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (int i = 0; i < segments; i++) {
      final start =
          -1.5707963 + i * (2 * 3.14159265 / segments) + gapRad / 2;
      canvas.drawArc(
        rect.deflate(4),
        start,
        sweepRad,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── History tile ──────────────────────────────────────────────────────────────

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
    final score = entry.score.overall.round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            ScoreBadge(score: score, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.address.displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(entry.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 15, color: Colors.white.withOpacity(0.25)),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ── Dimension pills ───────────────────────────────────────────────────────────

class _DimensionRow extends StatelessWidget {
  const _DimensionRow();

  static const _dims = [
    (emoji: '🚇', label: 'Transport', color: Color(0xFF29B6F6)),
    (emoji: '🎓', label: 'Schools',   color: Color(0xFF66BB6A)),
    (emoji: '🏥', label: 'Health',    color: Color(0xFFEF5350)),
    (emoji: '🛍', label: 'Shopping',  color: Color(0xFFFFA726)),
    (emoji: '🛡', label: 'Safety',    color: Color(0xFFAB47BC)),
    (emoji: '⛪', label: 'Community', color: Color(0xFF8D6E63)),
    (emoji: '🌳', label: 'Parks',     color: Color(0xFF26C6DA)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Text(
            '7 DIMENSIONS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.32),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _dims.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _dims[i];
              return Container(
                width: 72,
                decoration: BoxDecoration(
                  color: d.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: d.color.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 5),
                    Text(
                      d.label,
                      style: TextStyle(
                        color: d.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
