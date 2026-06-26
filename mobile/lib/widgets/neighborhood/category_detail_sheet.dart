import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../models/score_model.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1625);
const _kSurface2= Color(0xFF131F33);
const _kBorder  = Color(0xFF1A2845);
const _kAccent2 = Color(0xFF6C63FF);

// ── Entry point ───────────────────────────────────────────────────────────────

void showCategoryDetail({
  required BuildContext context,
  required CategoryScore cat,
  required List<AmenityModel> allAmenities,
  required AddressModel? address,
}) {
  final amenities = (allAmenities.where((a) => a.category.name == cat.id).toList()
        ..sort((a, b) => (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999)));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: false,
    builder: (_) => CategoryDetailSheet(
      cat: cat,
      amenities: amenities,
      address: address,
    ),
  );
}

// ── Static lookup tables ──────────────────────────────────────────────────────

const _catEmoji = {
  'transportation': '🚇',
  'education':      '🎓',
  'healthcare':     '🏥',
  'shopping':       '🛍',
  'safety':         '🛡',
  'religion':       '⛪',
  'recreation':     '🌳',
};

const _catColor = {
  'transportation': Color(0xFF29B6F6),
  'education':      Color(0xFF66BB6A),
  'healthcare':     Color(0xFFEF5350),
  'shopping':       Color(0xFFFFA726),
  'safety':         Color(0xFFAB47BC),
  'religion':       Color(0xFF8D6E63),
  'recreation':     Color(0xFF26C6DA),
};

const _catIcon = {
  'transportation': Icons.train_rounded,
  'education':      Icons.school_rounded,
  'healthcare':     Icons.local_hospital_rounded,
  'shopping':       Icons.shopping_bag_rounded,
  'safety':         Icons.shield_rounded,
  'religion':       Icons.church_rounded,
  'recreation':     Icons.park_rounded,
};

const _subTypeLabel = <String, String>{
  // Transportation
  'bus_stop': 'Bus Stops', 'station': 'Train Stations',
  'subway_entrance': 'Metro Stations', 'taxi': 'Taxi Stands',
  'bicycle_rental': 'Bike Sharing', 'parking': 'Parking Areas',
  'ferry_terminal': 'Ferry Terminals', 'tram_stop': 'Tram Stops',
  // Education
  'school': 'Schools', 'university': 'Universities',
  'college': 'Colleges', 'library': 'Libraries',
  'kindergarten': 'Kindergartens', 'language_school': 'Language Schools',
  // Healthcare
  'hospital': 'Hospitals', 'clinic': 'Clinics',
  'pharmacy': 'Pharmacies', 'doctors': 'Surgeries',
  'dentist': 'Dentists', 'veterinary': 'Veterinary',
  // Shopping
  'supermarket': 'Supermarkets', 'mall': 'Shopping Centres',
  'convenience': 'Convenience Stores', 'market': 'Markets',
  'bakery': 'Bakeries', 'butcher': 'Butchers',
  'clothes': 'Clothing Stores', 'electronics': 'Electronics',
  // Safety
  'police': 'Police Stations', 'fire_station': 'Fire Stations',
  'ambulance_station': 'Ambulance Stations',
  // Recreation
  'park': 'Parks', 'garden': 'Gardens',
  'sports_centre': 'Sports Centres', 'gym': 'Gyms',
  'playground': 'Playgrounds', 'pitch': 'Sports Pitches',
  'swimming_pool': 'Swimming Pools',
  // Religion
  'church': 'Churches', 'mosque': 'Mosques',
  'temple': 'Temples', 'synagogue': 'Synagogues',
  'place_of_worship': 'Places of Worship',
};

