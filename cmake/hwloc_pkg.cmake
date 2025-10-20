include(FindPkgConfig)

function(hwloc_pkg_prog_pkg_config)
    if (hwloc_pkg_prog_pkg_config_CALLED)
        return()
    endif()
    set(hwloc_pkg_prog_pkg_config_CALLED 1 CACHE BOOL "")

    set(PKG_CONFIG "" CACHE PATH "Specify the path to pkg-config utility")

    if (NOT DEFINED ENV{PKG_CONFIG})
        set(ENV{PKG_CONFIG} ${PKG_CONFIG_EXECUTABLE})
    endif ()

    if (PKG_CONFIG OR PKG_CONFIG_FOUND)
        if (NOT DEFINED ${minVersion})
            set(HWLOC_pkg_min_version "0.9.0")
        else ()
            set(HWLOC_pkg_min_version ${minVersion})
        endif ()

        message(CHECK_START "pkg-config is at least version ${HWLOC_pkg_min_version}")
        execute_process(
                COMMAND ${PKG_CONFIG_EXECUTABLE} --atleast-pkgconfig-version ${HWLOC_pkg_min_version}
                RESULT_VARIABLE PKGCONFIG_VERSION_CHECK_RESULT
        )

        if (PKGCONFIG_VERSION_CHECK_RESULT EQUAL 0)
            message(CHECK_PASS "yes")
        else ()
            set(PKG_CONFIG "")
            message(CHECK_FAIL "no")
        endif ()
    endif ()
endfunction()

function(hwloc_pkg_check_exists package)
    hwloc_pkg_prog_pkg_config()

    if (PKG_CONFIG_EXECUTABLE)
        execute_process(
                COMMAND ${PKG_CONFIG_EXECUTABLE} --exists --silence-errors "${package}"
                RESULT_VARIABLE PKGCONFIG_CHECK_RESULT
        )
    endif ()

    if (PKGCONFIG_CHECK_RESULT EQUAL 0)
        set(${package}_FOUND 1 PARENT_SCOPE)
    endif ()
endfunction()

function(_hwloc_pkg_config variable command modules)
    hwloc_pkg_prog_pkg_config()

    set(HWLOC_pkg_failed no PARENT_SCOPE)
    if (PKG_CONFIG_FOUND)
        hwloc_pkg_check_exists(${modules})
        if (${${modules}_FOUND})
            execute_process(
                    COMMAND ${PKG_CONFIG_EXECUTABLE} --${command} "${modules}"
                    OUTPUT_VARIABLE PKGCONFIG_CHECK_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            set(HWLOC_pkg_cv_${variable} "${PKGCONFIG_CHECK_RESULT}" PARENT_SCOPE)
        else ()
            set(HWLOC_pkg_failed yes PARENT_SCOPE)
        endif ()
    else ()
        set(HWLOC_pkg_failed untried PARENT_SCOPE)
    endif ()
endfunction()

function(_hwloc_pkg_short_errors_supported)
    hwloc_pkg_prog_pkg_config()
    if (PKG_CONFIG_FOUND)
        execute_process(
                COMMAND ${PKG_CONFIG_EXECUTABLE} --atleast-pkgconfig-version 0.20
                RESULT_VARIABLE PKGCONFIG_CHECK_RESULT
        )
        if (PKGCONFIG_CHECK_RESULT EQUAL 0)
            set(HWLOC_pkg_short_errors_supported 1 CACHE STRING "")
        else ()
            set(HWLOC_pkg_short_errors_supported 0 CACHE STRING "")
        endif ()
    endif ()
endfunction()


function(hwloc_pkg_check_modules variable modules function header)
    hwloc_pkg_prog_pkg_config()

    message(CHECK_START "checking for ${variable}")
    _hwloc_pkg_config(HWLOC_${variable}_CFLAGS cflags ${modules})
    _hwloc_pkg_config(HWLOC_${variable}_LIBS libs ${modules})

    if (${HWLOC_pkg_failed} STREQUAL yes)
        _hwloc_pkg_short_errors_supported()
        if (${HWLOC_pkg_short_errors_supported})
            execute_process(
                    COMMAND ${PKG_CONFIG_EXECUTABLE} --short-errors --errors-to-stdout --print-errors "${modules}" 2>&1
                    OUTPUT_VARIABLE PKGCONFIG_CHECK_RESULT
            )
            set(HWLOC_${variable}_PKG_ERRORS ${PKGCONFIG_CHECK_RESULT} CACHE STRING "")
        else ()
            execute_process(
                    COMMAND ${PKG_CONFIG_EXECUTABLE} --errors-to-stdout --print-errors "${modules}" 2>&1
                    OUTPUT_VARIABLE PKGCONFIG_CHECK_RESULT
            )
            set(HWLOC_${variable}_PKG_ERRORS ${PKGCONFIG_CHECK_RESULT} CACHE STRING "")
        endif ()
        warning(${HWLOC_${variable}_PKG_ERRORS})
    else()
        message(CHECK_PASS yes)
        # If we got good results from pkg-config, check that they
        # actually work (i.e., that we can link against the resulting
        # $LIBS).  The canonical example why we do this is if
        # pkg-config returns 64 bit libraries but ./configure was run
        # with CFLAGS=-m32 LDFLAGS=-m32.  pkg-config gave us valid
        # results, but we'll fail if we try to link.  So detect that
        # failure now.
        # There are also cases on Mac where pkg-config returns paths
        # that do not actually exists until some magic is applied.
        # https://www.open-mpi.org/community/lists/hwloc-devel/2015/03/4402.php
        # So check whether we find the header as well.

        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
        set(CMAKE_REQUIRED_FLAGS ${HWLOC_pkg_cv_HWLOC_${variable}_CFLAGS})
        set(CMAKE_REQUIRED_LIBRARIES_BAK ${CMAKE_REQUIRED_LIBRARIES})
        set(CMAKE_REQUIRED_LIBRARIES ${HWLOC_pkg_cv_HWLOC_${variable}_LIBS})

        set(hwloc_result 0)
        check_include_file(${header} ${variable}_HEADER_FOUND)
        if (${variable}_HEADER_FOUND)
            check_function_exists(${function} ${variable}_${function}_FOUND)
            if (${variable}_${function}_FOUND)
                set(hwloc_result 1)
            endif ()
        endif ()

        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})
        set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES_BAK})

        message(CHECK_START "Checking for final ${variable} support")

        if (${hwloc_result} STREQUAL 1)
            set(HWLOC_${variable}_CFLAGS ${HWLOC_pkg_cv_HWLOC_${variable}_CFLAGS} PARENT_SCOPE)
            set(HWLOC_${variable}_LIBS ${HWLOC_pkg_cv_HWLOC_${variable}_LIBS} PARENT_SCOPE)
            message(CHECK_PASS yes)
            set(HAVE_${variable} 1 PARENT_SCOPE)
        else ()
            message(CHECK_PASS no)
            set(HAVE_${variable} 0 PARENT_SCOPE)
        endif ()
    endif()

endfunction()