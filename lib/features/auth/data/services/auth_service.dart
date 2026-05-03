import 'package:firebase_auth/firebase_auth.dart';
import 'package:a_core/features/auth/domain/repositories/auth_repository.dart';
import 'package:a_core/features/user/data/services/user_service.dart';
import 'package:a_core/features/user/domain/entities/app_user.dart';

class AuthService implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _userService.getUser(firebaseUser.uid);
    });
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = await _userService.getUser(cred.user!.uid);
    if (user == null) throw Exception('Usuario no encontrado en Firestore');
    return user;
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

    final newUser = AppUser(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
      modules: [],
      createdAt: DateTime.now(),
    );

    await _userService.createUser(newUser);
    return newUser;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);
}
