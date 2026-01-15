import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final String? myUid = FirebaseAuth.instance.currentUser?.uid;

  // Sıralama verisini çek
  Stream<List<Map<String, dynamic>>> _getLeaderboardData() {
    final now = DateTime.now();
    final currentMonthKey = "${now.year}-${now.month}"; 

    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
      List<Map<String, dynamic>> leaderboard = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final uid = doc.id;

        // Veritabanındaki ayı kontrol et.
        // Eğer kullanıcı bu ay hiç okumadıysa veritabanında eski ay kalmış olabilir.
        // Bu durumda süresini 0 saymalıyız.
        String lastMonth = data['lastReadingMonth'] ?? "";
        int totalSeconds = 0;

        if (lastMonth == currentMonthKey) {
          totalSeconds = data['monthlyReadingSeconds'] ?? 0;
        }

        // Saniyeyi Saate çevir (Örn: 1.5 saat)
        double hours = totalSeconds / 3600;

        leaderboard.add({
          'uid': uid,
          'name': data['displayName'] ?? 'İsimsiz',
          'image': data['profileImage'],
          'hours': hours, // Sıralama kriterimiz artık bu
          'isMe': uid == myUid,
        });
      }

      // Saate göre Büyükten Küçüğe sırala
      leaderboard.sort((a, b) => b['hours'].compareTo(a['hours']));

      return leaderboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Bu Ayın Liderleri 🏆", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getLeaderboardData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final users = snapshot.data!;
          
          // Eğer kimse okumamışsa
          if (users.every((u) => u['hours'] == 0)) {
             return Center(child: Text("Bu ay henüz kimse okuma yapmadı.\nLider sen ol! 🚀", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey)));
          }

          return Column(
            children: [
              // --- İLK 3 KÜRSÜSÜ ---
              if (users.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (users.length > 1) _buildPodium(users[1], 2, 90, Colors.grey[400]!),
                      _buildPodium(users[0], 1, 110, Colors.amber),
                      if (users.length > 2) _buildPodium(users[2], 3, 70, const Color(0xFFCD7F32)),
                    ],
                  ),
                ),

              const Divider(),

              // --- DİĞERLERİ LİSTESİ ---
              Expanded(
                child: ListView.builder(
                  itemCount: users.length > 3 ? users.length - 3 : 0,
                  itemBuilder: (context, index) {
                    final user = users[index + 3];
                    final rank = index + 4;
                    // Eğer süresi 0 ise göstermeyebiliriz veya sonda gösterebiliriz.
                    if (user['hours'] == 0) return const SizedBox();

                    return Card(
                      color: user['isMe'] ? const Color(0xFFC69C82).withOpacity(0.2) : cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Text("$rank.", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black54)),
                        ),
                        title: Text(user['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                        trailing: Text(
                          "${user['hours'].toStringAsFixed(1)} Saat",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFC69C82)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(Map<String, dynamic> user, int rank, double size, Color color) {
    // Eğer süre 0 ise kürsüde gösterme (veya boş göster)
    if (user['hours'] == 0) return SizedBox(width: size);

    return Column(
      children: [
        CircleAvatar(
          radius: rank == 1 ? 35 : 25,
          backgroundColor: color.withOpacity(0.5),
          backgroundImage: user['image'] != null ? MemoryImage(base64Decode(user['image'])) : null,
          child: user['image'] == null ? Text(user['name'][0], style: const TextStyle(fontWeight: FontWeight.bold)) : null,
        ),
        const SizedBox(height: 5),
        Text(user['name'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(
           "${user['hours'].toStringAsFixed(1)} sa",
           style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Container(
          width: size - 20,
          height: rank == 1 ? 100 : (rank == 2 ? 70 : 50),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
          ),
          child: Center(
            child: Text(
              "$rank", 
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ),
        ),
      ],
    );
  }
}