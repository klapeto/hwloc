function(hwloc_check_specific_attribute ATTRIBUTE CHECK_CODE CROSS_CHECK_CODE ADDITIONAL_FLAGS)
    check_c_source_compiles("${CHECK_CODE}"
            HWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE}
            FAIL_REGEX "ignore|skip"
    )

    if (HWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE} AND CROSS_CHECK_CODE)
        set(CMAKE_REQUIRED_FLAGS  ${ADDITIONAL_FLAGS})
        check_c_source_compiles("${CROSS_CHECK}
                   int i=4711;
                   i=usage(&i);
        "
                HWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE}
                FAIL_REGEX "ignore|skip"
        )
    endif ()

    add_definitions(-DHWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE}=${HWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE}})
    set(HWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE} ${HWLOC_HAVE_ATTRIBUTE_${ATTRIBUTE}} CACHE INTERNAL "")
endfunction()

function(hwloc_check_attributes)
    include(CheckCSourceCompiles)

    set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
    set(CMAKE_REQUIRED_QUIET TRUE)

    check_c_source_compiles("
    #include <stdlib.h>
         /* Check for the longest available __attribute__ (since gcc-2.3) */
         struct foo {
           char a;
           int x[2] __attribute__ ((__packed__));
         };"
            HWLOC_HAVE_ATTRIBUTE
            FAIL_REGEX "ignore|skip"
    )

    if (HWLOC_HAVE_ATTRIBUTE)
        add_definitions(-DHWLOC_HAVE_ATTRIBUTE=${HWLOC_HAVE_ATTRIBUTE})
        set(HWLOC_HAVE_ATTRIBUTE 1 CACHE INTERNAL "")
    endif ()

    # Now that we know the compiler support __attribute__ let's check which kind of
    # attributed are supported.
    if (HWLOC_HAVE_ATTRIBUTE)
        hwloc_check_specific_attribute(ALIGNED
                "struct foo { char text[4]; }  __attribute__ ((__aligned__(8)));"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(ALWAYS_INLINE
                "int foo (int arg) __attribute__ ((__always_inline__));"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(COLD
                "
                int foo(int arg1, int arg2) __attribute__ ((__cold__));
                int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(CONST
                "
                 int foo(int arg1, int arg2) __attribute__ ((__const__));
                 int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(DEPRECATED
                "
                 int foo(int arg1, int arg2) __attribute__ ((__deprecated__));
                 int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(CONSTRUCTOR
                "
                 void foo(void) __attribute__ ((__constructor__));
                 void foo(void) { return; }"
                FALSE
                FALSE
        )

        set(HWLOC_ATTRIBUTE_CFLAGS "")
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(HWLOC_ATTRIBUTE_CFLAGS "-Wall")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            # we want specifically the warning on format string conversion
            set(HWLOC_ATTRIBUTE_CFLAGS "-we181")
        endif ()

        hwloc_check_specific_attribute(FORMAT
                "int this_printf (void *my_object, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));"
                "
                 static int usage (int * argument);
                 extern int this_printf (int arg1, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));

                 static int usage (int * argument) {
                     return this_printf (*argument, \"%d\", argument); /* This should produce a format warning */
                 }
                 /* The autoconf-generated main-function is int main(), which produces a warning by itself */
                 int main(void);
                "
                ${HWLOC_ATTRIBUTE_CFLAGS}
        )

        hwloc_check_specific_attribute(HOT
                "
                 int foo(int arg1, int arg2) __attribute__ ((__hot__));
                 int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(MALLOC
                "
                #ifdef HAVE_STDLIB_H
                #  include <stdlib.h>
                #endif
                 int * foo(int arg1) __attribute__ ((__malloc__));
                 int * foo(int arg1) { return (int*) malloc(arg1); }"
                FALSE
                FALSE
        )

        #
        # Attribute may_alias: No suitable cross-check available, that works for non-supporting compilers
        # Ignored by intel-9.1.045 -- turn off with -wd1292
        # Ignored by PGI-6.2.5; ignore not detected due to missing cross-check
        # The test case is chosen to match our only use in topology-xml-*.c, and reproduces an xlc-13.1.0 bug.
        #
        hwloc_check_specific_attribute(MAY_ALIAS
                "struct { int i; } __attribute__ ((__may_alias__)) * p_value;"
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(NO_INSTRUMENT_FUNCTION
                "int * foo(int arg1) __attribute__ ((__no_instrument_function__));"
                FALSE
                FALSE
        )

        #
        # Attribute nonnull:
        # Ignored by intel-compiler 9.1.045 -- recognized by cross-check
        # Ignored by PGI-6.2.5 (pgCC) -- recognized by cross-check
        #
        set(HWLOC_ATTRIBUTE_CFLAGS "")
        if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
            set(HWLOC_ATTRIBUTE_CFLAGS "-Wall")
        elseif (CMAKE_C_COMPILER_ID STREQUAL "Intel")
            # we do not want to get ignored attributes warnings, but rather real warnings
            set(HWLOC_ATTRIBUTE_CFLAGS "-wd1292")
        endif ()

        hwloc_check_specific_attribute(NONNULL
                "
                 int square(int *arg) __attribute__ ((__nonnull__));
                 int square(int *arg) { return *arg; }
                "
                "
                static int usage(int * argument);
                 int square(int * argument) __attribute__ ((__nonnull__));
                 int square(int * argument) { return (*argument) * (*argument); }

                 static int usage(int * argument) {
                     return square( ((void*)0) );    /* This should produce an argument must be nonnull warning */
                 }
                 /* The autoconf-generated main-function is int main(), which produces a warning by itself */
                 int main(void);
                "
                ${HWLOC_ATTRIBUTE_CFLAGS}
        )

        hwloc_check_specific_attribute(NORETURN
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
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(PACKED
                "
                 struct foo {
                     char a;
                     int x[2] __attribute__ ((__packed__));
                 };
                "
                FALSE
                FALSE
        )

        hwloc_check_specific_attribute(PURE
                "
                 int square(int arg) __attribute__ ((__pure__));
                 int square(int arg) { return arg * arg; }
                "
                FALSE
                FALSE
        )

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

        hwloc_check_specific_attribute(SENTINEL
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
                "
                ${HWLOC_ATTRIBUTE_CFLAGS}
        )

        hwloc_check_specific_attribute(UNUSED
                "
                 int square(int arg1 __attribute__ ((__unused__)), int arg2);
                 int square(int arg1, int arg2) { return arg2; }
                "
                FALSE
                FALSE
        )

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

        hwloc_check_specific_attribute(WARN_UNUSED_RESULT
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
                "
                ${HWLOC_ATTRIBUTE_CFLAGS}
        )

        hwloc_check_specific_attribute(WEAK_ALIAS
                "
                 int foo(int arg);
                 int foo(int arg) { return arg + 3; }
                 int foo2(int arg) __attribute__ ((__weak__, __alias__(\"foo\")));
                "
                FALSE
                FALSE
        )

    endif ()

endfunction()