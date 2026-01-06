import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_track/main.dart';
import 'package:study_track/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // --- YENİ EKLENEN: BİLGİ DÜZENLEME PENCERESİ ---
  void _editProfileInfo(String currentName, String currentDept) {
    TextEditingController nameController = TextEditingController(text: currentName);
    TextEditingController deptController = TextEditingController(text: currentDept);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profili Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Ad Soyad")),
            TextField(controller: deptController, decoration: const InputDecoration(labelText: "Bölüm / Sınıf")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                  'name': nameController.text,
                  'department': deptController.text,
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null && user != null) {
      setState(() => _isUploading = true);
      try {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${user!.uid}.jpg');
        await storageRef.putFile(File(pickedFile.path));
        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'profileImageUrl': downloadUrl});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fotoğraf güncellendi!")));
      } catch (e) {
        // Hata yönetimi
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var data = snapshot.data!.data() as Map<String, dynamic>?;
        
        String name = data?['name'] ?? "Öğrenci";
        String dept = data?['department'] ?? "Belirtilmedi";
        String? imageUrl = data?['profileImageUrl'];

        return Scaffold(
          appBar: AppBar(
            title: const Text("Profilim"),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editProfileInfo(name, dept), // Düzenleme penceresini açar
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null
                            ? Text(name.isNotEmpty ? name[0] : "?", style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor))
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                            child: _isUploading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(leading: Icon(Icons.person, color: Theme.of(context).primaryColor), title: const Text("Ad Soyad"), subtitle: Text(name)),
                        const Divider(),
                        ListTile(leading: Icon(Icons.email, color: Theme.of(context).primaryColor), title: const Text("E-posta"), subtitle: Text(user?.email ?? "")),
                        const Divider(),
                        ListTile(leading: Icon(Icons.school, color: Theme.of(context).primaryColor), title: const Text("Bölüm"), subtitle: Text(dept)),
                        const Divider(),
                        SwitchListTile(
                          title: const Text("Karanlık Mod 🌙"),
                          value: isDarkMode,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (bool value) => themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Çıkış Yap"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}