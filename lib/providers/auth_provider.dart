import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../domain/models/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Provides the Supabase client singleton.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Streams the current [AuthUser], or null when signed out.
final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// Exposes sign-in/sign-out actions with loading and error state.
final authActionsProvider =
    AsyncNotifierProvider<AuthActionsNotifier, void>(AuthActionsNotifier.new);

class AuthActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}