const _subTypeIcon = <String, IconData>{
  'bus_stop': Icons.directions_bus_rounded,
  'station': Icons.train_rounded,
  'subway_entrance': Icons.subway_rounded,
  'tram_stop': Icons.tram_rounded,
  'taxi': Icons.local_taxi_rounded,
  'bicycle_rental': Icons.pedal_bike_rounded,
  'parking': Icons.local_parking_rounded,
  'ferry_terminal': Icons.directions_boat_rounded,
  'school': Icons.school_rounded,
  'university': Icons.account_balance_rounded,
  'college': Icons.account_balance_rounded,
  'library': Icons.menu_book_rounded,
  'kindergarten': Icons.child_care_rounded,
  'hospital': Icons.local_hospital_rounded,
  'clinic': Icons.medical_services_rounded,
  'pharmacy': Icons.local_pharmacy_rounded,
  'doctors': Icons.medical_services_rounded,
  'dentist': Icons.medical_services_rounded,
  'supermarket': Icons.shopping_cart_rounded,
  'mall': Icons.store_mall_directory_rounded,
  'convenience': Icons.storefront_rounded,
  'market': Icons.storefront_rounded,
  'police': Icons.local_police_rounded,
  'fire_station': Icons.local_fire_department_rounded,
  'park': Icons.park_rounded,
  'garden': Icons.yard_rounded,
  'sports_centre': Icons.sports_rounded,
  'gym': Icons.fitness_center_rounded,
  'playground': Icons.child_friendly_rounded,
  'swimming_pool': Icons.pool_rounded,
  'church': Icons.church_rounded,
  'mosque': Icons.mosque_rounded,
  'place_of_worship': Icons.church_rounded,
};

const _lifestyleTags = <String, List<String>>{
  'transportation': [
    '✅ No car required',
    '✅ Great for daily commuters',
    '✅ Student-friendly transit',
    '✅ Easy city-centre access',
  ],
  'education': [
    '✅ Family-friendly area',
    '✅ Strong school access',
    '✅ University nearby',
    '✅ Great for students',
  ],
  'healthcare': [
    '✅ Pharmacy within walking distance',
    '✅ Emergency care reachable',
    '✅ Regular healthcare access',
  ],
  'shopping': [
    '✅ Daily needs covered on foot',
    '✅ No car needed for errands',
    '✅ Convenient lifestyle',
    '✅ Variety of options nearby',
  ],
  'safety': [
    '✅ Emergency services nearby',
    '✅ Well-monitored area',
    '✅ Peace of mind',
  ],
  'recreation': [
    '✅ Active lifestyle supported',
    '✅ Green spaces within reach',
    '✅ Outdoor activities available',
    '✅ Good for mental wellbeing',
  ],
  'religion': [
    '✅ Diverse spiritual community',
    '✅ Cultural richness nearby',
    '✅ Community spaces accessible',
  ],
};

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _scoreColor(double s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFF3B82F6);
  if (s >= 40) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _scoreLabel(double s) {
  if (s >= 80) return 'Excellent';
  if (s >= 60) return 'Good';
  if (s >= 40) return 'Fair';
  return 'Poor';
}

String _dist(int? m) {
  if (m == null) return '—';
  return m < 1000 ? '${m}m' : '${(m / 1000).toStringAsFixed(1)}km';
}

String _percentile(double score) {
  if (score >= 95) return 'Top 5%';
  if (score >= 90) return 'Top 10%';
  if (score >= 85) return 'Top 15%';
  if (score >= 80) return 'Top 20%';
  if (score >= 75) return 'Top 25%';
  if (score >= 70) return 'Top 30%';
  if (score >= 60) return 'Top 40%';
  return 'Average';
}

