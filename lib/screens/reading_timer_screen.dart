import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/reading_provider.dart';
import '../services/database_service.dart';

class ReadingTimerScreen extends StatefulWidget {
  const ReadingTimerScreen({super.key});

  @override
  State<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends State<ReadingTimerScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  // --- KAYDETME DİYALOĞU ---
  void _showFinishDialog(BuildContext context, ReadingProvider provider) {
    // Diyalog açılınca sayacı duraklat
    if (provider.isRunning) provider.toggleTimer();

    final pageController = TextEditingController();
    final noteController = TextEditingController();
    
    // Eğer "Okumaya Başla" butonuyla gelindiyse kitap seçili gelir
    String? selectedBookId = provider.currentBookId; 

    showDialog(
      context: context,
      barrierDismissible: false, // Boşluğa basınca kapanmasın
      builder: (context) {
        // Tema Renkleri
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
        final dialogColor = Theme.of(context).cardColor;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: dialogColor,
              title: Text("Okumayı Bitir", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hangi kitabı okudun?", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 5),
                      
                      // 1. KİTAP SEÇİMİ (Dropdown)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('library')
                            .where('status', isEqualTo: 'reading') // Sadece okunanlar
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const LinearProgressIndicator();
                          final books = snapshot.data!.docs;

                          if (books.isEmpty) {
                            return Text("Önce kütüphanene 'Okunuyor' statüsünde kitap ekle.", style: GoogleFonts.poppins(color: Colors.red, fontSize: 12));
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedBookId,
                            dropdownColor: dialogColor,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            hint: Text("Kitap Seç", style: TextStyle(color: textColor)),
                            items: books.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  data['title'], 
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor)
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => selectedBookId = val);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 15),

                      // 2. SAYFA SAYISI
                      Text("Kaçıncı sayfadasın?", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      TextField(
                        controller: pageController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          hintText: "Örn: 45",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 3. NOT EKLEME
                      Text("Notun var mı? (Opsiyonel)", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          hintText: "Buraya not al...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // İPTAL BUTONU
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
                ),
                
                // KAYDET VE BİTİR BUTONU
                ElevatedButton(
                  onPressed: () async {
                    if (selectedBookId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir kitap seç!")));
                      return;
                    }
                    
                    // 1. İlerlemeyi Kaydet (Sayfa sayısı)
                    if (pageController.text.isNotEmpty) {
                      int page = int.tryParse(pageController.text) ?? 0;
                      await _dbService.updateProgress(selectedBookId!, page);
                    }

                    // 2. Not varsa Kaydet
                    if (noteController.text.isNotEmpty) {
                      await _dbService.addNote(selectedBookId!, noteController.text);
                    }

                    // 3. --- YENİ EKLENEN KISIM: OKUMA SÜRESİNİ KAYDET ---
                    // Eğer süre 0'dan büyükse Liderlik Tablosu için kaydet
                    if (provider.secondsElapsed > 0) {
                       await _dbService.saveReadingSession(selectedBookId!, provider.secondsElapsed);
                    }

                    // 4. Timer'ı Sıfırla ve Çık
                    provider.resetTimer();
                    if (mounted) {
                      Navigator.pop(context); // Dialog kapat
                      Navigator.pop(context); // Timer ekranını kapat (Ana sayfaya dön)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Oturum ve Süre kaydedildi! ⏱️"), backgroundColor: Colors.green));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
                  child: const Text("Kaydet & Bitir", style: TextStyle(color: Colors.white)),
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
    final provider = Provider.of<ReadingProvider>(context);
    
    // --- TEMA RENKLERİ ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);

    // Hedef (Örn: 30 dakika = 1800 saniye). 
    int targetSeconds = 1800; 
    double percent = provider.secondsElapsed / targetSeconds;
    if (percent > 1.0) percent = 1.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Okuma Süresi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // Klavye açılınca taşmasın diye
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // DAİRESEL ZAMANLAYICI
            Center(
              child: CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 15.0,
                percent: percent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.timerString,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, 
                        fontSize: 40.0, 
                        color: textColor
                      ),
                    ),
                    Text("geçen süre", style: GoogleFonts.poppins(color: Colors.grey)),
                  ],
                ),
                progressColor: const Color(0xFFC69C82),
                backgroundColor: isDark ? const Color(0xFF2C2623) : Colors.grey[200]!,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
              ),
            ),
            const SizedBox(height: 50),
      
            // KONTROL BUTONLARI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BAŞLAT / DURAKLAT (Pause)
                ElevatedButton(
                  onPressed: provider.toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC69C82),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                  ),
                  child: Icon(
                    provider.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 30),
                
                // BİTİR / KAYDET (Stop)
                ElevatedButton(
                  // Burada direkt resetlemek yerine Diyaloğu açıyoruz
                  onPressed: () => _showFinishDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, 
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!)
                  ),
                  child: const Icon(Icons.stop, size: 35, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Kırmızı butona basarak oturumu kaydedebilirsin.",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            Text(
              provider.isRunning ? "Okumaya devam et! 📖" : "Mola verdin ☕",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}