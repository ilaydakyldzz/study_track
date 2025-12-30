import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafik kütüphanesi
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Haftanın günleri (Pazartesi=0, Salı=1...)
  final List<String> _weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  
  // Her gün için çalışma süresi (Dakika cinsinden)
  List<double> _weeklyStudyData = [0, 0, 0, 0, 0, 0, 0]; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeeklyData();
  }

  // Veritabanından verileri çekip hesaplayan fonksiyon
  Future<void> _fetchWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    
    // Veritabanından bu kullanıcının tüm kayıtlarını çek
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('study_sessions')
        .where('userId', isEqualTo: user.uid)
        .get();

    List<double> tempData = [0, 0, 0, 0, 0, 0, 0];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      Timestamp? timestamp = data['date'];
      int durationSeconds = data['durationSeconds'] ?? 0;

      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        // Basitçe haftanın gününe (Pzt-Paz) göre listeye ekliyoruz
        int dayIndex = date.weekday - 1; // 0=Pzt, 6=Paz
        double durationMinutes = durationSeconds / 60;
        
        // Hata olmasın diye kontrol (indeks 0-6 arasında mı?)
        if (dayIndex >= 0 && dayIndex < 7) {
           tempData[dayIndex] += durationMinutes;
        }
      }
    }

    if (mounted) {
      setState(() {
        _weeklyStudyData = tempData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Grafik için tavan değer hesaplama (En az 10 olsun ki boşken grafik çökmesin)
    double maxY = _weeklyStudyData.reduce((a, b) => a > b ? a : b);
    if (maxY < 10) maxY = 10; else maxY += 10;

    return Scaffold(
      appBar: AppBar(title: const Text("Haftalık İlerleme")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    "Günlük Çalışma Sürelerin (Dakika)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  
                  // GRAFİK ALANI
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            // HATA BURADAYDI, DÜZELTİLDİ:
                            tooltipBgColor: Colors.blueGrey, 
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.round()} dk',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
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
                                   return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      _weekDays[value.toInt()],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  );
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
                            barRods: [
                              BarChartRodData(
                                toY: _weeklyStudyData[index],
                                color: Colors.indigo,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Özet Bilgi Kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insights, color: Colors.indigo),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Bu hafta toplam ${(_weeklyStudyData.reduce((a, b) => a + b)).toStringAsFixed(1)} dakika çalıştın.",
                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}