import com.android.apksig.ApkVerifier
import com.android.build.api.artifact.SingleArtifact
import com.android.build.api.variant.BuiltArtifactsLoader
import org.gradle.process.ExecOperations
import java.util.Properties
import javax.inject.Inject
import javax.naming.ldap.LdapName

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
// Distribution requires the environment settings. A local store build accepts
// either source. Without either setting, validation uses the debug key.
val ditmeshDistribution = System.getenv("DITMESH_DISTRIBUTION") == "1"
val storeRelease = project.hasProperty("storeRelease")
val ditmeshSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val ditmeshReleaseSigning: Map<String, String>? = run {
    val env = mapOf(
        "storeFile" to "DITMESH_ANDROID_KEYSTORE",
        "storePassword" to "DITMESH_ANDROID_KEYSTORE_PASSWORD",
        "keyAlias" to "DITMESH_ANDROID_KEY_ALIAS",
        "keyPassword" to "DITMESH_ANDROID_KEY_PASSWORD",
    ).mapValues { System.getenv(it.value).orEmpty() }
    if (env.values.all { it.isNotEmpty() }) return@run env
    if (env.values.any { it.isNotEmpty() }) {
        throw GradleException("Partial DITMESH_ANDROID_* signing configuration; refusing fallback")
    }
    if (ditmeshDistribution) {
        throw GradleException("Distribution requires complete DITMESH_ANDROID_* release signing")
    }
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
    // SDK levels are pinned here rather than taken from the Flutter Gradle
    // plugin, so a Flutter upgrade cannot move them silently. Raise all three
    // together and update doc/release/APP_STORE.md; test/platform/
    // mobile_platform_config_test.dart pins the values. targetSdk 36 is what
    // Play requires for new apps and updates since 2026-08-31 (Flutter 3.41.9
    // defaults to the same three values).
    compileSdk = 36
    // Flutter's NDK (28.2 on 3.41.9) links plugin C/C++ 16 KB page-aligned by
    // default; libtim2tox_ffi.so is linked and checked by
    // tool/ci/build_tim2tox.sh. Never pin this below r28.
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
        // minSdk 24: Flutter 3.41's floor and the level NetworkPathChannel's
        // registerDefaultNetworkCallback needs. targetSdk 36: see compileSdk.
        minSdk = 24
        targetSdk = 36
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
            signingConfig = when {
                ditmeshReleaseSigning != null -> signingConfigs.getByName("release")
                storeRelease -> throw GradleException(
                    "Store release requires the DITMESH_ANDROID_* signing keys " +
                        "(env or android/key.properties); refusing to sign with the debug key"
                )
                else -> signingConfigs.getByName("debug")
            }
        }
    }
}

abstract class VerifyStoreApkSigning : DefaultTask() {
    @get:InputDirectory
    abstract val apkDirectory: DirectoryProperty

    @get:Internal
    abstract val artifactLoader: Property<BuiltArtifactsLoader>

    @TaskAction
    fun verify() {
        val artifacts = artifactLoader.get().load(apkDirectory.get())
            ?: throw GradleException("Missing store APK output metadata")
        if (artifacts.elements.isEmpty()) throw GradleException("No store APKs were built")

        for (artifact in artifacts.elements) {
            val apk = File(artifact.outputFile)
            val result = ApkVerifier.Builder(apk).build().verify()
            if (!result.isVerified || result.signerCertificates.isEmpty()) {
                throw GradleException("Could not verify store APK signature for ${apk.name}")
            }
            val certificates = result.signerCertificates +
                result.signingCertificateLineage?.certificatesInLineage.orEmpty()
            val hasDebugSigner = certificates.any { certificate ->
                LdapName(certificate.subjectX500Principal.name).rdns.any { rdn ->
                    rdn.toAttributes().get("CN")?.get()?.toString()
                        .equals("Android Debug", ignoreCase = true)
                }
            }
            if (hasDebugSigner) {
                throw GradleException("Android Debug certificate cannot sign a store APK (${apk.name})")
            }
        }
    }
}

abstract class VerifyStoreBundleSigning @Inject constructor(
    private val execOperations: ExecOperations,
) : DefaultTask() {
    @get:InputFile
    abstract val bundle: RegularFileProperty

    @get:InputFile
    abstract val verifier: RegularFileProperty

    @get:OutputFile
    abstract val verifiedBundle: RegularFileProperty

    @TaskAction
    fun verify() {
        val source = bundle.get().asFile
        val output = verifiedBundle.get().asFile
        val javaBin = File(System.getProperty("java.home"), "bin")
        val java = javaBin.resolve("java").takeIf { it.isFile } ?: javaBin.resolve("java.exe")
        if (output.exists() && !output.delete()) {
            throw GradleException("Could not remove the previous verified store AAB")
        }
        execOperations.exec {
            commandLine(java, verifier.get().asFile, source, "--reject-debug")
        }
        source.copyTo(output)
    }
}

if (storeRelease || ditmeshDistribution) {
    androidComponents.onVariants(androidComponents.selector().withBuildType("release")) { variant ->
        val verification = tasks.register<VerifyStoreApkSigning>(
            variant.computeTaskName("verify", "StoreApkSigning"),
        ) {
            apkDirectory.set(variant.artifacts.get(SingleArtifact.APK))
            artifactLoader.set(variant.artifacts.getBuiltArtifactsLoader())
        }
        // Run after AGP packages every APK and before Flutter copies the outputs.
        val assembleTask = "assemble${variant.name.replaceFirstChar { it.uppercaseChar() }}"
        tasks.matching { it.name == assembleTask }.configureEach {
            dependsOn(verification)
        }

        val bundleVerification = tasks.register<VerifyStoreBundleSigning>(
            variant.computeTaskName("verify", "StoreBundleSigning"),
        ) {
            verifier.set(ditmeshRepoRoot.resolve("tool/ci/VerifyAndroidBundle.java"))
        }
        variant.artifacts.use(bundleVerification)
            .wiredWithFiles(VerifyStoreBundleSigning::bundle, VerifyStoreBundleSigning::verifiedBundle)
            .toTransform(SingleArtifact.BUNDLE)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Pairs with isCoreLibraryDesugaringEnabled above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
