plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigning = listOf(
    "PIXELSEARCH_KEYSTORE_PATH",
    "PIXELSEARCH_KEYSTORE_PASSWORD",
    "PIXELSEARCH_KEY_ALIAS",
    "PIXELSEARCH_KEY_PASSWORD",
).associateWith { providers.environmentVariable(it).orNull }

android {
    namespace = "com.pixelsearch.pixelsearch"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pixelsearch.pixelsearch"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseSigning["PIXELSEARCH_KEYSTORE_PATH"]?.let { file(it) }
            storePassword = releaseSigning["PIXELSEARCH_KEYSTORE_PASSWORD"]
            keyAlias = releaseSigning["PIXELSEARCH_KEY_ALIAS"]
            keyPassword = releaseSigning["PIXELSEARCH_KEY_PASSWORD"]
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

val validateReleaseCredentials by tasks.registering {
    doLast {
        val missing = releaseSigning.filterValues { it.isNullOrBlank() }.keys
        check(missing.isEmpty()) {
            "Release signing is not configured. Set ${missing.joinToString()}. " +
                "Debug signing is never used for release. See docs/ANDROID_RELEASE_SIGNING.md."
        }
    }
}

tasks.configureEach {
    if (name in setOf("preReleaseBuild", "validateSigningRelease", "packageRelease",
            "packageReleaseBundle", "signReleaseBundle", "assembleRelease", "bundleRelease")) {
        dependsOn(validateReleaseCredentials)
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
