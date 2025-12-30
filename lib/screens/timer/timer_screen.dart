import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<String> _subjects = ['Matematik', 'Fizik', 'Kimya', 'Biyoloji', 'Edebiyat', 'Tarih', 'Yazılım', 'İngilizce'];
  String? _selectedSubject;
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _startTimer() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce bir ders seç!")));
      return;
    }
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);
    
    // Veritabanına Kaydet
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _seconds > 0) {
      await FirebaseFirestore.instance.collection('study_sessions').add({
        'userId': user.uid,
        'subject': _selectedSubject,
        'durationSeconds': _seconds,
        'date': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$_selectedSubject çalışması kaydedildi! 💾")));
    }
    setState(() => _seconds = 0);
  }

  // --- YENİ EKLENEN: MANUEL EKLEME FONKSİYONU ---
  void _addManualSession() {
    final TextEditingController minuteController = TextEditingController();
    String? manualSubject = _selectedSubject ?? _subjects.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Manuel Çalışma Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: manualSubject,
                isExpanded: true,
                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => manualSubject = val),
              ),
              TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Süre (Dakika)", suffixText: "dk"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final int? mins = int.tryParse(minuteController.text);
                
                if (user != null && mins != null && mins > 0) {
                  // Dakikayı saniyeye çevirip kaydediyoruz (Uyumlu olması için)
                  await FirebaseFirestore.instance.collection('study_sessions').add({
                    'userId': user.uid,
                    'subject': manualSubject,
                    'durationSeconds': mins * 60, 
                    'date': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manuel kayıt eklendi! ✅")));
                  }
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kronometre")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              hint: const Text("Ders Seçiniz"),
              value: _selectedSubject,
              onChanged: _isRunning ? null : (val) => setState(() => _selectedSubject = val),
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
            const SizedBox(height: 40),
            Text(_formatTime(_seconds), style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Başlat"),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopTimer : null,
                  icon: const Icon(Icons.stop),
                  label: const Text("Bitir & Kaydet"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
              ],
            ),
            
            // --- MANUEL EKLEME BUTONU ---
            const SizedBox(height: 50),
            TextButton.icon(
              onPressed: _addManualSession, 
              icon: const Icon(Icons.edit_note), 
              label: const Text("Süre tutmadan elle ekle"),
            ),
          ],
        ),
      ),
    );
  }
}