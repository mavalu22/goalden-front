/// Domain model for an authenticated user.
/// Keeps the domain layer free of Supabase types.
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.authProvider = AuthProvider.email,
  });

  final String id;
  final String? email;
  final String? displayName;

  /// The identity provider used to sign in.
  final AuthProvider authProvider;
}

enum AuthProvider { email, google, apple, unknown }
