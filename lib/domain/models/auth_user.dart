/// Domain model for an authenticated user.
/// Keeps the domain layer free of Supabase types.
class AuthUser {
  const AuthUser({required this.id, this.email});

  final String id;
  final String? email;
}
