import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Paylaşım Yapma Fonksiyonu
  void _showAddPostDialog() {
    final TextEditingController postController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Motivasyon Mesajı Paylaş"),
        content: TextField(
          controller: postController,
          decoration: const InputDecoration(hintText: "Örn: Bugün mat 2 bitti, bomba gibiyim! 🚀"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && postController.text.isNotEmpty) {
                // Önce kullanıcının adını bulalım
                var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                String userName = userDoc.data()?['name'] ?? 'Öğrenci';
                String? userImage = userDoc.data()?['profileImageUrl'];

                // Posts koleksiyonuna ekle
                await FirebaseFirestore.instance.collection('posts').add({
                  'userId': user.uid,
                  'userName': userName,
                  'userImage': userImage,
                  'message': postController.text,
                  'date': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mesajın paylaşıldı! 🎉")));
                }
              }
            },
            child: const Text("Paylaş"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Topluluk Duvarı")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add_comment),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Artık 'posts' koleksiyonunu dinliyoruz (Hocanın isteği)
        stream: FirebaseFirestore.instance.collection('posts').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kimse bir şey paylaşmamış.\nİlk mesajı sen at! 👇", textAlign: TextAlign.center));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              var data = post.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            backgroundImage: data['userImage'] != null ? NetworkImage(data['userImage']) : null,
                            child: data['userImage'] == null ? const Icon(Icons.person, color: Colors.indigo) : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['userName'] ?? "Öğrenci", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                "Az önce", // Tarih formatlamakla uğraşmamak için basit tuttum
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(data['message'] ?? "", style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}