# .msi for the Windows release runner directory (CPack + WiX v3). Driven by
# tool/ci/package_artifacts.sh --target windows; modelled on
# toxee/tool/ci/windows-installer.
cmake_minimum_required(VERSION 3.16)
project(ditmesh_windows_installer LANGUAGES NONE)

foreach(_var DITMESH_INSTALLER_SOURCE_DIR DITMESH_RELEASE_VERSION DITMESH_PACKAGE_ARCH)
  if(NOT DEFINED ${_var} OR "${${_var}}" STREQUAL "")
    message(FATAL_ERROR "${_var} is required")
  endif()
endforeach()
if(NOT EXISTS "${DITMESH_INSTALLER_SOURCE_DIR}/ditmesh.exe")
  message(FATAL_ERROR "No ditmesh.exe in ${DITMESH_INSTALLER_SOURCE_DIR}")
endif()

set(_app_dir "${CMAKE_CURRENT_LIST_DIR}/../../../apps/ditmesh")

# CPACK_PACKAGE_NAME is the WiX product name: what Add/Remove Programs shows.
# The .msi file name (CPACK_PACKAGE_FILE_NAME) and ditmesh.exe stay lowercase.
set(CPACK_PACKAGE_NAME "DitMesh")
set(CPACK_PACKAGE_VENDOR "agentx-icu")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Morse code chat with friends and groups over Tox")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/agentx-icu/ditmesh")
set(CPACK_PACKAGE_VERSION "${DITMESH_RELEASE_VERSION}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "DitMesh")
# Start-menu shortcut "DitMesh" -> ditmesh.exe
set(CPACK_PACKAGE_EXECUTABLES "ditmesh;DitMesh")
set(CPACK_PACKAGE_FILE_NAME "ditmesh-${DITMESH_RELEASE_VERSION}-windows-${DITMESH_PACKAGE_ARCH}")
set(CPACK_GENERATOR "WIX")
# LANGUAGES NONE leaves the pointer size unset, and CPack then builds an x86
# package into "Program Files (x86)"; the runner is x64.
set(CPACK_WIX_SIZEOF_VOID_P 8)
set(CPACK_WIX_ARCHITECTURE x64)
# Fixed forever: lets a newer .msi upgrade an installed older one in place.
set(CPACK_WIX_UPGRADE_GUID "DC44801B-6CC8-4DB9-A59F-5898EA7F0694")
set(CPACK_WIX_PRODUCT_ICON "${_app_dir}/windows/runner/resources/app_icon.ico")
set(CPACK_WIX_PROGRAM_MENU_FOLDER "DitMesh")
set(CPACK_WIX_PROPERTY_ARPURLINFOABOUT "https://github.com/agentx-icu/ditmesh")

# WiX wants the licence as .txt/.rtf.
file(READ "${CMAKE_CURRENT_LIST_DIR}/../../../LICENSE" _licence)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/LICENSE.txt" "${_licence}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_BINARY_DIR}/LICENSE.txt")

install(DIRECTORY "${DITMESH_INSTALLER_SOURCE_DIR}/" DESTINATION "." USE_SOURCE_PERMISSIONS)

include(CPack)
