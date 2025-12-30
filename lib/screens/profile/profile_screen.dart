import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_track/main.dart'; // themeNotifier'a erişmek için bunu ekledik
import 'package:study_track/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null && user != null) {
      setState(() { _imageFile = File(pickedFile.path); _isUploading = true; });

      try {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('${user!.uid}.jpg');
        await storageRef.putFile(_imageFile!);
        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'profileImageUrl': downloadUrl});
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil resmi güncellendi! ✨")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Şu an karanlık modda mıyız kontrolü
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Profilim")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                    builder: (context, snapshot) {
                      String? imageUrl;
                      String firstLetter = "?";
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        imageUrl = data['profileImageUrl'];
                        String name = data['name'] ?? "?";
                        if (name.isNotEmpty) firstLetter = name[0].toUpperCase();
                      }
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null
                            ? Text(firstLetter, style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor))
                            : null,
                      );
                    },
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

            // KULLANICI BİLGİLERİ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        var data = snapshot.data!.data() as Map<String, dynamic>?;
                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
                              title: const Text("Ad Soyad"),
                              subtitle: Text(data?['name'] ?? "Bilinmiyor"),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.email, color: Theme.of(context).primaryColor),
                              title: const Text("E-posta"),
                              subtitle: Text(data?['email'] ?? "Bilinmiyor"),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    // --- YENİ EKLENEN KARANLIK MOD AYARI ---
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Karanlık Mod 🌙"),
                      value: isDarkMode,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (bool value) {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                      secondary: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text("Çıkış Yap"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}