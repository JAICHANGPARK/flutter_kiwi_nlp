# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "flutter_kiwi_nlp")
project(${PROJECT_NAME} LANGUAGES CXX)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory(
  "${CMAKE_CURRENT_SOURCE_DIR}/../src"
  "${CMAKE_CURRENT_BINARY_DIR}/shared"
)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(flutter_kiwi_nlp_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:flutter_kiwi_ffi>
)

# Build Kiwi core library for Windows when needed, then bundle it.
set(FLUTTER_KIWI_NLP_PREBUILT_DLL
  "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/kiwi.dll"
)
set(FLUTTER_KIWI_NLP_WINDOWS_BUILD_SCRIPT
  "${CMAKE_CURRENT_SOURCE_DIR}/../tool/build_windows_kiwi_dll.ps1"
)

if(CMAKE_GENERATOR_PLATFORM)
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "${CMAKE_GENERATOR_PLATFORM}")
elseif(DEFINED ENV{Platform})
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "$ENV{Platform}")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "x64")
else()
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "Win32")
endif()

string(TOLOWER "${FLUTTER_KIWI_NLP_WINDOWS_ARCH}"
  FLUTTER_KIWI_NLP_WINDOWS_ARCH_LOWER
)
if(FLUTTER_KIWI_NLP_WINDOWS_ARCH_LOWER STREQUAL "amd64")
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "x64")
elseif(FLUTTER_KIWI_NLP_WINDOWS_ARCH_LOWER STREQUAL "x86_64")
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "x64")
elseif(FLUTTER_KIWI_NLP_WINDOWS_ARCH_LOWER STREQUAL "x86")
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "Win32")
elseif(FLUTTER_KIWI_NLP_WINDOWS_ARCH_LOWER STREQUAL "arm64")
  set(FLUTTER_KIWI_NLP_WINDOWS_ARCH "arm64")
endif()

add_custom_command(
  OUTPUT "${FLUTTER_KIWI_NLP_PREBUILT_DLL}"
  COMMAND powershell -NoProfile -ExecutionPolicy Bypass
    -File "${FLUTTER_KIWI_NLP_WINDOWS_BUILD_SCRIPT}"
    -Arch "${FLUTTER_KIWI_NLP_WINDOWS_ARCH}"
  DEPENDS "${FLUTTER_KIWI_NLP_WINDOWS_BUILD_SCRIPT}"
  COMMENT "[windows] Preparing Kiwi shared library (kiwi.dll)"
  VERBATIM
)

add_custom_target(prepare_kiwi_windows_dll
  DEPENDS "${FLUTTER_KIWI_NLP_PREBUILT_DLL}"
)
add_dependencies(flutter_kiwi_ffi prepare_kiwi_windows_dll)

list(APPEND flutter_kiwi_nlp_bundled_libraries
  "${FLUTTER_KIWI_NLP_PREBUILT_DLL}"
)

set(flutter_kiwi_nlp_bundled_libraries
  "${flutter_kiwi_nlp_bundled_libraries}"
  PARENT_SCOPE
)
