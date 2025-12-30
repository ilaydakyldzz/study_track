import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Şu anki kullanıcıyı getirir
  User? get currentUser => _auth.currentUser;

  // 1. Kayıt Olma Fonksiyonu (Hem Auth'a hem Firestore'a kaydeder)
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String department,
  }) async {
    try {
      // a. Auth servisine kullanıcıyı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // b. Kullanıcı oluştuysa, detayları Firestore'a 'users' koleksiyonuna kaydet
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'department': department,
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': '', // Başlangıçta boş
        });
      }

      return userCredential.user;
    } catch (e) {
      throw e; // Hatayı ekranda göstermek için fırlatıyoruz
    }
  }

  // 2. Giriş Yapma Fonksiyonu
  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // 3. Çıkış Yapma
  Future<void> signOut() async {
    await _auth.signOut();
  }
}