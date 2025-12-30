import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_track/screens/community/community_screen.dart';
import 'package:study_track/screens/profile/profile_screen.dart';
import 'package:study_track/screens/stats/stats_screen.dart';
import 'package:study_track/screens/timer/timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const DashboardView(),
    const TimerScreen(),
    const StatsScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Klavye açılınca ekranın bozulmaması için:
      resizeToAvoidBottomInset: false, 
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Zamanlayıcı'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'İstatistik'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Topluluk'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// ARTIK BURASI STATEFUL WIDGET (Çünkü yazı yazacağız)
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _todoController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  // Hedef Ekleme Fonksiyonu
  void _addTodo() {
    if (_todoController.text.isNotEmpty && user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('todos') // Kullanıcının altına 'todos' koleksiyonu açıyoruz
          .add({
        'title': _todoController.text,
        'isDone': false,
        'date': FieldValue.serverTimestamp(),
      });
      _todoController.clear(); // Yazı kutusunu temizle
    }
  }

  // Hedefi Silme Fonksiyonu
  void _deleteTodo(String docId) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('todos')
          .doc(docId)
          .delete();
    }
  }

  // Hedefi İşaretleme (Yapıldı/Yapılmadı)
  void _toggleTodo(String docId, bool currentStatus) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('todos')
          .doc(docId)
          .update({'isDone': !currentStatus});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("StudyTrack"), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. İSİM ALANI
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                    builder: (context, snapshot) {
                      String name = "Öğrenci";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        name = data['name'] ?? 'Öğrenci';
                      }
                      return Text(
                        "Merhaba, $name 👋",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 5),
                  const Text("Bugünkü hedeflerine hazır mısın?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // 2. MOR KUTU (Bugünkü Çalışma Süresi)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('study_sessions')
                        .where('userId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalMinutesToday = 0;
                      if (snapshot.hasData) {
                        DateTime now = DateTime.now();
                        DateTime startOfToday = DateTime(now.year, now.month, now.day);
                        for (var doc in snapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          Timestamp? t = data['date'];
                          int duration = data['durationSeconds'] ?? 0;
                          if (t != null && t.toDate().isAfter(startOfToday)) {
                            totalMinutesToday += (duration ~/ 60);
                          }
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Bugünkü Çalışma", style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 5),
                                Text("$totalMinutesToday dk", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Icon(Icons.access_time_filled, color: Colors.white, size: 40),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Text("Günlük Hedefler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // 3. YAPILACAKLAR LİSTESİ (TO-DO LIST)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('todos')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      var docs = snapshot.data!.docs;
                      
                      if (docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Henüz hedef eklemedin.", style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true, // Scroll içinde scroll olmasın diye
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var todo = docs[index];
                          bool isDone = todo['isDone'];
                          
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Checkbox(
                                value: isDone,
                                onChanged: (val) => _toggleTodo(todo.id, isDone),
                                activeColor: Colors.indigo,
                              ),
                              title: Text(
                                todo['title'],
                                style: TextStyle(
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? Colors.grey : Colors.black,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteTodo(todo.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  // Alt kısımda boşluk bırakalım ki "Ekle" alanı kapatmasın
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          // 4. HEDEF EKLEME ALANI (En Altta Sabit)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: const InputDecoration(
                      hintText: "Yeni bir hedef ekle...",
                      border: InputBorder.none, // Çizgiyi kaldırdık, daha temiz dursun
                      filled: false,
                    ),
                  ),
                ),
                FloatingActionButton.small(
                  onPressed: _addTodo,
                  backgroundColor: Colors.indigo,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}