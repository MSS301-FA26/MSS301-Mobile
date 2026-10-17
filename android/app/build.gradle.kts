plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mss301_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mss301_mobile"
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

// Make plain `flutter run` reach the host gateway through localhost on Android.
// This runs only for debug builds and is repeated after emulator restarts.
val localGatewayAdb = androidComponents.sdkComponents.adb
val forwardLocalGateway = tasks.register("forwardLocalGateway") {
    doLast {
        val adb = localGatewayAdb.get().asFile.absolutePath
        fun adbOutput(vararg arguments: String): Pair<Int, String> {
            val process = ProcessBuilder(listOf(adb) + arguments)
                .redirectErrorStream(true).start()
            val output = process.inputStream.bufferedReader().use { it.readText() }
            return process.waitFor() to output
        }
        val (status, devices) = adbOutput("devices")
        if (status != 0) {
            logger.warn("Cannot set up local gateway forwarding: $devices")
        } else {
            val requestedDevice = System.getenv("ANDROID_SERIAL")
            devices.lineSequence()
                .map { it.trim().split(Regex("\\s+")) }
                .filter { it.size == 2 && it[1] == "device" }
                .filter { requestedDevice.isNullOrBlank() || it[0] == requestedDevice }
                .forEach { device ->
                    val (result, output) = adbOutput("-s", device[0], "reverse", "tcp:8080", "tcp:8080")
                    if (result == 0) {
                        logger.lifecycle("Local gateway: ${device[0]} localhost:8080 -> host:8080")
                    } else {
                        logger.warn("Cannot forward local gateway for ${device[0]}: $output")
                    }
                }
        }
    }
}
tasks.matching { it.name == "preDebugBuild" }.configureEach {
    dependsOn(forwardLocalGateway)
}
