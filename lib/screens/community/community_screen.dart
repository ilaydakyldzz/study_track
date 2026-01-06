import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  
  // Paylaşım Yapma Penceresi
  void _showAddPostDialog() {
    final TextEditingController postController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;
    
    // Dialog içinde state güncellemek için StatefulBuilder kullanıyoruz
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Paylaşım Yap"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: postController,
                    decoration: const InputDecoration(hintText: "Bir şeyler yaz..."),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  // Resim Seçme Alanı
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                      if (picked != null) {
                        setState(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        image: selectedImage != null 
                          ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                          : null
                      ),
                      child: selectedImage == null 
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.add_a_photo, color: Colors.grey), Text("Resim Ekle (İsteğe bağlı)", style: TextStyle(color: Colors.grey))],
                          ) 
                        : null,
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && postController.text.isNotEmpty) {
                      setState(() => isUploading = true);
                      
                      String? imageUrl;
                      
                      // Eğer resim seçildiyse yükle
                      if (selectedImage != null) {
                        try {
                          final ref = FirebaseStorage.instance.ref().child('post_images').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                          await ref.putFile(selectedImage!);
                          imageUrl = await ref.getDownloadURL();
                        } catch (e) {
                          // Hata olsa da devam etsin, sadece resim olmaz
                        }
                      }

                      // Kullanıcı bilgilerini al
                      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                      String userName = userDoc.data()?['name'] ?? 'Öğrenci';
                      String? userProfilePic = userDoc.data()?['profileImageUrl'];

                      // Postu kaydet
                      await FirebaseFirestore.instance.collection('posts').add({
                        'userId': user.uid,
                        'userName': userName,
                        'userImage': userProfilePic,
                        'message': postController.text,
                        'postImage': imageUrl, // Varsa resim URL'si
                        'date': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paylaşıldı! 🚀")));
                      }
                    }
                  },
                  child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text("Paylaş"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Topluluk")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz paylaşım yok."));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(backgroundImage: data['userImage'] != null ? NetworkImage(data['userImage']) : null, child: data['userImage'] == null ? const Icon(Icons.person) : null),
                      title: Text(data['userName'] ?? "Öğrenci", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Az önce"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(data['message'] ?? "", style: const TextStyle(fontSize: 16)),
                    ),
                    if (data['postImage'] != null)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(data['postImage'], height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}