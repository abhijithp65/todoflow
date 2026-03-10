import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> signUpWithEmailAndPassword(
      String email, String password, String name);
  Future<UserEntity?> signInWithGoogle();
  Future<void> signOut();
  Future<String?> getIdToken();
  UserEntity? get currentUser;
}
