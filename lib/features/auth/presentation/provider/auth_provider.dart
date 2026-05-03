import 'dart:async';
import 'package:flutter/material.dart';
import 'package:a_core/features/auth/data/services/auth_service.dart';
import 'package:a_core/features/user/domain/entities/app_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  StreamSubscription<AppUser?>? _authSub;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = _authService.authStateChanges.listen((user) {
      _user = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      _user = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      _setError(_parseError(e));
    }
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading();
    try {
      _user = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      _setError(_parseError(e));
    }
    notifyListeners();
  }

  Future<void> sendPasswordReset({required String email}) async {
    _setLoading();
    try {
      await _authService.sendPasswordReset(email: email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _setError(_parseError(e));
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'Este correo ya está registrado.';
    }
    if (msg.contains('weak-password')) {
      return 'La contraseña es muy débil.';
    }
    if (msg.contains('invalid-email')) {
      return 'Correo electrónico inválido.';
    }
    if (msg.contains('network-request-failed')) {
      return 'Sin conexión a internet.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
