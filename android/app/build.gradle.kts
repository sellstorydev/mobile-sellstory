plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "me.sellstory.app"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {

        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "me.sellstory.pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Added signingConfigs for release using key.properties
    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                val storeFilePath = keystoreProperties["storeFile"] as String?
                if (!storeFilePath.isNullOrBlank()) {
                    storeFile = file(storeFilePath)
                }
                storePassword = (keystoreProperties["storePassword"] as String?) ?: ""
                keyAlias = (keystoreProperties["keyAlias"] as String?) ?: ""
                keyPassword = (keystoreProperties["keyPassword"] as String?) ?: ""
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")  // หรือ debug ถ้ายังไม่มีคีย์
            isMinifyEnabled = true
            isShrinkResources = true
            ndk { debugSymbolLevel = "NONE" } // Disable native debug symbol packaging to avoid strip tool requirement
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

configurations.all {
    exclude(group = "com.google.android.play", module = "core-common")
}

dependencies {
    // Play Core library needed when Flutter embedding references deferred components classes during minify
    implementation("com.google.android.play:core:1.10.3")
}
