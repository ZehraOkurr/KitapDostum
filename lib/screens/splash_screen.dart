import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // AuthWrapper'a erişmek için

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // SÜREYİ UZATTIK: 6 Saniye yaptık
    Timer(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Radyolu GIF'in o sıcak kahve tonu
      backgroundColor: const Color(0xFF6D5636), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GIF'i büyük ve güzel gösteriyoruz
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/splash.gif', // Radyolu GIF
                  width: 350, // Ekranı güzelce doldursun
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Yükleniyor Yazısı
            Text(
              "KitapDostum",
              style: GoogleFonts.libreBaskerville(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEFEBE9), // Açık krem rengi yazı
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(2, 2),
                  )
                ]
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Minik bir yüklenme çubuğu (Opsiyonel ama şık durur)
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                color: Color(0xFFEFEBE9),
                backgroundColor: Colors.black12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}