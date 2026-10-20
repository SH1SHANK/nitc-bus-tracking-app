import java.io.File
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Evaluate CI environment and strict signing enforcement
val isCi = System.getenv("CI") == "true"
val allowUnsigned = System.getenv("ALLOW_UNSIGNED") == "true" || project.hasProperty("allowUnsigned")
val isStrictSigning = (isCi && !allowUnsigned) || project.hasProperty("strictSigning")
val envStorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val envKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
val hasPropertiesSigning = keystorePropertiesFile.exists() && keystoreProperties.containsKey("storeFile")
val hasEnvSigning = !envStorePath.isNullOrBlank() && !envKeyAlias.isNullOrBlank()
val hasReleaseSigning = hasPropertiesSigning || hasEnvSigning

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "in.ac.nitc.tracklet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "in.ac.nitc.tracklet"
        minSdk = flutter.minSdkVersion.coerceAtLeast(24)
        targetSdk = flutter.targetSdkVersion.coerceAtLeast(35)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                val sFile = if (hasPropertiesSigning) {
                    keystoreProperties["storeFile"] as String
                } else {
                    envStorePath!!
                }
                val rawFile = File(sFile)
                val resolvedFile = if (rawFile.isAbsolute) {
                    rawFile
                } else {
                    val rootCandidate = File(rootProject.projectDir, sFile)
                    if (rootCandidate.exists()) rootCandidate else File(projectDir, sFile)
                }
                storeFile = resolvedFile
                storePassword = if (hasPropertiesSigning) {
                    keystoreProperties["storePassword"] as String
                } else {
                    System.getenv("ANDROID_STORE_PASSWORD") ?: System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
                }
                keyAlias = if (hasPropertiesSigning) {
                    keystoreProperties["keyAlias"] as String
                } else {
                    envKeyAlias!!
                }
                keyPassword = if (hasPropertiesSigning) {
                    keystoreProperties["keyPassword"] as String
                } else {
                    System.getenv("ANDROID_KEY_PASSWORD") ?: ""
                }
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (isStrictSigning) {
                val isReleaseBuildRequested = gradle.startParameter.taskNames.any {
                    it.contains("Release", ignoreCase = true) || it.contains("bundle", ignoreCase = true)
                }
                if (isReleaseBuildRequested) {
                    throw GradleException(
                        "Production release build failed: Missing release signing configuration.\n" +
                        "CI builds strictly require signing credentials via android/key.properties or environment variables\n" +
                        "(ANDROID_KEYSTORE_BASE64 / ANDROID_KEYSTORE_PATH, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD, ANDROID_STORE_PASSWORD).\n" +
                        "Debug signing fallback is strictly prohibited in CI."
                    )
                } else {
                    logger.warn("WARNING: Non-release task requested without signing credentials. Falling back to debug signing for configuration.")
                    signingConfig = signingConfigs.getByName("debug")
                }
            } else {
                logger.warn("WARNING: Building release variant with debug signing for local testing. For production builds, configure android/key.properties.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.10.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.1")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
