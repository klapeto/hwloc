function(hwloc_check_specific_attribute attribute check_code cross_check_code additional_flags)
    message(CHECK_START "Checking for for __attribute__([${attribute}])")

    #
    # Try to compile using the C compiler
    #
    check_c_source_compiles("${check_code}"
            hwloc_cv___attribute__${attribute}
            FAIL_REGEX "[iI]gnore|[sS]kip"
    )

    #
    # If the attribute is supported by both compilers,
    # try to recompile a *cross-check*, IFF defined.
    #
    if (hwloc_cv___attribute__${attribute} AND NOT cross_check_code STREQUAL "")
        set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
        set(CMAKE_REQUIRED_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror")

        check_c_source_compiles("${cross_check_code}
                int main() {
                   int i=4711;
                   i=usage(&i);
                   return 0;
                }
        "
                hwloc_cv___attribute__${attribute}
                FAIL_REGEX "[iI]gnore|[sS]kip"
        )

        set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_BAK})
    endif ()

    if (hwloc_cv___attribute__${attribute} STREQUAL 1)
        message(CHECK_PASS yes)
    else ()
        message(CHECK_PASS no)
    endif ()

endfunction()

function(hwloc_check_attributes)
    include(CheckCSourceCompiles)

    set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
    set(CMAKE_REQUIRED_QUIET TRUE)

    message(CHECK_START "Checking for __attribute__")

    check_c_source_compiles("
            #include <stdlib.h>

            int main() {
                 /* Check for the longest available __attribute__ (since gcc-2.3) */
                 struct foo {
                   char a;
                   int x[2] __attribute__ ((__packed__));
                 };
                 return 0;
            }
            "
            hwloc_cv___attribute__
            FAIL_REGEX "[iI]gnore|[sS]kip"
    )

    if (hwloc_cv___attribute__)
        check_c_source_compiles("
                #include <stdlib.h>

                int main() {
                     /* Check for the longest available __attribute__ (since gcc-2.3) */
                     struct foo {
                       char a;
                       int x[2] __attribute__ ((__packed__));
                      };
                     return 0;
                }"
                hwloc_cv___attribute__
                FAIL_REGEX "[iI]gnore|[sS]kip"
        )
    else ()
        set(hwloc_cv___attribute__ 0)
    endif ()


    add_definitions(-DHWLOC_HAVE_ATTRIBUTE=${hwloc_cv___attribute__})
    set(HWLOC_HAVE_ATTRIBUTE ${hwloc_cv___attribute__} CACHE BOOL "Whether your compiler has __attribute__ or not")

    #
    # Now that we know the compiler support __attribute__ let's check which kind of
    # attributed are supported.
    #
    if (hwloc_cv___attribute__ STREQUAL "0")
        message(CHECK_FAIL no)
        set(hwloc_cv___attribute__aligned 0)
        set(hwloc_cv___attribute__always_inline 0)
        set(hwloc_cv___attribute__cold 0)
        set(hwloc_cv___attribute__const 0)
        set(hwloc_cv___attribute__deprecated 0)
        set(hwloc_cv___attribute__constructor 0)
        set(hwloc_cv___attribute__format 0)
        set(hwloc_cv___attribute__hot 0)
        set(hwloc_cv___attribute__malloc 0)
        set(hwloc_cv___attribute__may_alias 0)
        set(hwloc_cv___attribute__no_instrument_function 0)
        set(hwloc_cv___attribute__nonnull 0)
        set(hwloc_cv___attribute__noreturn 0)
        set(hwloc_cv___attribute__packed 0)
        set(hwloc_cv___attribute__pure 0)
        set(hwloc_cv___attribute__sentinel 0)
        set(hwloc_cv___attribute__unused 0)
        set(hwloc_cv___attribute__warn_unused_result 0)
        set(hwloc_cv___attribute__weak_alias 0)
    else ()
        message(CHECK_PASS yes)

        hwloc_check_specific_attribute(aligned "struct foo { char text[4]; }  __attribute__ ((__aligned__(8)));" NULL NULL)

        #
        # Ignored by PGI-6.2.5; -- recognized by output-parser
        #
        hwloc_check_specific_attribute(always_inline "int foo (int arg) __attribute__ ((__always_inline__));" NULL NULL)

        hwloc_check_specific_attribute(cold "
            int foo(int arg1, int arg2) __attribute__ ((__cold__));
            int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }" NULL NULL)

        hwloc_check_specific_attribute(const "
         int foo(int arg1, int arg2) __attribute__ ((__const__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }" NULL NULL)

        hwloc_check_specific_attribute(deprecated "
         int foo(int arg1, int arg2) __attribute__ ((__deprecated__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }" NULL NULL)

        hwloc_check_specific_attribute(constructor "
         void foo(void) __attribute__ ((__constructor__));
         void foo(void) { return; }" NULL NULL)

        set(HWLOC_ATTRIBUTE_CFLAGS "" CACHE STRING "")

        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(HWLOC_ATTRIBUTE_CFLAGS "-Wall")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            # we want specifically the warning on format string conversion
            set(HWLOC_ATTRIBUTE_CFLAGS "-we181")
        endif ()

        hwloc_check_specific_attribute(format "
                int this_printf (void *my_object, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));
                "
                "
                static int usage (int * argument);
                extern int this_printf (int arg1, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));

                static int usage (int * argument) {
                return this_printf (*argument, \"%d\", argument); /* This should produce a format warning */
                }
                /* The autoconf-generated main-function is int main(), which produces a warning by itself */
                int main(void);
            " ${HWLOC_ATTRIBUTE_CFLAGS})

        hwloc_check_specific_attribute(hot "
         int foo(int arg1, int arg2) __attribute__ ((__hot__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }" NULL NULL)

        hwloc_check_specific_attribute(malloc "
            #ifdef HAVE_STDLIB_H
            #  include <stdlib.h>
            #endif
         int * foo(int arg1) __attribute__ ((__malloc__));
         int * foo(int arg1) { return (int*) malloc(arg1); }" NULL NULL)

        #
        # Attribute may_alias: No suitable cross-check available, that works for non-supporting compilers
        # Ignored by intel-9.1.045 -- turn off with -wd1292
        # Ignored by PGI-6.2.5; ignore not detected due to missing cross-check
        # The test case is chosen to match our only use in topology-xml-*.c, and reproduces an xlc-13.1.0 bug.
        #
        hwloc_check_specific_attribute(may_alias "
            struct { int i; } __attribute__ ((__may_alias__)) * p_value;" NULL NULL)

        hwloc_check_specific_attribute(no_instrument_function "
            int * foo(int arg1) __attribute__ ((__no_instrument_function__));" NULL NULL)

        #
        # Attribute nonnull:
        # Ignored by intel-compiler 9.1.045 -- recognized by cross-check
        # Ignored by PGI-6.2.5 (pgCC) -- recognized by cross-check
        #

        set(HWLOC_ATTRIBUTE_CFLAGS "")

        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(HWLOC_ATTRIBUTE_CFLAGS "-Wall")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            # we want specifically the warning on format string conversion
            set(HWLOC_ATTRIBUTE_CFLAGS "-wd1292")
        endif ()

        hwloc_check_specific_attribute(nonnull "
         int square(int *arg) __attribute__ ((__nonnull__));
         int square(int *arg) { return *arg; }"
            "
             static int usage(int * argument);
             int square(int * argument) __attribute__ ((__nonnull__));
             int square(int * argument) { return (*argument) * (*argument); }

             static int usage(int * argument) {
                 return square( ((void*)0) );    /* This should produce an argument must be nonnull warning */
             }
             /* The autoconf-generated main-function is int main(), which produces a warning by itself */
             int main(void);
            " ${HWLOC_ATTRIBUTE_CFLAGS})

        hwloc_check_specific_attribute(noreturn
            "
            #ifdef HAVE_UNISTD_H
            #  include <unistd.h>
            #endif
            #ifdef HAVE_STDLIB_H
            #  include <stdlib.h>
            #endif
            void fatal(int arg1) __attribute__ ((__noreturn__));
            void fatal(int arg1) { exit(arg1); }
            "
                NULL NULL)

        hwloc_check_specific_attribute(packed
             "
             struct foo {
                 char a;
                 int x[2] __attribute__ ((__packed__));
             };
            "
                NULL NULL)

        hwloc_check_specific_attribute(pure
                "
                 int square(int arg) __attribute__ ((__pure__));
                 int square(int arg) { return arg * arg; }
                 " NULL NULL)

        #
        # Attribute sentinel:
        # Ignored by the intel-9.1.045 -- recognized by cross-check
        #                intel-10.0beta works fine
        # Ignored by PGI-6.2.5 (pgCC) -- recognized by output-parser and cross-check
        # Ignored by pathcc-2.2.1 -- recognized by cross-check (through grep ignore)
        #
        set(HWLOC_ATTRIBUTE_CFLAGS "")
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(HWLOC_ATTRIBUTE_CFLAGS "-Wall")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            # we do not want to get ignored attributes warnings
            set(HWLOC_ATTRIBUTE_CFLAGS "-wd1292")
        endif ()

        hwloc_check_specific_attribute(sentinel
                "
                int my_execlp(const char * file, const char *arg, ...) __attribute__ ((__sentinel__));
                "
                "
                static int usage(int * argument);
                 int my_execlp(const char * file, const char *arg, ...) __attribute__ ((__sentinel__));

                 static int usage(int * argument) {
                     void * last_arg_should_be_null = argument;
                     return my_execlp (\"lala\", \"/home/there\", last_arg_should_be_null);   /* This should produce a warning */
                 }
                 /* The autoconf-generated main-function is int main(), which produces a warning by itself */
                 int main(void);
                " ${HWLOC_ATTRIBUTE_CFLAGS})

        hwloc_check_specific_attribute(unused
                "
         int square(int arg1 __attribute__ ((__unused__)), int arg2);
         int square(int arg1, int arg2) { return arg2; }
                 " NULL NULL)

        #
        # Attribute warn_unused_result:
        # Ignored by the intel-compiler 9.1.045 -- recognized by cross-check
        # Ignored by pathcc-2.2.1 -- recognized by cross-check (through grep ignore)
        #
        set(HWLOC_ATTRIBUTE_CFLAGS "")
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(HWLOC_ATTRIBUTE_CFLAGS "-Wall")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            # we do not want to get ignored attributes warnings
            set(HWLOC_ATTRIBUTE_CFLAGS "-wd1292")
        endif ()

        hwloc_check_specific_attribute(warn_unused_result
                "
                int foo(int arg) __attribute__ ((__warn_unused_result__));
                int foo(int arg) { return arg + 3; }
                "
                "
                 static int usage(int * argument);
                 int foo(int arg) __attribute__ ((__warn_unused_result__));

                 int foo(int arg) { return arg + 3; }
                 static int usage(int * argument) {
                   foo (*argument);        /* Should produce an unused result warning */
                   return 0;
                 }

                 /* The autoconf-generated main-function is int main(), which produces a warning by itself */
                 int main(void);
                " ${HWLOC_ATTRIBUTE_CFLAGS})

        hwloc_check_specific_attribute(weak_alias
                "
         int foo(int arg);
         int foo(int arg) { return arg + 3; }
         int foo2(int arg) __attribute__ ((__weak__, __alias__(\"foo\")));
                 " NULL NULL)
    endif ()

    # Now that all the values are set, define them

    set(HWLOC_HAVE_ATTRIBUTE_ALIGNED ${hwloc_cv___attribute__aligned} CACHE BOOL "Whether your compiler has __attribute__ aligned or not")
    set(HWLOC_HAVE_ATTRIBUTE_ALWAYS_INLINE ${hwloc_cv___attribute__always_inline} CACHE BOOL "Whether your compiler has __attribute__ always_inline or not")
    set(HWLOC_HAVE_ATTRIBUTE_COLD ${hwloc_cv___attribute__cold} CACHE BOOL "Whether your compiler has __attribute__ cold or not")
    set(HWLOC_HAVE_ATTRIBUTE_CONST ${hwloc_cv___attribute__const} CACHE BOOL "Whether your compiler has __attribute__ const or not")
    set(HWLOC_HAVE_ATTRIBUTE_DEPRECATED ${hwloc_cv___attribute__deprecated} CACHE BOOL "Whether your compiler has __attribute__ deprecated or not")
    set(HWLOC_HAVE_ATTRIBUTE_CONSTRUCTOR ${hwloc_cv___attribute__constructor} CACHE BOOL "Whether your compiler has __attribute__ constructor or not")
    set(HWLOC_HAVE_ATTRIBUTE_FORMAT ${hwloc_cv___attribute__format} CACHE BOOL "Whether your compiler has __attribute__ format or not")
    set(HWLOC_HAVE_ATTRIBUTE_HOT ${hwloc_cv___attribute__hot} CACHE BOOL "Whether your compiler has __attribute__ hot or not")
    set(HWLOC_HAVE_ATTRIBUTE_MALLOC ${hwloc_cv___attribute__malloc} CACHE BOOL "Whether your compiler has __attribute__ malloc or not")
    set(HWLOC_HAVE_ATTRIBUTE_MAY_ALIAS ${hwloc_cv___attribute__may_alias} CACHE BOOL "Whether your compiler has __attribute__ may_alias or not")
    set(HWLOC_HAVE_ATTRIBUTE_NO_INSTRUMENT_FUNCTION ${hwloc_cv___attribute__no_instrument_function} CACHE BOOL "Whether your compiler has __attribute__ no_instrument_function or not")
    set(HWLOC_HAVE_ATTRIBUTE_NONNULL ${hwloc_cv___attribute__nonnull} CACHE BOOL "Whether your compiler has __attribute__ nonnull or not")
    set(HWLOC_HAVE_ATTRIBUTE_NORETURN ${hwloc_cv___attribute__noreturn} CACHE BOOL "Whether your compiler has __attribute__ noreturn or not")
    set(HWLOC_HAVE_ATTRIBUTE_PACKED ${hwloc_cv___attribute__packed} CACHE BOOL "Whether your compiler has __attribute__ packed or not")
    set(HWLOC_HAVE_ATTRIBUTE_PURE ${hwloc_cv___attribute__pure} CACHE BOOL "Whether your compiler has __attribute__ pure or not")
    set(HWLOC_HAVE_ATTRIBUTE_SENTINEL ${hwloc_cv___attribute__sentinel} CACHE BOOL "Whether your compiler has __attribute__ sentinel or not")
    set(HWLOC_HAVE_ATTRIBUTE_UNUSED ${hwloc_cv___attribute__unused} CACHE BOOL "Whether your compiler has __attribute__ unused or not")
    set(HWLOC_HAVE_ATTRIBUTE_WARN_UNUSED_RESULT ${hwloc_cv___attribute__warn_unused_result} CACHE BOOL "Whether your compiler has __attribute__ warn unused result or not")
    set(HWLOC_HAVE_ATTRIBUTE_WEAK_ALIAS ${hwloc_cv___attribute__weak_alias} CACHE BOOL "Whether your compiler has __attribute__ weak alias or not")

endfunction()