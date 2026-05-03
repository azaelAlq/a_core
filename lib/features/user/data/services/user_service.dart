import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/user/data/models/user_model.dart';
import 'package:a_core/features/user/domain/entities/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');

  Future<void> createUser(AppUser user) async {
    final model = UserModel.fromEntity(user);
    await _users.doc(user.uid).set(model.toFirestore());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateModules(String uid, List<String> modules) async {
    await _users.doc(uid).update({'modules': modules});
  }

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
