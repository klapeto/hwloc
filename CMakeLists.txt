cmake_minimum_required(VERSION 3.24)

project(hwloc
        LANGUAGES C
)

find_program(SH_PROGRAM NAMES bash sh)

include(cmake/hwloc_internal.cmake)
include(cmake/hwloc.cmake)
include(cmake/hwloc_check_attributes.cmake)
include(cmake/hwloc_check_vendor.cmake)
include(cmake/hwloc_check_visibility.cmake)
include(cmake/hwloc_pkg.cmake)
include(cmake/hwloc_components.cmake)

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
        hwloc_build_standalone()
    endif ()
endif ()

####################################################################
# Setup for the hwloc API
####################################################################
# Setup the hwloc core
hwloc_setup_core("" "" "")

####################################################################
# Version information
####################################################################

# HWLOC_VERSION was setup by HWLOC_SETUP_CORE above.

# Override/fixup the version numbers set by AC_INIT, since on
# developer builds, there's no good way to know what the version is
# before running configure :(.  We only use the base version number
# for the version set in AC_INIT.  This will always match reality
# because we add the VERSION file (the only way to change the
# major.minor.release{greek}) into the configure dependencies.
set(PACKAGE_VERSION "${HWLOC_VERSION}")
set(PACKAGE_STRING "${PACKAGE_NAME} ${PACKAGE_VERSION}")
set(VERSION "${PACKAGE_NAME} ${PACKAGE_VERSION}")

# For standalone configurations, we also include a .so version number.

include(VERSION.cmake)

string(REPLACE ":" ";" libhwloc_so_version_list ${libhwloc_so_version})
list(GET libhwloc_so_version_list 0 libhwloc_so_version_current)
list(GET libhwloc_so_version_list 2 libhwloc_so_version_age)
math(EXPR libhwloc_so_name "${libhwloc_so_version_current} - ${libhwloc_so_version_age}")

####################################################################
# Setup the rest of the infrastructure
####################################################################

# Setup hwloc's docs, utils, and tests
if (hwloc_mode STREQUAL "standalone")
    # TODO: Setup docs and test
    hwloc_setup_utils()
endif ()



#add_executable(testPr test_visibility.c)
#target_link_options(testPr PRIVATE -fvisibility=hidden -Werror)
#target_compile_options(testPr PRIVATE -fvisibility=hidden -Werror)