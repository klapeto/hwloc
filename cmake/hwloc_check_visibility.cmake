function(hwloc_check_visibility)
    # Check if the compiler has support for visibility, like some
    # versions of gcc, icc, Sun Studio cc.
    include(CheckCSourceCompiles)

    option(ENABLE_VISIBILITY "Enable visibility feature of certain compilers/linkers" ON)

    if (CMAKE_SYSTEM_NAME MATCHES "AIX" OR CMAKE_SYSTEM_NAME MATCHES "MSYS" OR CMAKE_SYSTEM_NAME MATCHES "MINGW" OR CMAKE_SYSTEM_NAME MATCHES "CYGWIN" OR CMAKE_SYSTEM_NAME MATCHES "HP-UX")
        set(ENABLE_VISIBILITY NO)
    endif ()

    if (NOT ENABLE_VISIBILITY)
        message(STATUS "Symbol visibility: no (disabled)")
    else ()

        set(HWLOC_WARNING_FLAGS)
        if (CMAKE_C_COMPILER_ID STREQUAL "SunPro")
            # Check using Sun Studio -xldscope=hidden flag
            set(HWLOC_VISIBILITY_TEST_FLAGS "-xldscope=hidden")
            set(HWLOC_WARNING_FLAGS "-errwarn=%all")
        else ()
            # Check using -fvisibility=hidden
            set(HWLOC_VISIBILITY_TEST_FLAGS "-fvisibility=hidden")
            set(HWLOC_WARNING_FLAGS "-Werror")
        endif ()

        set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} ${HWLOC_VISIBILITY_TEST_FLAGS} ${HWLOC_WARNING_FLAGS}")
        check_c_source_compiles("
                #include <stdio.h>
                __attribute__((visibility(\"default\"))) int foo;
                int main(){
                    fprintf(stderr, \"Hello, world\");
                    return 0;
                }
                "
                HWLOC_HAVE_VISIBILITY
        )

        if (HWLOC_HAVE_VISIBILITY)
            set(HWLOC_VISIBILITY_CFLAGS ${HWLOC_VISIBILITY_TEST_FLAGS} CACHE INTERNAL "")
            set(HWLOC_C_HAVE_VISIBILITY ${HWLOC_HAVE_VISIBILITY} CACHE INTERNAL "")
        elseif (ENABLE_VISIBILITY)
            message(FATAL_ERROR "Symbol visibility support requested but compiler does not seem to support it.  Aborting")
        else()
            message("Visibility is not supported")
        endif ()

        add_definitions(-DHWLOC_C_HAVE_VISIBILITY=${HWLOC_HAVE_VISIBILITY})

    endif ()
endfunction()