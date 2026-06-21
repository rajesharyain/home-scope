import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/search/advanced_search_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/history/history_screen.dart';
import '../models/address_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'advanced-search',
        builder: (context, state) => const AdvancedSearchScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          final address = state.extra as AddressModel?;
          return DashboardScreen(address: address);
        },
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) {
          final address = state.extra as AddressModel?;
          return MapScreen(address: address);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
});
