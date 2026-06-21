import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/app_constants.dart';

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'data': data,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory CacheEntry.fromMap(Map<String, dynamic> map) => CacheEntry(
        data: map['data'],
        expiresAt: DateTime.parse(map['expires_at'] as String),
      );
}

class CacheService {
  Box get _box => Hive.box('homescope_cache');

  T? get<T>(String key) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final entry = CacheEntry.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw as String) as Map),
      );
      if (entry.isExpired) {
        _box.delete(key);
        return null;
      }
      return entry.data as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    final entry = CacheEntry(
      data: value,
      expiresAt: DateTime.now().add(ttl ?? AppConstants.cacheTtl),
    );
    await _box.put(key, jsonEncode(entry.toMap()));
  }

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}
