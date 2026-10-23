# JNI arrives through Android-only federated implementations (path_provider).
# DitMesh has no Java feature on Linux/Windows. jni's upstream Flutter CMake
# builds/bundles libdartjni only when an incidental host JDK is discoverable.
# Disable that optional discovery before generated plugins are configured;
# Android's JNI build and every other desktop native asset remain unchanged.
# A future desktop Java feature must explicitly declare/package its JVM runtime
# and restore JNI only with final installed dependency/lifecycle evidence.
set(CMAKE_DISABLE_FIND_PACKAGE_JNI TRUE)
