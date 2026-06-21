import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/analysis_provider.dart';
import '../../widgets/neighborhood/dna_widget.dart';
import '../../widgets/neighborhood/life_radius_widget.dart';
import '../../widgets/neighborhood/time_machine_widget.dart';
import '../../widgets/neighborhood/ai_story_widget.dart';
import '../../widgets/neighborhood/future_score_widget.dart';

const kNbDarkBg = Color(0xFF080E1A);
const kNbSurface = Color(0xFF111827);
const kNbAccent = Color(0xFF6C63FF);

class NeighborhoodScreen extends ConsumerStatefulWidget {
  const NeighborhoodScreen({super.key});

  @override
  ConsumerState<NeighborhoodScreen> createState() => _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends ConsumerState<NeighborhoodScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _sections = [
    ('🧬', 'DNA'),
    ('🗺', 'Radius'),
    ('⏱', 'Timeline'),
    ('📖', 'Story'),
    ('🔮', 'Future'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int i) => _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    final result = analysis.result;

    if (result == null) {
      return Scaffold(
        backgroundColor: kNbDarkBg,
        appBar: AppBar(
          backgroundColor: kNbDarkBg,
          foregroundColor: Colors.white,
          title: const Text('Neighbourhood Intelligence'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: const Center(
          child: Text('No analysis found.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kNbDarkBg,
        colorScheme: const ColorScheme.dark(primary: kNbAccent, surface: kNbSurface),
      ),
      child: Scaffold(
        backgroundColor: kNbDarkBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Neighbourhood Intelligence',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
              if (analysis.address != null)
                Text(
                  analysis.address!.displayAddress,
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  DNAWidget(score: result.score),
                  LifeRadiusWidget(
                    amenities: result.amenities,
                    addressLat: analysis.address?.lat,
                    addressLng: analysis.address?.lng,
                  ),
                  TimeMachineWidget(score: result.score),
                  AIStoryWidget(result: result),
                  FutureScoreWidget(score: result.score),
                ],
              ),
            ),
            _BottomIndicator(current: _page, sections: _sections, onTap: _goTo),
          ],
        ),
      ),
    );
  }
}

class _BottomIndicator extends StatelessWidget {
  final int current;
  final List<(String, String)> sections;
  final ValueChanged<int> onTap;

  const _BottomIndicator({required this.current, required this.sections, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottom),
      decoration: BoxDecoration(
        color: kNbSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sections.asMap().entries.map((e) {
          final active = e.key == current;
          return GestureDetector(
            onTap: () => onTap(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              height: 44,
              width: active ? 108 : 50,
              decoration: BoxDecoration(
                color: active ? kNbAccent : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e.value.$1, style: const TextStyle(fontSize: 17)),
                  if (active) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        e.value.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
