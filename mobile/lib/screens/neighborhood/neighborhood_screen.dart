import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/address_model.dart';
import '../../models/score_model.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/neighborhood/dna_widget.dart';
import '../../widgets/neighborhood/life_radius_widget.dart';
import '../../widgets/neighborhood/time_machine_widget.dart';
import '../../widgets/neighborhood/ai_story_widget.dart';
import '../../widgets/neighborhood/future_score_widget.dart';
import '../../widgets/map/map_tab_body.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF060B14);
const _kSurface  = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kBorder   = Color(0xFF1A2845);
const _kAccent   = Color(0xFF3B82F6);
const _kAccent2  = Color(0xFF6C63FF);

class NeighborhoodScreen extends ConsumerStatefulWidget {
  const NeighborhoodScreen({super.key});

  @override
  ConsumerState<NeighborhoodScreen> createState() =>
      _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends ConsumerState<NeighborhoodScreen> {
  int _tab = 0;

  static const _tabs = [
    ('🗺', 'Map'),
    ('🧬', 'DNA'),
    ('📍', 'Radius'),
    ('⏱', 'Timeline'),
    ('✨', 'Story'),
    ('🔮', 'Future'),
  ];

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    final result   = analysis.result;
    final top      = MediaQuery.of(context).padding.top;

    if (result == null) {
      return _EmptyExplore(top: top);
    }

    return Column(
      children: [
        SizedBox(height: top),
        _ScoreHeader(score: result.score, address: analysis.address),
        _TabStrip(
          current: _tab,
          tabs: _tabs,
          onSelect: (i) => setState(() => _tab = i),
        ),
        Expanded(child: _buildContent(result, analysis.address)),
      ],
    );
  }

  Widget _buildContent(AnalysisResult result, AddressModel? address) {
    switch (_tab) {
      case 0:
        return const MapTabBody();
      case 1:
        return DNAWidget(score: result.score, address: address, topPadding: 0);
      case 2:
        return LifeRadiusWidget(
          amenities: result.amenities,
          addressLat: address?.lat,
          addressLng: address?.lng,
          topPadding: 0,
        );
      case 3:
        return TimeMachineWidget(score: result.score, topPadding: 0);
      case 4:
        return AIStoryWidget(result: result, topPadding: 0);
      case 5:
        return FutureScoreWidget(score: result.score, topPadding: 0);
      default:
        return const SizedBox();
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyExplore extends StatelessWidget {
  final double top;
  const _EmptyExplore({required this.top});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(Icons.explore_rounded,
                      color: _kAccent, size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No analysis yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search an address in the Search tab\nto explore its full neighbourhood profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Score header ──────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final LocationScore score;
  final AddressModel? address;
  const _ScoreHeader({required this.score, this.address});

  Color _scoreColor() {
    final s = score.overall;
    if (s >= 80) return const Color(0xFF22C55E);
    if (s >= 60) return const Color(0xFF3B82F6);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _scoreLabel() {
    final s = score.overall;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Score ring
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              color: color.withOpacity(0.08),
            ),
            child: Center(
              child: Text(
                score.overall.round().toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _scoreLabel(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${score.categories.length} categories',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.32),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    if (address?.lat != null)
                      GestureDetector(
                        onTap: () =>
                            _openStreetView(address!.lat!, address!.lng!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.streetview_rounded,
                                size: 12, color: _kAccent2),
                            const SizedBox(width: 3),
                            const Text(
                              'Street View',
                              style: TextStyle(
                                color: _kAccent2,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address?.displayAddress ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openStreetView(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano'
      '&viewpoint=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ── Horizontal tab strip ──────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  final int current;
  final List<(String, String)> tabs;
  final ValueChanged<int> onSelect;

  const _TabStrip({
    required this.current,
    required this.tabs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == current;
          final tab = tabs[i];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: active ? _kAccent.withOpacity(0.14) : _kSurface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? _kAccent
                      : Colors.white.withOpacity(0.07),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.$1, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    tab.$2,
                    style: TextStyle(
                      color: active
                          ? _kAccent
                          : Colors.white.withOpacity(0.45),
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
