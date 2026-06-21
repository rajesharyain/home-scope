import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/country_provider.dart';

final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService(ref);
});

class ValidationService {
  final Ref _ref;

  ValidationService(this._ref);

  String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) return null; // optional field
    final country = _ref.read(selectedCountryProvider);
    if (country == null) return null;
    if (!RegExp(country.postalPattern).hasMatch(value)) {
      return 'Invalid format. Expected: ${country.postalFormat}';
    }
    return null;
  }

  String? validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    if (value.trim().length < 5) return 'Address is too short';
    return null;
  }
}
