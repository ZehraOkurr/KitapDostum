import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/books_api_service.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'add_custom_book_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Book> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    if (query.isNotEmpty) {
      _performSearch(query);
    }
  }

  void _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _bookService.searchBooks(query);
      setState(() => _searchResults = results);
    } catch (e) {
      print("Arama hatası: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "Kitap Dostu";
    
    // Tema kontrolü
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEDE0D4) 
        : const Color(0xFF3E2723);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Keşfet", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Text("Merhaba, $name 👋", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
          Text("Bugün ne okumak istersin?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),

          // --- ARAMA ÇUBUĞU ---
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Kitap, yazar veya tür ara...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); })
                  : null,
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 10),

          // --- İŞTE EKLENEN BUTON BURADA 👇 ---
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AddCustomBookScreen())
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFFC69C82)),
              label: Text(
                "Aradığını bulamadın mı? Kitap Ekle", 
                style: GoogleFonts.poppins(color: const Color(0xFFC69C82), fontWeight: FontWeight.bold)
              ),
            ),
          ),
          // ------------------------------------
          
          const SizedBox(height: 10),

          Expanded(
            child: SingleChildScrollView(
              child: _searchQuery.isEmpty ? _buildDefaultLists() : _buildSearchResults(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Popüler Kitaplar 🔥"),
        const SizedBox(height: 15),
        _buildBookList("Harry Potter"), 

        const SizedBox(height: 30),
        _buildSectionTitle("Bilim Kurgu & Fantastik 🚀"),
        const SizedBox(height: 15),
        _buildBookList("Science Fiction Fantasy"),

        const SizedBox(height: 30),
        _buildSectionTitle("Kişisel Gelişim 🧠"),
        const SizedBox(height: 15),
        _buildBookList("Self Help Motivation"),
        
        const SizedBox(height: 80), 
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) return Center(child: Text("Sonuç bulunamadı", style: GoogleFonts.poppins(color: Colors.grey)));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildBookItem(_searchResults[index]),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    return Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor));
  }

  Widget _buildBookList(String query) {
    return FutureBuilder<List<Book>>(
      future: _bookService.searchBooks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return const Text("Hata oluştu");
        final books = snapshot.data ?? [];
        
        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              return Padding(padding: const EdgeInsets.only(right: 16.0), child: _buildBookItem(books[index]));
            },
          ),
        );
      },
    );
  }

  Widget _buildBookItem(Book book) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookDetailScreen(book: book))),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: book.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: book.thumbnailUrl, fit: BoxFit.cover, width: double.infinity,
                    errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}