String _whyText(String catId, double score, int count, int? closestM) {
  final tier = _scoreLabel(score).toLowerCase();
  final distStr = closestM != null ? _dist(closestM) : 'nearby';
  switch (catId) {
    case 'transportation':
      return score >= 80
          ? 'This property has $tier transportation access with $count transit options available, the nearest being just $distStr away. Car-free living is very practical here.'
          : score >= 60
          ? 'Transportation access is $tier with $count options within range. Most daily destinations are reachable without a car.'
          : 'Transportation options are limited with $count facilities in range. A private vehicle may be needed for some journeys.';
    case 'education':
      return score >= 80
          ? 'Education access is $tier with $count learning facilities nearby. The closest is just $distStr away, making school runs and campus visits easy.'
          : score >= 60
          ? 'Education provision is $tier with $count facilities within reach. Families and students will find reasonable access to schools and institutions.'
          : 'Educational facilities are limited with $count options in the area. Consider this if schooling proximity is a priority.';
    case 'healthcare':
      return score >= 80
          ? 'Healthcare access is $tier with $count facilities available, starting from $distStr. Emergency and routine care are both well covered.'
          : score >= 60
          ? 'Healthcare provision is $tier with $count facilities within range. Routine care is accessible without long travel.'
          : 'Healthcare options are limited with $count facilities nearby. Urgent or specialist care may require longer journeys.';
    case 'shopping':
      return score >= 80
          ? 'Shopping convenience is $tier with $count retail options available. Daily essentials are within easy walking distance — no car needed.'
          : score >= 60
          ? 'Shopping access is $tier with $count stores and markets in range. Most everyday needs can be met locally.'
          : 'Shopping options are limited with $count facilities nearby. A larger supermarket or shopping centre may require travel.';
    case 'safety':
      return score >= 80
          ? 'Safety infrastructure is $tier with $count emergency services in the vicinity. Response times should be fast given the proximity of services.'
          : score >= 60
          ? 'Safety provision is $tier with $count emergency services within range.'
          : 'Emergency services coverage is limited with $count facilities in the area.';
    case 'recreation':
      return score >= 80
          ? 'Recreation access is $tier with $count green spaces and leisure facilities nearby. The closest is just $distStr away — an active, outdoor lifestyle is well supported.'
          : score >= 60
          ? 'Recreation options are $tier with $count facilities in range. Parks and leisure areas are reasonably accessible.'
          : 'Recreation facilities are limited with $count options nearby. Green space access may require more deliberate travel.';
    default:
      return score >= 80
          ? 'This category scores $tier with $count places of interest, the nearest at $distStr.'
          : 'This category shows $tier availability with $count options within the search area.';
  }
}

String _recommendation(String catId, double score) {
  switch (catId) {
    case 'transportation':
      return score >= 80
          ? 'If transportation is a priority, this property is an excellent choice. Daily commuting is comfortable without depending on a private vehicle. Public transit, cycling, and walking are all practical options.'
          : score >= 60
          ? 'This property offers reasonable transit connections. Most destinations are reachable but you may want to plan commute routes in advance for less frequent services.'
          : 'Transportation access is a potential concern here. Factor in commute times and the cost of private transport when evaluating this property.';
    case 'education':
      return score >= 80
          ? 'For families or students, this is a strong location. Multiple schools and learning institutions are within easy reach, reducing daily commute time significantly.'
          : score >= 60
          ? 'Educational access is adequate. Families should verify specific school catchment areas and proximity to preferred institutions.'
          : 'Limited nearby educational facilities may be a consideration for families. Research transport options to schools further afield.';
    case 'healthcare':
      return score >= 80
          ? 'Healthcare access is a genuine strength of this property. From pharmacies to hospitals, medical needs at any urgency level are well catered for nearby.'
          : score >= 60
          ? 'Routine healthcare needs are reasonably met. Verify the location of your preferred GP, pharmacy, and any specialist services you regularly use.'
          : 'Healthcare access is limited here. Ensure you are comfortable with travel distances to hospitals and clinics before committing.';
    case 'shopping':
      return score >= 80
          ? 'Day-to-day living is very convenient here. Groceries, retail, and dining options are all within easy reach — a real quality-of-life advantage.'
          : score >= 60
          ? 'Shopping needs are reasonably covered. Major weekly shops may require a short journey but everyday essentials should be accessible on foot.'
          : 'Shopping convenience is limited. Budget extra time and potentially transport costs for regular grocery and retail needs.';
    case 'safety':
      return score >= 80
          ? 'Emergency services are well positioned relative to this property. This is reassuring both for daily peace of mind and for insurance considerations.'
          : 'Emergency service coverage is adequate for the area. As with any location, it is worth checking local crime statistics independently.';
    case 'recreation':
      return score >= 80
          ? 'For an active lifestyle, this property scores highly. Parks, sports facilities, and green spaces nearby support both physical and mental wellbeing.'
          : score >= 60
          ? 'Recreation options are available within a reasonable distance. Consider your preferred activities and verify specific facility access before deciding.'
          : 'Green space and leisure facilities are limited nearby. If outdoor activity is important to you, factor this into your decision.';
    default:
      return score >= 80
          ? 'This category is a genuine asset of the property — well above average for the area.'
          : score >= 60
          ? 'This category meets typical expectations for the area with some room for improvement.'
          : 'This category is below average and worth considering as part of your overall assessment.';
  }
}

