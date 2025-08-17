# HWLOC_CHECK_DECL
#
# Check that the declaration of the given function has a complete prototype
# with argument list by trying to call it with an insane dnl number of
# arguments (10). Success means the compiler couldn't really check.
function(hwloc_check_decl name variable)
    message(CHECK_START "Checking whether function ${name} has a complete prototype")
    check_function_exists(${name} ${name}_EXISTS)

    if (${name}_EXISTS)
        set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
        set(CMAKE_REQUIRED_QUIET TRUE)

        check_c_source_compiles("
            ${ARGV2}
            ${name}(1,2,3,4,5,6,7,8,9,10);"
                COMPILES
        )

        if (COMPILES)
            message(CHECK_PASS No)
        else ()
            message(CHECK_PASS Yes)
            set(${variable} 1 CACHE INTERNAL "")
        endif ()
    else ()
        message(CHECK_PASS No)
    endif ()
endfunction()

function(hwloc_setup_core prefix mode)
    include(CheckFunctionExists)
    include(CheckTypeSize)

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

    message(CHECK_START "Checking which OS support to include")

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        add_definitions(-DHWLOC_LINUX_SYS=1)
        set(HWLOC_LINUX_SYS 1 CACHE INTERNAL "")
        set(HWLOC_HAVE_LINUX 1 CACHE INTERNAL "")
        message(CHECK_PASS "Linux")
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
        message(CHECK_PASS "IRIX")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        add_definitions(-DHWLOC_DARWIN_SYS=1)
        set(HWLOC_DARWIN_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "Darwin")
        list(APPEND HWLOC_COMPONENTS darwin)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "Solaris")
        add_definitions(-DHWLOC_SOLARIS_SYS=1)
        set(HWLOC_SOLARIS_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "Solaris")
        list(APPEND HWLOC_COMPONENTS solaris)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "AIX")
        add_definitions(-DHWLOC_AIX_SYS=1)
        set(HWLOC_AIX_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "AIX")
        list(APPEND HWLOC_COMPONENTS aix)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "HP-UX")
        add_definitions(-DHWLOC_HPUX_SYS=1)
        set(HWLOC_HPUX_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "HP-UX")
        list(APPEND HWLOC_COMPONENTS hpux)

    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
        add_definitions(-DHWLOC_WIN_SYS=1)
        set(HWLOC_WIN_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "Windows")
        list(APPEND HWLOC_COMPONENTS windows)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
        add_definitions(-DHWLOC_FREEBSD_SYS=1)
        set(HWLOC_FREEBSD_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "FreeBSD")
        list(APPEND HWLOC_COMPONENTS freebsd)

    elseif(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
        add_definitions(-DHWLOC_NETBSD_SYS=1)
        set(HWLOC_NETBSD_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "NetBSD")
        list(APPEND HWLOC_COMPONENTS netbsd)

    else()
        message(CHECK_FAIL "Unsupported! (${CMAKE_SYSTEM_NAME})")
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


    message(CHECK_START "Checking which CPU support to include")

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "i[3-9]86|amd64|x86_64")
        if(SIZE_OF_VOID_PTR EQUAL 4)
            add_definitions(-DHWLOC_X86_32_ARCH=1)
            set(HWLOC_X86_32_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X86" CACHE STRING "Library architecture for MS")
            message(CHECK_PASS "x86_32")
        elseif(SIZE_OF_VOID_PTR EQUAL 8)
            add_definitions(-DHWLOC_X86_64_ARCH=1)
            set(HWLOC_X86_64_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X64" CACHE STRING "Library architecture for MS")
            message(CHECK_PASS "x86_64")
        else()
            add_definitions(-DHWLOC_X86_64_ARCH=1)
            set(HWLOC_X86_64_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X64" CACHE STRING "Library architecture for MS")
            message(CHECK_PASS "unknown -- assuming x86_64")
        endif()
    else()
        message(CHECK_PASS "unknown")
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
    hwloc_check_visibility()
    set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_VISIBILITY_CFLAGS}")
    if (NOT HWLOC_VISIBILITY_CFLAGS STREQUAL "")
        message(STATUS "\"${HWLOC_VISIBILITY_CFLAGS}\" has been added to the hwloc CFLAGS")
    endif ()

    # Make sure the compiler returns an error code when function arg
    # count is wrong, otherwise sched_setaffinity checks may fail.
    set(HWLOC_STRICT_ARGS_CFLAGS "" CACHE INTERNAL "")
    set(HWLOC_ARGS_CHECK 0)

    message(CHECK_START "Checking whether the C compiler rejects function calls with too many arguments")
    check_c_source_compiles("
        extern int one_arg(int x);
        int foo(void) { return one_arg(1, 2); }
    " HWLOC_ARGS_CHECK_PASS)

    if (HWLOC_ARGS_CHECK_PASS)
        message(CHECK_PASS No)
    else ()
        math(EXPR HWLOC_ARGS_CHECK "${HWLOC_ARGS_CHECK}+1")
        message(CHECK_PASS Yes)
    endif ()

    message(CHECK_START "Checking whether the C compiler rejects function calls with too few arguments")
    check_c_source_compiles("
        extern int two_arg(int x, int y);
        int foo(void) { return two_arg(3); }
    " HWLOC_ARGS_CHECK_PASS)

    if (HWLOC_ARGS_CHECK_PASS)
        message(CHECK_PASS No)
    else ()
        math(EXPR HWLOC_ARGS_CHECK "${HWLOC_ARGS_CHECK}+1")
        message(CHECK_PASS Yes)
    endif ()

    if (NOT HWLOC_ARGS_CHECK EQUAL 2)
        message(WARNING "Your C compiler does not consider incorrect argument counts to be a fatal error.")

        if (CMAKE_C_COMPILER_ID STREQUAL "XL")
            set(HWLOC_STRICT_ARGS_CFLAGS "-qhalt=e")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            set(HWLOC_STRICT_ARGS_CFLAGS "-we140")
        else ()
            set(HWLOC_STRICT_ARGS_CFLAGS "FAIL")
            message(WARNING "Please report this warning and configure using a different C compiler if possible.")
        endif ()

        if (NOT HWLOC_STRICT_ARGS_CFLAGS STREQUAL "FAIL")
            message(WARNING "Configure will append '${HWLOC_STRICT_ARGS_CFLAGS}' to the value of CFLAGS when needed.")
        else ()
            message(WARNING "Alternatively you may configure with a different compiler.")
        endif ()
    endif ()

    if (HWLOC_MODE STREQUAL "standalone")
        # For the common developer case, if we're in a developer checkout and
        # using the GNU compilers, turn on maximum warnings unless
        # specifically disabled by the user.

        message(CHECK_START "Checking whether to enable "picky" compiler mode")
        set(HWLOC_WANT_PICKY 0)
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
                set(HWLOC_WANT_PICKY 1)
            endif()
        endif ()

        if (ENABLE_PICKY STREQUAL "ON")
            if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
                message(CHECK_PASS Yes)
                set(HWLOC_WANT_PICKY 1)
            else ()
                message(CHECK_PASS No)
                message(WARNING "Warning: --enable-picky used, but is currently only defined for the GCC compiler set -- automatically disabled")
                set(HWLOC_WANT_PICKY 0)
            endif ()
        elseif (ENABLE_PICKY STREQUAL "OFF")
            message(CHECK_PASS No)
            set(HWLOC_WANT_PICKY 0)
        else ()
            if (HWLOC_WANT_PICKY EQUAL 1)
                message(CHECK_PASS "Yes (default)")
            else ()
                message(CHECK_PASS "No (default)")
            endif ()
        endif ()

        if (HWLOC_WANT_PICKY)
            set(HWLOC_ADD "")
            set(HWLOC_ADD "${HWLOC_ADD} -Wall -Wextra -Wunused-parameter -Wundef -Wno-long-long -Wsign-compare")
            set(HWLOC_ADD "${HWLOC_ADD} -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes")
            set(HWLOC_ADD "${HWLOC_ADD} -Wcomment -pedantic -Wshadow -Wwrite-strings -Wnested-externs")
            set(HWLOC_ADD "${HWLOC_ADD} -Wpointer-arith -Wbad-function-cast -Wold-style-definition")
            set(HWLOC_ADD "${HWLOC_ADD} -Werror-implicit-function-declaration")

            hwloc_check_cc_option("-Wdiscarded-qualifiers" HWLOC_ADD)
            hwloc_check_cc_option("-Wvariadic-macros" HWLOC_ADD)
            hwloc_check_cc_option("-Wtype-limits" HWLOC_ADD)
            hwloc_check_cc_option("-Wstack-usage=262144" HWLOC_ADD)

            # -Wextra enables some -Wfoo that we want to disable it at some place
            hwloc_check_cc_option("-Wmissing-field-initializers" HWLOC_ADD "HWLOC_HAVE_GCC_W_MISSING_FIELD_INITIALIZERS")
            hwloc_check_cc_option("-Wcast-function-type" HWLOC_ADD "HWLOC_HAVE_GCC_W_CAST_FUNCTION_TYPE")

            set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_ADD}")
        endif ()
    endif ()

    #
    # Now detect support
    #
    check_include_file("unistd.h" HAVE_UNISTD_H)
    check_include_file("dirent.h" HAVE_DIRENT_H)
    check_include_file("strings.h" HAVE_STRINGS_H)
    check_include_file("ctype.h" HAVE_CTYPE_H)
    check_include_file("sys/wait.h" HAVE_CTYPE_H)

    hwloc_check_decl(strcasecmp HWLOC_HAVE_DECL_STRCASECMP)
    hwloc_check_decl(strncasecmp HWLOC_HAVE_DECL_STRNCASECMP)

    check_function_exists(strftime HAVE_STRFTIME)
    check_function_exists(setlocale HAVE_SETLOCALE)

    check_include_file("stdint.h" HWLOC_HAVE_STDINT_H)

    check_include_file("sys/mman.h" HAVE_SYS_MMAN_H)

    if (HWLOC_FREEBSD_SYS)
        message("")
        message("**** FreeBSD-specific checks")

        check_include_file("sys/domainset.h" HAVE_SYS_DOMAINSET_H)
        check_include_file("sys/thr.h" HAVE_SYS_THR_H)
        check_include_file("pthread_np.h" HAVE_PTHREAD_NP_H)
        check_include_file("sys/cpuset.h" HAVE_SYS_CPUSET_H)
        check_function_exists(cpuset_setaffinity HAVE_CPUSET_SETAFFINITY)
        check_function_exists(cpuset_setid HAVE_CPUSET_SETID)

        message("**** end of FreeBSD-specific checks")
    endif ()

    if (HWLOC_WIN_SYS)
        message("")
        message("**** Windows-specific checks")

        check_include_file("windows.h" HWLOC_HAVE_WINDOWS_H)

        set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} -D_WIN32_WINNT=0x0601")

        check_type_size(KAFFINITY KAFFINITY)
        check_type_size(PROCESSOR_CACHE_TYPE PROCESSOR_CACHE_TYPE)
        check_type_size(CACHE_DESCRIPTOR CACHE_DESCRIPTOR)
        check_type_size(LOGICAL_PROCESSOR_RELATIONSHIP LOGICAL_PROCESSOR_RELATIONSHIP)
        check_type_size(RelationProcessorPackage RELATIONPROCESSORDIE)
        check_type_size(RelationProcessorDie RELATIONPROCESSORDIE)
        check_type_size(GROUP_AFFINITY GROUP_AFFINITY)
        check_type_size(PROCESSOR_RELATIONSHIP PROCESSOR_RELATIONSHIP)
        check_type_size(NUMA_NODE_RELATIONSHIP NUMA_NODE_RELATIONSHIP)
        check_type_size(CACHE_RELATIONSHIP CACHE_RELATIONSHIP)
        check_type_size(PROCESSOR_GROUP_INFO PROCESSOR_GROUP_INFO)
        check_type_size(GROUP_RELATIONSHIP GROUP_RELATIONSHIP)
        check_type_size(SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX)
        check_type_size(PSAPI_WORKING_SET_EX_BLOCK PSAPI_WORKING_SET_EX_BLOCK)
        check_type_size(PSAPI_WORKING_SET_EX_INFORMATION PSAPI_WORKING_SET_EX_INFORMATION)
        check_type_size(PROCESSOR_NUMBER PROCESSOR_NUMBER)

        check_function_exists(GetModuleFileName HAVE_DECL_GETMODULEFILENAME)

        find_library(HAVE_LIBGDI32 gdi32)
        if (HAVE_LIBGDI32)
            set(HWLOC_LIBS "-lgdi32  ${HWLOC_LIBS}")
        endif ()

        find_library(HAVE_USER32 user32)

        find_program(HWLOC_MS_LIB lib)

        message("**** end of Windows-specific checks")
    endif ()

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