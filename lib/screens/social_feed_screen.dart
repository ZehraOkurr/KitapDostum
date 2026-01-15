import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import 'leaderboard_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String? myUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Sosyal Akış", style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Arkadaş Listesini Çek
        stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('friends').snapshots(),
        builder: (context, friendSnapshot) {
          if (friendSnapshot.hasError) {
             return Center(child: Text("Arkadaş listesi hatası: ${friendSnapshot.error}"));
          }
          if (friendSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }
          
          final friends = friendSnapshot.data?.docs ?? [];
          
          // Kendimizi de listeye ekleyelim
          List<String> activityUserIds = friends.map((doc) => doc.id).toList();
          if (myUid != null) {
            activityUserIds.add(myUid!); 
          }

          // 2. Aktivite Sorgusu
          return StreamBuilder<QuerySnapshot>(
            stream: _dbService.getFriendActivities(activityUserIds),
            builder: (context, feedSnapshot) {
              
              // --- İŞTE BURASI: HATAYI YAKALIYORUZ ---
              if (feedSnapshot.hasError) {
                // Eğer hata varsa konsola ve ekrana basıyoruz
                print("AKIS HATASI: ${feedSnapshot.error}");
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 50, color: Colors.red),
                        const SizedBox(height: 10),
                        const Text("Veritabanı İndeks Hatası!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 10),
                        Text(
                          "Lütfen aşağıdaki 'Run' (Çıktı) penceresindeki linke tıkla:\n\n${feedSnapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // ----------------------------------------

              if (feedSnapshot.connectionState == ConnectionState.waiting) {
                 return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
              }

              final activities = feedSnapshot.data?.docs ?? [];

              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories, size: 60, color: Colors.grey.withOpacity(0.3)),
                      const SizedBox(height: 10),
                      Text("Akışın çok sessiz... 🍃", style: GoogleFonts.sourceSans3(color: textColor, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text("Bir kitap oku veya not ekle!", style: GoogleFonts.sourceSans3(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final data = activities[index].data() as Map<String, dynamic>;
                  return _buildActivityCard(context, data, isDark);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Kart tasarımı aynı kalacak
  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> data, bool isDark) {
    String actionText = "";
    IconData actionIcon = Icons.info;
    Color iconColor = Colors.grey;

    if (data['type'] == 'start_book') {
      actionText = "okumaya başladı";
      actionIcon = Icons.book;
      iconColor = Colors.blueAccent;
    } else if (data['type'] == 'review_book') {
      actionText = "bir kitap değerlendirdi";
      actionIcon = Icons.star;
      iconColor = Colors.amber;
    } else if (data['type'] == 'finish_book') {
      actionText = "kitabı bitirdi 🏆";
      actionIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (data['type'] == 'add_note') {
      actionText = "bir not paylaştı 📝";
      actionIcon = Icons.edit_note;
      iconColor = const Color(0xFFC69C82);
    }

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFC69C82).withOpacity(0.2),
                  backgroundImage: data['userImage'] != null 
                      ? MemoryImage(base64Decode(data['userImage'])) 
                      : null,
                  child: data['userImage'] == null ? Text(data['userName'][0]) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.sourceSans3(color: isDark ? Colors.white : Colors.black),
                      children: [
                        TextSpan(text: data['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: " $actionText", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                Icon(actionIcon, size: 20, color: iconColor),
              ],
            ),
            const SizedBox(height: 12),
            if (data['bookTitle'] != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildBookImage(data['bookImage']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['bookTitle'] ?? "Kitap", style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (data['content'] != null && data['content'].toString().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            '"${data['content']}"', 
                            style: GoogleFonts.sourceSans3(fontStyle: FontStyle.italic, fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (data['rating'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (data['rating'] as num).round() ? Icons.star : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage(String? url) {
    if (url == null || url.isEmpty) return Container(width: 50, height: 75, color: Colors.grey);
    try {
      if (!url.startsWith('http')) {
        return Image.memory(base64Decode(url), width: 50, height: 75, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(width: 50, height: 75, color: Colors.grey));
      } else {
        return CachedNetworkImage(imageUrl: url, width: 50, height: 75, fit: BoxFit.cover,
          errorWidget: (context, url, error) => Container(width: 50, height: 75, color: Colors.grey));
      }
    } catch (e) {
      return Container(width: 50, height: 75, color: Colors.grey);
    }
  }
}