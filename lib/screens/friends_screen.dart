import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final String? myUid = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- ARKADAŞ EKLEME PENCERESİ (İSTEK GÖNDERME) ---
  void _showAddFriendDialog() {
    final codeController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        // Dialog içinde setState kullanabilmek için StatefulBuilder şart
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text("Arkadaş Ekle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: "Arkadaş Kodu",
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      hintText: "Örn: A1B2C",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: const OutlineInputBorder(),
                      errorText: errorMessage,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.5))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFC69C82))),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 10),
                  Text("Kodu girince istek gönderilecektir.", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  if (isLoading) const Padding(padding: EdgeInsets.only(top: 10), child: CircularProgressIndicator(color: Color(0xFFC69C82))),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("İptal", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setState(() { isLoading = true; errorMessage = null; });
                    final code = codeController.text.trim().toUpperCase();
                    
                    if (code.isEmpty) {
                      setState(() { isLoading = false; errorMessage = "Lütfen bir kod giriniz."; });
                      return;
                    }

                    // 1. Kullanıcıyı bul
                    final userMap = await _userService.searchUserByCode(code);
                    
                    if (userMap != null) {
                      // Kendini eklemeyi engelle
                      if (userMap['uid'] == myUid) {
                         setState(() { isLoading = false; errorMessage = "Kendini ekleyemezsin! 😅"; });
                         return;
                      }

                      // 2. İSTEK GÖNDER
                      String result = await _userService.sendFriendRequest(userMap['uid'], userMap['displayName']);
                      
                      if (result == "Success") {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Arkadaşlık isteği gönderildi! 📩"), backgroundColor: Colors.green)
                          );
                        }
                      } else {
                        // Hata mesajı (Örn: Zaten arkadaşsınız)
                        setState(() { isLoading = false; errorMessage = result; });
                      }
                    } else {
                      setState(() { isLoading = false; errorMessage = "Bu koda sahip kullanıcı bulunamadı."; });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
                  child: const Text("İstek Gönder", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema Renkleri
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Arkadaşlar", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFC69C82),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFC69C82),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Arkadaşlarım"),
            Tab(text: "Gelen İstekler 📩"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(textColor),
          _buildRequestsList(textColor),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: const Color(0xFFC69C82),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // 1. SEKME: MEVCUT ARKADAŞLAR LİSTESİ
  Widget _buildFriendsList(Color textColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(myUid).collection('friends').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final friends = snapshot.data!.docs;

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 10),
                Text("Henüz arkadaşın yok.", style: GoogleFonts.poppins(color: Colors.grey)),
                Text("Sağ alttaki butondan ekle!", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final data = friend.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'İsimsiz';

            return Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFC69C82).withOpacity(0.2),
                  child: Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFC69C82), fontWeight: FontWeight.bold)),
                ),
                title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text("Kitap Dostu", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  onPressed: () => _showDeleteDialog(friend.id, name),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. SEKME: GELEN İSTEKLER LİSTESİ
  Widget _buildRequestsList(Color textColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('receiverUid', isEqualTo: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 10),
                Text("Bekleyen istek yok.", style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final reqData = req.data() as Map<String, dynamic>;

            return Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(reqData['senderName'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                subtitle: Text("Arkadaşlık isteği gönderdi", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // REDDET BUTONU
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                         await _userService.rejectFriendRequest(req.id);
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İstek reddedildi.")));
                      },
                    ),
                    // KABUL ET BUTONU
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                         await _userService.acceptFriendRequest(req.id, reqData['senderUid'], reqData['senderName']);
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arkadaş eklendi! 🎉"), backgroundColor: Colors.green));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Arkadaş Silme Onay Kutusu
  void _showDeleteDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("$friendName silinsin mi?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Bu kişiyi arkadaş listenden çıkarmak istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              await _userService.removeFriend(friendId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arkadaş silindi."), backgroundColor: Colors.redAccent));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}