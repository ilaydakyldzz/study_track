plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin'i Android ve Kotlin pluginlerinden sonra gelmeli
    id("dev.flutter.flutter-gradle-plugin")
    // BURASI EKLENDİ: Firebase Google Services Plugini
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.study_track"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Kendi Application ID'ni buraya yazabilirsin (şu an dokunmana gerek yok)
        applicationId = "com.example.study_track"
        
        // BURASI DEĞİŞTİ: Firebase için en az 23 olması gerekiyor
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Release build için imza ayarlarını buraya ekle.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
