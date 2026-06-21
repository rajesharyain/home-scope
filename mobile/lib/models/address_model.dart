class AddressModel {
  final String displayAddress;
  final String? street;
  final String? number;
  final String? apartment;
  final String? postalCode;
  final String? city;
  final String? district;
  final String country;
  final String countryCode;
  final double? lat;
  final double? lng;
  final String? id;

  const AddressModel({
    required this.displayAddress,
    this.street,
    this.number,
    this.apartment,
    this.postalCode,
    this.city,
    this.district,
    this.country = 'Portugal',
    this.countryCode = 'PT',
    this.lat,
    this.lng,
    this.id,
  });

  AddressModel copyWith({
    String? displayAddress,
    String? street,
    String? number,
    String? apartment,
    String? postalCode,
    String? city,
    String? district,
    String? country,
    String? countryCode,
    double? lat,
    double? lng,
    String? id,
  }) =>
      AddressModel(
        displayAddress: displayAddress ?? this.displayAddress,
        street: street ?? this.street,
        number: number ?? this.number,
        apartment: apartment ?? this.apartment,
        postalCode: postalCode ?? this.postalCode,
        city: city ?? this.city,
        district: district ?? this.district,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        id: id ?? this.id,
      );

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        displayAddress: json['display_address'] as String? ?? json['displayAddress'] as String? ?? '',
        street: json['street'] as String?,
        number: json['number'] as String?,
        apartment: json['apartment'] as String?,
        postalCode: json['postal_code'] as String?,
        city: json['city'] as String?,
        district: json['district'] as String?,
        country: json['country'] as String? ?? 'Portugal',
        countryCode: json['country_code'] as String? ?? 'PT',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        id: json['id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'display_address': displayAddress,
        if (street != null) 'street': street,
        if (number != null) 'number': number,
        if (apartment != null) 'apartment': apartment,
        if (postalCode != null) 'postal_code': postalCode,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        'country': country,
        'country_code': countryCode,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (id != null) 'id': id,
      };
}

class CountryConfig {
  final String code;
  final String name;
  final String language;
  final String currency;
  final String postalPattern;
  final String postalFormat;
  final String postalExample;
  final String nominatimCountry;
  final String defaultCity;
  final LatLngModel center;
  final double defaultZoom;

  const CountryConfig({
    required this.code,
    required this.name,
    required this.language,
    required this.currency,
    required this.postalPattern,
    required this.postalFormat,
    required this.postalExample,
    required this.nominatimCountry,
    required this.defaultCity,
    required this.center,
    required this.defaultZoom,
  });

  factory CountryConfig.fromJson(Map<String, dynamic> json) => CountryConfig(
        code: json['code'] as String,
        name: json['name'] as String,
        language: json['language'] as String,
        currency: json['currency'] as String,
        postalPattern: json['postalPattern'] as String,
        postalFormat: json['postalFormat'] as String,
        postalExample: json['postalExample'] as String,
        nominatimCountry: json['nominatimCountry'] as String,
        defaultCity: json['defaultCity'] as String,
        center: LatLngModel.fromJson(json['center'] as Map<String, dynamic>),
        defaultZoom: (json['defaultZoom'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CountryConfig && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class LatLngModel {
  final double lat;
  final double lng;

  const LatLngModel({required this.lat, required this.lng});

  factory LatLngModel.fromJson(Map<String, dynamic> json) => LatLngModel(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}
