import 'package:flutter/foundation.dart';
import '../../domain/models/user.dart';
import '../../data/repositories/auth_repository_impl.dart';

enum LoginResult {
  success,
  invalidCredentials,
  needs2FA,
}

/// Provider for authentication state
class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isSpecialist => _currentUser?.role == UserRole.specialist;
  bool get isClient => _currentUser?.role == UserRole.client;

  Future<void> initialize() async {
    await _authRepository.initialize();
    // Check for saved session (could use SharedPreferences in production)
    notifyListeners();
  }

  Future<LoginResult> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.login(email, password);
      if (user != null) {
        if (user.isTwoFactorEnabled) {
          _isLoading = false;
          notifyListeners();
          return LoginResult.needs2FA;
        } else {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return LoginResult.success;
        }
      }
      _isLoading = false;
      notifyListeners();
      return LoginResult.invalidCredentials;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return LoginResult.invalidCredentials;
    }
  }

  void completeLogin(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> toggleTwoFactor(bool enable) async {
    if (_currentUser?.id != null) {
      final success = await _authRepository.updateTwoFactorSetting(_currentUser!.id!, enable);
      if (success > 0) {
        _currentUser = _currentUser!.copyWith(isTwoFactorEnabled: enable);
        notifyListeners();
      }
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.registerUser(
        email: email,
        password: password,
        role: role,
        name: name,
        phone: phone,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser?.id != null) {
      final user = await _authRepository.getUserById(_currentUser!.id!);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }
}

