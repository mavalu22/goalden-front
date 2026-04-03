import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  Stream<AuthUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      return _mapUser(event.session?.user);
    });
  }

  @override
  AuthUser? get currentUser => _mapUser(_supabase.auth.currentUser);

  @override
  Future<void> signInWithGoogle() async {
    // Desktop / Web: use Supabase OAuth redirect flow
    if (kIsWeb || _isDesktop) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.goalden://login-callback',
      );
      return;
    }

    // Mobile (iOS / Android): use google_sign_in to get ID token
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in flow
      throw AuthException('Sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthException('Failed to obtain Google ID token');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  @override
  Future<void> signInWithApple() => throw UnimplementedError('Implemented in TASK-007');

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError('Implemented in TASK-008');

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError('Implemented in TASK-008');

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError('Implemented in TASK-008');

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email);
  }

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}
