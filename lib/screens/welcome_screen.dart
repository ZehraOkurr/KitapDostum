import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // Giriş ekranı
import 'register_screen.dart'; // Kayıt ekranı

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. KATMAN: Dalgalı Arka Plan
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              color: const Color(0xFFC69C82), // Senin Kahve Tonun
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 100, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      "KitapDostum",
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 2. KATMAN: Alt Kısımdaki Butonlar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.35,
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Okuma yolculuğuna başla...",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  
                  // GİRİŞ YAP BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                     onPressed: () {
                     Navigator.push(
                     context,
                   MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                     },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC69C82),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text("Giriş Yap", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // KAYIT OL BUTONU
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                     onPressed: () {
                     Navigator.push(
                    context,
                     MaterialPageRoute(builder: (context) => const RegisterScreen()),
                   );
                     },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC69C82), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text("Kayıt Ol", style: GoogleFonts.poppins(fontSize: 18, color: const Color(0xFFC69C82))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// O meşhur dalga şeklini çizen kod
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.8);
    
    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.6);
    var secondEndPoint = Offset(size.width, size.height * 0.8);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}