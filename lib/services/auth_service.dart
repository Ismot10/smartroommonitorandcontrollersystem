import '../models/auth_user.dart';

abstract interface class AuthService {
  /// Emits the signed-in user or null when signed out.
  Stream<AuthUser?> authStateChanges();

  /// Returns the current authenticated user when available.
  AuthUser? get currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<void> signOut();
}