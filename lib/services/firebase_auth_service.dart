import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth =
      firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
      _mapFirebaseUser,
    );
  }

  @override
  AuthUser? get currentUser {
    return _mapFirebaseUser(
      _firebaseAuth.currentUser,
    );
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw Exception(
        'Unable to sign in. Please try again.',
      );
    }
  }

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential =
      await _firebaseAuth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          'The account was created, but the user '
              'profile could not be loaded.',
        );
      }

      await user.updateDisplayName(
        displayName.trim(),
      );

      // Reload so currentUser contains the new name.
      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _messageForCode(error.code),
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to create your account. '
            'Please try again.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw Exception(
        'Unable to send password reset instructions.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw Exception(
        _messageForCode(error.code),
      );
    } catch (_) {
      throw Exception(
        'Unable to sign out. Please try again.',
      );
    }
  }

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'email-already-in-use':
        return 'An account already exists for this email.';

      case 'weak-password':
        return 'Choose a stronger password.';

      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled.';

      case 'too-many-requests':
        return 'Too many attempts were made. '
            'Please wait and try again.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      case 'requires-recent-login':
        return 'Please sign in again before continuing.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}