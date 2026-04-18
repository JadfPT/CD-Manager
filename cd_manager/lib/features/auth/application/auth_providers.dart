import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../shared/repositories/auth_repository.dart';
import 'auth_repository_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

final sessionProvider = StreamProvider<AuthState>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);

  final currentUser = repository.currentUser;
  yield currentUser == null
      ? const AuthInitial()
      : AuthSuccess(user: currentUser);

  yield* repository.sessionChanges().map((_) {
    final user = repository.currentUser;
    return user == null ? const AuthInitial() : AuthSuccess(user: user);
  });
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthInitial()) {
    _checkSession();
  }

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<void> _checkSession() async {
    final user = _repository.currentUser;

    if (user != null) {
      state = AuthSuccess(user: user);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      final response = await _repository.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user != null) {
        state = AuthSuccess(user: user);
      }
    } on ArgumentError {
      try {
        await _repository.signOut();
      } catch (_) {}

      try {
        final retryResponse = await _repository.signInWithPassword(
          email: email,
          password: password,
        );

        final retryUser = retryResponse.user;
        if (retryUser != null) {
          state = AuthSuccess(user: retryUser);
          return;
        }
      } on AuthException catch (e) {
        state = AuthError(message: e.message);
        return;
      } catch (e) {
        state = AuthError(message: e.toString());
        return;
      }

      state = const AuthError(
        message: 'Não foi possível iniciar sessão. Tenta novamente.',
      );
    } on AppException catch (e) {
      state = AuthError(message: e.message);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      final response = await _repository.signUpWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        state = AuthSuccess(user: user);
      }
    } on AppException catch (e) {
      state = AuthError(message: e.message);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();

    try {
      await _repository.signOut();
      state = const AuthInitial();
    } on AppException catch (e) {
      state = AuthError(message: e.message);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthInitial();
    }
  }
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});
}
