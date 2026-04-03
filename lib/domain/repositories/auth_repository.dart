import '../models/auth_user.dart';

abstract class AuthRepository {
  /// Stream that emits the current user or null when signed out.
  Stream<AuthUser?> get authStateChanges;

  /// Returns the currently authenticated user, or null.
  AuthUser? get currentUser;

  /// Sign in with Google OAuth.
  Future<void> signInWithGoogle();

  /// Sign in with Apple OAuth.
  Future<void> signInWithApple();

  /// Sign in with email/password. Creates the account if it does not exist.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email/password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign the current user out.
  Future<void> signOut();
}
