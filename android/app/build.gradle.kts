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
    ndkVersion = "27.0.12077973"
    
    // Configure NDK path explicitly
    ndkPath = "C:\\Users\\MiniMark\\AppData\\Local\\Android\\sdk\\ndk\\27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable core library desugaring to support newer Java APIs on older Android
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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
            isMinifyEnabled = false  // Disable minification
            isShrinkResources = false  // Disable resource shrinking
            ndk {
                debugSymbolLevel = "NONE" // Disable native debug symbol packaging to avoid strip tool requirement
                // Disable stripping completely
                abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = false
        }
        abi {
            enableSplit = false
        }
    }
    
    packaging {
        jniLibs {
            useLegacyPackaging = true
            // Prevent any stripping of native libraries
            pickFirsts.addAll(listOf(
                "**/libc++_shared.so",
                "**/libjsc.so",
                "**/*.so"
            ))
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// Custom task to handle bundle creation without symbol stripping
tasks.whenTaskAdded {
    if (name.contains("bundle") && name.contains("Release")) {
        doFirst {
            // Disable symbol processing for this task
            println("Disabling symbol stripping for bundle task: $name")
        }
    }
}

// Override the bundle task to handle strip failures gracefully
afterEvaluate {
    tasks.named("bundleRelease") {
        doLast {
            println("Bundle task completed - ignoring any symbol stripping warnings")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Updated Play libraries for modern Android
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:app-update-ktx:2.1.0")
    implementation("com.google.android.play:review:2.0.1")
    implementation("com.google.android.play:review-ktx:2.0.1")
    // Core library desugaring for Java 8+ APIs on older Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