// ── Sub-type model ────────────────────────────────────────────────────────────

class _SubType {
  final String type;
  final int count;
  final double score;
  final int closestM;
  const _SubType({
    required this.type,
    required this.count,
    required this.score,
    required this.closestM,
  });
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class CategoryDetailSheet extends StatefulWidget {
  final CategoryScore cat;
  final List<AmenityModel> amenities;
  final AddressModel? address;

  const CategoryDetailSheet({
    super.key,
    required this.cat,
    required this.amenities,
    this.address,
  });

  @override
  State<CategoryDetailSheet> createState() => _CategoryDetailSheetState();
}

class _CategoryDetailSheetState extends State<CategoryDetailSheet> {
  late final Color _color;
  late final List<_SubType> _subtypes;
  late final List<int> _distBands; // count per band: 0-200, 200-500, 500-1k, 1-2k, >2k
  late final List<double> _curve;  // relative score per distance band

  @override
  void initState() {
    super.initState();
    _color = _catColor[widget.cat.id] ?? const Color(0xFF3B82F6);
    _subtypes = _computeSubtypes();
    _distBands = _computeDistBands();
    _curve = _computeCurve();
  }

  List<_SubType> _computeSubtypes() {
    final groups = <String, List<AmenityModel>>{};
    for (final a in widget.amenities) {
      groups.putIfAbsent(a.type, () => []).add(a);
    }
    if (groups.isEmpty) return [];
    final maxCount = groups.values.map((l) => l.length).reduce(max);
    final base = widget.cat.score;
    return (groups.entries.map((e) {
      final list = e.value..sort((a, b) =>
          (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999));
      final count = list.length;
      final closest = list.first.distanceMeters ?? 99999;
      final countFactor = 0.7 + (count / maxCount) * 0.3;
      final distFactor = closest < 200 ? 1.06 : closest < 500 ? 1.0 : closest < 1000 ? 0.95 : 0.88;
      final score = (base * countFactor * distFactor).clamp(0, 100);
      return _SubType(type: e.key, count: count, score: score, closestM: closest);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score)));
  }

  List<int> _computeDistBands() {
    final bands = [200, 500, 1000, 2000, 99999];
    final prev = [0, 200, 500, 1000, 2000];
    return List.generate(bands.length, (i) => widget.amenities
        .where((a) {
          final d = a.distanceMeters ?? 99999;
          return d > prev[i] && d <= bands[i];
        })
        .length);
  }

  List<double> _computeCurve() {
    final thresholds = [200.0, 500.0, 1000.0, 2000.0, 5000.0];
    final total = widget.amenities.length;
    if (total == 0) return List.filled(thresholds.length, 0);
    return thresholds.map((t) {
      final inRange = widget.amenities.where((a) => (a.distanceMeters ?? 99999) <= t).length;
      return (widget.cat.score * (0.35 + 0.65 * inRange / total)).clamp(0, 100);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: CustomScrollView(
          controller: ctrl,
          slivers: [
            SliverToBoxAdapter(child: _buildHandle()),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildScoreOverview()),
            SliverToBoxAdapter(child: _buildBreakdown()),
            SliverToBoxAdapter(child: _buildNearby()),
            if (widget.address?.lat != null && widget.address?.lng != null)
              SliverToBoxAdapter(child: _buildMiniMap()),
            SliverToBoxAdapter(child: _buildWhatMakes()),
            SliverToBoxAdapter(child: _buildQuickStats()),
            SliverToBoxAdapter(child: _buildLifestyle()),
            SliverToBoxAdapter(child: _buildRecommendation()),
            SliverToBoxAdapter(child: SizedBox(height: 32 + bottom)),
          ],
        ),
      ),
    );
  }

  // ── Drag handle ─────────────────────────────────────────────────────────────

