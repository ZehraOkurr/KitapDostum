import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Resimleri hızlı yüklemek için
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // Kartın genişliği
        margin: const EdgeInsets.only(right: 16), // Yanındakiyle boşluk
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KİTAP KAPAĞI (Gölge ve Yuvarlak Köşe)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: book.thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. KİTAP ADI
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis, // Sığmazsa ... koy
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            // 3. YAZAR ADI
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}