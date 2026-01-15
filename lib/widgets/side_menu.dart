import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; 
import '../providers/theme_provider.dart'; 
import '../services/auth_service.dart';
import '../screens/friends_screen.dart';
import '../screens/social_feed_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : user?.email?.split('@')[0] ?? "Misafir";
    final email = user?.email ?? "";
    
    // Tema Durumunu Al
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Drawer(
      // Dark Mode'da çekmece rengi de değişsin
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFC69C82)),
            accountName: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            accountEmail: Text(email, style: GoogleFonts.poppins()),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Arka plana uyumlu olsun
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "M",
                style: GoogleFonts.poppins(fontSize: 24, color: const Color(0xFFC69C82), fontWeight: FontWeight.bold),
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.people_outline, color: Theme.of(context).iconTheme.color),
            title: Text("Arkadaşlarım", style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen()));
            },
          ),
          
          ListTile(
            leading: Icon(Icons.dynamic_feed, color: Theme.of(context).iconTheme.color),
            title: Text("Sosyal Akış", style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialFeedScreen()));
            },
          ),
          
          const Divider(),

          // --- YENİ: GECE MODU ANAHTARI ---
          SwitchListTile(
            title: Text("Gece Modu", style: GoogleFonts.poppins()),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).iconTheme.color
            ),
            value: themeProvider.isDarkMode,
            activeColor: const Color(0xFFC69C82),
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
          ),
          // -------------------------------

          const Spacer(),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text("Çıkış Yap", style: GoogleFonts.poppins(color: Colors.red)),
            onTap: () async {
              await AuthService().signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}