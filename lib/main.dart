import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'logic/lesson/lesson_bloc.dart';
import 'logic/streak/streak_bloc.dart';
import 'logic/subscription/subscription_bloc.dart';
import 'presentation/screens/daily_lesson/daily_lesson_screen.dart';
import 'presentation/screens/archive/archive_screen.dart';
import 'presentation/screens/saved/saved_screen.dart';
import 'presentation/screens/paywall/paywall_screen.dart';
import 'presentation/screens/auth/login_screen.dart';

import 'package:google_sign_in/google_sign_in.dart';

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
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<LessonBloc>(
            create: (context) => LessonBloc(
              lessonRepository: lessonRepository,
              userRepository: userRepository,
            ),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const DailyLessonScreen();
        } else if (state is Unauthenticated || state is AuthError) {
          return const LoginScreen();
        }
        return const Scaffold(
          backgroundColor: Color(0xFFFCFCFD),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