  Widget _buildHandle() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final score = widget.cat.score;
    final color = _color;
    final label = _scoreLabel(score);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Animated ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 80, height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _RingPainter(progress: 1, color: _kBorder, stroke: 5),
                  ),
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _RingPainter(progress: v, color: color, stroke: 5),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.round().toString(),
                        style: TextStyle(
                          color: color, fontSize: 24,
                          fontWeight: FontWeight.w900, height: 1,
                        ),
                      ),
                      Text('/ 100', style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 9.5,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _catEmoji[widget.cat.id] ?? '📍',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.cat.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _scoreColor(score).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _scoreColor(score),
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Text(
                        _percentile(score),
                        style: TextStyle(
                          color: color,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.cat.count} places in this category',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Score overview chart ─────────────────────────────────────────────────────

  Widget _buildScoreOverview() {
    const labels = ['0–200m', '–500m', '–1km', '–2km', '–5km'];
    final color = _color;

    return _Section(
      title: 'SCORE OVERVIEW',
      child: SizedBox(
        height: 130,
        child: CustomPaint(
          painter: _SparklinePainter(values: _curve, color: color),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: labels.map((l) => Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 9,
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 350.ms);
  }

  // ── Breakdown ────────────────────────────────────────────────────────────────

  Widget _buildBreakdown() {
    if (_subtypes.isEmpty) return const SizedBox.shrink();
    final color = _color;
    final top = _subtypes.take(6).toList();
    final maxScore = top.map((s) => s.score).reduce(max);

    return _Section(
      title: 'BREAKDOWN',
      child: Column(
        children: List.generate(top.length, (i) {
          final s = top[i];
          final label = _subTypeLabel[s.type] ?? _prettify(s.type);
          final icon = _subTypeIcon[s.type] ?? _catIcon[widget.cat.id] ?? Icons.place_rounded;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: const TextStyle(
                            color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500,
                          )),
                          Text(
                            s.score.round().toString(),
                            style: TextStyle(
                              color: color, fontSize: 13, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: s.score / maxScore),
                        duration: Duration(milliseconds: 700 + i * 80),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 5,
                            backgroundColor: _kBorder,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.04, end: 0);
        }),
      ),
    );
  }

  // ── Nearby places ────────────────────────────────────────────────────────────

  Widget _buildNearby() {
    final top = widget.amenities.take(6).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final color = _color;
    final icon = _catIcon[widget.cat.id] ?? Icons.place_rounded;

    return _Section(
      title: 'NEARBY PLACES',
      trailing: widget.amenities.length > 6
          ? Text(
              'View all ${widget.amenities.length}',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          children: [
            for (int i = 0; i < top.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.white.withOpacity(0.05)),
              _NearbyTile(
                amenity: top[i],
                color: color,
                icon: icon,
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: 120.ms).fadeIn(duration: 350.ms);
  }

  // ── Mini map ─────────────────────────────────────────────────────────────────

  Widget _buildMiniMap() {
    final lat = widget.address!.lat!;
    final lng = widget.address!.lng!;
    final color = _color;
    final icon = _catIcon[widget.cat.id] ?? Icons.place_rounded;
    final markers = widget.amenities.take(15).toList();

    return _Section(
      title: 'MAP PREVIEW',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 190,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.homescope.app',
              ),
              CircleLayer(circles: [
                CircleMarker(
                  point: LatLng(lat, lng),
                  radius: 500,
                  useRadiusInMeter: true,
                  color: color.withOpacity(0.08),
                  borderColor: color.withOpacity(0.35),
                  borderStrokeWidth: 1.5,
                ),
              ]),
              MarkerLayer(markers: [
                // Category amenity markers
                ...markers.map((a) => Marker(
                  point: LatLng(a.lat, a.lng),
                  width: 22, height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(icon, color: Colors.white, size: 10),
                  ),
                )),
                // Home pin
                Marker(
                  point: LatLng(lat, lng),
                  width: 32, height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kBg, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFF060B14), size: 16),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ).animate(delay: 160.ms).fadeIn(duration: 350.ms);
  }

  // ── What makes this score ────────────────────────────────────────────────────

  Widget _buildWhatMakes() {
    final score = widget.cat.score;
    final label = _scoreLabel(score).toLowerCase();
    final color = _color;

    // Build bullet points from actual data
    final bullets = <String>[];
    for (final st in _subtypes.take(4)) {
      final stLabel = _subTypeLabel[st.type] ?? _prettify(st.type);
      bullets.add('${st.count} $stLabel within ${_dist(st.closestM)}');
    }
    if (widget.cat.closest?.walkingMinutes != null) {
      bullets.add('Nearest place: ${widget.cat.closest!.walkingMinutes} min walk');
    }

    return _Section(
      title: 'WHY IS THIS SCORE ${label.toUpperCase()}?',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kSurface, color.withOpacity(0.06)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You have:',
                  style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(b, style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13, height: 1.4,
                    )),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 350.ms);
  }

  // ── Quick stats ──────────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    final closest = widget.amenities.isNotEmpty ? widget.amenities.first : null;
    final within500 = widget.amenities.where((a) => (a.distanceMeters ?? 99999) <= 500).length;
    final within1k = widget.amenities.where((a) => (a.distanceMeters ?? 99999) <= 1000).length;

    final stats = [
      _Stat('Nearest', closest != null ? _dist(closest.distanceMeters) : '—', Icons.near_me_rounded),
      _Stat('Walk time', closest?.walkingMinutes != null ? '${closest!.walkingMinutes} min' : '—', Icons.directions_walk_rounded),
      _Stat('Within 500m', '$within500 places', Icons.radio_button_checked_rounded),
      _Stat('Within 1km', '$within1k places', Icons.radio_button_off_rounded),
      _Stat('Total nearby', '${widget.cat.count} places', Icons.place_rounded),
      _Stat('Score', '${widget.cat.score.round()} / 100', Icons.bar_chart_rounded),
    ];

    return _Section(
      title: 'QUICK STATISTICS',
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.45,
        children: stats.map((s) => _StatTile(stat: s, color: _color)).toList(),
      ),
    ).animate(delay: 240.ms).fadeIn(duration: 350.ms);
  }

  // ── Lifestyle tags ────────────────────────────────────────────────────────────

  Widget _buildLifestyle() {
    final tags = _lifestyleTags[widget.cat.id] ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'LIFESTYLE INSIGHTS',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Text(t, style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 12.5,
          )),
        )).toList(),
      ),
    ).animate(delay: 280.ms).fadeIn(duration: 350.ms);
  }

  // ── AI recommendation ─────────────────────────────────────────────────────────

  Widget _buildRecommendation() {
    final text = _recommendation(widget.cat.id, widget.cat.score);
    return _Section(
      title: 'AI RECOMMENDATION',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kSurface, _kAccent2.withOpacity(0.07)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kAccent2.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: _kAccent2, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13.5, height: 1.65,
              )),
            ),
          ],
        ),
      ),
    ).animate(delay: 320.ms).fadeIn(duration: 350.ms);
  }
}

