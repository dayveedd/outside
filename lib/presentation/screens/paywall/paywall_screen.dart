import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/subscription/subscription_bloc.dart';
import '../../../logic/subscription/subscription_event.dart';
import '../../../logic/subscription/subscription_state.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    debugPrint('[PaywallScreen] initState - triggering CheckSubscriptionStatus');
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
  }

  void _onPurchasePressed() {
    if (_selectedPackage != null) {
      debugPrint('[PaywallScreen] Purchase tapped for: ${_selectedPackage!.identifier}');
      context.read<SubscriptionBloc>().add(PurchasePackageEvent(_selectedPackage!));
    }
  }

  void _onRestorePressed() {
    debugPrint('[PaywallScreen] Restore tapped');
    context.read<SubscriptionBloc>().add(RestorePurchasesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionStatus && state.isPremium) {
          debugPrint('[PaywallScreen] Premium unlocked');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Outside Pro! Access unlocked.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is SubscriptionError) {
          debugPrint('[PaywallScreen] Error listener: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _onRestorePressed,
              child: Text(
                'Restore',
                style: AppTypography.uiSemiBold.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            final isLoading = state is SubscriptionLoading;
            List<Package> packages = [];
            bool isPremium = false;

            if (state is SubscriptionStatus) {
              packages = state.packages;
              isPremium = state.isPremium;

              if (packages.isNotEmpty) {
                final containsSelected = _selectedPackage != null &&
                    packages.any((p) => p.identifier == _selectedPackage!.identifier);
                if (!containsSelected) {
                  _selectedPackage = packages.where((p) {
                    final isAnnual = p.packageType == PackageType.annual ||
                        p.identifier.toLowerCase().contains('annual');
                    return isAnnual && p.storeProduct.price > 5;
                  }).firstOrNull ?? packages.first;
                }
              }
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'OUTSIDE PRO',
                            style: AppTypography.uiSemiBold.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.2,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Deepen your curiosity.',
                        textAlign: TextAlign.center,
                        style: AppTypography.h1.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Unlock the complete historical archive, alternate perspectives, and daily mindful reflections.',
                          textAlign: TextAlign.center,
                          style: AppTypography.subtitle.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildPerkItem(
                              icon: Icons.history_edu_rounded,
                              title: 'Complete Historical Archive',
                              description: 'Read every lesson across philosophy, arts, science, and history.',
                            ),
                            const SizedBox(height: 14),
                            _buildPerkItem(
                              icon: Icons.alt_route_rounded,
                              title: 'Multi-Perspective Exploration',
                              description: 'Toggle and compare alternative viewpoints on every daily idea.',
                            ),
                            const SizedBox(height: 14),
                            _buildPerkItem(
                              icon: Icons.menu_book_rounded,
                              title: 'Daily Deep Dives & Journals',
                              description: 'Record personal reflections and build unbroken learning streaks.',
                            ),
                            const SizedBox(height: 14),
                            _buildPerkItem(
                              icon: Icons.star_border_rounded,
                              title: 'Independent & 100% Ad-Free',
                              description: 'Pure editorial insights crafted with care, zero algorithms or noise.',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'CHOOSE YOUR PLAN',
                        style: AppTypography.uiSemiBold.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (packages.isEmpty && !isLoading)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                state is SubscriptionError
                                    ? state.message
                                    : 'Unable to load subscription plans from App Store.',
                                textAlign: TextAlign.center,
                                style: AppTypography.subtitle.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check console logs for [RevenueCat] diagnostics or tap Retry.',
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () {
                                  debugPrint('[PaywallScreen] Retry button tapped');
                                  context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
                                  ),
                                ),
                                child: Text(
                                  'Retry',
                                  style: AppTypography.uiSemiBold.copyWith(color: AppColors.secondary),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (packages.isEmpty && isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.accent),
                          ),
                        )
                      else
                        ...packages.map((package) {
                          final isSelected = _selectedPackage?.identifier == package.identifier;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLivePackageCard(
                              package: package,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedPackage = package;
                                });
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading || isPremium || _selectedPackage == null
                            ? null
                            : _onPurchasePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.secondary,
                          minimumSize: const Size(double.infinity, 54),
                          elevation: 4,
                          shadowColor: AppColors.accent.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppShapes.buttonRadius),
                          ),
                        ),
                        child: Text(
                          isPremium
                              ? 'Outside Pro Active'
                              : _selectedPackage != null
                                  ? 'Start Subscription — ${_selectedPackage!.storeProduct.priceString}'
                                  : 'Select a Plan',
                          style: AppTypography.uiSemiBold.copyWith(
                            color: AppColors.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Auto-renews until cancelled. Manage anytime in App Store settings.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                if (isLoading && packages.isNotEmpty)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLivePackageCard({
    required Package package,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final product = package.storeProduct;
    final title = product.title.split('(')[0].trim().isEmpty
        ? package.identifier
        : product.title.split('(')[0].trim();

    String? badgeText;
    String periodDisplay = '';
    String effectiveMonthly = product.priceString;
    String billingSummary = product.description;

    final isAnnual = package.packageType == PackageType.annual ||
        package.identifier.toLowerCase().contains('annual');
    final isMonthly = package.packageType == PackageType.monthly ||
        package.identifier.toLowerCase().contains('monthly');

    if (isAnnual) {
      if (product.price > 5) {
        badgeText = 'BEST VALUE • SAVE 58%';
        periodDisplay = '/ year';
        effectiveMonthly = '\$${(product.price / 12).toStringAsFixed(2)} / month';
        billingSummary = '${product.priceString} billed annually';
      } else {
        badgeText = 'SAVE 50%';
        periodDisplay = '/ month';
        effectiveMonthly = '${product.priceString} / month';
        billingSummary = '12-month commitment • ${product.priceString} billed monthly';
      }
    } else if (isMonthly) {
      periodDisplay = '/ month';
      effectiveMonthly = '${product.priceString} / month';
      billingSummary = 'Billed monthly • Cancel anytime';
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fade,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.secondary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.uiSemiBold.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveMonthly,
                        style: AppTypography.uiSemiBold.copyWith(
                          color: isSelected ? AppColors.accent : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        billingSummary,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      product.priceString,
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    if (periodDisplay.isNotEmpty)
                      Text(
                        periodDisplay,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.uiSemiBold.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
