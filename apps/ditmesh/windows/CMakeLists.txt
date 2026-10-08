# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(ditmesh LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "ditmesh")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# ditmesh only plays a generated sine wave through flutter_soloud and never
# decodes Opus/Ogg/Vorbis/FLAC. Without this the plugin links and bundles its
# prebuilt Xiph libraries -- on Linux a libopus.so.0 that needs glibc 2.43, so
# the plugin fails to load on Ubuntu 24.04 (glibc 2.39). The plugin's
# CMakeLists reads this from the environment of the configure run.
set(ENV{NO_XIPH_LIBS} 1)

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

# ditmesh: bundle libtim2tox_ffi
# ---------------------------------------------------------------------------
# Install tim2tox_ffi.dll and the runtime DLLs it imports (vcpkg libsodium.dll,
# pthreadVC3.dll) next to ditmesh.exe; Tim2Tox's Dart loader probes the
# executable directory first. Source: tool/ci/build_tim2tox.sh --target
# windows-<x64|arm64> -> <repo>/build/native/windows-<arch>/ (DITMESH_NATIVE_DIR
# overrides). Falls back to $ENV{VCPKG_ROOT}/installed/<triplet>/bin for the
# dependency DLLs. A missing transitive DLL makes LoadLibrary fail with error
# 126 even though tim2tox_ffi.dll is present. (Mirrors toxee/windows/CMakeLists.txt.)
if(CMAKE_GENERATOR_PLATFORM MATCHES "[Aa][Rr][Mm]64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64|aarch64")
  set(_DITMESH_NATIVE_ARCH "arm64")
  set(_DITMESH_VCPKG_TRIPLET "arm64-windows")
else()
  set(_DITMESH_NATIVE_ARCH "x64")
  set(_DITMESH_VCPKG_TRIPLET "x64-windows")
endif()
set(DITMESH_NATIVE_DIR
  "${CMAKE_SOURCE_DIR}/../../../build/native/windows-${_DITMESH_NATIVE_ARCH}"
  CACHE PATH "Directory holding tim2tox_ffi.dll (output of tool/ci/build_tim2tox.sh)")
if(DEFINED ENV{DITMESH_NATIVE_DIR})
  set(DITMESH_NATIVE_DIR "$ENV{DITMESH_NATIVE_DIR}")
endif()

# Install the first existing candidate; sets ditmesh_install_first_existing_result.
function(ditmesh_install_first_existing _label)
  set(_hit "")
  foreach(_f IN LISTS ARGN)
    if(EXISTS "${_f}")
      set(_hit "${_f}")
      break()
    endif()
  endforeach()
  if(_hit)
    install(FILES "${_hit}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
    message(STATUS "ditmesh: bundling ${_label} from ${_hit}")
  endif()
  set(ditmesh_install_first_existing_result "${_hit}" PARENT_SCOPE)
endfunction()

ditmesh_install_first_existing("tim2tox_ffi.dll" "${DITMESH_NATIVE_DIR}/tim2tox_ffi.dll")
if(NOT ditmesh_install_first_existing_result)
  if("$ENV{DITMESH_ALLOW_MISSING_FFI}" STREQUAL "1")
    message(WARNING "DitMesh UI test build has no tim2tox_ffi.dll.")
  else()
    message(FATAL_ERROR "DitMesh requires tim2tox_ffi.dll in ${DITMESH_NATIVE_DIR}. "
      "Run tool/ci/build_tim2tox.sh --target windows before building.")
  endif()
endif()
if(EXISTS "${DITMESH_NATIVE_DIR}/tim2tox_ffi.pdb")
  install(FILES "${DITMESH_NATIVE_DIR}/tim2tox_ffi.pdb" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    CONFIGURATIONS Debug;Profile COMPONENT Runtime)
endif()

set(_ditmesh_dep_dll_dirs "${DITMESH_NATIVE_DIR}")
if(DEFINED ENV{VCPKG_ROOT})
  list(APPEND _ditmesh_dep_dll_dirs "$ENV{VCPKG_ROOT}/installed/${_DITMESH_VCPKG_TRIPLET}/bin")
endif()
foreach(_dep_dll IN ITEMS libsodium.dll pthreadVC3.dll)
  set(_cands "")
  foreach(_d IN LISTS _ditmesh_dep_dll_dirs)
    list(APPEND _cands "${_d}/${_dep_dll}")
  endforeach()
  ditmesh_install_first_existing("${_dep_dll}" ${_cands})
  if(_dep_dll STREQUAL "libsodium.dll" AND
     EXISTS "${DITMESH_NATIVE_DIR}/tim2tox_ffi.dll" AND
     NOT ditmesh_install_first_existing_result)
    message(FATAL_ERROR "DitMesh requires the libsodium.dll runtime beside tim2tox_ffi.dll.")
  endif()
endforeach()
