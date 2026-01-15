import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart'; 
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/database_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = "Tümü"; 

  void _showUpdateDialog(Book book) {
    final controller = TextEditingController(text: book.currentPage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("İlerlemeyi Güncelle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(book.title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Şu an kaçıncı sayfadasın?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: "/ ${book.pageCount}",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              int newPage = int.tryParse(controller.text) ?? book.currentPage;
              if (newPage > book.pageCount) newPage = book.pageCount; 
              _dbService.updateProgress(book.id, newPage); 
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String bookId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Kitabı Sil", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Bu kitabı kütüphanenden kaldırmak istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              _dbService.removeBook(bookId); 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kitap silindi 🗑️"), backgroundColor: Colors.redAccent));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  } 
  
  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Center(child: Text("Giriş Yapmalısın"));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // GÜNCELLENDİ: Arka plan temaya göre
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: Text("Kütüphanem", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip("Tümü"),
                const SizedBox(width: 10),
                _buildFilterChip("Okunuyor"),
                const SizedBox(width: 10),
                _buildFilterChip("Bitti"),
                const SizedBox(width: 10),
                _buildFilterChip("Okunacak"),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('library').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final allDocs = snapshot.data?.docs ?? [];
                
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  int current = data['currentPage'] ?? 0;
                  int total = data['pageCount'] ?? 100;
                  if (_selectedFilter == "Tümü") return true;
                  if (_selectedFilter == "Okunuyor") return current > 0 && current < total;
                  if (_selectedFilter == "Bitti") return current >= total;
                  if (_selectedFilter == "Okunacak") return current == 0;
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("Bu kategoride kitap yok.", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    if (data['id'] == null) return const SizedBox(); 
                    
                    Book book = Book(
                      id: data['id'],
                      title: data['title'] ?? "",
                      author: data['author'] ?? "",
                      thumbnailUrl: data['thumbnailUrl'] ?? "",
                      description: data['description'] ?? "",
                      pageCount: data['pageCount'] ?? 100,
                      currentPage: data['currentPage'] ?? 0,
                      status: data['status'] ?? "reading",
                    );

                    double percent = book.currentPage / book.pageCount;
                    if (percent > 1.0) percent = 1.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      // GÜNCELLENDİ: Kart rengi temaya göre
                      color: Theme.of(context).cardColor, 
                      child: InkWell(
                        onTap: () => _showUpdateDialog(book), 
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: book.thumbnailUrl,
                                  width: 60, height: 90, fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Text("${book.currentPage} / ${book.pageCount} Sayfa", style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFC69C82), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              CircularPercentIndicator(
                                radius: 22.0, lineWidth: 4.0, percent: percent,
                                center: Text("%${(percent * 100).toInt()}", style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold)),
                                progressColor: percent >= 1.0 ? Colors.green : const Color(0xFFC69C82),
                                backgroundColor: Colors.grey[200]!,
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                              const SizedBox(width: 8), 
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                onPressed: () => _showDeleteDialog(book.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // GÜNCELLENMİŞ FİLTRE BUTONU TASARIMI
  Widget _buildFilterChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _selectedFilter == label;

    // Gece modunda seçili olmayan rengi ayarla
    Color unselectedColor = isDark ? const Color(0xFF2C2623) : Colors.white;
    Color borderColor = isDark ? const Color(0xFF3E3E3E) : Colors.grey[300]!;
    Color textColor = isSelected ? Colors.white : (isDark ? Colors.grey[400]! : Colors.grey[600]!);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC69C82) : unselectedColor, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFC69C82) : borderColor),
          boxShadow: isSelected 
              ? [BoxShadow(color: const Color(0xFFC69C82).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}