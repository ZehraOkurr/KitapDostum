import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Şifre sıfırlama için gerekli
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Kutulara yazılanları okumak için araçlar (Controller)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false; // Yükleniyor dönmesi için

  // --- GİRİŞ YAPMA FONKSİYONU ---
  void _login() async {
    // 1. Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    // 2. Servise git
    String? error = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // EĞER SAYFA KAPANDIYSA İŞLEM YAPMA
    if (!mounted) return;

    // 3. Yükleniyor'u durdur
    setState(() => _isLoading = false);

    if (error != null) {
      // Hata varsa göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error), // Hata mesajını direkt gösteriyoruz
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Hata yoksa başarılıdır, sayfayı kapat (Giriş yapıldı)
      Navigator.pop(context);
    }
  }

  // --- YENİ EKLENEN: ŞİFRE SIFIRLAMA PENCERESİ ---
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    
    // Eğer ana ekranda e-posta yazılıysa, kolaylık olsun diye buraya kopyala
    if (_emailController.text.isNotEmpty) {
      resetEmailController.text = _emailController.text;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Şifre Sıfırla", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("E-posta adresini gir, sana sıfırlama linki gönderelim."),
            const SizedBox(height: 20),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: "E-posta",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lütfen e-posta adresini gir.")),
                );
                return;
              }

              try {
                // Firebase'in sihirli fonksiyonu
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                
                if (mounted) {
                  Navigator.pop(context); // Pencereyi kapat
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sıfırlama maili gönderildi! 📩 Lütfen kutunu kontrol et."), 
                      backgroundColor: Colors.green
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
            child: const Text("Gönder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Giriş Yap", style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView( // Klavye açılınca taşmasın diye eklendi
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Üstten biraz boşluk
              // LOGO veya İKON
              const Icon(Icons.lock_open_rounded, size: 80, color: Color(0xFFC69C82)),
              const SizedBox(height: 40),

              // E-POSTA KUTUSU
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // ŞİFRE KUTUSU
              TextField(
                controller: _passwordController,
                obscureText: true, // Şifreyi gizle
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.key_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              
              // --- ŞİFREMİ UNUTTUM BUTONU (Sağa Yaslı) ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    "Şifremi Unuttum?",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFC69C82), 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // GİRİŞ BUTONU
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login, // Yüklenirken tıklanmasın
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC69C82),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text("Giriş Yap", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}