import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. KİTAP KAYDETME ---
  Future<void> saveBook(Book book) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // 1. Kitabı Kütüphaneye Ekle
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc(book.id)
        .set(book.toMap());
    
    // 2. HABERCİ: "Kitaba Başladı" diye kaydet
    await logPublicActivity(
      type: "start_book", 
      bookTitle: book.title, 
      bookId: book.id,
      bookImage: book.thumbnailUrl
    );
  }

  // --- 2. NOT EKLEME ---
  Future<void> addNote(String bookId, String text) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // 1. Notu Kitabın İçine Kaydet (Özel)
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('library')
        .doc(bookId)
        .collection('notes')
        .add({
      'text': text,
      'date': Timestamp.now(),
    });

    // Kitap ismini bulmamız lazım (Akışta göstermek için)
    final bookDoc = await _firestore.collection('users').doc(uid).collection('library').doc(bookId).get();
    final bookTitle = bookDoc.data()?['title'] ?? "Kitap";
    final bookImage = bookDoc.data()?['thumbnailUrl'] ?? "";

    // 2. HABERCİ: "Not Paylaştı" diye kaydet (Herkese Açık)
    await logPublicActivity(
      type: "add_note", 
      bookTitle: bookTitle, 
      bookId: bookId, 
      content: text,
      bookImage: bookImage
    );

    // 3. ROZET KONTROLÜ: Araştırmacı
    await _checkScholarBadge();
  }

  // --- 3. İLERLEME GÜNCELLEME ---
  Future<void> updateProgress(String bookId, int newPage) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final docRef = _firestore.collection('users').doc(uid).collection('library').doc(bookId);
    
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;
    
    int totalPages = docSnapshot.data()?['pageCount'] ?? 100;

    // Eğer kitap bittiyse statüyü de güncelle
    if (newPage >= totalPages) {
       await docRef.update({'currentPage': newPage, 'status': 'finished'});
       
       final bookTitle = docSnapshot.data()?['title'] ?? "Kitap";
       final bookImage = docSnapshot.data()?['thumbnailUrl'] ?? "";
       
       // Akışa yaz
       await logPublicActivity(
         type: "finish_book", 
         bookTitle: bookTitle, 
         bookId: bookId,
         bookImage: bookImage
       );

       // KULLANICI İSTATİSTİKLERİNİ GÜNCELLE (Kitap Sayısı İçin)
       await _firestore.collection('users').doc(uid).update({
         'totalBooksRead': FieldValue.increment(1),
         'totalPagesRead': FieldValue.increment(totalPages),
       });

       // ROZET KONTROLÜ: Kitap Sayısı
       await _checkBookCountBadges();

    } else {
       await docRef.update({'currentPage': newPage});
    }
  }

  // --- AKTİVİTE KAYDETME (ORTAK PANO) ---
  Future<void> logPublicActivity({
    required String type, // 'start_book', 'add_note', 'finish_book'
    required String bookTitle,
    required String bookId,
    String? content,
    String? bookImage,
    double? rating,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['displayName'] ?? "İsimsiz Okur";
    final userImage = userDoc.data()?['profileImage'];

    await _firestore.collection('public_activities').add({
      'uid': user.uid,
      'userName': userName,
      'userImage': userImage,
      'type': type,
      'bookTitle': bookTitle,
      'bookId': bookId,
      'bookImage': bookImage,
      'content': content,
      'rating': rating,
      'timestamp': Timestamp.now(),
    });
  }

  // --- SOSYAL AKIŞI ÇEKME ---
  Stream<QuerySnapshot> getFriendActivities(List<String> friendIds) {
    if (friendIds.isEmpty) return const Stream.empty();

    return _firestore
        .collection('public_activities')
        .where('uid', whereIn: friendIds)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  // --- DİĞER FONKSİYONLAR ---
  
  Future<bool> isBookSaved(String bookId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid).collection('library').doc(bookId).get();
    return doc.exists;
  }

  Future<void> deleteNote(String bookId, String noteId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('library').doc(bookId).collection('notes').doc(noteId).delete();
  }

  Future<void> removeBook(String bookId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('library').doc(bookId).delete();
  }

  // --- OKUMA SÜRESİ KAYDETME ---
  Future<void> saveReadingSession(String bookId, int durationSeconds) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final currentMonthKey = "${now.year}-${now.month}";

    // 1. Detaylı Kayıt
    await _firestore.collection('users').doc(user.uid).collection('reading_sessions').add({
      'bookId': bookId,
      'duration': durationSeconds,
      'date': Timestamp.now(),
    });

    // 2. Liderlik Tablosu Güncellemesi
    final userRef = _firestore.collection('users').doc(user.uid);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final lastMonthKey = data['lastReadingMonth'] ?? "";
      int currentMonthlySeconds = data['monthlyReadingSeconds'] ?? 0;

      // Yeni aya girildiyse sıfırla
      if (lastMonthKey != currentMonthKey) {
        currentMonthlySeconds = 0;
      }

      currentMonthlySeconds += durationSeconds;

      transaction.update(userRef, {
        'lastReadingMonth': currentMonthKey,
        'monthlyReadingSeconds': currentMonthlySeconds,
      });
    });

    // ROZET KONTROLÜ: Gece Kuşu
    await _checkNightOwlBadge();
  }

  // --- YORUM VE PUAN ---
  Future<void> addReview(String bookId, String bookTitle, String bookImage, double rating, String comment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['displayName'] ?? "İsimsiz Okur";
    final userImage = userDoc.data()?['profileImage'];

    await _firestore.collection('books').doc(bookId).collection('reviews').add({
      'uid': user.uid,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.now(),
    });

    await logPublicActivity(
      type: 'review_book', 
      bookTitle: bookTitle,
      bookId: bookId,
      bookImage: bookImage,
      content: "$rating Yıldız: $comment",
      rating: rating,
    );
  }

  Stream<QuerySnapshot> getBookReviews(String bookId) {
    return _firestore
        .collection('books')
        .doc(bookId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- SOSYAL: ARKADAŞ EKLEME ---
  Future<String> addFriendByCode(String code) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "Hata: Oturum açılmamış.";

    try {
      final query = await _firestore.collection('users').where('friendCode', isEqualTo: code).get();
      if (query.docs.isEmpty) return "Bu koda sahip bir kullanıcı bulunamadı. 😔";

      final friendDoc = query.docs.first;
      final friendData = friendDoc.data();
      final friendId = friendDoc.id;

      if (friendId == currentUser.uid) return "Kendini arkadaş olarak ekleyemezsin! 😅";

      final alreadyFriend = await _firestore.collection('users').doc(currentUser.uid).collection('friends').doc(friendId).get();
      if (alreadyFriend.exists) return "Bu kişi zaten arkadaş listenizde var.";

      await _firestore.collection('users').doc(currentUser.uid).collection('friends').doc(friendId).set({
        'uid': friendId,
        'displayName': friendData['displayName'] ?? 'İsimsiz',
        'profileImage': friendData['profileImage'],
        'addedAt': Timestamp.now(),
      });

      return "success";
    } catch (e) {
      return "Hata oluştu: $e";
    }
  }

  Stream<QuerySnapshot> getMyFriends() {
    final uid = _auth.currentUser?.uid;
    return _firestore.collection('users').doc(uid).collection('friends').orderBy('addedAt', descending: true).snapshots();
  }
  
  Future<void> removeFriend(String friendId) async {
    final uid = _auth.currentUser?.uid;
    await _firestore.collection('users').doc(uid).collection('friends').doc(friendId).delete();
  }

  // --- ROZET SİSTEMİ (Gamification) ---

  // Rozet Verme Fonksiyonu (Yardımcı)
  Future<void> _unlockBadge(String badgeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    
    // Önce kullanıcının mevcut rozetlerini çek
    final doc = await userRef.get();
    List<dynamic> currentBadges = doc.data()?['badges'] ?? [];

    // Eğer bu rozet zaten varsa işlem yapma
    if (currentBadges.contains(badgeId)) return;

    // Yoksa ekle
    await userRef.update({
      'badges': FieldValue.arrayUnion([badgeId])
    });
  }

  // Kontrol 1: Kitap Sayısına Göre Rozet (İlk Adım & Kitap Kurdu)
  Future<void> _checkBookCountBadges() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Biten kitapları say
    final query = await _firestore.collection('users').doc(uid).collection('library').where('status', isEqualTo: 'finished').get();
    final count = query.docs.length;

    if (count >= 1) await _unlockBadge('first_step'); // 1 Kitap
    if (count >= 5) await _unlockBadge('book_worm');  // 5 Kitap
    if (count >= 10) await _unlockBadge('library_king'); // 10 Kitap
  }

  // Kontrol 2: Gece Kuşu (Saat 00:00 - 05:00 arası okuma)
  Future<void> _checkNightOwlBadge() async {
    final now = DateTime.now();
    // Eğer saat gece 00 ile 06 arasındaysa
    if (now.hour >= 0 && now.hour < 6) {
      await _unlockBadge('night_owl');
    }
  }

  // Kontrol 3: Notçu (İlk Notunu Alan)
  Future<void> _checkScholarBadge() async {
     await _unlockBadge('scholar');
  }
}