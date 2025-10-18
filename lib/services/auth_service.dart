import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async =>
      await _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential?> signUp(String email, String password) async =>
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

  Future<void> signOut() async => await _auth.signOut();
}