import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart'; // Provider eklendi
import '../models/book.dart';
import '../services/database_service.dart';
import '../providers/reading_provider.dart'; // ReadingProvider eklendi
import 'reading_timer_screen.dart'; // Timer ekranı eklendi

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _noteController = TextEditingController();
  
  // Hızlı Yorum Değişkenleri
  final TextEditingController _inlineCommentController = TextEditingController();
  double _inlineRating = 5.0;

  // --- HIZLI YORUM GÖNDER ---
  void _submitInlineReview() async {
    if (_inlineCommentController.text.isEmpty) return;

    await _dbService.addReview(
      widget.book.id, 
      widget.book.title,
      widget.book.thumbnailUrl,
      _inlineRating, 
      _inlineCommentController.text
    );
    
    _inlineCommentController.clear();
    FocusScope.of(context).unfocus();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorumun gönderildi! 🐻"), backgroundColor: Colors.green),
      );
    }
  }

  // --- BUTONDAN AÇILAN YORUM PENCERESİ ---
  void _showReviewDialog() {
    double rating = 3.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Kitabı Değerlendir", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 3,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rat) { rating = rat; },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Düşüncelerin neler?",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await _dbService.addReview(
                widget.book.id, widget.book.title, widget.book.thumbnailUrl, rating, commentController.text
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorumun paylaşıldı! 🌟"), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
            child: const Text("Paylaş", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- NOT EKLEME PENCERESİ ---
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Özel Not Ekle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Sadece sen görebilirsin...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (_noteController.text.isNotEmpty) {
                await _dbService.addNote(widget.book.id, _noteController.text);
                _noteController.clear();
                if (mounted) { Navigator.pop(context); setState(() {}); }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- BURADA TANIMLIYORUZ Kİ HATA VERMESİN ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        actions: [ IconButton(icon: Icon(Icons.share, color: textColor), onPressed: () {}) ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KİTAP BİLGİSİ ---
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: widget.book.id,
                    child: Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))]),
                      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: widget.book.thumbnailUrl, height: 250, fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(widget.book.title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  Text(widget.book.author, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- BUTONLAR ---
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<bool>(
                    future: _dbService.isBookSaved(widget.book.id),
                    builder: (context, snapshot) {
                      bool isSaved = snapshot.data ?? false;
                      return ElevatedButton.icon(
                        onPressed: isSaved ? null : () async { await _dbService.saveBook(widget.book); if (mounted) setState(() {}); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC69C82),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(isSaved ? Icons.check : Icons.bookmark_border, color: Colors.white),
                        label: Text(isSaved ? "Eklendi" : "Kaydet", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showReviewDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.star, color: Colors.white),
                    label: Text("Puanla", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            // --- OKUMAYA BAŞLA BUTONU ---
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // 1. Kitabı Kaydet
                  _dbService.saveBook(widget.book);
                  
                  // 2. Provider'a Haber Ver
                  final provider = Provider.of<ReadingProvider>(context, listen: false);
                  provider.startReading(widget.book.id);

                  // 3. Sayfaya Git
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const ReadingTimerScreen())
                  );
                },
                // BURADAKİ HATA isDark TANIMLANDIĞI İÇİN ARTIK GİDECEK
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2C2623) : const Color(0xFF3E2723), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: const Color(0xFFC69C82).withOpacity(0.5))
                ),
                icon: const Icon(Icons.timer_outlined, color: Color(0xFFC69C82)),
                label: Text("Şimdi Oku & Süre Tut", style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFFC69C82), fontWeight: FontWeight.bold)),
              ),
            ),
            // -----------------------------

            const SizedBox(height: 30),

            Text("Hakkında", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Text(
              widget.book.description.isNotEmpty ? widget.book.description : "Açıklama yok.",
              style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),

            // --- SEKMELİ YAPI ---
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: const Color(0xFFC69C82),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFFC69C82),
                    tabs: const [ Tab(text: "Yorumlar 💬"), Tab(text: "Notlarım 📝") ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        // 1. SEKME: YORUMLAR
                        Column(
                          children: [
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _dbService.getBookReviews(widget.book.id),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  final reviews = snapshot.data!.docs;
                                  
                                  if (reviews.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text("Henüz yorum yapılmamış.\nİlk yorumu sen yap! 👇", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 20),
                                          _buildInlineReviewInput(context),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: reviews.length,
                                    padding: const EdgeInsets.only(top: 10),
                                    itemBuilder: (context, index) {
                                      final data = reviews[index].data() as Map<String, dynamic>;
                                      return Card(
                                        color: cardColor,
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFFC69C82).withOpacity(0.2),
                                            backgroundImage: data['userImage'] != null ? MemoryImage(base64Decode(data['userImage'])) : null,
                                            child: data['userImage'] == null ? Text(data['userName'][0]) : null,
                                          ),
                                          title: Row(
                                            children: [
                                              Text(data['userName'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                              const Spacer(),
                                              const Icon(Icons.star, size: 14, color: Colors.amber),
                                              Text(" ${data['rating']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          subtitle: Text(data['comment'], style: GoogleFonts.poppins(fontSize: 12)),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // 2. SEKME: NOTLAR
                        Stack(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('library').doc(widget.book.id).collection('notes').orderBy('date', descending: true).snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                final notes = snapshot.data!.docs;
                                if (notes.isEmpty) return Center(child: Text("Özel notun yok.", style: GoogleFonts.poppins(color: Colors.grey)));

                                return ListView.builder(
                                  itemCount: notes.length,
                                  padding: const EdgeInsets.only(top: 10, bottom: 60),
                                  itemBuilder: (context, index) {
                                    var noteData = notes[index].data() as Map<String, dynamic>;
                                    return Card(
                                      color: cardColor,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(noteData['text'], style: GoogleFonts.poppins(fontSize: 13, color: textColor)),
                                        trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey), onPressed: () => _dbService.deleteNote(widget.book.id, notes[index].id)),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: FloatingActionButton.small(onPressed: _showAddNoteDialog, backgroundColor: const Color(0xFFC69C82), child: const Icon(Icons.add, color: Colors.white)),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // HIZLI YORUM WIDGET'I
  Widget _buildInlineReviewInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Puanın:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              RatingBar.builder(
                initialRating: 5,
                minRating: 1,
                itemSize: 20,
                direction: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) { _inlineRating = rating; },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inlineCommentController,
                  decoration: const InputDecoration(
                    hintText: "Buraya yorumunu yaz...",
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _submitInlineReview,
                icon: const Icon(Icons.send, color: Color(0xFFC69C82)),
              )
            ],
          ),
        ],
      ),
    );
  }
}