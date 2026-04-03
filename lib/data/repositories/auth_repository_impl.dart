import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      return _mapUser(event.session?.user);
    });
  }

  @override
  AppUser? get currentUser => _mapUser(_supabase.auth.currentUser);

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
      throw const AuthException('Sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const AuthException('Failed to obtain Google ID token');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  @override
  Future<void> signInWithApple() async {
    // iOS and macOS: use native Apple Sign In to obtain an identity token
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Failed to obtain Apple identity token');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      return;
    }

    // All other platforms (Android, Linux, Windows, Web): use Supabase OAuth redirect
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'io.supabase.goalden://login-callback',
    );
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email);
  }

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}
