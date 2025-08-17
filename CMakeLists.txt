cmake_minimum_required(VERSION 3.24)

find_program(SH_PROGRAM NAMES bash sh)

include(cmake/hwloc_internal.cmake)
include(cmake/hwloc.cmake)
include(cmake/hwloc_check_attributes.cmake)
include(cmake/hwloc_check_vendor.cmake)
include(cmake/hwloc_check_visibility.cmake)

enable_testing()

hwloc_define_args()

if (ENABLE_DEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
endif()

if (NOT ${ENABLE_EMBEDDED_MODE})
    if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/doc")
        message(WARNING "The hwloc source tree looks incomplete for a standalone build.")
        message(WARNING "Perhaps this hwloc tree is intended for an embedded build?")
        message(WARNING "Try using the --enable-embedded-mode switch.")
        message(FATAL_ERROR "Cannot build standalone hwloc")
    else ()
        set(HWLOC_BUILD_STANDALONE ON)
        set(HWLOC_MODE standalone)
    endif ()
endif ()

hwloc_setup_core("" "")

project(hwloc
        LANGUAGES C
        VERSION ${HWLOC_VERSION_MAJOR}.${HWLOC_VERSION_MINOR}.${HWLOC_VERSION_RELEASE}
)

#add_executable(testPr test_visibility.c)
#target_link_options(testPr PRIVATE -fvisibility=hidden -Werror)
#target_compile_options(testPr PRIVATE -fvisibility=hidden -Werror)