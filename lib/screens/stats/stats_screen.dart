import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final List<String> _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  List<double> _weeklyStudyData = [0, 0, 0, 0, 0, 0, 0];
  Map<String, int> _subjectSummary = {}; // Ders bazlı toplam süreler
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeeklyData();
  }

  Future<void> _fetchWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Sadece bu haftanın değil, genel istatistikleri çekelim
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('study_sessions')
        .where('userId', isEqualTo: user.uid)
        .get();

    List<double> tempData = [0, 0, 0, 0, 0, 0, 0];
    Map<String, int> tempSubjects = {};
    DateTime now = DateTime.now();
    // Basitlik adına son 7 güne odaklanalım grafik için
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['date'];
      int durationSeconds = data['durationSeconds'] ?? 0;
      String subject = data['subject'] ?? 'Diğer';

      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        int durationMinutes = durationSeconds ~/ 60;

        // 1. Grafik Verisi (Bu hafta)
        // Basit mantık: kaydın haftası ile bu hafta aynı mı?
        // Daha detaylı kontrol yapılabilir ama demo için yeterli.
        if (date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
           int dayIndex = date.weekday - 1;
           if (dayIndex >= 0 && dayIndex < 7) {
             tempData[dayIndex] += durationMinutes;
           }
        }

        // 2. Ders Özeti (Genel Toplam)
        if (tempSubjects.containsKey(subject)) {
          tempSubjects[subject] = tempSubjects[subject]! + durationMinutes;
        } else {
          tempSubjects[subject] = durationMinutes;
        }
      }
    }

    if (mounted) {
      setState(() {
        _weeklyStudyData = tempData;
        _subjectSummary = tempSubjects;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxY = _weeklyStudyData.reduce((a, b) => a > b ? a : b);
    if (maxY < 10) maxY = 10; else maxY += 10;

    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Haftalık Çalışma (Dakika)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem('${rod.toY.round()} dk', const TextStyle(color: Colors.white));
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() >= 0 && value.toInt() < _weekDays.length) {
                                   return SideTitleWidget(axisSide: meta.axisSide, child: Text(_weekDays[value.toInt()], style: const TextStyle(fontSize: 10)));
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: List.generate(7, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [BarChartRodData(toY: _weeklyStudyData[index], color: Colors.indigo, width: 14, borderRadius: BorderRadius.circular(4))],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // --- YENİ EKLENEN: DERS BAZLI ÖZET ---
                  const Text("Ders Bazlı Toplam Süreler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _subjectSummary.isEmpty 
                  ? const Text("Henüz veri yok.")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subjectSummary.length,
                      itemBuilder: (context, index) {
                        String key = _subjectSummary.keys.elementAt(index);
                        int value = _subjectSummary[key]!;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade50,
                              child: const Icon(Icons.book, color: Colors.indigo),
                            ),
                            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text("$value dk", style: const TextStyle(fontSize: 16, color: Colors.indigo)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}