import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pro_provider.dart';

const Color _kBg = Color(0xFF060B14);
const Color _kSurface = Color(0xFF0D1625);
const Color _kSurface2 = Color(0xFF131F33);
const Color _kAccent = Color(0xFF3B82F6);
const Color _kBorder = Color(0xFF1A2845);
const Color _kPurple = Color(0xFF7C3AED);
const Color _kIndigo = Color(0xFF4F46E5);

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTierCards(),
                    const SizedBox(height: 24),
                    _buildCTAButtons(context, ref),
                    const SizedBox(height: 12),
                    _buildRestoreButton(),
                    const SizedBox(height: 8),
                    _buildLegalText(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kSurface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Icon(
            Icons.close_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoProBadge(),
        const SizedBox(height: 16),
        const Text(
          'Unlock the full\nHomeScope',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Make confident decisions with every insight at your fingertips.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGoProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccent, _kPurple],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Go Pro',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTierCards() {
    return Column(
      children: [
        _buildFreeCard(),
        const SizedBox(height: 12),
        _buildProCard(),
        const SizedBox(height: 12),
        _buildPremiumCard(),
      ],
    );
  }

  Widget _buildFreeCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Opacity(
        opacity: 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTierHeader('Free', '€0 / forever'),
            const SizedBox(height: 14),
            _buildFeatureItem('2 property comparisons'),
            _buildFeatureItem('1 neighbourhood alert'),
            _buildFeatureItem('Core analysis & maps'),
          ],
        ),
      ),
    );
  }

  Widget _buildProCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kAccent.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTierHeader('Pro', '€7.99 / month'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kAccent, _kIndigo],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFeatureItem('Unlimited comparisons'),
          _buildFeatureItem('10 neighbourhood alerts'),
          _buildFeatureItem('Priority analysis'),
          _buildFeatureItem('Historical timeline'),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _kPurple.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTierHeader('Premium', '€14.99 / month'),
          const SizedBox(height: 14),
          _buildFeatureItem('Everything in Pro'),
          _buildFeatureItem('99 alerts with push notifications'),
          _buildFeatureItem('AI investment insights'),
          _buildFeatureItem('Trend forecasting'),
        ],
      ),
    );
  }

  Widget _buildTierHeader(String name, String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          price,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: _kAccent,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildGradientButton(
          label: 'Start Pro — €7.99/mo',
          gradient: const LinearGradient(
            colors: [_kAccent, _kPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onTap: () {
            ref.read(proProvider.notifier).upgradeTo(ProTier.pro);
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 12),
        _buildGradientButton(
          label: 'Try Premium — €14.99/mo',
          gradient: const LinearGradient(
            colors: [_kPurple, _kIndigo],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onTap: () {
            ref.read(proProvider.notifier).upgradeTo(ProTier.premium);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return Center(
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text(
          'Restore purchases',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalText() {
    return Center(
      child: Text(
        'Cancel anytime. Billed monthly.',
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.3),
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
