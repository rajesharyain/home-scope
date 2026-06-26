import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProTier { free, pro, premium }

class ProState {
  final ProTier tier;
  const ProState({this.tier = ProTier.free});

  bool get isPro => tier == ProTier.pro || tier == ProTier.premium;
  bool get isPremium => tier == ProTier.premium;
  int get maxCompare => isPro ? 10 : 2;
  int get maxAlerts => isPremium ? 99 : (isPro ? 10 : 1);
}

class ProNotifier extends StateNotifier<ProState> {
  ProNotifier() : super(const ProState());
  void upgradeTo(ProTier tier) => state = ProState(tier: tier);
  void reset() => state = const ProState();
}

final proProvider = StateNotifierProvider<ProNotifier, ProState>(
  (ref) => ProNotifier(),
);
