import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "dev.aquiles.wheretofly"
    compileSdk = flutter.compileSdkVersion
    // NDK r28+ (from Flutter) compiles 16 KB-aligned ELF by default; required for Play on Android 15+.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.aquiles.wheretofly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    // AGP 8.5.1+ zip-aligns uncompressed JNI libs to 16 KB for app bundles.
    packaging {
        jniLibs {
            // Prefer app-local libwasm_run_dart.so (see scripts/rebuild_wasm_run_android_16k.sh).
            pickFirsts += listOf("**/libwasm_run_dart.so")
        }
    }
}

val wasmRun16kLibs =
    listOf(
        "src/main/jniLibs/arm64-v8a/libwasm_run_dart.so",
        "src/main/jniLibs/x86_64/libwasm_run_dart.so",
    )

tasks.register("checkWasmRun16kJniLibs") {
    group = "verification"
    description = "Ensures 16 KB-aligned wasm_run JNI libraries are present before release builds."
    doLast {
        val missing = wasmRun16kLibs.filter { !file(it).isFile }
        if (missing.isNotEmpty()) {
            error(
                "Missing 16 KB wasm_run libraries: ${missing.joinToString()}. " +
                    "Run: ./scripts/rebuild_wasm_run_android_16k.sh",
            )
        }
    }
}

tasks.configureEach {
    if (name == "assembleRelease" || name == "bundleRelease") {
        dependsOn("checkWasmRun16kJniLibs")
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
