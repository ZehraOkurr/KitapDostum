class Book {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String description;
  final int pageCount;
  
  // OpenReads Özellikleri
  int currentPage;
  String status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.description,
    required this.pageCount,
    this.currentPage = 0,
    this.status = 'wishlist',
  });

  // 1. İNTERNETTEN VERİ ÇEKERKEN (API) KULLANILAN KISIM (Senin yazdığın kısım)
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    
    // --- RESİM LİNKİ DÜZELTME OPERASYONU ---
    String imageLink = volumeInfo['imageLinks']?['thumbnail'] ?? "";
    
    if (imageLink.isNotEmpty && imageLink.startsWith("http://")) {
      imageLink = imageLink.replaceFirst("http://", "https://");
    }
    
    if (imageLink.isEmpty) {
      imageLink = "https://placehold.co/150.png";
    }
    // ----------------------------------------

    return Book(
      id: json['id'],
      title: volumeInfo['title'] ?? 'İsimsiz Kitap',
      author: (volumeInfo['authors'] as List<dynamic>?)?.join(", ") ?? "Bilinmiyor",
      thumbnailUrl: imageLink, 
      description: volumeInfo['description'] ?? "Açıklama yok.",
      pageCount: volumeInfo['pageCount'] ?? 100,
    );
  }

  // 2. VERİTABANINA KAYDEDERKEN KULLANILAN KISIM
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'pageCount': pageCount,
      'currentPage': currentPage,
      'status': status,
    };
  }

  // --- 3. EKSİK OLAN PARÇA (Sanal Raf İçin Gerekli) ---
  // Firebase'den gelen veriyi (Map) alıp Book nesnesine çevirir.
  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId, // Doküman ID'sini kullanıyoruz
      title: map['title'] ?? 'Bilinmeyen Kitap',
      author: map['author'] ?? 'Bilinmiyor',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      description: map['description'] ?? '',
      pageCount: map['pageCount'] ?? 0,
      currentPage: map['currentPage'] ?? 0,
      status: map['status'] ?? 'wishlist',
    );
  }
}