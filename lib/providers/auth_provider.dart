import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
  }) : _authService = authService {
    _authSubscription =
        _authService.authStateChanges().listen(
          _handleAuthStateChanged,
          onError: _handleAuthStateError,
        );
  }

  final AuthService _authService;

  StreamSubscription<AuthUser?>?
  _authSubscription;

  final Completer<void> _readyCompleter =
  Completer<void>();

  bool _isLoading = false;
  bool _isSignedIn = false;
  bool _isAuthReady = false;

  String? _errorMessage;
  String? _successMessage;

  String? _userId;
  String? _userEmail;
  String? _displayName;

  bool get isLoading => _isLoading;
  bool get isSignedIn => _isSignedIn;
  bool get isAuthReady => _isAuthReady;

  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get displayName => _displayName;

  Future<void> waitUntilReady() async {
    if (_isAuthReady) {
      return;
    }

    await _readyCompleter.future;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _beginRequest();

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );

      _applyUser(_authService.currentUser);

      _successMessage =
      'Signed in successfully.';

      _finishRequest();
      return true;
    } catch (error) {
      _handleRequestError(error);
      return false;
    }
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _beginRequest();

    try {
      await _authService.register(
        displayName: displayName,
        email: email,
        password: password,
      );

      _applyUser(_authService.currentUser);

      _successMessage =
      'Your Aurora account was created successfully.';

      _finishRequest();
      return true;
    } catch (error) {
      _handleRequestError(error);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({
    required String email,
  }) async {
    _beginRequest();

    try {
      await _authService.sendPasswordResetEmail(
        email: email,
      );

      _successMessage =
      'Password reset instructions were sent '
          'to ${email.trim()}.';

      _finishRequest();
      return true;
    } catch (error) {
      _handleRequestError(error);
      return false;
    }
  }

  Future<void> signOut() async {
    _beginRequest();

    try {
      await _authService.signOut();
      _applyUser(null);
    } catch (error) {
      _handleRequestError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handleAuthStateChanged(
      AuthUser? user,
      ) {
    _applyUser(user);
    _markAuthReady();
  }

  void _handleAuthStateError(
      Object error,
      ) {
    _errorMessage = _cleanError(error);
    _applyUser(null);
    _markAuthReady();
  }

  void _applyUser(AuthUser? user) {
    _isSignedIn = user != null;

    _userId = user?.uid;
    _userEmail = user?.email;
    _displayName = user?.displayName;

    notifyListeners();
  }

  void _markAuthReady() {
    if (_isAuthReady) {
      return;
    }

    _isAuthReady = true;

    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }

    notifyListeners();
  }

  void _beginRequest() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _finishRequest() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleRequestError(
      Object error,
      ) {
    _isLoading = false;
    _errorMessage = _cleanError(error);
    _successMessage = null;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}