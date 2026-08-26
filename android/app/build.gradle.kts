plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.techmirus.fsd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // Required so SharedStoreProvider can read BuildConfig.SHARED_STORE_KEY.
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.techmirus.fsd"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // MMKV encryption key for the shared store. Empty locally (store is
        // written unencrypted); injected in CI via -PSHARED_STORE_KEY=... or
        // the SHARED_STORE_KEY environment variable. Never commit a real key.
        val sharedStoreKey = (project.findProperty("SHARED_STORE_KEY") as String?)
            ?: System.getenv("SHARED_STORE_KEY")
            ?: ""
        buildConfigField("String", "SHARED_STORE_KEY", "\"$sharedStoreKey\"")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backing store for SharedStoreProvider. Only FSD links MMKV — QT and LT
    // reach the store through the provider and have no MMKV dependency.
    implementation("com.tencent:mmkv:2.4.2")
}
