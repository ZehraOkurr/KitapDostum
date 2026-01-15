import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/reading_provider.dart';
import '../providers/theme_provider.dart'; 
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'reading_timer_screen.dart'; 
import 'shelf_screen.dart'; 
import 'social_feed_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const LibraryScreen(),
    const SocialFeedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final readingProvider = Provider.of<ReadingProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context); 
    
    bool showMiniPlayer = readingProvider.isRunning || readingProvider.secondsElapsed > 0;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    final accentColor = const Color(0xFFC69C82); 

    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? "Kitap Dostu";
    if (displayName.isEmpty) displayName = "Kitap Dostu";
    final email = user?.email ?? "";

    return Scaffold(
      // --- YAN MENÜ (DRAWER) ---
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // 1. HEADER (Profil)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                String currentName = displayName;
                ImageProvider? profileImage;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  if (data['displayName'] != null) currentName = data['displayName'];
                  if (data['profileImage'] != null && data['profileImage'].toString().isNotEmpty) {
                    try {
                      profileImage = MemoryImage(base64Decode(data['profileImage']));
                    } catch (e) {}
                  } else if (user?.photoURL != null) {
                    profileImage = NetworkImage(user!.photoURL!);
                  }
                }

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: accentColor),
                  accountName: Text(currentName, style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, color: Colors.white)),
                  accountEmail: Text(email, style: GoogleFonts.sourceSans3(fontSize: 12, color: Colors.white70)),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: profileImage,
                    child: (profileImage == null) ? Text(currentName.isNotEmpty ? currentName[0].toUpperCase() : "K", style: TextStyle(fontSize: 24, color: accentColor)) : null,
                  ),
                );
              },
            ),

            // 2. MENÜ ÖĞELERİ
            ListTile(
              leading: Icon(Icons.shelves, color: accentColor),
              title: Text('Sanal Rafım', style: GoogleFonts.libreBaskerville()),
              subtitle: Text('Bitirdiğin kitapları gör', style: GoogleFonts.sourceSans3(fontSize: 10, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShelfScreen()));
              },
            ),

            const Divider(),

            // 3. KOMPAKT GECE MODU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: InkWell(
                onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.brown.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text("Gece Modu", style: GoogleFonts.libreBaskerville(fontSize: 14, color: isDark ? Colors.white70 : Colors.brown[800])),
                      const Spacer(),
                      Icon(
                        isDark ? Icons.dark_mode : Icons.wb_sunny,
                        color: isDark ? Colors.purple[200] : Colors.orange,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(), // Boşluğu doldurur ve versiyonu aşağı iter

            // 4. VERSİYON (En altta)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("v1.0.0", style: GoogleFonts.sourceSans3(color: Colors.grey[400], fontSize: 10)),
            ),
          ],
        ),
      ),
      
      appBar: _selectedIndex == 0 
          ? AppBar(
              title: Text("KitapDostum", style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, color: textColor)),
              backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, iconTheme: IconThemeData(color: textColor),
            ) 
          : null,

      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: showMiniPlayer ? 70 : 0), 
            child: _pages[_selectedIndex],
          ),

          if (showMiniPlayer)
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReadingTimerScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2623) : const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: Row(
                    children: [
                      // Timer İkonu (Burada da GIF olsun mu? Yoksa ikon mu kalsın?)
                      // Şu an timer_icon.gif kullanıyor.
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset("assets/images/timer_icon.gif", fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Okuma Süresi", style: GoogleFonts.sourceSans3(color: Colors.white70, fontSize: 11)),
                            Text(readingProvider.timerString, style: GoogleFonts.sourceSans3(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => readingProvider.toggleTimer(),
                        icon: Icon(readingProvider.isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill, color: accentColor, size: 38),
                      ),
                      IconButton(
                        onPressed: () => readingProvider.resetTimer(),
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        indicatorColor: accentColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Keşfet'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Kütüphanem'),
          NavigationDestination(icon: Icon(Icons.rss_feed), selectedIcon: Icon(Icons.rss_feed), label: 'Akış'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}