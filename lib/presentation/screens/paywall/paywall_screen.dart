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
    // Load packages and state
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
  }

  void _onPurchasePressed() {
    if (_selectedPackage != null) {
      context.read<SubscriptionBloc>().add(PurchasePackageEvent(_selectedPackage!));
    }
  }

  void _onRestorePressed() {
    context.read<SubscriptionBloc>().add(RestorePurchasesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionStatus && state.isPremium) {
          // Success dialog and pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Outside Premium! Access unlocked.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is SubscriptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.secondary, // Premium deep navy background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            final isLoading = state is SubscriptionLoading;
            List<Package> packages = [];
            bool isPremium = false;

            if (state is SubscriptionStatus) {
              packages = state.packages;
              isPremium = state.isPremium;
              if (_selectedPackage == null && packages.isNotEmpty) {
                // Auto-select the first package (usually annual is best, but let's select first)
                _selectedPackage = packages.first;
              }
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Branding
                      const Icon(
                        Icons.blur_on_rounded,
                        color: AppColors.accent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'OUTSIDE PREMIUM',
                        textAlign: TextAlign.center,
                        style: AppTypography.uiSemiBold.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 3.0,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deepen your curiosity.',
                        textAlign: TextAlign.center,
                        style: AppTypography.h1.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock the complete historical archive, daily deep dives, and support independent, thoughtful learning.',
                        textAlign: TextAlign.center,
                        style: AppTypography.subtitle.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Premium Perks List
                      _buildPerkItem(
                        icon: Icons.history_rounded,
                        title: 'Unlimited Archive Access',
                        description: 'Read any historical lesson desde long ago.',
                      ),
                      _buildPerkItem(
                        icon: Icons.lightbulb_rounded,
                        title: 'Daily Deep Dives',
                        description: 'Access curated links, books, and references.',
                      ),
                      _buildPerkItem(
                        icon: Icons.star_rounded,
                        title: 'Support Independent Writing',
                        description: 'No ads, no algorithmic optimization, just curated learning.',
                      ),
                      const SizedBox(height: 40),

                      // Packages selector
                      if (packages.isEmpty && !isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No active purchase options found. Please try again later.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...packages.map((package) {
                          final isSelected = _selectedPackage?.identifier == package.identifier;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPackage = package;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          package.storeProduct.title.split('(')[0].trim(),
                                          style: AppTypography.uiSemiBold.copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          package.storeProduct.description,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    package.storeProduct.priceString,
                                    style: AppTypography.uiSemiBold.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      
                      const SizedBox(height: 24),

                      // Primary Purchase CTA
                      ElevatedButton(
                        onPressed: _selectedPackage != null && !isLoading && !isPremium
                            ? _onPurchasePressed
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.secondary,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Text(
                          isPremium ? 'Premium Active' : 'Start Subscription',
                          style: AppTypography.uiSemiBold.copyWith(
                            color: AppColors.secondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Restore Purchase link
                      TextButton(
                        onPressed: isLoading ? null : _onRestorePressed,
                        child: Text(
                          'Restore Previous Purchases',
                          style: AppTypography.uiSemiBold.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                
                // Loading overlay
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
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

  Widget _buildPerkItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.uiSemiBold.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
