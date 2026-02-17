# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

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

# Build Kiwi core library for Linux when needed, then bundle it.
set(FLUTTER_KIWI_NLP_PREBUILT_SO
  "${CMAKE_CURRENT_SOURCE_DIR}/prebuilt/libkiwi.so"
)
set(FLUTTER_KIWI_NLP_LINUX_BUILD_SCRIPT
  "${CMAKE_CURRENT_SOURCE_DIR}/../tool/build_linux_libkiwi.sh"
)

set(FLUTTER_KIWI_NLP_LINUX_ARCH "${CMAKE_SYSTEM_PROCESSOR}")
string(TOLOWER "${FLUTTER_KIWI_NLP_LINUX_ARCH}" FLUTTER_KIWI_NLP_LINUX_ARCH)
if(FLUTTER_KIWI_NLP_LINUX_ARCH STREQUAL "amd64")
  set(FLUTTER_KIWI_NLP_LINUX_ARCH "x86_64")
elseif(FLUTTER_KIWI_NLP_LINUX_ARCH STREQUAL "aarch64")
  set(FLUTTER_KIWI_NLP_LINUX_ARCH "arm64")
endif()

add_custom_command(
  OUTPUT "${FLUTTER_KIWI_NLP_PREBUILT_SO}"
  COMMAND bash "${FLUTTER_KIWI_NLP_LINUX_BUILD_SCRIPT}"
    --arch "${FLUTTER_KIWI_NLP_LINUX_ARCH}"
  DEPENDS "${FLUTTER_KIWI_NLP_LINUX_BUILD_SCRIPT}"
  COMMENT "[linux] Preparing Kiwi shared library (libkiwi.so)"
  VERBATIM
)

add_custom_target(prepare_kiwi_linux_lib
  DEPENDS "${FLUTTER_KIWI_NLP_PREBUILT_SO}"
)
add_dependencies(flutter_kiwi_ffi prepare_kiwi_linux_lib)

list(APPEND flutter_kiwi_nlp_bundled_libraries
  "${FLUTTER_KIWI_NLP_PREBUILT_SO}"
)

set(flutter_kiwi_nlp_bundled_libraries
  "${flutter_kiwi_nlp_bundled_libraries}"
  PARENT_SCOPE
)
