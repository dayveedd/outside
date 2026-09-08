import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'core/constants/constants.dart';
import 'core/services/onesignal_service.dart';
import 'core/services/revenuecat_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/lesson_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/auth/auth_state.dart';
import 'logic/streak/streak_bloc.dart';
import 'logic/subscription/subscription_bloc.dart';
import 'presentation/screens/archive/archive_screen.dart';
import 'presentation/screens/saved/saved_screen.dart';
import 'presentation/screens/paywall/paywall_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/unauthenticated_flow_screen.dart';
import 'presentation/screens/home/main_navigation_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();
  final onesignalService = OneSignalService();
  final revenueCatService = RevenueCatService();
  await onesignalService.initialize();
  await revenueCatService.initialize();
  final userRepository = UserRepository();
  final lessonRepository = LessonRepository();
  final authRepository = AuthRepository();
  runApp(
    MyApp(
      userRepository: userRepository,
      lessonRepository: lessonRepository,
      authRepository: authRepository,
      revenueCatService: revenueCatService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final LessonRepository lessonRepository;
  final AuthRepository authRepository;
  final RevenueCatService revenueCatService;

  const MyApp({
    super.key,
    required this.userRepository,
    required this.lessonRepository,
    required this.authRepository,
    required this.revenueCatService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: lessonRepository),
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: revenueCatService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: authRepository,
              lessonRepository: lessonRepository,
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<StreakBloc>(
            create: (context) => StreakBloc(
              userRepository: userRepository,
            ),
          ),
          BlocProvider<SubscriptionBloc>(
            create: (context) => SubscriptionBloc(
              revenueCatService: revenueCatService,
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Outside',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
          routes: {
            AppConstants.archiveRoute: (context) => const ArchiveScreen(),
            AppConstants.savedRoute: (context) => const SavedScreen(),
            AppConstants.paywallRoute: (context) => const PaywallScreen(),
            AppConstants.loginRoute: (context) => const LoginScreen(),
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription? _subscriptionIdSub;
  StreamSubscription? _deepLinkSub;
  bool _verificationDialogShown = false;

  @override
  void initState() {
    super.initState();
    _subscriptionIdSub = OneSignalService().subscriptionIdStream.listen((id) {
      if (!mounted) return;
      if (!_verificationDialogShown) {
        _verificationDialogShown = true;
        _showVerificationDialog();
      }
    });

    _deepLinkSub = OneSignalService().deepLinkStream.listen((lessonId) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted || _verificationDialogShown) return;
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated && !OneSignalService().hasPermission) {
          _verificationDialogShown = true;
          _showVerificationDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _subscriptionIdSub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Daily Drop Notifications',
            style: AppTypography.h3.copyWith(color: AppColors.secondary),
          ),
          content: Text(
            'Outside delivers exactly one curated perspective each day at 00:00 UTC. Tap below to enable push notifications so you never miss a daily drop.',
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Later',
                style: AppTypography.uiMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await OneSignalService().promptNotificationPermission();
              },
              child: const Text('Enable Notifications'),
            ),
          ],
        );
      },
    );
  }

  bool _isSplashFinished = false;

  void _onSplashFinish() {
    if (mounted) {
      setState(() {
        _isSplashFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (!_isSplashFinished) {
          return SplashScreen(onFinish: _onSplashFinish);
        }
        if (state is Authenticated) {
          return const MainNavigationScreen();
        } else if (state is Unauthenticated || state is AuthError) {
          return const UnauthenticatedFlowScreen();
        }
        return const SplashScreen();
      },
    );
  }
}
