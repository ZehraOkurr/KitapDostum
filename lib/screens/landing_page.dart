import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart'; // Birazdan oluşturacağız
import 'main_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase'in kapıdaki nöbetçisi: Giriş-Çıkışları dinler
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Durum: Bağlantı bekleniyor (Yükleniyor...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Durum: Veri geldi mi? (Kullanıcı var mı?)
        if (snapshot.hasData) {
          // Evet, kullanıcı giriş yapmış -> Ana Sayfaya git!
         return const MainScreen();
        }

        // 3. Durum: Kullanıcı yok -> Hoşgeldin (Login/Register) ekranına git!
        return const WelcomeScreen();
      },
    );
  }
}