# 📚 StudyTrack

**StudyTrack**, üniversite öğrencilerinin ders çalışma sürelerini takip etmelerini, hedeflerini yönetmelerini ve topluluk desteğiyle motivasyonlarını artırmalarını sağlayan **Flutter & Firebase** tabanlı bir mobil uygulamadır.

Mobil Programlama dersi final projesi olarak geliştirilmiştir.

---

## 🚀 Proje Özellikleri

Uygulama, aşağıdaki temel ve gelişmiş özellikleri eksiksiz içermektedir:

### 🔐 1. Kimlik Doğrulama (Authentication)
* **Kayıt Ol / Giriş Yap:** Firebase Auth altyapısı ile güvenli giriş.
* **Şifremi Unuttum:** E-posta adresine şifre sıfırlama bağlantısı gönderme.
* **Oturum Yönetimi:** Uygulama açıldığında oturumun hatırlanması.

### 🏠 2. Ana Sayfa (Dashboard)
* **Canlı Veri:** O günkü toplam çalışma süresinin anlık takibi.
* **Hedef ve İlerleme:** Günlük hedef belirleme (örn: 120 dk) ve yüzdesel ilerleme çubuğu (Progress Bar).
* **Yapılacaklar Listesi (To-Do):** Günlük görevleri ekleme, tamamlama ve silme.

### ⏱️ 3. Çalışma Zamanlayıcısı (Timer)
* **Kronometre:** Ders seçerek süre tutma ve kaydetme.
* **Manuel Ekleme:** Süre tutulmayan çalışmaları geriye dönük olarak (Ders adı ve dakika girerek) sisteme ekleme özelliği.

### 📊 4. İstatistikler
* **Haftalık Analiz:** Son 7 günün çalışma verilerini gösteren Sütun Grafik (Bar Chart).
* **Ders Bazlı Özet:** Hangi derse toplam kaç dakika çalışıldığını gösteren detaylı liste.

### 💬 5. Topluluk (Community)
* **Sosyal Akış:** Öğrencilerin motivasyon mesajları paylaştığı alan.
* **Resimli Paylaşım:** Mesajlara **görsel (fotoğraf)** ekleme özelliği (Firebase Storage).
* **Canlı Akış:** Diğer kullanıcıların paylaşımlarını anlık görüntüleme.

### 👤 6. Profil ve Ayarlar
* **Profil Yönetimi:** Ad, Soyad ve Bölüm bilgilerini güncelleme.
* **Fotoğraf Yükleme:** Galeriden profil fotoğrafı seçip buluta yükleme.
* **🌙 Karanlık Mod (Dark Mode):** Uygulama içi tema değiştirme (Light/Dark).

---

## 🛠️ Kullanılan Teknolojiler

Bu proje **Flutter** kullanılarak geliştirilmiş olup, Backend servisi olarak **Google Firebase** kullanılmıştır.

* **Dil:** Dart
* **Framework:** Flutter
* **Backend:** Firebase (Authentication, Firestore, Storage)
* **Mimari:** Modüler Dosya Yapısı (MVC Prensibine uygun ekran/widget ayrımı)

### 📦 Kullanılan Paketler (Dependencies)
* `firebase_auth`: Kimlik doğrulama işlemleri.
* `cloud_firestore`: NoSQL veritabanı işlemleri.
* `firebase_storage`: Fotoğraf depolama.
* `fl_chart`: İstatistik grafikleri.
* `image_picker`: Galeriden resim seçimi.
* `intl`: Tarih ve saat formatlama.
* `flutter_native_splash`: Özel açılış ekranı.

---

## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımlar izlenmelidir:

1.  **Depoyu Klonlayın:**
    ```bash
    git clone [https://github.com/ilaydakyldzz/study_track.git](https://github.com/ilaydakyldzz/study_track.git)
    ```

2.  **Proje Klasörüne Gidin:**
    ```bash
    cd study_track
    ```

3.  **Paketleri Yükleyin:**
    ```bash
    flutter pub get
    ```

4.  **Firebase Kurulumu:**
    * Bu proje Firebase bağlantısı gerektirir. `google-services.json` dosyasının `android/app/` dizininde olduğundan emin olun.

5.  **Uygulamayı Başlatın:**
    ```bash
    flutter run
    ```

---

## 📄 Lisans ve Hazırlayan

Bu proje **Mobil Programlama Dersi Final Ödevi** kapsamında hazırlanmıştır.

**Geliştirici:** İlayda AKYILDIZ
**Öğrenci No:** 22060366  
