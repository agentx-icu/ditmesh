import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ditmesh: bundle libtim2tox_ffi
// ---------------------------------------------------------------------------
// The Tox backend is libtim2tox_ffi.so, staged per ABI into
// src/main/jniLibs/<abi>/ by tool/build_android_ffi.sh (jniLibs is gitignored,
// so a fresh clone has none). Gradle packages whatever sits there, so this file
// (a) packages only the ABIs that actually have the library — otherwise
// Flutter's default ABI set ships slices where DynamicLibrary.open() fails at
// runtime, (b) fails fast when none is staged instead of shipping an APK that
// crashes on first chat use, and (c) byte-scans the staged .so for the
// Tim2Tox auto_tests-only hooks, the last point before they land in an APK.
// (Modelled on toxee/android/app/build.gradle.kts.)
//
// Escape hatch for UI-only builds (--dart-define=DITMESH_FAKE_BACKEND=true):
//   ./gradlew ... -PditmeshAllowMissingFfi=true   or   DITMESH_ALLOW_MISSING_FFI=1
val ditmeshRepoRoot: File = rootProject.file("../../..")

// The forbidden symbol NAMES are read out of tool/ci/assert_no_test_hooks.sh so
// there is exactly one list to maintain; done in Kotlin (not by shelling out)
// because an Android build must work on a host with no bash.
fun ditmeshForbiddenTestHookNames(): List<String> {
    val gate = File(ditmeshRepoRoot, "tool/ci/assert_no_test_hooks.sh")
    if (!gate.isFile) {
        throw GradleException(
            "tool/ci/assert_no_test_hooks.sh is missing — cannot verify that the " +
                "staged libtim2tox_ffi.so carries no test-only hook."
        )
    }
    val pattern = Regex("^FORBIDDEN_[A-Z_]*=\"([^\"\$]+)\"", RegexOption.MULTILINE)
    val names = pattern.findAll(gate.readText()).map { it.groupValues[1] }.toList()
    if (names.isEmpty()) {
        throw GradleException(
            "no FORBIDDEN_* names parsed from tool/ci/assert_no_test_hooks.sh — " +
                "the gate's format changed and this check would silently pass."
        )
    }
    return names
}

// Export names are plain ASCII in the ELF .dynstr, so a byte scan finds them;
// it errs towards failing (also matches a non-exported occurrence).
fun ditmeshAssertNoTestHooks(lib: File, forbidden: List<String>) {
    if (!lib.isFile) return
    val bytes = lib.readBytes()
    for (name in forbidden) {
        val needle = name.toByteArray(Charsets.US_ASCII)
        var i = 0
        outer@ while (i <= bytes.size - needle.size) {
            for (j in needle.indices) {
                if (bytes[i + j] != needle[j]) {
                    i++
                    continue@outer
                }
            }
            throw GradleException(
                "${lib.path} carries the TEST-ONLY tim2tox hook $name and must not be " +
                    "packaged. Rebuild with tool/build_android_ffi.sh (it passes " +
                    "-DTIM2TOX_ENABLE_TEST_HOOKS=OFF) or delete the staged artifact."
            )
        }
    }
}

fun ditmeshIsUnitTestOnlyInvocation(taskNames: List<String>): Boolean {
    if (taskNames.isEmpty()) return false
    return taskNames.all { taskName ->
        val lowerName = taskName.lowercase()
        lowerName == "test" || lowerName.endsWith(":test") || lowerName.contains("unittest")
    }
}

// Release signing, first match wins:
//  1. env DITMESH_ANDROID_KEYSTORE / _KEYSTORE_PASSWORD / _KEY_ALIAS /
//     _KEY_PASSWORD (CI, from repository secrets — passed verbatim, so a
//     password may contain any character);
//  2. android/key.properties (storeFile, storePassword, keyAlias, keyPassword;
//     gitignored), the usual Flutter setup for a local release build.
// Neither: signed with the debug key — installable for testing, not for a
// store, and not upgradable to/from a properly signed build.
val ditmeshSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val ditmeshReleaseSigning: Map<String, String>? = run {
    val env = mapOf(
        "storeFile" to "DITMESH_ANDROID_KEYSTORE",
        "storePassword" to "DITMESH_ANDROID_KEYSTORE_PASSWORD",
        "keyAlias" to "DITMESH_ANDROID_KEY_ALIAS",
        "keyPassword" to "DITMESH_ANDROID_KEY_PASSWORD",
    ).mapValues { System.getenv(it.value).orEmpty() }
    if (env.values.all { it.isNotEmpty() }) return@run env
    val file = rootProject.file("key.properties").takeIf { it.isFile } ?: return@run null
    val props = Properties().apply { file.inputStream().use { load(it) } }
    ditmeshSigningKeys.associateWith { props.getProperty(it).orEmpty() }
        .takeIf { keys -> keys.values.all { it.isNotEmpty() } }
        ?: throw GradleException("android/key.properties must set $ditmeshSigningKeys")
}

val ditmeshAllowMissingFfi: Boolean =
    (project.findProperty("ditmeshAllowMissingFfi")?.toString() == "true") ||
        (System.getenv("DITMESH_ALLOW_MISSING_FFI") == "1")

android {
    namespace = "icu.agentx.ditmesh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications >= 16 requires core-library desugaring
        // (java.time on API < 26). See lib/notifications/README.md.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Stable identity, independent from the MorseCQ learning app.
        applicationId = "icu.agentx.ditmesh"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ditmesh: bundle libtim2tox_ffi — package exactly the ABIs that have it.
        val ffiAbis = file("src/main/jniLibs").listFiles()
            ?.filter { it.isDirectory && it.resolve("libtim2tox_ffi.so").exists() }
            ?.map { it.name }?.sorted() ?: emptyList()
        val packaging = !ditmeshIsUnitTestOnlyInvocation(gradle.startParameter.taskNames)
        if (ffiAbis.isNotEmpty()) {
            ndk { abiFilters.addAll(ffiAbis) }
            if (packaging) {
                val forbidden = ditmeshForbiddenTestHookNames()
                for (abi in ffiAbis) {
                    ditmeshAssertNoTestHooks(file("src/main/jniLibs/$abi/libtim2tox_ffi.so"), forbidden)
                }
                logger.lifecycle("ditmesh: packaging libtim2tox_ffi.so for ABIs $ffiAbis")
            }
        } else if (packaging && !ditmeshAllowMissingFfi) {
            throw GradleException(
                "libtim2tox_ffi.so not found under apps/ditmesh/android/app/src/main/jniLibs/<abi>/ " +
                    "— run tool/build_android_ffi.sh (ABIS=\"arm64-v8a x86_64\" for emulators) " +
                    "before building the Android app, or pass -PditmeshAllowMissingFfi=true " +
                    "for a UI-only build with --dart-define=DITMESH_FAKE_BACKEND=true."
            )
        } else if (packaging) {
            logger.warn("ditmesh: no libtim2tox_ffi.so staged; building WITHOUT the Tox backend (ditmeshAllowMissingFfi)")
        }
    }

    signingConfigs {
        ditmeshReleaseSigning?.let { keys ->
            create("release") {
                storeFile = file(keys.getValue("storeFile"))
                storePassword = keys.getValue("storePassword")
                keyAlias = keys.getValue("keyAlias")
                keyPassword = keys.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (ditmeshReleaseSigning != null) "release" else "debug",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Pairs with isCoreLibraryDesugaringEnabled above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
