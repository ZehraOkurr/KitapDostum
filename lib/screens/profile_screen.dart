import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'statistics_screen.dart';
import 'reading_timer_screen.dart';
import 'friends_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _base64Image;
  String? _friendCode; 
  List<dynamic> _myBadges = []; // Kazanılan rozetlerin listesi

  @override
  void initState() {
    super.initState();
    _loadProfileData(); 
  }

  String _generateFriendCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Veriyi anlık dinleyelim (Rozet kazanınca hemen güncellensin)
    _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _base64Image = doc.data()!['profileImage'];
            _friendCode = doc.data()!['friendCode'];
            _myBadges = doc.data()!['badges'] ?? []; // Rozetleri çek
          });
        }
        
        // Kod yoksa oluştur
        if (doc.data()!['friendCode'] == null) {
           _createCode(user);
        }
      }
    });
  }

  Future<void> _createCode(User user) async {
      String newCode = _generateFriendCode();
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName ?? user.email!.split('@')[0],
        'uid': user.uid,
        'friendCode': newCode,
      }, SetOptions(merge: true));
  }

  void _copyCodeToClipboard() {
    if (_friendCode != null) {
      Clipboard.setData(ClipboardData(text: _friendCode!));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kopyalandı! 📋"), backgroundColor: Colors.green));
    }
  }

  void _pickAndSaveImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final String base64String = base64Encode(bytes);
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({'profileImage': base64String}, SetOptions(merge: true));
      }
    }
  }

  void _showEditNameDialog() {
    final user = _auth.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, 
        title: Text("İsmini Değiştir", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Yeni Görünen Ad", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && user != null) {
                await user.updateDisplayName(nameController.text);
                await _firestore.collection('users').doc(user.uid).update({'displayName': nameController.text});
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ROZET VERİLERİ ---
  final List<Map<String, dynamic>> allBadges = [
    {'id': 'first_step', 'name': 'İlk Adım', 'icon': Icons.directions_walk, 'desc': 'İlk kitabını bitirdin!'},
    {'id': 'night_owl', 'name': 'Gece Kuşu', 'icon': Icons.nightlight_round, 'desc': 'Gece 00:00 - 06:00 arası okuma yaptın.'},
    {'id': 'scholar', 'name': 'Araştırmacı', 'icon': Icons.edit_note, 'desc': 'Bir kitaba ilk notunu aldın.'},
    {'id': 'book_worm', 'name': 'Kitap Kurdu', 'icon': Icons.auto_stories, 'desc': '5 kitap bitirdin!'},
    {'id': 'library_king', 'name': 'Kütüphane Kralı', 'icon': Icons.castle, 'desc': '10 kitap bitirdin!'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? "Misafir";
    final name = (user?.displayName != null && user!.displayName!.isNotEmpty) ? user.displayName! : email.split('@')[0];
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    final cardColor = isDark ? const Color(0xFF2C2623) : Colors.grey[100];
    final cardBorderColor = isDark ? const Color(0xFF3E3E3E) : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // PROFİL FOTOĞRAFI
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC69C82).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC69C82), width: 2),
                      image: _base64Image != null
                          ? DecorationImage(image: MemoryImage(base64Decode(_base64Image!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _base64Image == null ? const Icon(Icons.person, size: 60, color: Color(0xFFC69C82)) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _pickAndSaveImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFC69C82), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: _showEditNameDialog,
                ),
              ],
            ),
            Text(email, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            // ARKADAŞ KODU KARTI
            GestureDetector(
              onTap: _copyCodeToClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorderColor)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      _friendCode ?? "...",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 2.0),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // --- YENİ BÖLÜM: BAŞARIMLAR / ROZETLER ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Rozetlerim & Başarımlar 🏅", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            ),
            const SizedBox(height: 10),
            
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allBadges.length,
                itemBuilder: (context, index) {
                  final badge = allBadges[index];
                  final isUnlocked = _myBadges.contains(badge['id']);
                  
                  return Tooltip(
                    message: isUnlocked ? "${badge['name']}\n${badge['desc']}" : "Kilitli: ${badge['desc']}",
                    triggerMode: TooltipTriggerMode.tap, // Dokununca bilgi versin
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isUnlocked ? const Color(0xFFC69C82).withOpacity(0.1) : cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isUnlocked ? const Color(0xFFC69C82) : Colors.transparent,
                          width: 2
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            badge['icon'], 
                            size: 32, 
                            color: isUnlocked ? Colors.amber : Colors.grey[400]
                          ),
                          const SizedBox(height: 5),
                          Text(
                            badge['name'], 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10, 
                              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                              color: isUnlocked ? textColor : Colors.grey
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // LİSTE ELEMANLARI
            _buildProfileItem(Icons.people, "Arkadaşlarım & Arkadaş Ekle", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen()));
            }, textColor),

            _buildProfileItem(Icons.bar_chart, "İstatistikler & Hedefler", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()));
            }, textColor),
            
            _buildProfileItem(Icons.timer, "Okuma Zamanlayıcısı", () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const ReadingTimerScreen()));
            }, textColor),
            
            const SizedBox(height: 40), 

            // Çıkış Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async { await AuthService().signOut(); },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text("Çıkış Yap", style: GoogleFonts.poppins(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String text, VoidCallback onTap, Color textColor) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFC69C82)),
      title: Text(text, style: GoogleFonts.poppins(color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}