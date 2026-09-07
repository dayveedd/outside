import 'package:flutter/material.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

class UnauthenticatedFlowScreen extends StatefulWidget {
  const UnauthenticatedFlowScreen({super.key});

  @override
  State<UnauthenticatedFlowScreen> createState() => _UnauthenticatedFlowScreenState();
}

class _UnauthenticatedFlowScreenState extends State<UnauthenticatedFlowScreen> {
  bool _showLogin = false;
  bool _initialIsSignUp = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showLogin
          ? LoginScreen(
              key: const ValueKey('login_screen'),
              initialIsSignUp: _initialIsSignUp,
              onBack: () {
                setState(() {
                  _showLogin = false;
                });
              },
            )
          : OnboardingScreen(
              key: const ValueKey('onboarding_screen'),
              onGetStarted: () {
                setState(() {
                  _initialIsSignUp = true;
                  _showLogin = true;
                });
              },
              onSignIn: () {
                setState(() {
                  _initialIsSignUp = false;
                  _showLogin = true;
                });
              },
            ),
    );
  }
}
