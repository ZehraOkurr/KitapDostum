import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final provider = Provider.of<ReadingProvider>(context);

    // Tema Renkleri
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("İstatistikler", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: textColor),
            onPressed: () => _showEditGoalsDialog(context, provider),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEDEFLER
            Text("Aylık Okuma Hedefleri", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('library').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;
                
                // Toplam biten kitapları ve okunan sayfaları hesapla
                int readBooks = docs.where((d) => (d['currentPage'] ?? 0) >= (d['pageCount'] ?? 100)).length;
                int totalPages = docs.fold(0, (sum, d) => sum + (d['currentPage'] as int? ?? 0));

                return Column(
                  children: [
                    _buildChallengeCard(context, "Aylık Kitap Hedefi", readBooks, provider.bookGoal, "Kitap"),
                    const SizedBox(height: 15),
                    _buildChallengeCard(context, "Aylık Sayfa Adedi", totalPages, provider.pageGoal, "Sayfa"),
                  ],
                );
              }
            ),

            const SizedBox(height: 40),

            // 2. AYLIK OKUMA SÜRESİ GRAFİĞİ
            Text("Aylık Okuma Süresi (Saat)", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor, // Gece modunda koyu, gündüz beyaz
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: _buildMonthlyChart(uid, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // --- GRAFİK OLUŞTURUCU FONKSİYON ---
  Widget _buildMonthlyChart(String? uid, bool isDark) {
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reading_sessions')
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        Map<int, double> monthlyData = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 0, 11: 0, 12: 0};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          final seconds = data['duration'] as int? ?? 0;
          
          monthlyData[date.month] = (monthlyData[date.month] ?? 0) + (seconds / 3600);
        }

        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const months = ['O', 'Ş', 'M', 'N', 'M', 'H', 'T', 'A', 'E', 'E', 'K', 'A'];
                    if (value.toInt() >= 1 && value.toInt() <= 12) {
                      return Text(months[value.toInt() - 1], style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12));
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(12, (index) {
              int month = index + 1;
              return BarChartGroupData(
                x: month,
                barRods: [
                  BarChartRodData(
                    toY: monthlyData[month]!,
                    color: monthlyData[month]! > 0 ? const Color(0xFFC69C82) : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    width: 12,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 10, // Maksimum Yüksekliği buraya göre ayarlayabilirsin
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // --- DÜZENLEME PENCERESİ ---
  void _showEditGoalsDialog(BuildContext context, ReadingProvider provider) {
    final bookController = TextEditingController(text: provider.bookGoal.toString());
    final pageController = TextEditingController(text: provider.pageGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Hedefleri Düzenle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bookController, decoration: const InputDecoration(labelText: "Aylık Kitap Hedefi"), keyboardType: TextInputType.number),
            TextField(controller: pageController, decoration: const InputDecoration(labelText: "Aylık Sayfa Hedefi"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text("İptal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
             onPressed: () {
              int b = int.tryParse(bookController.text) ?? 5;
              int p = int.tryParse(pageController.text) ?? 500;
              provider.updateGoals(b, p);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC69C82)),
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  // --- HEDEF KARTI WIDGET'I ---
  Widget _buildChallengeCard(BuildContext context, String title, int current, int target, String unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEDE0D4) : const Color(0xFF3E2723);

    double percent = target > 0 ? current / target : 0;
    if (percent > 1.0) percent = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 12.0,
            percent: percent,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            progressColor: const Color(0xFFC69C82),
            barRadius: const Radius.circular(10),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text("$current / $target $unit", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}