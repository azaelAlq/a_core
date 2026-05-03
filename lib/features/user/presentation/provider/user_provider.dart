import 'dart:async';
import 'package:flutter/material.dart';
import 'package:a_core/features/user/data/services/user_service.dart';
import 'package:a_core/features/user/domain/entities/app_user.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  AppUser? _user;
  StreamSubscription<AppUser?>? _userSub;

  AppUser? get user => _user;

  void watchUser(String uid) {
    _userSub?.cancel();
    _userSub = _userService.watchUser(uid).listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> addModule(String moduleName) async {
    if (_user == null) return;
    final updated = List<String>.from(_user!.modules)..add(moduleName);
    await _userService.updateModules(_user!.uid, updated);
  }

  Future<void> removeModule(String moduleName) async {
    if (_user == null) return;
    final updated = List<String>.from(_user!.modules)..remove(moduleName);
    await _userService.updateModules(_user!.uid, updated);
  }

  void stopWatching() {
    _userSub?.cancel();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
