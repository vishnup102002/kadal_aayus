// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "com.kadal.aayus"
    compileSdk = flutter.compileSdkVersion.toInt()

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.kadal.aayus"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion.toInt()
        versionCode = (localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1)
        versionName = localProperties.getProperty("flutter.versionName")

        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ FINAL FIX: Updated to the version required by your plugins.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
}
