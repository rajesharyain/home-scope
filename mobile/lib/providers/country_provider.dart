import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';

final countriesProvider = FutureProvider<List<CountryConfig>>((ref) async {
  final raw = await rootBundle.loadString('assets/config/countries.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final list = data['countries'] as List;
  return list.map((e) => CountryConfig.fromJson(e as Map<String, dynamic>)).toList();
});

final selectedCountryProvider =
    StateNotifierProvider<SelectedCountryNotifier, CountryConfig?>(
  (ref) => SelectedCountryNotifier(ref),
);

class SelectedCountryNotifier extends StateNotifier<CountryConfig?> {
  final Ref _ref;

  SelectedCountryNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final countries = await _ref.read(countriesProvider.future);
    state = countries.firstWhere(
      (c) => c.code == 'PT',
      orElse: () => countries.first,
    );
  }

  void select(CountryConfig country) => state = country;

  bool validatePostal(String postal) {
    if (state == null) return true;
    return RegExp(state!.postalPattern).hasMatch(postal);
  }
}
