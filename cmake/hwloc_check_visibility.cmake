function(hwloc_check_visibility)
    # Check if the compiler has support for visibility, like some
    # versions of gcc, icc, Sun Studio cc.
    include(CheckCSourceCompiles)

    option(ENABLE_VISIBILITY "enable visibility feature of certain compilers/linkers (default: enabled on platforms that support it)" ON)

    if (CMAKE_SYSTEM_NAME MATCHES "AIX" OR CMAKE_SYSTEM_NAME MATCHES "MSYS" OR CMAKE_SYSTEM_NAME MATCHES "MINGW" OR CMAKE_SYSTEM_NAME MATCHES "CYGWIN" OR CMAKE_SYSTEM_NAME MATCHES "HP-UX")
        set(ENABLE_VISIBILITY NO)
    endif ()

    set(hwloc_visibility_define 0)
    set(hwloc_msg "whether to enable symbol visibility")

    if (NOT ENABLE_VISIBILITY)
        message(CHECK_START ${hwloc_msg})
        message(CHECK_FAIL "no (disabled)")
    else ()

        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})

        set(hwloc_add "")
        if (CMAKE_C_COMPILER_ID STREQUAL "SunPro")
            # Check using Sun Studio -xldscope=hidden flag
            set(hwloc_add "-xldscope=hidden")
            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} ${hwloc_add} -errwarn=%all")
        else ()
            # Check using -fvisibility=hidden
            set(hwloc_add "-fvisibility=hidden")
            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} ${hwloc_add} -Werror")
        endif ()

        message(CHECK_START "Checking if ${CMAKE_C_COMPILER_ID} supports ${hwloc_add}")
        check_c_source_compiles("
            #include <stdio.h>
            __attribute__((visibility(\"default\"))) int foo;

            int main(){
                fprintf(stderr, \"Hello, world\");
                return 0;
            }" COMPILES FAIL_REGEX "[Ww]arn.+visibility")

        if (COMPILES)
            message(CHECK_PASS "yes")
        else ()
            message(CHECK_PASS "no")
        endif ()

        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})

        set(HWLOC_VISIBILITY_CFLAGS ${hwloc_add} CACHE INTERNAL "")

        if (NOT hwloc_add STREQUAL "")
            set (hwloc_visibility_define 1)
            message(CHECK_START "Checking ${hwloc_msg}")
            message(CHECK_PASS "yes (via ${hwloc_add})")
        elseif(ENABLE_VISIBILITY STREQUAL ON)
            message(FATAL_ERROR "Symbol visibility support requested but compiler does not seem to support it.  Aborting")
        else ()
            message(CHECK_START "Checking ${hwloc_msg}")
            message(CHECK_PASS "no (unsupported)")
        endif ()

        set(HWLOC_C_HAVE_VISIBILITY ${hwloc_visibility_define} CACHE BOOL "Whether C compiler supports symbol visibility or not")
        add_definitions(-DHWLOC_C_HAVE_VISIBILITY=${hwloc_visibility_define})
    endif ()
endfunction()