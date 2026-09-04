import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/subscription/subscription_bloc.dart';
import '../../../logic/subscription/subscription_event.dart';
import '../../../logic/subscription/subscription_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<SubscriptionBloc>().add(CheckSubscriptionStatus());
    OneSignalService().refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      OneSignalService().refreshPermission();
    }
  }

  void _onLogoutPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Outside?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onDeleteAccountPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. All your progress, streak history, and subscription access will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(DeleteAccountRequested());
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: AppTypography.uiSemiBold.copyWith(
            fontSize: 16,
            letterSpacing: 2.0,
            color: AppColors.secondary,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  bool isPremium = false;
                  if (state is SubscriptionStatus) {
                    isPremium = state.isPremium;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Membership Status',
                        style: AppTypography.uiSemiBold.copyWith(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPremium ? 'Outside Premium' : 'Free Plan',
                            style: AppTypography.h3.copyWith(
                              color: isPremium ? AppColors.primary : AppColors.secondary,
                            ),
                          ),
                          if (isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Lifetime',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppConstants.paywallRoute);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Upgrade',
                                style: AppTypography.uiSemiBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: OneSignalService().permissionNotifier,
              builder: (context, hasPermission, _) {
                final bool active = hasPermission || OneSignalService().hasPermission;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notifications',
                        style: AppTypography.uiSemiBold.copyWith(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Lesson Drop (00:00 UTC)',
                                  style: AppTypography.uiSemiBold.copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  active
                                      ? 'Notifications are active'
                                      : 'Enable to receive daily perspectives',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          if (!active)
                            ElevatedButton(
                              onPressed: () async {
                                final granted = await OneSignalService().promptNotificationPermission();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            granted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                            color: granted ? AppColors.success : AppColors.accent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              granted
                                                  ? 'Daily drop notifications enabled.'
                                                  : 'Notification preferences updated.',
                                              style: AppTypography.uiMedium.copyWith(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.surface,
                                      behavior: SnackBarBehavior.floating,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: AppColors.border),
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Enable', style: TextStyle(fontSize: 12)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Active',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF166534),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
                title: Text(
                  'Log Out',
                  style: AppTypography.uiMedium.copyWith(color: AppColors.textPrimary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: _onLogoutPressed,
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'DANGER ZONE',
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                title: Text(
                  'Delete Account',
                  style: AppTypography.uiMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Permanently remove all your progress and data',
                  style: AppTypography.caption.copyWith(
                    color: Colors.red.shade400,
                    fontSize: 11,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.error, size: 14),
                onTap: _onDeleteAccountPressed,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