// ── Nearby tile ───────────────────────────────────────────────────────────────

class _NearbyTile extends StatelessWidget {
  final AmenityModel amenity;
  final Color color;
  final IconData icon;
  const _NearbyTile({required this.amenity, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amenity.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _prettify(amenity.type),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38), fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _dist(amenity.distanceMeters),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w600,
                ),
              ),
              if (amenity.walkingMinutes != null)
                Text(
                  '${amenity.walkingMinutes} min',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.32),
                  fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Stat model & tile ─────────────────────────────────────────────────────────

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  final Color color;
  const _StatTile({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat.icon, color: color.withOpacity(0.7), size: 15),
          const Spacer(),
          Text(
            stat.value,
            style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.32), fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkline painter ──────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(max).clamp(1, 100);
    final w = size.width / (values.length - 1);
    final chartH = size.height - 20;
    final pts = List.generate(values.length, (i) {
      final x = i * w;
      final y = chartH - (values[i] / maxV * chartH * 0.8);
      return Offset(x, y);
    });

    // Gradient fill
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    path
      ..lineTo(size.width, chartH)
      ..lineTo(0, chartH)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (final p in pts) {
      canvas.drawCircle(p, 4, Paint()..color = color);
      canvas.drawCircle(p, 3, Paint()..color = _kBg);
    }

    // Score labels on dots
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < pts.length; i++) {
      tp.text = TextSpan(
        text: values[i].round().toString(),
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w700),
      );
      tp.layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, pts[i].dy - 16));
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  const _RingPainter({required this.progress, required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = stroke / 2;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    canvas.drawArc(
      rect, -pi / 2, 2 * pi * progress, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Utilities ──────────────────────────────────────────────────────────────────

String _prettify(String type) =>
    type.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');

String _dist(int? m) {
  if (m == null) return '—';
  return m < 1000 ? '${m}m' : '${(m / 1000).toStringAsFixed(1)}km';
}
