import 'package:a_core/features/user/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({required String email, required String password, String? displayName});
  Future<void> signOut();
  Future<void> sendPasswordReset({required String email});
  Stream<AppUser?> get authStateChanges;
}
