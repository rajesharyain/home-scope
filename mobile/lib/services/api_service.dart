import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<Map<String, dynamic>> analyzeAddress({
    required String address,
    required String countryCode,
    required String profile,
    required double radius,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/analyze',
      data: {
        'address': address,
        'country_code': countryCode,
        'profile': profile,
        'radius': radius,
      },
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> geocode(String address, String countryCode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/geocode',
      data: {'address': address, 'country_code': countryCode},
    );
    return response.data!;
  }
}
