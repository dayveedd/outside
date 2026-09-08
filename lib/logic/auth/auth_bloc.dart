import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../core/services/onesignal_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final LessonRepository? _lessonRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    LessonRepository? lessonRepository,
  })  : _authRepository = authRepository,
        _lessonRepository = lessonRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<SignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);

    _authSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthCheckRequested());
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      OneSignalService().login(user.uid);
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authRepository.signInWithEmail(event.email, event.password);
      if (credential.user != null) {
        OneSignalService().login(credential.user!.uid);
        emit(Authenticated(credential.user!));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authRepository.signUpWithEmail(event.email, event.password);
      if (credential.user != null) {
        OneSignalService().login(credential.user!.uid);
        emit(Authenticated(credential.user!));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authRepository.signInWithGoogle();
      if (credential.user != null) {
        OneSignalService().login(credential.user!.uid);
        emit(Authenticated(credential.user!));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithAppleRequested(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _authRepository.signInWithApple();
      if (credential.user != null) {
        OneSignalService().login(credential.user!.uid);
        emit(Authenticated(credential.user!));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      _lessonRepository?.clearCache();
      OneSignalService().logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.deleteAccount();
      _lessonRepository?.clearCache();
      OneSignalService().logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
