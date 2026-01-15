import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Giriş Yap (GÜNCELLENDİ)
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Bir Firebase hatası oluştu.";
    } catch (e) {
      // BURASI YENİ: Firebase dışındaki hataları da yakala!
      return "Bilinmeyen hata: $e";
    }
  }

  // 2. Kayıt Ol (GÜNCELLENDİ)
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Bir Firebase hatası oluştu.";
    } catch (e) {
      return "Bilinmeyen hata: $e";
    }
  }

  // 3. Çıkış Yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Kullanıcı bilgisini getir
  String? get loggedUser => _auth.currentUser?.email;
}