import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "it.overside.irenefy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.overside.irenefy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Firma di rilascio (F6 fase 4, D-65). `android/key.properties` (escluso da
    // git) dice dov'è la chiave e il suo alias; la password non sta mai su
    // disco: la passa `tool/build_release.sh`, che la legge dal Portachiavi
    // macOS, nella variabile IRENEFY_KEYSTORE_PASSWORD. Senza file o senza
    // variabile la build di rilascio resta firmata con la chiave di debug
    // (es. `flutter run --release`): lo script controlla la firma alla fine.
    val keyProperties = Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use { load(it) }
    }
    val keystorePassword = System.getenv("IRENEFY_KEYSTORE_PASSWORD")
    val releaseSigning = keyProperties.getProperty("storeFile") != null &&
        !keystorePassword.isNullOrEmpty()

    signingConfigs {
        if (releaseSigning) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keystorePassword
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keystorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseSigning) "release" else "debug",
            )
        }
    }

    // Modello Whisper incluso (D-67): non compresso nell'APK, così al primo
    // avvio si copia in fretta (264 MB che non si comprimerebbero comunque).
    androidResources {
        noCompress += listOf("bin")
    }

    // Solo telefoni arm64 (D-65): Whisper esiste solo lì, e le librerie native
    // delle altre architetture (ffmpeg-kit, Flutter) triplicavano l'APK.
    // `ndk.abiFilters` non basta per le librerie già compilate nei plugin.
    packaging {
        jniLibs {
            excludes += listOf("lib/armeabi-v7a/**", "lib/x86/**", "lib/x86_64/**")
        }
    }
}

flutter {
    source = "../.."
}
