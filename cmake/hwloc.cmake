function(hwloc_setup_core prefix mode)

    # Print configuration message if provided
    if(ARGV3)
        message(STATUS "")
        message(STATUS "### Configuring hwloc core ###")
        message(STATUS "")
    endif()

    # If no prefix was defined, set a good value
    if(DEFINED prefix)
        set(HWLOC_CONFIG_PREFIX "${prefix}/")
    else()
        set(HWLOC_CONFIG_PREFIX ${CMAKE_BINARY_DIR})
    endif()

    if(NOT DEFINED HWLOC_MODE)
        set(HWLOC_MODE "embedded")
    endif()

    message(STATUS "Checking hwloc building mode: ${HWLOC_MODE}")

    set(HWLOC_TOP_BUILDDIR ${CMAKE_BINARY_DIR})
    set(HWLOC_TOP_SRCDIR ${CMAKE_SOURCE_DIR})

    message(STATUS "HWLOC builddir: ${HWLOC_TOP_BUILDDIR}")
    message(STATUS "HWLOC srcdir: ${HWLOC_TOP_SRCDIR}")

    if(NOT "${HWLOC_TOP_BUILDDIR}" STREQUAL "${HWLOC_TOP_SRCDIR}")
        MESSAGE(STATUS "Detected VPATH build")
    endif()

    # Get the version of hwloc that we are installing
    find_program(SH_PROGRAM NAMES bash sh)
    execute_process(
            COMMAND ${SH_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/config/hwloc_get_version.sh" "${CMAKE_CURRENT_SOURCE_DIR}/VERSION"
            OUTPUT_VARIABLE HWLOC_VERSION
            RESULT_VARIABLE HWLOC_GET_VERSION_RESULT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT HWLOC_GET_VERSION_RESULT EQUAL "0")
        message(FATAL_ERROR "Cannot continue")
    endif()

    message(STATUS "HWLOC version: ${HWLOC_VERSION}")

    set(HWLOC_VERSION "${HWLOC_VERSION}" CACHE INTERNAL "The library version, always available, even in embedded mode, contrary to VERSION")

    add_definitions(-DHWLOC_VERSION="${HWLOC_VERSION}")

    execute_process(
            COMMAND ${SH_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/config/hwloc_get_version.sh" "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" --major
            OUTPUT_VARIABLE HWLOC_VERSION_MAJOR
            RESULT_VARIABLE HWLOC_GET_VERSION_RESULT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(STRIP "${HWLOC_VERSION_MAJOR}" HWLOC_VERSION_MAJOR)
    add_definitions(-DHWLOC_VERSION_MAJOR=${HWLOC_VERSION_MAJOR})
    set(HWLOC_VERSION_MAJOR "${HWLOC_VERSION_MAJOR}" CACHE INTERNAL "Hwloc major version")

    execute_process(
            COMMAND ${SH_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/config/hwloc_get_version.sh" "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" --minor
            OUTPUT_VARIABLE HWLOC_VERSION_MINOR
            RESULT_VARIABLE HWLOC_GET_VERSION_RESULT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(STRIP "${HWLOC_VERSION_MINOR}" HWLOC_VERSION_MINOR)
    add_definitions(-DHWLOC_VERSION_MINOR=${HWLOC_VERSION_MINOR})
    set(HWLOC_VERSION_MINOR "${HWLOC_VERSION_MINOR}" CACHE INTERNAL "Hwloc Minor version")

    execute_process(
            COMMAND ${SH_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/config/hwloc_get_version.sh" "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" --release
            OUTPUT_VARIABLE HWLOC_VERSION_RELEASE
            RESULT_VARIABLE HWLOC_GET_VERSION_RESULT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(STRIP "${HWLOC_VERSION_RELEASE}" HWLOC_VERSION_RELEASE)
    add_definitions(-DHWLOC_VERSION_RELEASE=${HWLOC_VERSION_RELEASE})
    set(HWLOC_VERSION_RELEASE "${HWLOC_VERSION_RELEASE}" CACHE INTERNAL "Hwloc relese version")

    execute_process(
            COMMAND ${SH_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/config/hwloc_get_version.sh" "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" --greek
            OUTPUT_VARIABLE HWLOC_VERSION_GREEK
            RESULT_VARIABLE HWLOC_GET_VERSION_RESULT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(STRIP "${HWLOC_VERSION_GREEK}" HWLOC_VERSION_GREEK)
    add_definitions(-DHWLOC_VERSION_GREEK=${HWLOC_VERSION_GREEK})
    set(DHWLOC_VERSION_GREEK "${DHWLOC_VERSION_GREEK}" CACHE INTERNAL "Hwloc greek verson")

    execute_process(
            COMMAND ${SH_PROGRAM} "${CMAKE_CURRENT_SOURCE_DIR}/config/hwloc_get_version.sh" "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" --release-date
            OUTPUT_VARIABLE HWLOC_RELEASE_DATE
            RESULT_VARIABLE HWLOC_GET_VERSION_RESULT
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(STRIP "${HWLOC_RELEASE_DATE}" HWLOC_RELEASE_DATE)
    set(HWLOC_RELEASE_DATE "${HWLOC_RELEASE_DATE}" CACHE INTERNAL "Hwloc release date")

    # Unconditionally disable debug mode in embedded mode; if someone
    # asks, we can add a configure-time option for it.  Disable it
    # now, however, because --enable-debug is not even added as an
    # option when configuring in embedded mode, and we wouldn't want
    # to hijack the enclosing application's --enable-debug configure
    # switch.
    if(${HWLOC_MODE} STREQUAL "embedded")
        set(HWLOC_DEBUG 0 CACHE INTERNAL "")
        set(HWLOC_DEBUG_MSG "disabled (embedded mode)"  CACHE INTERNAL "")
    else()
        if(NOT DEFINED HWLOC_DEBUG AND enable_debug)
            set(HWLOC_DEBUG 1  CACHE INTERNAL "")
            set(HWLOC_DEBUG_MSG "enabled"  CACHE INTERNAL "")
        else()
            set(HWLOC_DEBUG 0  CACHE INTERNAL "")
            set(HWLOC_DEBUG_MSG "disabled" CACHE INTERNAL "")
        endif()
    endif()

    # Grr; we use #ifndef for HWLOC_DEBUG!  :-(
    if(HWLOC_DEBUG)
        add_definitions(HWLOC_DEBUG)
    endif()

    message(STATUS "${HWLOC_DEBUG_MSG}")

    # We need to set a path for header, etc files depending on whether
    # we're standalone or embedded. this is taken care of by HWLOC_EMBEDDED.
    if(DEFINED HWLOC_CONFIG_PREFIX)
        message(STATUS "HWLOC directory prefix: ${HWLOC_CONFIG_PREFIX}")
    else()
        message(STATUS "HWLOC directory prefix: (none)")
    endif()

    # What prefix are we using?
    if(NOT DEFINED HWLOC_SYMBOL_PREFIX_VALUE)
        if(NOT DEFINED WITH_HWLOC_SYMBOL_PREFIX)
            set(HWLOC_SYMBOL_PREFIX_VALUE "hwloc_")
        else()
            set(HWLOC_SYMBOL_PREFIX_VALUE "${HWLOC_SYMBOL_PREFIX}")
        endif()
    endif()

    add_definitions(-DHWLOC_SYM_PREFIX=${HWLOC_SYMBOL_PREFIX_VALUE})

    string(TOUPPER "${HWLOC_SYMBOL_PREFIX_VALUE}" HWLOC_SYMBOL_PREFIX_CAPS)
    add_definitions(-DHWLOC_SYM_PREFIX_CAPS=${HWLOC_SYMBOL_PREFIX_CAPS})
    message(STATUS ${HWLOC_SYMBOL_PREFIX_VALUE})

    # Give an easy #define to know if we need to transform all the
    # hwloc names
    if(NOT HWLOC_SYMBOL_PREFIX_VALUE STREQUAL "hwloc_")
        add_definitions(-DHWLOC_SYM_TRANSFORM=1)
        set(HWLOC_SYM_TRANSFORM 1 CACHE INTERNAL "Whether we need to re-define all the hwloc public symbols or not")
    else()
        add_definitions(-DHWLOC_SYM_TRANSFORM=0)
        set(HWLOC_SYM_TRANSFORM 0 CACHE INTERNAL "Whether we need to re-define all the hwloc public symbols or not")
    endif()

    project(hwloc
            LANGUAGES C
            VERSION ${HWLOC_VERSION_MAJOR}.${HWLOC_VERSION_MINOR}.${HWLOC_VERSION_RELEASE}
    )

    # hwloc 2.0+ requires a C99 compliant compiler
    set(CMAKE_C_STANDARD 99 CACHE INTERNAL "C99 standard")

    if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
        add_compile_options(-Wall -Wmissing-prototypes -Wundef -Wpointer-arith -Wcast-align)
    endif()

    # Enample system extensions for O_DIRECTORY, fdopen, fssl, etc.
    option(USE_HPUX_SYSTEM_EXTENSIONS "Enable extensions on HP-UX" ON)
    if(USE_HPUX_SYSTEM_EXTENSIONS)
        add_definitions(-D_HPUX_SOURCE)
        set(_HPUX_SOURCE 1 CACHE INTERNAL "HP-UX")
    endif()

    # Check to see if we're producing a 32 or 64 bit executable by
    # checking the sizeof void*.  Note that AC CHECK_SIZEOF even works
    # when cross compiling (!), according to the AC 2.64 docs.  This
    # check is needed because on some systems, you can instruct the
    # compiler to specifically build 32 or 64 bit executables -- even
    # though the $target may indicate something different.
    include(CheckTypeSize)
    check_type_size(void* SIZE_OF_VOID_PTR)

    #
    # List of components to be built, either statically or dynamically.
    # To be enlarged below.
    #
    set(HWLOC_COMPONENTS noos xml synthetic xml_nolibxml CACHE INTERNAL "Hwloc Components")

    message(STATUS "Checking which OS support to include")

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        add_definitions(-DHWLOC_LINUX_SYS=1)
        set(HWLOC_LINUX_SYS 1 CACHE INTERNAL "")
        set(HWLOC_HAVE_LINUX 1 CACHE INTERNAL "")
        message(STATUS "Linux")
        list(APPEND HWLOC_COMPONENTS linux)

        if(NOT DISABLE_IO)
            add_definitions(-DHWLOC_HAVE_LINUXIO=1)
            set(HWLOC_HAVE_LINUXIO 1 CACHE INTERNAL "")
            if(NOT DISABLE_IO)
                add_definitions(-DHWLOC_HAVE_LINUXPCI=1)
                set(HWLOC_HAVE_LINUXPCI 1 CACHE INTERNAL "")
            endif()
        endif()

    elseif(CMAKE_SYSTEM_NAME STREQUAL "IRIX")
        add_definitions(-DHWLOC_IRIX_SYS=1)
        set(HWLOC_IRIX_SYS 1 CACHE INTERNAL "")
        message(STATUS "IRIX")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        add_definitions(-DHWLOC_DARWIN_SYS=1)
        set(HWLOC_DARWIN_SYS 1 CACHE INTERNAL "")
        message(STATUS "Darwin")
        list(APPEND HWLOC_COMPONENTS darwin)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "Solaris")
        add_definitions(-DHWLOC_SOLARIS_SYS=1)
        set(HWLOC_SOLARIS_SYS 1 CACHE INTERNAL "")
        message(STATUS "Solaris")
        list(APPEND HWLOC_COMPONENTS solaris)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "AIX")
        add_definitions(-DHWLOC_AIX_SYS=1)
        set(HWLOC_AIX_SYS 1 CACHE INTERNAL "")
        message(STATUS "AIX")
        list(APPEND HWLOC_COMPONENTS aix)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "HP-UX")
        add_definitions(-DHWLOC_HPUX_SYS=1)
        set(HWLOC_HPUX_SYS 1 CACHE INTERNAL "")
        message(STATUS "HP-UX")
        list(APPEND HWLOC_COMPONENTS hpux)

    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
        add_definitions(-DHWLOC_WIN_SYS=1)
        set(HWLOC_WIN_SYS 1 CACHE INTERNAL "")
        message(STATUS "Windows")
        list(APPEND HWLOC_COMPONENTS windows)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
        add_definitions(-DHWLOC_FREEBSD_SYS=1)
        set(HWLOC_FREEBSD_SYS 1 CACHE INTERNAL "")
        message(STATUS "FreeBSD")
        list(APPEND HWLOC_COMPONENTS freebsd)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
        add_definitions(-DHWLOC_NETBSD_SYS=1)
        set(HWLOC_NETBSD_SYS 1 CACHE INTERNAL "")
        message(STATUS "NetBSD")
        list(APPEND HWLOC_COMPONENTS netbsd)

    else()
        message(STATUS "Unsupported! (${CMAKE_SYSTEM_NAME})")
        add_definitions(-DHWLOC_UNSUPPORTED_SYS=1)
        set(HWLOC_UNSUPPORTED_SYS 1 CACHE INTERNAL "")
        message(WARNING "***********************************************************")
        message(WARNING "*** hwloc does not support this system.")
        message(WARNING "*** hwloc will *attempt* to build (but it may not work).")
        message(WARNING "*** hwloc run-time results may be reduced to showing just one processor,")
        message(WARNING "*** and binding will not be supported.")
        message(WARNING "*** You have been warned.")
        message(WARNING "*** Pausing to give you time to read this message...")
        message(WARNING "***********************************************************")
        execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 10)
    endif()


    message(STATUS "Checking which CPU support to include")

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "i[3-9]86|amd64|x86_64")
        if(SIZE_OF_VOID_PTR EQUAL 4)
            add_definitions(-DHWLOC_X86_32_ARCH=1)
            set(HWLOC_X86_32_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X86" CACHE STRING "Library architecture for MS")
            message(STATUS "x86_32")
        elseif(SIZE_OF_VOID_PTR EQUAL 8)
            add_definitions(-DHWLOC_X86_64_ARCH=1)
            set(HWLOC_X86_64_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X64" CACHE STRING "Library architecture for MS")
            message(STATUS "x86_64")
        else()
            add_definitions(-DHWLOC_X86_64_ARCH=1)
            set(HWLOC_X86_64_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X64" CACHE STRING "Library architecture for MS")
            message(STATUS "unknown -- assuming x86_64")
        endif()
    else()
        message(STATUS "unknown")
    endif()

    set(HWLOC_MS_LIB_ARCH "${HWLOC_MS_LIB_ARCH}" CACHE INTERNAL "")

    check_type_size("unsigned long" SIZEOF_UNSIGNED_LONG)
    add_definitions(-DHWLOC_SIZEOF_UNSIGNED_LONG=${SIZEOF_UNSIGNED_LONG})
    set(HWLOC_SIZEOF_UNSIGNED_LONG ${SIZEOF_UNSIGNED_LONG} CACHE INTERNAL "")

    check_type_size("unsigned int" SIZEOF_UNSIGNED_INT)
    add_definitions(-DHWLOC_SIZEOF_UNSIGNED_INT=${SIZEOF_UNSIGNED_INT})
    set(HWLOC_SIZEOF_UNSIGNED_INT ${SIZEOF_UNSIGNED_INT} CACHE INTERNAL "")

    #
    # Check for compiler attributes and visibility
    #

    hwloc_check_attributes()

    # Note that private/config.h *MUST* be listed first so that it
    # becomes the "main" config header file.  Any AC-CONFIG-HEADERS
    # after that (hwloc/config.h) will only have selective #defines
    # replaced, not the entire file.
    configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/include/private/autogen/cmake_config.h.in"
            "${CMAKE_BINARY_DIR}/include/private/autogen/config.h"
    )

    configure_file(
            "${CMAKE_CURRENT_SOURCE_DIR}/include/hwloc/autogen/cmake_config.h.in"
            "${CMAKE_BINARY_DIR}/include/hwloc/autogen/config.h"
    )
endfunction()