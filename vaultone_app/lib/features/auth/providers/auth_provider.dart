import 'package:flutter_riverpod/legacy.dart';

import '../../../data/api_exception.dart';
import '../models/request/auth_requests.dart';
import '../repositories/auth_repository.dart';

final authActionProvider =
    StateNotifierProvider<AuthActionNotifier, AuthActionState>((ref) {
      return AuthActionNotifier(ref.watch(authRepositoryProvider));
    });

class AuthActionState {
  const AuthActionState({this.isLoading = false, this.error, this.lastOtp});

  final bool isLoading;
  final String? error;
  final String? lastOtp;
}

class AuthActionNotifier extends StateNotifier<AuthActionState> {
  AuthActionNotifier(this._repository) : super(const AuthActionState());

  final AuthRepository _repository;

  Future<bool> register(RegisterRequest request) {
    return _runWithOtp(() => _repository.register(request));
  }

  Future<bool> login(LoginRequest request) {
    return _run(() => _repository.login(request));
  }

  Future<bool> sendLoginOtp(String email) {
    return _runWithOtp(() => _repository.sendLoginOtp(email));
  }

  Future<bool> forgotPassword(String identity) {
    return _runWithOtp(() => _repository.forgotPassword(identity));
  }

  Future<bool> verifyOtp({
    required String identity,
    required String otp,
    required String purpose,
  }) {
    return _run(
      () =>
          _repository.verifyOtp(identity: identity, otp: otp, purpose: purpose),
    );
  }

  Future<bool> resendOtp({required String identity, required String purpose}) {
    return _runWithOtp(
      () => _repository.resendOtp(identity: identity, purpose: purpose),
    );
  }

  Future<bool> _runWithOtp(Future<String?> Function() action) async {
    if (state.isLoading) return false;
    state = const AuthActionState(isLoading: true);
    try {
      final otp = await action();
      state = AuthActionState(lastOtp: otp);
      return true;
    } catch (error) {
      state = AuthActionState(error: readableApiError(error));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  }) {
    return _run(
      () => _repository.resetPassword(
        identity: identity,
        otp: otp,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    if (state.isLoading) return false;
    state = const AuthActionState(isLoading: true);
    try {
      await action();
      state = const AuthActionState();
      return true;
    } catch (error) {
      state = AuthActionState(error: readableApiError(error));
      return false;
    }
  }
}
