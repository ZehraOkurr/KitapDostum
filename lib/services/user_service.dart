import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Kod ile Kullanıcı Ara
  Future<Map<String, dynamic>?> searchUserByCode(String friendCode) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('friendCode', isEqualTo: friendCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. ARKADAŞLIK İSTEĞİ GÖNDER (YENİ)
  Future<String> sendFriendRequest(String receiverUid, String receiverName) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return "Hata";

    // Kendi bilgilerimi alayım
    final myDoc = await _firestore.collection('users').doc(myUid).get();
    final myName = myDoc.data()?['displayName'] ?? "İsimsiz";
    final myCode = myDoc.data()?['friendCode'] ?? "";

    // Zaten arkadaş mıyız?
    final checkFriend = await _firestore.collection('users').doc(myUid).collection('friends').doc(receiverUid).get();
    if (checkFriend.exists) return "Zaten arkadaşsınız!";

    // Zaten istek atmış mıyım?
    final checkReq = await _firestore.collection('friend_requests')
        .where('senderUid', isEqualTo: myUid)
        .where('receiverUid', isEqualTo: receiverUid)
        .get();
    if (checkReq.docs.isNotEmpty) return "İstek zaten gönderilmiş.";

    // İsteği Kaydet
    await _firestore.collection('friend_requests').add({
      'senderUid': myUid,
      'senderName': myName,
      'senderCode': myCode,
      'receiverUid': receiverUid,
      'receiverName': receiverName,
      'status': 'pending',
      'timestamp': Timestamp.now(),
    });

    return "Success";
  }

  // 3. İSTEĞİ KABUL ET (YENİ)
  Future<void> acceptFriendRequest(String requestId, String senderUid, String senderName) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;

    final myDoc = await _firestore.collection('users').doc(myUid).get();
    final myName = myDoc.data()?['displayName'] ?? "İsimsiz";

    // A. Benim listeme onu ekle
    await _firestore.collection('users').doc(myUid).collection('friends').doc(senderUid).set({
      'uid': senderUid,
      'name': senderName,
      'addedAt': Timestamp.now(),
    });

    // B. Onun listesine beni ekle (Karşılıklı olması için)
    await _firestore.collection('users').doc(senderUid).collection('friends').doc(myUid).set({
      'uid': myUid,
      'name': myName,
      'addedAt': Timestamp.now(),
    });

    // C. İsteği Sil
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  // 4. İSTEĞİ REDDET (YENİ)
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  // 5. Arkadaş Sil (Hem benden hem ondan siler)
  Future<void> removeFriend(String friendUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;

    // Benden sil
    await _firestore.collection('users').doc(myUid).collection('friends').doc(friendUid).delete();
    // Ondan sil (Opsiyonel, ama temizlik için iyi)
    await _firestore.collection('users').doc(friendUid).collection('friends').doc(myUid).delete();
  }
}