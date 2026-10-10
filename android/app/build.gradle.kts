import java.io.InputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.healthbase.healthbase"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.healthbase.healthbase"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing: CI env wins, then android/key.properties (local,
    // git-ignored), then debug keys so local builds never break. CI must
    // decode the HB_KEYSTORE_BASE64 secret to a file and export
    // HB_KEYSTORE_FILE_PATH, HB_STORE_PASSWORD, HB_KEY_ALIAS,
    // HB_KEY_PASSWORD to ship store-ready builds.
    val keystoreProps = Properties()
    val keystorePropsFile = rootProject.file("key.properties")
    if (keystorePropsFile.exists()) {
        keystorePropsFile.inputStream().use { stream: InputStream ->
            keystoreProps.load(stream)
        }
    }

    fun envOrProp(name: String, propName: String): String? {
        val fromEnv: String? = System.getenv(name)
        if (fromEnv != null && fromEnv.isNotBlank()) return fromEnv
        val fromFile: String? = keystoreProps.getProperty(propName)
        if (fromFile != null && fromFile.isNotBlank()) return fromFile
        return null
    }

    val releaseStoreFile = envOrProp("HB_KEYSTORE_FILE_PATH", "storeFile")
    val hasReleaseKeys = envOrProp("HB_STORE_PASSWORD", "storePassword") != null &&
        envOrProp("HB_KEY_PASSWORD", "keyPassword") != null &&
        envOrProp("HB_KEY_ALIAS", "keyAlias") != null &&
        releaseStoreFile != null

    if (hasReleaseKeys) {
        signingConfigs.create("release") {
            // Non-null: guarded by hasReleaseKeys above.
            storeFile = file(releaseStoreFile!!)
            storePassword = envOrProp("HB_STORE_PASSWORD", "storePassword")!!
            keyAlias = envOrProp("HB_KEY_ALIAS", "keyAlias")!!
            keyPassword = envOrProp("HB_KEY_PASSWORD", "keyPassword")!!
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeys) {
                signingConfigs.getByName("release")
            } else {
                // Local fallback only; CI uses real keys (see above).
                signingConfigs.getByName("debug")
            }
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
