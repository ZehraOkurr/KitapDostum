import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mevcut ismi kutuya doldur
    _nameController.text = _auth.currentUser?.displayName ?? "";
  }

  // 1. İsim Güncelleme Fonksiyonu
  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) return;

    try {
      await _auth.currentUser?.updateDisplayName(_nameController.text.trim());
      await _auth.currentUser?.reload(); // Kullanıcıyı yenile
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("İsim güncellendi! (Görmek için çıkıp girmen gerekebilir)"), backgroundColor: Colors.green),
        );
        FocusScope.of(context).unfocus(); // Klavyeyi kapat
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // 2. Şifre Sıfırlama E-postası Gönder
  Future<void> _resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: email);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("E-posta Gönderildi"),
              content: Text("$email adresine şifre sıfırlama linki gönderdik. Lütfen kutunu kontrol et."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam"))
              ],
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ayarlar", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          Text("Hesap Ayarları", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFC69C82))),
          const SizedBox(height: 20),

          // İSİM DEĞİŞTİRME ALANI
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Görünen İsim",
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save, color: Color(0xFFC69C82)),
                onPressed: _updateName, // Kaydet butonu
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text("İsmini değiştirdikten sonra yandaki kaydet ikonuna bas.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),

          // ŞİFRE DEĞİŞTİRME BUTONU
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_reset, color: Colors.orange),
            ),
            title: Text("Şifremi Sıfırla", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text("E-postana sıfırlama linki gönderir.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: _resetPassword,
          ),

          const SizedBox(height: 20),

          // HAKKINDA BUTONU
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.info_outline, color: Colors.blue),
            ),
            title: Text("Hakkında", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text("Versiyon 1.0.0", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "KitapDostum",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.menu_book, size: 50, color: Color(0xFFC69C82)),
                children: [
                  const Text("Bu uygulama Flutter ile geliştirilmiştir. Kitaplarınızı takip etmenizi sağlar."),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}