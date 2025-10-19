# HWLOC_CHECK_DECL
#
# Check that the declaration of the given function has a complete prototype
# with argument list by trying to call it with an insane dnl number of
# arguments (10). Success means the compiler couldn't really check.
function(hwloc_check_decl name variable includes)
    message(CHECK_START "Checking whether function ${name} has a complete prototype")

    set(COMPILES 0)
    check_c_source_compiles("
    ${includes}
            int main(){
                ${name}(1,2,3,4,5,6,7,8,9,10);
                return 0;
            }"
            COMPILES
    )
    if (COMPILES)
        message(CHECK_PASS "no")
    else ()
        message(CHECK_PASS "yes")
        set(${variable} 1 PARENT_SCOPE)
    endif ()
endfunction()

function(hwloc_setup_core prefix mode message)
    include(CheckFunctionExists)
    include(CheckTypeSize)
    include(CheckSymbolExists)
    include(CheckSourceRuns)
    include(FindPkgConfig)

    # Print configuration message if provided
    if(message)
        message(STATUS "")
        message(STATUS "### Configuring hwloc core ###")
        message(STATUS "")
    endif()

    # If no prefix was defined, set a good value
    if(DEFINED prefix)
        set(hwloc_config_prefix "${prefix}/")
    else()
        set(hwloc_config_prefix ${CMAKE_BINARY_DIR})
    endif()

    if(NOT DEFINED hwloc_mode)
        set(hwloc_mode "embedded")
    endif()

    message(CHECK_START "Checking hwloc building mode")
    message(CHECK_PASS ${hwloc_mode})

    # Get hwloc's absolute top builddir (which may not be the same as
    # the real $top_builddir, because we may be building in embedded
    # mode).

    set(HWLOC_startdir ${CMAKE_BINARY_DIR})
    set(HWLOC_top_builddir ${CMAKE_BINARY_DIR} CACHE PATH "")

    # Get hwloc's absolute top srcdir (which may not be the same as
    # the real $top_srcdir, because we may be building in embedded
    # mode).  First, go back to the startdir incase the $srcdir is
    # relative.

    set(HWLOC_top_srcdir ${CMAKE_SOURCE_DIR} CACHE PATH "")

    message(STATUS "HWLOC builddir: ${HWLOC_top_builddir}")
    message(STATUS "HWLOC srcdir: ${HWLOC_top_srcdir}")

    if(NOT HWLOC_top_builddir STREQUAL ${HWLOC_top_srcdir})
        message(STATUS "Detected VPATH build")
    endif()

    # Get the version of hwloc that we are installing
    message(CHECK_START "Checking for hwloc version")
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

    message(CHECK_PASS "HWLOC version: ${HWLOC_VERSION}")

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
    set(HWLOC_VERSION_RELEASE "${HWLOC_VERSION_RELEASE}" CACHE INTERNAL "Hwloc release version")

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

    # Debug mode?
    message(CHECK_START "Checking if want hwloc maintainer support")
    set(hwloc_debug "")

    # Unconditionally disable debug mode in embedded mode; if someone
    # asks, we can add a configure-time option for it.  Disable it
    # now, however, because --enable-debug is not even added as an
    # option when configuring in embedded mode, and we wouldn't want
    # to hijack the enclosing application's --enable-debug configure
    # switch.
    if (${hwloc_mode} STREQUAL "embedded")
        set(hwloc_debug 0)
        set(hwloc_debug_msg "disabled (embedded mode)")
    endif ()
    if (NOT hwloc_debug AND ${ENABLE_DEBUG} STREQUAL ON)
        set(hwloc_debug 1)
        set(hwloc_debug_msg "enabled")
    endif ()
    if (NOT hwloc_debug)
        set(hwloc_debug 0)
        set(hwloc_debug_msg "disabled")
    endif ()

    # Grr; we use #ifndef for HWLOC_DEBUG!  :-(
    if(hwloc_debug)
        add_definitions(-DHWLOC_DEBUG)
        set(HWLOC_DEBUG 1 CACHE BOOL "Whether we are in debugging mode or not")
    endif()

    message(CHECK_PASS "${hwloc_debug_msg}")

    # We need to set a path for header, etc files depending on whether
    # we're standalone or embedded. this is taken care of by HWLOC_EMBEDDED.

    message(CHECK_START "Checking for hwloc directory prefix")

    if(prefix)
        message(CHECK_PASS "${hwloc_config_prefix}")
    else ()
        message(CHECK_PASS "(none)")
    endif ()

    # What prefix are we using?
    message(CHECK_START "Checking for hwloc symbol prefix")
    if (NOT DEFINED hwloc_symbol_prefix_value)
        if (HWLOC_SYMBOL_PREFIX)
            set(hwloc_symbol_prefix_value ${HWLOC_SYMBOL_PREFIX})
        else ()
            set(hwloc_symbol_prefix_value "hwloc_")
        endif ()
    endif ()

    add_definitions(-DHWLOC_SYM_PREFIX=${hwloc_symbol_prefix_value})

    string(TOUPPER "${hwloc_symbol_prefix_value}" HWLOC_SYMBOL_PREFIX_CAPS)
    add_definitions(-DHWLOC_SYM_PREFIX_CAPS=${HWLOC_SYMBOL_PREFIX_CAPS})
    message(CHECK_PASS ${hwloc_symbol_prefix_value})

    # Give an easy #define to know if we need to transform all the
    # hwloc names
    if(hwloc_symbol_prefix_value STREQUAL "hwloc_")
        set(HWLOC_SYM_TRANSFORM 0 CACHE BOOL "Whether we need to re-define all the hwloc public symbols or not")
    else()
        set(HWLOC_SYM_TRANSFORM 1 CACHE BOOL "Whether we need to re-define all the hwloc public symbols or not")
    endif()

    project(hwloc
            LANGUAGES C
            VERSION ${HWLOC_VERSION_MAJOR}.${HWLOC_VERSION_MINOR}.${HWLOC_VERSION_RELEASE}
    )

    # hwloc 2.0+ requires a C99 compliant compiler
    set(CMAKE_C_STANDARD 99 CACHE INTERNAL "C99 standard")

    # GCC specifics.
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
        #add_compile_options(-Wall -Wmissing-prototypes -Wundef -Wpointer-arith -Wcast-align)
        set(HWLOC_GCC_CFLAGS "-Wall -Wmissing-prototypes -Wundef -Wpointer-arith -Wcast-align" CACHE STRING "")
    endif()

    # Enample system extensions for O_DIRECTORY, fdopen, fssl, etc.
    option(USE_HPUX_SYSTEM_EXTENSIONS "Enable extensions on HP-UX" ON)
    if(USE_HPUX_SYSTEM_EXTENSIONS)
        add_definitions(-D_HPUX_SOURCE)
        set(_HPUX_SOURCE 1 CACHE INTERNAL "Are we building for HP-UX?")
    endif()

    # Check to see if we're producing a 32 or 64 bit executable by
    # checking the sizeof void*.  Note that AC CHECK_SIZEOF even works
    # when cross compiling (!), according to the AC 2.64 docs.  This
    # check is needed because on some systems, you can instruct the
    # compiler to specifically build 32 or 64 bit executables -- even
    # though the $target may indicate something different.
    check_type_size(void* SIZE_OF_VOID_PTR)

    #
    # List of components to be built, either statically or dynamically.
    # To be enlarged below.
    #
    set(hwloc_components "noos xml synthetic xml_nolibxml")

    #
    # Check OS support
    #
    message(CHECK_START "Checking which OS support to include")

    set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -D_GNU_SOURCE=1")

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(HWLOC_LINUX_SYS 1 CACHE INTERNAL "")
        set(HWLOC_HAVE_LINUX 1 CACHE INTERNAL "")
        set(hwloc_linux yes)
        message(CHECK_PASS "Linux")

        set(hwloc_components "${hwloc_components} linux")

        if(ENABLE_IO)
            add_definitions(-DHWLOC_HAVE_LINUXIO=1)
            set(HWLOC_HAVE_LINUXIO 1 CACHE INTERNAL "Define to 1 for I/O discovery in the Linux component")
            set(hwloc_linuxio_happy yes)
            if(ENABLE_PIC)
                set(HWLOC_HAVE_LINUXPCI 1 CACHE INTERNAL "Define to 1 if enabling Linux-specific PCI discovery in the Linux I/O component")
                set(hwloc_linuxpci_happy yes)
            endif()
        endif()

    elseif(CMAKE_SYSTEM_NAME STREQUAL "IRIX")
        set(hwloc_irix yes)
        set(HWLOC_IRIX_SYS 1 CACHE INTERNAL "Define to 1 on Irix")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_IRIX_SYS=1")
        message(CHECK_PASS "IRIX")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        set(hwloc_darwin yes)
        set(HWLOC_DARWIN_SYS 1 CACHE INTERNAL "")
        message(CHECK_PASS "Darwin")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_DARWIN_SYS=1")
        set(hwloc_components "${hwloc_components} darwin")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "Solaris")
        set(hwloc_solaris yes)
        set(HWLOC_SOLARIS_SYS 1 CACHE INTERNAL "Define to 1 on Darwin")
        message(CHECK_PASS "Solaris")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_SOLARIS_SYS=1")
        set(hwloc_components "${hwloc_components} solaris")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "AIX")
        set(hwloc_aix yes)
        set(HWLOC_AIX_SYS 1 CACHE INTERNAL "Define to 1 on AIX")
        message(CHECK_PASS "AIX")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_AIX_SYS=1")
        set(hwloc_components "${hwloc_components} aix")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "HP-UX")
        set(hwloc_hpux yes)
        set(HWLOC_HPUX_SYS 1 CACHE INTERNAL "Define to 1 on HP-UX")
        message(CHECK_PASS "HP-UX")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_HPUX_SYS=1")
        set(hwloc_components "${hwloc_components} hpux")

    elseif(CMAKE_SYSTEM_NAME MATCHES "Windows")
        set(hwloc_windows yes)
        set(HWLOC_WIN_SYS 1 CACHE INTERNAL "Define to 1 on WINDOWS")
        message(CHECK_PASS "Windows")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_WIN_SYS=1")
        set(hwloc_components "${hwloc_components} windows")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
        set(hwloc_freebsd yes)
        set(HWLOC_FREEBSD_SYS 1 CACHE INTERNAL "Define to 1 on *FREEBSD")
        message(CHECK_PASS "FreeBSD")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_FREEBSD_SYS=1")
        set(hwloc_components "${hwloc_components} freebsd")

    elseif(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
        set(hwloc_netbsd yes)
        set(HWLOC_NETBSD_SYS 1 CACHE INTERNAL "Define to 1 on *NETBSD")
        message(CHECK_PASS "NetBSD")
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_NETBSD_SYS=1")
        set(hwloc_components "${hwloc_components} netbsd")

    else()
        message(CHECK_FAIL "Unsupported! (${CMAKE_SYSTEM_NAME})")
        add_definitions(-DHWLOC_UNSUPPORTED_SYS=1)
        set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_UNSUPPORTED_SYS=1")
        set(HWLOC_UNSUPPORTED_SYS 1 CACHE INTERNAL "Define to 1 on unsupported systems")
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

    #
    # Check CPU support
    #
    message(CHECK_START "Checking which CPU support to include")

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "i[3-9]86|amd64|x86_64")
        if(SIZE_OF_VOID_PTR EQUAL 4)
            add_definitions(-DHWLOC_X86_32_ARCH=1)
            set(HWLOC_X86_32_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X86" CACHE STRING "Library architecture for MS")
            set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_X86_32_ARCH=1 -DHWLOC_MS_LIB_ARCH=X86")
            set(hwloc_x86_32 yes)
            message(CHECK_PASS "x86_32")
        elseif(SIZE_OF_VOID_PTR EQUAL 8)
            add_definitions(-DHWLOC_X86_64_ARCH=1)
            set(HWLOC_X86_64_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X64" CACHE STRING "Library architecture for MS")
            set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_X86_64_ARCH=1 -DHWLOC_MS_LIB_ARCH=X64")
            set(hwloc_x86_64 yes)
            message(CHECK_PASS "x86_64")
        else()
            add_definitions(-DHWLOC_X86_64_ARCH)
            set(HWLOC_X86_64_ARCH 1 CACHE INTERNAL "")
            set(HWLOC_MS_LIB_ARCH "X64" CACHE STRING "Library architecture for MS")
            set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_X86_64_ARCH=1 -DHWLOC_MS_LIB_ARCH=X64")
            set(hwloc_x86_64 yes)
            message(CHECK_PASS "unknown -- assuming x86_64")
        endif()
    else()
        message(CHECK_PASS "unknown")
    endif()

    check_type_size("unsigned long" SIZEOF_UNSIGNED_LONG)
    add_definitions(-DHWLOC_SIZEOF_UNSIGNED_LONG=${SIZEOF_UNSIGNED_LONG})
    set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_SIZEOF_UNSIGNED_LONG=${SIZEOF_UNSIGNED_LONG}")
    set(HWLOC_SIZEOF_UNSIGNED_LONG ${SIZEOF_UNSIGNED_LONG} CACHE INTERNAL "")

    check_type_size("unsigned int" SIZEOF_UNSIGNED_INT)
    add_definitions(-DHWLOC_SIZEOF_UNSIGNED_INT=${SIZEOF_UNSIGNED_INT})
    set(CMAKE_REQUIRED_DEFINITIONS "${CMAKE_REQUIRED_DEFINITIONS} -DHWLOC_SIZEOF_UNSIGNED_INT=${SIZEOF_UNSIGNED_INT}")
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
    set(hwloc_args_check 0)

    message(CHECK_START "Checking whether the C compiler rejects function calls with too many arguments")
    check_c_source_compiles("
            extern int one_arg(int x);
            int foo(void) { return one_arg(1, 2); }
        " HWLOC_ARGS_CHECK_PASS)

    if (HWLOC_ARGS_CHECK_PASS)
        message(CHECK_PASS "no")
    else ()
        math(EXPR hwloc_args_check 1)
        message(CHECK_PASS "yes")
    endif ()

    message(CHECK_START "Checking whether the C compiler rejects function calls with too few arguments")
    check_c_source_compiles("
            extern int two_arg(int x, int y);
            int foo(void) { return two_arg(3); }
        " HWLOC_ARGS_CHECK_PASS)

    if (HWLOC_ARGS_CHECK_PASS)
        message(CHECK_PASS "no")
    else ()
        math(EXPR hwloc_args_check "${hwloc_args_check}+1")
        message(CHECK_PASS "yes")
    endif ()


    if (NOT hwloc_args_check STREQUAL 2)
        message(WARNING "Your C compiler does not consider incorrect argument counts to be a fatal error.")

        if (CMAKE_C_COMPILER_ID STREQUAL "XL")
            set(HWLOC_STRICT_ARGS_CFLAGS "-qhalt=e" CACHE INTERNAL "")
        elseif (CMAKE_C_COMPILER_ID MATCHES "Intel")
            set(HWLOC_STRICT_ARGS_CFLAGS "-we140" CACHE INTERNAL "")
        else ()
            set(HWLOC_STRICT_ARGS_CFLAGS "FAIL" CACHE INTERNAL "")
            message(WARNING "Please report this warning and configure using a different C compiler if possible.")
        endif ()
        if (NOT HWLOC_STRICT_ARGS_CFLAGS STREQUAL "FAIL")
            message(WARNING "Configure will append '${HWLOC_STRICT_ARGS_CFLAGS}' to the value of CFLAGS when needed.")
            message(WARNING "Alternatively you may configure with a different compiler.")
        endif ()
    endif ()

    if (hwloc_mode STREQUAL "standalone")
        # For the common developer case, if we're in a developer checkout and
        # using the GNU compilers, turn on maximum warnings unless
        # specifically disabled by the user.

        message(CHECK_START "Checking whether to enable "picky" compiler mode")

        set(hwloc_want_picky 0)
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            if (EXISTS ${HWLOC_top_srcdir}/.git)
                set(hwloc_want_picky 1)
            endif ()
        endif ()

        if (ENABLE_PICKY STREQUAL ON)
            if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
                message(CHECK_PASS "yes")
                set(hwloc_want_picky 1)
            else ()
                message(CHECK_PASS "no")
                message(WARNING "Warning: --enable-picky used, but is currently only defined for the GCC compiler set -- automatically disabled")
                set(hwloc_want_picky 0)
            endif ()
        elseif (ENABLE_PICKY STREQUAL OFF)
            message(CHECK_PASS "no")
            set(hwloc_want_picky 0)
        else ()
            if (hwloc_want_picky STREQUAL 1)
                message(CHECK_PASS "yes (default)")
            else ()
                message(CHECK_PASS "no (default)")
            endif ()
        endif ()

        if (hwloc_want_picky STREQUAL 1)
            set(add "${add} -Wall -Wextra -Wunused-parameter -Wundef -Wno-long-long -Wsign-compare")
            set(add "${add} -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes")
            set(add "${add} -Wcomment -pedantic -Wshadow -Wwrite-strings -Wnested-externs")
            set(add "${add} -Wpointer-arith -Wbad-function-cast -Wold-style-definition")
            set(add "${add} -Werror-implicit-function-declaration")

            hwloc_check_cc_option(-Wdiscarded-qualifiers add "")
            hwloc_check_cc_option(-Wvariadic-macros add "")
            hwloc_check_cc_option(-Wtype-limits add "")
            hwloc_check_cc_option(-Wstack-usage=262144 add "")

            # -Wextra enables some -Wfoo that we want to disable it at some place
            hwloc_check_cc_option(-Wmissing-field-initializers add pass)
            if (pass)
                set(HWLOC_HAVE_GCC_W_MISSING_FIELD_INITIALIZERS 1 CACHE INTERNAL "Define to 1 if gcc -Wmissing-field-initializers is supported and enabled")
            endif ()

            hwloc_check_cc_option(-Wcast-function-type add pass)
            if (pass)
                set(HWLOC_HAVE_GCC_W_CAST_FUNCTION_TYPE 1 CACHE INTERNAL "Define to 1 if gcc -Wcast-function-type is supported and enabled")
            endif ()

            set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${add}")
        endif ()
    endif ()

    #
    # Now detect support
    #

    check_include_file("unistd.h" HAVE_UNISTD_H)
    check_include_file("dirent.h" HAVE_DIRENT_H)
    check_include_file("strings.h" HAVE_STRINGS_H)
    check_include_file("ctype.h" HAVE_CTYPE_H)
    check_include_file("sys/wait.h" HAVE_SYS_WAIT_H)

    check_function_exists(strcasecmp HAVE_STRCASECMP)
    if (HAVE_STRCASECMP)
        hwloc_check_decl(strcasecmp have_strcasecmp "")
        if (have_strcasecmp)
            set(HWLOC_HAVE_DECL_STRCASECMP 1 CACHE INTERNAL "Define to 1 if function `strcasecmp' is declared by system headers")
        endif ()
    endif ()

    check_function_exists(strncasecmp HAVE_STRNCASECMP)
    if (HAVE_STRNCASECMP)
        hwloc_check_decl(strncasecmp have_strncasecmp "")
        if (have_strncasecmp)
            set(HWLOC_HAVE_DECL_STRNCASECMP 1 CACHE INTERNAL "Define to 1 if function `strncasecmp' is declared by system headers")
        endif ()
    endif ()

    check_function_exists(strftime HAVE_STRFTIME)
    check_function_exists(setlocale HAVE_SETLOCALE)

    check_include_file("stdint.h" HAVE_STDINT_H)
    if (HAVE_STDINT_H)
        set(HWLOC_HAVE_STDINT_H 1 CACHE INTERNAL "Define to 1 if you have the <stdint.h> header file.")
    endif ()

    check_include_file("sys/mman.h" HAVE_SYS_MMAN_H)

    if (hwloc_freebsd STREQUAL "yes")

        # TODO: Check if this works

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

    if (hwloc_windows STREQUAL "yes")

        # TODO: Check if this works

        message("")
        message("**** Windows-specific checks")

        check_include_file("windows.h" HWLOC_HAVE_WINDOWS_H)

        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
        set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} -D_WIN32_WINNT=0x0601")
        set(CMAKE_REQUIRED_INCLUDES_BAK ${CMAKE_REQUIRED_INCLUDES})
        set(CMAKE_REQUIRED_INCLUDES "windows.h")

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

        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})

        check_function_exists(GetModuleFileName HAVE_DECL_GETMODULEFILENAME)

        find_library(HAVE_LIBGDI32 gdi32)
        if (HAVE_LIBGDI32)
            set(HWLOC_LIBS "-lgdi32 ${HWLOC_LIBS}")
        endif ()

        find_library(HAVE_USER32 user32)

        if (HAVE_USER32)
            set(hwloc_have_user32 "yes")
        endif ()

        set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES_BAK})
        find_program(HWLOC_MS_LIB lib)

        message("**** end of Windows-specific checks")
    endif ()

    if (hwloc_solaris STREQUAL "yes")

        # TODO: Check if this works

        message("")
        message("**** Solaris-specific checks")

        check_include_file("sys/lgrp_user.h" HAVE_SYS_LGRP_USER_H)
        if (HAVE_SYS_LGRP_USER_H)
            find_library(HAVE_LIBLGRP lgrp)
            if (HAVE_LIBLGRP)
                set(HWLOC_LIBS "-llgrp ${HWLOC_LIBS}")
            endif ()
        endif ()

        check_include_file("kstat.h" HAVE_KSTAT_H)
        if (HAVE_KSTAT_H)
            find_library(HAVE_LIBKSTAT kstat)
            if (HAVE_LIBKSTAT)
                set(HWLOC_LIBS "-lkstat ${HWLOC_LIBS}")
            endif ()
        endif ()

        check_include_file("picl.h" HAVE_PICL_H)
        if (HAVE_PICL_H)
            find_library(HAVE_LIBPICL picl)
            if (HAVE_LIBPICL)
                set(HWLOC_LIBS "-lpicl ${HWLOC_LIBS}")
            endif ()
        endif ()

        message("**** end of Solaris-specific checks")
    endif ()

    if (hwloc_aix STREQUAL "yes")

        # TODO: Check if this works

        message("")
        message("**** AIX-specific checks")

        find_library(HWLOC_HAVE_PTHREAD pthread)
        if (HWLOC_HAVE_PTHREAD)
            check_function_exists(pthread_getthrds_np HWLOC_HAVE_PTHREAD_GETTHRDS_NP)
        endif ()

        message("**** end of AIX-specific checks")
    endif ()

    if (hwloc_darwin STREQUAL "yes")

        # TODO: Check if this works

        message("")
        message("**** Darwin-specific checks")

        message(CHECK_START "Checking for the Foundation framework")

        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
        set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} -framework Foundation")

        check_c_source_compiles(
                "
                #include <CoreFoundation/CoreFoundation.h>

                int main(){
                    return CFDictionaryGetTypeID();
                }
                "
                HWLOC_HAVE_DARWIN_FOUNDATION
        )

        if (HWLOC_HAVE_DARWIN_FOUNDATION)
            message(CHECK_PASS "yes")
            set(HWLOC_DARWIN_LDFLAGS "${HWLOC_DARWIN_LDFLAGS} -framework Foundation" CACHE INTERNAL "")
        else ()
            message(CHECK_PASS "no")
        endif ()
        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})


        message(CHECK_START "Checking for the IOKit framework")

        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
        set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} -framework IOKit")

        check_c_source_compiles(
                "
                #include <IOKit/IOKitLib.h>

                int main() {
                    io_registry_entry_t service = IORegistryGetRootEntry(kIOMasterPortDefault);
                    return 0;
                }
                "
                HWLOC_HAVE_DARWIN_IOKIT
        )

        if (HWLOC_HAVE_DARWIN_IOKIT)
            message(CHECK_PASS "yes")
            set(HWLOC_DARWIN_LDFLAGS "${HWLOC_DARWIN_LDFLAGS} -framework IOKit")
        else ()
            message(CHECK_PASS "no")
        endif ()
        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})

        message("**** end of Darwin-specific checks")
    endif ()


    if (hwloc_linux STREQUAL "yes")

        # TODO: Check if this works

        message("")
        message("**** Linux-specific checks")

        check_function_exists(sched_getcpu HAVE_DECL_SCHED_GETCPU)

        hwloc_check_decl(sched_setaffinity have_sched_setaffinity
            "
            #ifndef _GNU_SOURCE
            # define _GNU_SOURCE
            #endif
            #include <sched.h>"
        )

        if (have_sched_setaffinity)
            set(HWLOC_HAVE_SCHED_SETAFFINITY 1 CACHE BOOL "Define to 1 if glibc provides a prototype of sched_setaffinity()")

            if (HWLOC_STRICT_ARGS_CFLAGS STREQUAL "FAIL")
                message(WARNING "Support for sched_setaffinity() requires a C compiler which")
                message(WARNING "considers incorrect argument counts to be a fatal error.")
                message(FATAL_ERROR "Cannot continue.")
            endif ()

            message(CHECK_START "Checking for old prototype of sched_setaffinity")

            set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
            set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} ${HWLOC_STRICT_ARGS_CFLAGS}")

            check_c_source_compiles(
                    "
                    #ifndef _GNU_SOURCE
                    # define _GNU_SOURCE
                    #endif
                    #include <sched.h>
                    static unsigned long mask;

                    int main() {
                        sched_setaffinity(0, (void*) &mask);
                        return 0;
                    }
                    "
                    HWLOC_HAVE_OLD_SCHED_SETAFFINITY
            )
            if (HWLOC_HAVE_OLD_SCHED_SETAFFINITY)
                message(CHECK_PASS "yes")
            else ()
                message(CHECK_FAIL "no")
            endif ()

            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS_BAK}")
        endif ()

        message(CHECK_START "Checking for working CPU_SET")

        check_c_source_compiles(
                "
                    #ifndef _GNU_SOURCE
                    # define _GNU_SOURCE
                    #endif
                    #include <sched.h>
                    cpu_set_t set;

                    int main() {
                        CPU_ZERO(&set); CPU_SET(0, &set);
                        return 0;
                    }
                    "
                HWLOC_HAVE_CPU_SET
        )
        if (HWLOC_HAVE_CPU_SET)
            message(CHECK_PASS "yes")
        else ()
            message(CHECK_FAIL "no")
        endif ()


        message(CHECK_START "Checking for working CPU_SET")

        check_c_source_compiles(
                "
                    #ifndef _GNU_SOURCE
                    # define _GNU_SOURCE
                    #endif
                    #include <sched.h>
                    cpu_set_t *set;

                    int main() {
                        set = CPU_ALLOC(1024);
                        CPU_ZERO_S(CPU_ALLOC_SIZE(1024), set);
                        CPU_SET_S(CPU_ALLOC_SIZE(1024), 0, set);
                        CPU_FREE(set);
                        return 0;
                    }
                    "
                HWLOC_HAVE_CPU_SET_S
        )
        if (HWLOC_HAVE_CPU_SET_S)
            message(CHECK_PASS "yes")
        else ()
            message(CHECK_FAIL "no")
        endif ()

        message(CHECK_START "Checking for working syscall with 6 parameters")

        check_c_source_compiles(
                "
                    #ifndef _GNU_SOURCE
                    # define _GNU_SOURCE
                    #endif
                    #include <unistd.h>
                    #include <sys/syscall.h>

                    int main() {
                        syscall(0, 1, 2, 3, 4, 5, 6);
                        return 0;
                    }
                    "
                HWLOC_HAVE_SYSCALL
        )
        if (HWLOC_HAVE_SYSCALL)
            message(CHECK_PASS "yes")
        else ()
            message(CHECK_FAIL "no")
        endif ()

        # Linux libudev support
        if (ENABLE_LIBUDEV STREQUAL ON)
            check_include_file("libudev.h" HAVE_LIBUDEV_H)
            if (HAVE_LIBUDEV_H)
                find_library(HWLOC_HAVE_LIBUDEV udev)
                if (HWLOC_HAVE_LIBUDEV)
                    set(HWLOC_LIBS "${HWLOC_LIBS} -ludev")
                endif ()
            endif ()
        endif ()

        message("**** end of Linux-specific checks")
    endif ()

    if (NOT hwloc_linux STREQUAL "yes")

        # Don't look for sys/sysctl.h on Linux because it's deprecated and
        # generates a warning in GCC10. Also it's unneeded.
        check_include_file("sys/param.h" HAVE_SYS_PARAM_H)
        check_include_file("sys/sysctl.h" HAVE_SYS_SYSCTL_H)

        if (HAVE_SYS_SYSCTL_H)
            set(HWLOC_SYS_TEST_HEADERS "sys/sysctl.h")
            check_symbol_exists(CTL_HW ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_CTL_HW)
            check_symbol_exists(HW_NCPU ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_NCPU)
            check_symbol_exists(HW_REALMEM64 ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_REALMEM64)
            check_symbol_exists(HW_MEMSIZE64 ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_MEMSIZE64)
            check_symbol_exists(HW_PHYSMEM64 ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_PHYSMEM64)
            check_symbol_exists(HW_USERMEM64 ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_USERMEM64)
            check_symbol_exists(HW_REALMEM ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_REALMEM)
            check_symbol_exists(HW_MEMSIZE ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_MEMSIZE)
            check_symbol_exists(HW_PHYSMEM ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_PHYSMEM)
            check_symbol_exists(HW_USERMEM ${HWLOC_SYS_TEST_HEADERS} HAVE_DECL_HW_USERMEM)
        endif ()

        # Don't detect sysctl* on Linux because its sysctl() syscall is
        # long deprecated and unneeded. Some libc still expose the symbol
        # and raise a big warning at link time.

        # Do a full link test instead of just using AC_CHECK_FUNCS, which
        # just checks to see if the symbol exists or not.  For example,
        # the prototype of sysctl uses u_int, which on some platforms
        # (such as FreeBSD) is only defined under __BSD_VISIBLE, __USE_BSD
        # or other similar definitions.  So while the symbols "sysctl" and
        # "sysctlbyname" might still be available in libc (which autoconf
        # checks for), they might not be actually usable.

        message(CHECK_START "Checking for sysctl")
        check_c_source_compiles(
                "
                #include <stdio.h>
                #include <sys/types.h>
                #include <sys/sysctl.h>

                int main() {
                    return sysctl(NULL,0,NULL,NULL,NULL,0);
                }
                "
                HAVE_SYSCTL)

        if (HAVE_SYSCTL)
            message(CHECK_PASS "yes")
        else ()
            message(CHECK_FAIL "no")
        endif ()

        message(CHECK_START "Checking for sysctlbyname")
        check_c_source_compiles(
                "
                #include <stdio.h>
                #include <sys/types.h>
                #include <sys/sysctl.h>

                int main() {
                    return sysctlbyname(NULL,NULL,NULL,NULL,0);
                }
                "
                HAVE_SYSCTLBYNAME)

        if (HAVE_SYSCTLBYNAME)
            message(CHECK_PASS "yes")
        else ()
            message(CHECK_FAIL "no")
        endif ()
    endif ()

    set(pthreadHeaders "pthread.h")
    check_include_file("pthread_np.h" HAVE_PTHREAD_NP_H)
    if (HAVE_PTHREAD_NP_H)
        set(pthreadHeaders "${pthreadHeaders};pthread_np.h")
    endif ()

    check_symbol_exists("pthread_setaffinity_np" ${pthreadHeaders} HAVE_DECL_PTHREAD_SETAFFINITY_NP)
    check_symbol_exists("pthread_getaffinity_np" ${pthreadHeaders} HAVE_DECL_PTHREAD_GETAFFINITY_NP)

    find_library(HAVE_LIBM m)
    set(CMAKE_REQUIRED_LIBRARIES_BAK ${CMAKE_REQUIRED_LIBRARIES})
    if (HAVE_LIBM)
        set(need_libm "yes")
        set(CMAKE_REQUIRED_LIBRARIES "m")
    endif ()

    check_symbol_exists("fabsf" "math.h" HAVE_DECL_FABSF)
    check_symbol_exists("modff" "math.h" HAVE_DECL_MODFF)

    if (need_libm STREQUAL "yes")
        set(HWLOC_LIBS "-lm ${HWLOC_LIBS}")
    endif ()

    set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES_BAK})

    check_symbol_exists("_SC_NPROCESSORS_ONLN" "unistd.h" HAVE_DECL__SC_NPROCESSORS_ONLN)
    check_symbol_exists("_SC_NPROCESSORS_CONF" "unistd.h" HAVE_DECL__SC_NPROCESSORS_CONF)
    check_symbol_exists("_SC_NPROC_ONLN" "unistd.h" HAVE_DECL__SC_NPROC_ONLN)
    check_symbol_exists("_SC_NPROC_CONF" "unistd.h" HAVE_DECL__SC_NPROC_CONF)
    check_symbol_exists("_SC_PAGESIZE" "unistd.h" HAVE_DECL__SC_PAGESIZE)
    check_symbol_exists("_SC_PAGE_SIZE" "unistd.h" HAVE_DECL__SC_PAGE_SIZE)
    check_symbol_exists("_SC_LARGE_PAGESIZE" "unistd.h" HAVE_DECL__SC_LARGE_PAGESIZE)

    check_include_file("mach/mach_init.h" HAVE_MACH_MACH_INIT_H)
    check_include_file("mach_init.h" HAVE_MACH_INIT_H)
    check_include_file("mach/mach_host.h" HAVE_MACH_MACH_HOST_H)

    if (HAVE_MACH_MACH_HOST_H)
        check_symbol_exists("host_info" "mach/mach_host.h" HAVE_HOST_INFO)
    endif ()

    check_symbol_exists("strtoull" "stdlib.h" HAVE_STRTOULL)


    # Needed for Windows in private/misc.h1
    check_type_size("ssize_t" HAVE_SSIZE_T)
    check_symbol_exists("snprintf" "stdio.h" HAVE_DECL_SNPRINTF)
    # strdup and putenv are declared in windows headers but marked deprecated
    check_symbol_exists("_strdup" "string.h" HAVE_DECL__STRDUP)
    check_symbol_exists("_putenv" "stdlib.h" HAVE_DECL__PUTENV)
    # Could add mkdir and access for hwloc-gather-cpuid.c on Windows


    set(CMAKE_REQUIRED_QUIET 1)
    set(broken_snprintf "no")
    message(CHECK_START "Checking whether snprintf is correct")

    check_source_runs(C "
        #include <stdio.h>
        #include <string.h>
        #include <assert.h>

        int main() {
            char buf[7];
            assert(snprintf(buf, 7, \"abcdef\") == 6);
            assert(snprintf(buf, 6, \"abcdef\") == 6);
            assert(snprintf(buf, 5, \"abcdef\") == 6);
            assert(snprintf(buf, 0, \"abcdef\") == 6);
            assert(snprintf(NULL, 0, \"abcdef\") == 6);
            return 0;
        }
    " has_working_sprintf)

    if (has_working_sprintf)
        message(CHECK_PASS "yes")

    else ()
        message(CHECK_FAIL "no")
        set(broken_snprintf "yes")
    endif ()

    if (broken_snprintf STREQUAL "no")
        set(HWLOC_HAVE_CORRECT_SNPRINTF 1 CACHE BOOL "Define to 1 if snprintf supports NULL output buffer and returns the correct length on truncation")
    endif ()

    set(CMAKE_REQUIRED_QUIET 0)

    check_symbol_exists("getprogname" "stdlib.h" HAVE_DECL_GETPROGNAME)
    check_symbol_exists("getexecname" "stdlib.h" HAVE_DECL_GETEXECNAME)
    # program_invocation_name and __progname may be available but not exported in headers


    set(CMAKE_REQUIRED_QUIET 1)
    message(CHECK_START "Checking for program_invocation_name")

    check_c_source_compiles("
        #ifndef _GNU_SOURCE
        # define _GNU_SOURCE
        #endif
        #include <errno.h>
        #include <stdio.h>

        extern char *program_invocation_name;

        int main() {
            return printf(\"%s\", program_invocation_name);
        }
    " HAVE_PROGRAM_INVOCATION_NAME)

    if (HAVE_PROGRAM_INVOCATION_NAME)
        message(CHECK_PASS "yes")
    else ()
        message(CHECK_FAIL "no")
    endif ()

    message(CHECK_START "Checking for __progname")

    check_c_source_compiles("
        #include <stdio.h>
        extern char *__progname;

        int main() {
            return printf(\"%s\", __progname);
        }
    " HAVE___PROGNAME)

    if (HAVE___PROGNAME)
        message(CHECK_PASS "yes")
    else ()
        message(CHECK_FAIL "no")
    endif ()

    set(CMAKE_REQUIRED_QUIET 0)

    if(MINGW OR CYGWIN)
        set(hwloc_pid_t "HANDLE")
        set(hwloc_thread_t "HANDLE")
    else()
        set(hwloc_pid_t "pid_t")

        check_type_size("pthread_t" hwloc_thread_t_ok)

        if(hwloc_thread_t_ok)
            set(hwloc_thread_t "pthread_t")
        endif()
    endif()

    set(hwloc_pid_t ${hwloc_pid_t} CACHE INTERNAL "Define this to the process ID type")
    if (hwloc_thread_t)
        set(hwloc_thread_t ${hwloc_thread_t} CACHE INTERNAL "Define this to the thread ID type")
    endif ()

    check_symbol_exists("ffs" "strings.h" HAVE_FFS)
    if (HAVE_FFS)
        hwloc_check_decl("ffs" hwloc_have_decl_ffs "strings.h")
        if (hwloc_have_decl_ffs)
            set(HWLOC_HAVE_DECL_FFS 1 CACHE INTERNAL "Define to 1 if function `ffs' is declared by system headers")
        endif ()
        set(HWLOC_HAVE_FFS 1 CACHE INTERNAL "Define to 1 if you have the `ffs' function.")

        # May be broken due to
        #    https://forums.oracle.com/forums/thread.jspa?threadID=1997328
        # TODO: a more selective test, since bug may be version dependent.
        # We can't use AC_TRY_LINK because the failure does not appear until
        # run/load time and there is currently no precedent for AC_TRY_RUN
        # use in hwloc.  --PHH
        # For now, we're going with "all gccfss compilers are broken".
        # Better to be safe and correct; it's not like this is
        # performance-critical code, after all.

        # Check for GCC with known broken ffs
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            execute_process(
                    COMMAND ${CMAKE_C_COMPILER} --version
                    OUTPUT_VARIABLE cc_version_output
                    ERROR_QUIET
                    OUTPUT_STRIP_TRAILING_WHITESPACE
            )

            string(FIND "${cc_version_output}" "gccfss" gccfss_found)

            if (gccfss_found GREATER -1)
                set(HWLOC_HAVE_BROKEN_FFS 1 CACHE INTERNAL "Define to 1 if your `ffs' function is known to be broken.")
            endif()
        endif ()
    endif ()

    check_symbol_exists("ffsl" "strings.h" HAVE_FFSL)
    if (HAVE_FFSL)
        hwloc_check_decl("ffsl" hwloc_have_decl_ffsl "strings.h")
        if (hwloc_have_decl_ffsl)
            set(HWLOC_HAVE_DECL_FFSL 1 CACHE INTERNAL "Define to 1 if function `ffsl' is declared by system headers")
        endif ()
        set(HWLOC_HAVE_FFSL 1 CACHE INTERNAL "Define to 1 if you have the `ffsl' function.")
    endif ()

    check_symbol_exists("fls" "strings.h" HAVE_FLS)
    if (HAVE_FLS)
        hwloc_check_decl("fls" hwloc_have_decl_fls "strings.h")
        if (hwloc_have_decl_fls)
            set(HWLOC_HAVE_DECL_FLS 1 CACHE INTERNAL "Define to 1 if function `fls' is declared by system headers")
        endif ()
        set(HWLOC_HAVE_FLS 1 CACHE INTERNAL "Define to 1 if you have the `fls' function.")
    endif ()

    check_symbol_exists("flsl" "strings.h" HAVE_FLSL)
    if (HAVE_FLSL)
        hwloc_check_decl("flsl" hwloc_have_decl_flsl "strings.h")
        if (hwloc_have_decl_flsl)
            set(HWLOC_HAVE_DECL_FLSL 1 CACHE INTERNAL "Define to 1 if function `flsl' is declared by system headers")
        endif ()
        set(HWLOC_HAVE_FLSL 1 CACHE INTERNAL "Define to 1 if you have the `flsl' function.")
    endif ()

    check_symbol_exists("clz" "strings.h" HAVE_CLZ)
    if (HAVE_CLZ)
        hwloc_check_decl("clz" hwloc_have_decl_clz "strings.h")
        if (hwloc_have_decl_clz)
            set(HWLOC_HAVE_DECL_CLZ 1 CACHE INTERNAL "Define to 1 if function `clz' is declared by system headers")
        endif ()
        set(HWLOC_HAVE_CLZ 1 CACHE INTERNAL "Define to 1 if you have the `clz' function.")
    endif ()

    check_symbol_exists("clzl" "strings.h" HAVE_CLZL)
    if (HAVE_CLZL)
        hwloc_check_decl("clzl" hwloc_have_decl_clzl "strings.h")
        if (hwloc_have_decl_clzl)
            set(HWLOC_HAVE_DECL_CLZL 1 CACHE INTERNAL "Define to 1 if function `clzl' is declared by system headers")
        endif ()
        set(HWLOC_HAVE_CLZL 1 CACHE INTERNAL "Define to 1 if you have the `clzl' function.")
    endif ()


    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Android")
        check_symbol_exists(openat "fcntl.h" hwloc_have_openat)
    endif()

    check_include_file("malloc.h" HAVE_MALLOC_H)
    check_symbol_exists("getpagesize" "unistd.h" HAVE_GETPAGESIZE)
    check_symbol_exists("memalign" "malloc.h" HAVE_MEMALIGN)
    check_symbol_exists("posix_memalign" "stdlib.h" HAVE_POSIX_MEMALIGN)

    check_include_file("sys/utsname.h" HAVE_SYS_UTSNAME_H)

    check_symbol_exists("uname" "sys/utsname.h" HAVE_UNAME)

    # Components and pciaccess require pthread_mutex, see if it needs -lpthread

    set(hwloc_pthread_mutex_happy "no")
    # Try without explicit -lpthread first
    check_symbol_exists("pthread_mutex_lock" "pthread.h" pthread_mutex_lock_exists)
    if (pthread_mutex_lock_exists)
        set(HWLOC_LIBS_PRIVATE "${HWLOC_LIBS_PRIVATE} -lpthread")
        set(hwloc_pthread_mutex_happy "yes")
    else()
        message("trying again with -lpthread ...")
        # Try again with explicit -lpthread

        set(CMAKE_REQUIRED_LIBRARIES_BAK ${CMAKE_REQUIRED_LIBRARIES})
        set(CMAKE_REQUIRED_LIBRARIES "pthread")

        check_symbol_exists("pthread_mutex_lock" "pthread.h" pthread_mutex_lock_exists)
        if (pthread_mutex_lock_exists)
            set(HWLOC_LIBS "${HWLOC_LIBS} -lpthread")
            set(hwloc_pthread_mutex_happy "yes")
        endif ()

        set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES_BAK})
    endif ()

    if (hwloc_pthread_mutex_happy STREQUAL 1)
        set(HWLOC_HAVE_PTHREAD_MUTEX 1 CACHE INTERNAL "Define to 1 if pthread mutexes are available")
    endif ()

    if(NOT hwloc_pthread_mutex_happy STREQUAL "yes" AND NOT hwloc_windows STREQUAL "yes")
        message(WARNING "pthread_mutex_lock not available, required for thread-safe initialization on non-Windows platforms.")
        message(WARNING "Please report this to the hwloc-users mailing list or at https://github.com/open-mpi/hwloc")
        message(FATAL_ERROR "Cannot continue")
    endif()

    # Don't check for valgrind in embedded mode because this may conflict
    # with the embedder projects also checking for it.
    # We only use Valgrind to nicely disable the x86 backend with a warning,
    # but we can live without it in embedded mode (it auto-disables itself
    # because of invalid CPUID outputs).
    # Non-embedded checks usually go to hwloc_internal.m4 but this one is
    # is really for the core library.
    if (NOT hwloc_mode STREQUAL "embedded")
        check_include_file("valgrind/valgrind.h" HAVE_VALGRIND_VALGRIND_H)
        check_symbol_exists("RUNNING_ON_VALGRIND" "valgrind/valgrind.h" HAVE_DECL_RUNNING_ON_VALGRIND)
    else()
        set(HAVE_DECL_RUNNING_ON_VALGRIND 0 INTERNAL BOOL CACHE "Embedded mode; just assume we do not have Valgrind support")
    endif ()

    # PCI support via libpciaccess.  NOTE: we do not support
    # libpci/pciutils because that library is GPL and is incompatible
    # with our BSD license.

    if (ENABLE_IO STREQUAL ON AND ENABLE_PCI STREQUAL ON)
        message("")
        message("**** pciaccess configuration")

        set(hwloc_pciaccess_happy "yes")

        hwloc_pkg_check_modules(PCIACCESS pciaccess pci_slot_match_iterator_create "pciaccess.h")

        if (NOT DEFINED HAVE_PCIACCESS)
            set(hwloc_pciaccess_happy "no")
        endif ()

        # Only add the REQUIRES if we got pciaccess through pkg-config.
        # Otherwise we don't know if pciaccess.pc is installed
        if (hwloc_pciaccess_happy STREQUAL "yes")
            set(HWLOC_PCIACCESS_REQUIRES "pciaccess" CACHE INTERNAL "")
        endif ()

        # Just for giggles, if we didn't find a pciaccess pkg-config,
        # just try looking for its header file and library.
        if (NOT hwloc_pciaccess_happy STREQUAL "yes")
            check_include_file("pciaccess.h" HAVE_PCIACCESS_H)
            if (HAVE_PCIACCESS_H)
                find_library(HAVE_PCIACCESS pciaccess)
                if (HAVE_PCIACCESS)
                    set(hwloc_pciaccess_happy "yes")
                    set(HWLOC_PCIACCESS_LIBS "-lpciaccess" CACHE INTERNAL "")
                endif ()
            endif ()
        endif ()

        if (hwloc_pciaccess_happy STREQUAL "yes")
            set(hwloc_components "${hwloc_components} pci")
            set(hwloc_pci_component_maybeplugin 1)
        endif ()

        message("**** end of pciaccess configuration")
    endif ()

    if (ENABLE_PCI STREQUAL ON AND hwloc_pciaccess_happy STREQUAL "no")
        message(WARNING "Specified --enable-pci switch, but could not")
        message(WARNING "find appropriate support")
        message(FATAL_ERROR "Cannot continue")
    endif ()
    # don't add LIBS/CFLAGS/REQUIRES yet, depends on plugins

    # TODO: Nvidia/CUDA/NVLM/RSMI/ROCM/OpenCL/LevelZero/GL config

    set(hwloc_libxml2_happy "no")
    if (ENABLE_LIBXML2 STREQUAL ON)
        message("")
        message("**** libxml2 configuration")

        set(hwloc_libxml2_happy 0)

        hwloc_pkg_check_modules(LIBXML2 libxml-2.0 xmlNewDoc "libxml/parser.h")
        if (HAVE_LIBXML2)
            set(hwloc_libxml2_happy "yes")
        else ()
            set(hwloc_libxml2_happy "no")
        endif ()

        message("**** end of libxml2 configuration")
    endif ()

    if (hwloc_libxml2_happy STREQUAL "yes")
        set(HWLOC_LIBXML2_REQUIRES "libxml-2.0" CACHE INTERNAL STRING "")
        set(HWLOC_HAVE_LIBXML2 1 CACHE INTERNAL BOOL "Define to 1 if you have the `libxml2' library.")
        set(hwloc_components "${hwloc_components} xml_libxml")
        set(hwloc_xml_libxml_component_maybeplugin 1)
    else ()
        set(HWLOC_HAVE_LIBXML2 0 CACHE INTERNAL BOOL "Define to 1 if you have the `libxml2' library.")

        if (ENABLE_LIBXML2 STREQUAL ON)
            message(WARNING "--enable-libxml2 requested, but libxml2 was not found")
            message(FATAL_ERROR "Cannot continue")
        endif ()
    endif ()
    # don't add LIBS/CFLAGS/REQUIRES yet, depends on plugins

    # Try to compile the x86 cpuid inlines
    if (ENABLE_CPUID STREQUAL ON)
        message("")
        message("**** x86 CPUID configuration")

        message(CHECK_START "Checking for x86 cpuid")
        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
        set(CMAKE_REQUIRED_FLAGS "-I${HWLOC_top_srcdir}/include")

        # We need hwloc_uint64_t but we can't use autogen/config.h before configure ends.
        # So pass #include/#define manually here for now.

        if (hwloc_windows STREQUAL "yes")
            set(X86_CPUID_CHECK_HEADERS "#include <windows.h>")
            set(X86_CPUID_CHECK_DEFINE "#define hwloc_uint64_t DWORDLONG")
        else ()
            set(X86_CPUID_CHECK_DEFINE "#define hwloc_uint64_t uint64_t")
            if (HAVE_STDINT_H)
                set(X86_CPUID_CHECK_HEADERS "#include <stdint.h>")
            endif ()
        endif ()

        set(CMAKE_REQUIRED_QUIET 1)
        check_c_source_compiles("
                	    #include <stdio.h>
                        ${X86_CPUID_CHECK_HEADERS}
                        ${X86_CPUID_CHECK_DEFINE}
                        #define __hwloc_inline
        	            #include <private/cpuid-x86.h>

        	            int main(){
        	                if (hwloc_have_x86_cpuid()) {
        		                unsigned eax = 0, ebx, ecx = 0, edx;
        		                hwloc_x86_cpuid(&eax, &ebx, &ecx, &edx);
        		                printf(\"highest x86 cpuid %x\", eax);
        		                return 0;
        	                 }
        	                return 0;
        	            }
                " x86_cpuid_compiles)
        set(CMAKE_REQUIRED_QUIET 0)

        if (x86_cpuid_compiles)
            message(CHECK_PASS "yes")
            set(HWLOC_HAVE_X86_CPUID 1 CACHE BOOL "Define to 1 if you have x86 cpuid")
            set(hwloc_have_x86_cpuid "yes")
        else ()
            message(CHECK_PASS "no")
            set(hwloc_have_x86_cpuid "no")
        endif ()

        if (hwloc_have_x86_cpuid STREQUAL "yes")
            set(hwloc_components "${hwloc_components} x86")
        endif ()

        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})

        message("**** end of x86 CPUID configuration")
    endif ()


    #
    # Now enable registration of listed components
    #

    message("")
    message("**** component and plugin-specific configuration")

    # Plugin support
    message(CHECK_START "Checking if plugin support is enabled")
    # Plugins (even core support) are totally disabled by default.
    # Pass --enable-plugins=foo (with "foo" NOT an existing component) to enable plugins but build none of them.

    if (ENABLE_PLUGINS STREQUAL "")
        set(hwloc_have_plugins "yes")
        set(requested_plugins ${hwloc_components})
    elseif (NOT ENABLE_PLUGINS STREQUAL "-1")
        set(hwloc_have_plugins "yes")
        string(REPLACE "," " " requested_plugins "${ENABLE_PLUGINS}")
    else ()
        set(hwloc_have_plugins "no")
        set(requested_plugins " ")
    endif ()

    message(CHECK_PASS ${hwloc_have_plugins})

    if (hwloc_have_plugins STREQUAL yes)
        # dlopen and ltdl (at least 2.4.2) doesn't work on AIX
        # posix linkers don't work well with plugins and windows dll constraints
        if (ENABLE_PLUGIN_DLOPEN STREQUAL ON)
            if (hwloc_aix STREQUAL "yes")
                message(WARNING "dlopen does not work on AIX, disabled by default.")
                set(enable_plugin_dlopen "no")
            elseif (hwloc_windows STREQUAL "yes")
                message(WARNING "dlopen not supported on non-native Windows build, disabled by default.")
                set(enable_plugin_dlopen "no")
            endif ()
        endif ()

        if (ENABLE_PLUGIN_LTDL STREQUAL ON)
            if (hwloc_aix STREQUAL "yes")
                message(WARNING "ltdl does not work on AIX, disabled by default.")
                set(enable_plugin_dlopen no)
            elseif (hwloc_windows STREQUAL "yes")
                message(WARNING "ltdl not supported on non-native Windows build, disabled by default.")
                set(enable_plugin_dlopen "no")
            endif ()
        endif ()

        if (NOT enable_plugin_dlopen STREQUAL "no")
            hwloc_check_dlopen(hwloc_dlopen_ready hwloc_dlopen_libs)
        endif ()

        if (ENABLE_PLUGIN_LTDL STREQUAL ON)
            hwloc_check_ltdl(hwloc_ltdl_ready hwloc_ltdl_libs)
        endif ()

        # Now use dlopen by default, or ltdl, or just fail to enable plugins
        message(CHECK_START "Checking which library to use for loading plugins")

        if (hwloc_dlopen_ready STREQUAL "yes")
            message(CHECK_PASS "dlopen")
            set(hwloc_plugins_load dlopen)

            # Now enable dlopen libs
            set(HWLOC_DL_LIBS ${hwloc_dlopen_libs} CACHE STRING "")
        elseif (hwloc_ltdl_ready STREQUAL "yes")
            message(CHECK_PASS "ltdl")
            set(hwloc_plugins_load ltdl)

            # Now enable ltdl libs
            set(HWLOC_HAVE_LTDL 1 CACHE INTERNAL "")
            set(HWLOC_LTDL_LIBS ${hwloc_ltdl_libs} CACHE STRING "Define to 1 if the hwloc library should use ltdl for loading plugins")

            # Add ltdl static-build dependencies to hwloc.pc
            hwloc_check_ltdl_deps()
        else ()
            message(CHECK_FAIL "none")
            message(FATAL_ERROR "Plugin support requested, but could not enable dlopen or ltdl, Cannot continue")
        endif ()

        add_definitions(HWLOC_HAVE_PLUGINS 1 CACHE BOOL "Define to 1 if the hwloc library should support dynamically-loaded plugins")

    endif ()

    # HWLOC_PLUGINS_PATH is defined in AC_ARG_WITH([hwloc-plugins-path]...)
    set(HWLOC_PLUGINS_PATH "" CACHE STRING "")
    set(HWLOC_PLUGINS_DIR "" CACHE STRING "")
    string(SUBSTRING "${HWLOC_PLUGINS_PATH}" 0 ":" HWLOC_PLUGINS_DIR)

    # Static components output file
    set(hwloc_static_components_dir "${HWLOC_top_builddir}/hwloc")
    set(hwloc_static_components_file "${hwloc_static_components_dir}/static-components.h")

    hwloc_prepare_filter_components(${requested_plugins})
    # Now we have some hwloc_<name>_component_wantplugin=1

    # See which core components want plugin and support it
    hwloc_filter_components()

    # Now we have some hwloc_<name>_component=plugin/static
    # and hwloc_static/plugin_components=list (space separated)
    message(CHECK_START "Checking for components to build statically")
    message(CHECK_PASS ${hwloc_static_components})
    hwloc_list_static_components("${hwloc_static_components_file}" ${hwloc_static_components})
    message(CHECK_START "Checking for components to build as plugins")
    message(CHECK_PASS ${hwloc_plugin_components})

    if (hwloc_pci_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_PCIACCESS_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_PCIACCESS_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_PCIACCESS_CPPFLAGS} ${HWLOC_PCIACCESS_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_PCIACCESS_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_PCI_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the PCI component is built statically inside libhwloc")
    endif ()

    if (hwloc_opencl_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_OPENCL_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_OPENCL_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_OPENCL_CPPFLAGS} ${HWLOC_OPENCL_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_OPENCL_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_OPENCL_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the OpenCL component is built statically inside libhwloc")
    endif ()

    if (hwloc_cuda_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_CUDART_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_CUDART_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_CUDART_CPPFLAGS} ${HWLOC_CUDART_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_CUDART_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_CUDA_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the OpenCL component is built statically inside libhwloc")
    endif ()

    if (hwloc_nvml_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_NVML_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_NVML_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_NVML_CPPFLAGS} ${HWLOC_NVML_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_NVML_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_NVML_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the NVML component is built statically inside libhwloc")
    endif ()

    if (hwloc_rsmi_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_RSMI_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_RSMI_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_RSMI_CPPFLAGS} ${HWLOC_RSMI_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_RSMI_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_RSMI_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the RSMI component is built statically inside libhwloc")
    endif ()

    if (hwloc_levelzero_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_LEVELZERO_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_LEVELZERO_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_LEVELZERO_CPPFLAGS} ${HWLOC_LEVELZERO_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_LEVELZERO_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_LEVELZERO_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the LevelZero component is built statically inside libhwloc")
    endif ()

    if (hwloc_xml_libxml_component STREQUAL "static")
        set(HWLOC_LIBS "${HWLOC_LIBS} ${HWLOC_LIBXML2_LIBS}")
        set(HWLOC_LDFLAGS "${HWLOC_LDFLAGS} ${HWLOC_LIBXML2_LDFLAGS}")
        set(HWLOC_CFLAGS "${HWLOC_CFLAGS} ${HWLOC_LIBXML2_CPPFLAGS} ${HWLOC_LIBXML2_CFLAGS}")
        set(HWLOC_REQUIRES "${HWLOC_LIBXML2_REQUIRES} ${HWLOC_REQUIRES}")
        set(HWLOC_XML_LIBXML_COMPONENT_BUILTIN 1 CACHE BOOL "Define if the libxml XML component is built statically inside libhwloc")
    endif ()

    message("**** end of component and plugin configuration")

    #
    # Setup HWLOC's C, CPP, and LD flags, and LIBS
    #
    set(HWLOC_REQUIRES ${HWLOC_REQUIRES} CACHE INTERNAL "")
    set(HWLOC_CFLAGS ${HWLOC_CFLAGS} CACHE INTERNAL "")
    set(HWLOC_CPPFLAGS "-I\"${HWLOC_top_builddir}/include\" -I\"${HWLOC_top_srcdir}/include\"")
    set(HWLOC_CPPFLAGS ${HWLOC_CPPFLAGS} CACHE INTERNAL "")
    set(HWLOC_LDFLAGS ${HWLOC_LDFLAGS} CACHE INTERNAL "")
    set(HWLOC_LIBS ${HWLOC_LIBS} CACHE INTERNAL "")
    set(HWLOC_LIBS_PRIVATE ${HWLOC_LIBS_PRIVATE} CACHE INTERNAL "")

    # Set these values explicitly for embedded builds.  Exporting
    # these values through *_EMBEDDED_* values gives us the freedom to
    # do something different someday if we ever need to.  There's no
    # need to fill these values in unless we're in embedded mode.
    # Indeed, if we're building in embedded mode, we want HWLOC_LIBS
    # to be empty so that nothing is linked into libhwloc_embedded.la
    # itself -- only the upper-layer will link in anything required.

    if (hwloc_mode STREQUAL "embedded")
        set(HWLOC_EMBEDDED_CFLAGS ${HWLOC_CFLAGS})
        set(HWLOC_EMBEDDED_CPPFLAGS ${HWLOC_CPPFLAGS})
        set(HWLOC_EMBEDDED_LDFLAGS ${HWLOC_LDFLAGS})
        set(HWLOC_EMBEDDED_LDADD "${HWLOC_top_builddir}/hwloc/libhwloc_embedded.la")
        set(HWLOC_EMBEDDED_LIBS ${HWLOC_LIBS})
        set(HWLOC_LIBS "")
    endif ()

    set(HWLOC_EMBEDDED_CFLAGS ${HWLOC_EMBEDDED_CFLAGS} CACHE INTERNAL "")
    set(HWLOC_EMBEDDED_CPPFLAGS ${HWLOC_EMBEDDED_CPPFLAGS} CACHE INTERNAL "")
    set(HWLOC_EMBEDDED_LDFLAGS ${HWLOC_EMBEDDED_LDFLAGS} CACHE INTERNAL "")
    set(HWLOC_EMBEDDED_LDADD ${HWLOC_EMBEDDED_LDADD} CACHE INTERNAL "")
    set(HWLOC_EMBEDDED_LIBS ${HWLOC_EMBEDDED_LIBS} CACHE INTERNAL "")


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

function(hwloc_check_dlopen variable lib_variable)
    message(CHECK_START "Checking for dlopen")

    set(CMAKE_REQUIRED_QUIET 1)
    check_c_source_compiles("
      #include <dlfcn.h>
      #include <stdlib.h>
      void *handle;

      int main(){
        handle = dlopen(NULL, RTLD_NOW|RTLD_LOCAL);
        return 0;
      }
    " DLOPEN_COMPILES)
    set(CMAKE_REQUIRED_QUIET 0)

    set(${variable} "no" PARENT_SCOPE)
    set(${lib_variable} "" PARENT_SCOPE)
    if (DLOPEN_COMPILES)
        message(CHECK_PASS "yes")
        set(${variable} "yes" PARENT_SCOPE)
    else ()
        message(CHECK_PASS "no")
        check_include_file("dlfcn.h" HAVE_DLFCN_H)
        if (HAVE_DLFCN_H)
            find_library(DL_LIBRARY NAMES dl)

            if (DL_LIBRARY)
                set(${variable} "yes" PARENT_SCOPE)
                set(${lib_variable} "-ldl" PARENT_SCOPE)
            endif ()
        endif ()
    endif ()
endfunction()

function(hwloc_check_ltdl variable lib_variable)
    set(${variable} "no" PARENT_SCOPE)
    set(${lib_variable} "" PARENT_SCOPE)
    check_include_file("ltdl.h" HAVE_LTDL_H)
    if (HAVE_LTDL_H)
        find_library(LTDL_LIBRARY NAMES ltdl)
        if (LTDL_LIBRARY)
            set(${variable} "yes" PARENT_SCOPE)
            set(${lib_variable} "-lltdl" PARENT_SCOPE)
        endif ()
    endif ()
endfunction()

function(hwloc_check_ltdl_deps)

    # save variables that we'll modify below
    set(save_lt_cv_dlopen ${lt_cv_dlopen})
    set(save_lt_cv_dlopen_libs ${lt_cv_dlopen_libs})
    set(save_lt_cv_dlopen_self ${lt_cv_dlopen_self})

    if (CMAKE_SYSTEM_NAME MATCHES "BeOS")
        set(HWLOC_LT_CV_DLOPEN "load_add_on")
        set(HWLOC_LT_CV_DLOPEN_LIBS "")
        set(HWLOC_LT_CV_DLOPEN_SELF TRUE)
    elseif (CMAKE_SYSTEM_NAME MATCHES "Mingw" OR CMAKE_SYSTEM_NAME MATCHES "pw32" OR CMAKE_SYSTEM_NAME MATCHES "cegcc")
        set(HWLOC_LT_CV_DLOPEN "LoadLibrary")
        set(HWLOC_LT_CV_DLOPEN_LIBS "")
    elseif (CMAKE_SYSTEM_NAME MATCHES "Cygwin")
        set(HWLOC_LT_CV_DLOPEN "dlopen")
        set(HWLOC_LT_CV_DLOPEN_LIBS "")
    elseif (CMAKE_SYSTEM_NAME MATCHES "Darwin")
        find_library(DARWIN_LIBDL NAMES dl)
        if (DARWIN_LIBDL)
            set(HWLOC_LT_CV_DLOPEN "dlopen")
            set(HWLOC_LT_CV_DLOPEN_LIBS "-ldl")
        else()
            set(HWLOC_LT_CV_DLOPEN "dyld")
            set(HWLOC_LT_CV_DLOPEN_LIBS "")
            set(HWLOC_LT_CV_DLOPEN_SELF TRUE)
        endif()
    else()
        check_function_exists(shl_load HWLOC_HAVE_SHL_LOAD)
        if (HWLOC_HAVE_SHL_LOAD)
            set(HWLOC_LT_CV_DLOPEN "shl_load")
        else()
            find_library(DLD_LIB NAMES dld)
            if (DLD_LIB)
                set(HWLOC_LT_CV_DLOPEN "shl_load")
                set(HWLOC_LT_CV_DLOPEN_LIBS "-ldld")
            else()
                check_function_exists(dlopen HWLOC_HAVE_DLOPEN)
                if (HWLOC_HAVE_DLOPEN)
                    set(HWLOC_LT_CV_DLOPEN "dlopen")
                else()
                    find_library(DL_LIB NAMES dl)
                    if (DL_LIB)
                        set(HWLOC_LT_CV_DLOPEN "dlopen")
                        set(HWLOC_LT_CV_DLOPEN_LIBS "-ldl")
                    else()
                        find_library(SVLD_LIB NAMES svld)
                        if (SVLD_LIB)
                            set(HWLOC_LT_CV_DLOPEN "dlopen")
                            set(HWLOC_LT_CV_DLOPEN_LIBS "-lsvld")
                        else()
                            find_library(DLD_LINK_LIB NAMES dld)
                            if (DLD_LINK_LIB)
                                set(HWLOC_LT_CV_DLOPEN "dld_link")
                                set(HWLOC_LT_CV_DLOPEN_LIBS "-ldld")
                            endif()
                        endif()
                    endif()
                endif()
            endif()
        endif()
    endif()

    if (NOT DEFINED HWLOC_LT_CV_DLOPEN)
        set(HWLOC_LT_CV_DLOPEN "dlopen")
        set(HWLOC_LT_CV_DLOPEN_LIBS "")
    endif()

    set(HWLOC_LIBS_PRIVATE "${HWLOC_LIBS_PRIVATE} ${HWLOC_LT_CV_DLOPEN_LIBS}")

    # restore modified variable in case the actual libtool code uses them
    set(lt_cv_dlopen ${save_lt_cv_dlopen})
    set(lt_cv_dlopen_libs ${save_lt_cv_dlopen_libs})
    set(lt_cv_dlopen_self ${save_lt_cv_dlopen_self})
endfunction()