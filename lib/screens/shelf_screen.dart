import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';

class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Duvar rengi (Krem veya Koyu Kahve)
    final wallColor = isDark ? const Color(0xFF261C19) : const Color(0xFFF9F7F2);
    
    // Raf Tahtası Rengi (Daha koyu bir şerit)
    final shelfColor = isDark ? const Color(0xFF4E342E) : const Color(0xFFD7CCC8);
    
    // Rafın Gölgesi (Gece modunda daha koyu, gündüz daha yumuşak)
    final shelfShadowColor = isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.2);

    return Scaffold(
      backgroundColor: wallColor,
      appBar: AppBar(
        // Başlık yazı tipi güncellendi
        title: Text("Kütüphanem", style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('library')
            .where('status', isEqualTo: 'finished')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shelves, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text("Rafın boş duruyor...", style: GoogleFonts.libreBaskerville(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text("Okuduğun kitaplar burada sergilenecek.", style: GoogleFonts.sourceSans3(color: Colors.grey)),
                ],
              ),
            );
          }

          // GridView Ayarları
          return GridView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Bir rafta 3 kitap
              childAspectRatio: 0.55, // Raf yüksekliği oranı
              crossAxisSpacing: 10, 
              mainAxisSpacing: 0, // Rafları birbirine yapıştırıyoruz
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              Book book = Book.fromMap(data, docs[index].id);

              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)));
                },
                child: Container(
                  // Her bir hücre bir "Raf Bölmesi" gibi davranacak
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: shelfColor, width: 12), // İşte RAF TAHTASI burası!
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end, // Kitapları dibe (rafa) yasla
                    children: [
                      // KİTAP GÖRSELİ
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8), 
                          decoration: BoxDecoration(
                            boxShadow: [
                              // 1. DÜZELTME: shelfShadowColor değişkenini BURADA kullandık
                              // Kitabın arkasına gölge (Derinlik hissi)
                              BoxShadow(
                                color: shelfShadowColor, 
                                offset: const Offset(4, 0), // Sağ tarafa gölge
                                blurRadius: 4,
                              ),
                              // Kitabın altına hafif gölge (Rafa otursun)
                              BoxShadow(
                                color: shelfShadowColor,
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2), 
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                              bottomLeft: Radius.circular(2),
                            ),
                            child: data['thumbnailUrl'] != null && data['thumbnailUrl'].toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: data['thumbnailUrl'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[300]),
                                    errorWidget: (context, url, error) => Container(color: const Color(0xFF8D6E63), child: const Center(child: Text("?", style: TextStyle(color: Colors.white)))),
                                  )
                                : Container(color: const Color(0xFF8D6E63)),
                          ),
                        ),
                      ),
                      
                      // Kitap ile raf arasındaki milimetrik boşluk
                      const SizedBox(height: 1), 
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}