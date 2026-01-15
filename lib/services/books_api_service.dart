import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

// Sınıf ismini 'BookService' yaptık ki HomeScreen ile eşleşsin
class BookService {
  
  // Google Books API üzerinden kitap arar
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    // Türkçe sonuçlar için &langRestrict=tr ekledik
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query&langRestrict=tr&maxResults=20');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) {
          final volumeInfo = item['volumeInfo'];
          
          return Book(
            id: item['id'],
            title: volumeInfo['title'] ?? "Başlıksız",
            author: (volumeInfo['authors'] as List<dynamic>?)?.first ?? "Bilinmeyen Yazar",
            // Resim kontrolü (http linklerini https yapıyoruz)
            thumbnailUrl: volumeInfo['imageLinks']?['thumbnail']?.toString().replaceFirst("http://", "https://") ?? 
                          "https://via.placeholder.com/150", 
            description: volumeInfo['description'] ?? "Açıklama yok.",
            pageCount: volumeInfo['pageCount'] ?? 100,
            currentPage: 0,
            status: 'reading',
          );
        }).toList();
      } else {
        print("API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("İnternet Hatası: $e");
      return [];
    }
  }
  // --- YENİ: ISBN (Barkod) İLE KİTAP BULMA ---
  Future<Book?> searchBookByIsbn(String isbn) async {
    // ISBN araması için özel sorgu: "isbn:978..."
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn&langRestrict=tr&maxResults=1');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['totalItems'] > 0 && data['items'] != null) {
          final item = data['items'][0]; // İlk sonucu al
          final volumeInfo = item['volumeInfo'];
          
          return Book(
            id: item['id'],
            title: volumeInfo['title'] ?? "Başlıksız",
            author: (volumeInfo['authors'] as List<dynamic>?)?.first ?? "Bilinmeyen Yazar",
            thumbnailUrl: volumeInfo['imageLinks']?['thumbnail']?.toString().replaceFirst("http://", "https://") ?? "",
            description: volumeInfo['description'] ?? "",
            pageCount: volumeInfo['pageCount'] ?? 100,
            currentPage: 0,
            status: 'reading',
          );
        }
      }
      return null; // Bulunamadı
    } catch (e) {
      print("ISBN Hatası: $e");
      return null;
    }
  }
}