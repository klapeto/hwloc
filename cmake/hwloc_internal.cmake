function(hwloc_build_standalone)
    set(hwloc_mode standalone PARENT_SCOPE)
endfunction()

function(hwloc_define_args)
    option(ENABLE_EMBEDDED_MODE "Using --enable-embedded-mode puts the HWLOC into 'embedded' mode. The default is --disable-embedded-mode, meaning that the HWLOC is in 'standalone' mode." OFF)
    set(HWLOC_SYMBOL_PREFIX "" CACHE STRING "STRING can be any valid C symbol name. It will be prefixed to all public HWLOC symbols. Default: '' (no prefix)")

    # For the windows build
    set(HWLOC_MS_LIB "" CACHE PATH "Path to Microsoft's Visual Studio `lib' tool")

    option(ENABLE_DEBUG "Using --enable-debug enables various hwloc maintainer-level debugging controls. This option is not recommended for end users." OFF)
    option(ENABLE_DOXYGEN "Enable support for building Doxygen documentation (note that this option is ONLY relevant in developer builds; Doxygen documentation is pre-built for tarball builds and this option is therefore ignored)" OFF)
    option(DISABLE_README "Disable the updating of the top-level README file from the HTML documentation index" ON)

    option(ENABLE_PICKY "When in developer checkouts of hwloc and compiling with gcc, the default is to enable maximum compiler pickyness. Using --disable-picky or --enable-picky overrides any default setting." ON)
    option(ENABLE_CAIRO "Disable the Cairo back-end of hwloc's lstopo command" ON)

    option(ENABLE_CPUID "Disable the cpuid-based architecture specific support (x86 component)" ON)
    option(ENABLE_LIBXML2 "Do not use libxml2 for XML support, use a custom minimalistic support" ON)

    option(ENABLE_IO "Disable I/O discovery build entirely (PCI, LinuxIO, CUDA, OpenCL, NVML, RSMI, LevelZero, GL) instead of only disabling it at runtime by default" ON)
    option(ENABLE_PCI "Disable the PCI device discovery build (instead of only disabling PCI at runtime by default)" ON)
    option(ENABLE_OPENCL "Disable the OpenCL device discovery build (instead of only disabling OpenCL at runtime by default)" ON)
    option(ENABLE_CUDA "Disable the CUDA device discovery build using libcudart (instead of only disabling CUDA at runtime by default)" ON)
    option(ENABLE_NVML "Disable the NVML device discovery build (instead of only disabling NVML at runtime by default)" ON)

    set(CUDA_VERSION "" CACHE STRING "Specify the CUDA version (e.g. 11.2) for selecting the appropriate pkg-config file")
    set(CUDA_PATH "" CACHE PATH "Specify the CUDA installation directory, used for NVIDIA NVML and OpenCL too.")

    option(DISABLE_RSMI "Disable the ROCm SMI device discovery" ON)
    set(ROCM_VERSION "" CACHE STRING "Specify the ROCm version (e.g. 4.2.0) for selecting the default ROCm installation path (e.g. /opt/rocm-4.2.0)")
    set(ROCM_PATH "" CACHE PATH "Specify the ROCm installation directory")

    option(ENABLE_LEVELZERO "Disable the oneAPI Level Zero device discovery" ON)

    option(ENABLE_GL "Disable the GL display device discovery (instead of only disabling GL at runtime by default)" ON)
    option(ENABLE_LIBUDEV "Disable the Linux libudev" ON)

    set(ENABLE_PLUGINS "-1" CACHE STRING "Build the given components as dynamically-loaded plugins")

    set(HWLOC_PLUGINS_PATH "$<TARGET_FILE_DIR:hwloc>" CACHE PATH "Colon-separated list of plugin directories. Default: '$<TARGET_FILE_DIR:hwloc>'. Plugins will be installed in the first directory. They will be loaded from all of them, in order.")

    option(ENABLE_PLUGIN_DLOPEN "Do not use dlopen for loading plugins." ON)
    option(ENABLE_PLUGIN_LTDL "Do not use ltdl for loading plugins." OFF)
endfunction()

# Probably only ever invoked by hwloc's configure.ac
function(hwloc_setup_utils)
    include(CheckTypeSize)
    include(CheckSymbolExists)

    message("")
    message("###")
    message("### Configuring hwloc command line utilities")
    message("###")

    find_program(HAVE_SED sed)

    include(GNUInstallDirs)

    set(HWLOC_runstatedir ${RUNSTATEDIR} CACHE INTERNAL "")

    # X11 support
    find_package(X11)

    if (X11_FOUND)
        check_include_file("X11/Xlib.h" HAVE_X11_XLIB_H)
        if (HAVE_X11_XLIB_H)
            check_include_file("X11/Xutil.h" HAVE_X11_XUTIL_H)
            if (HAVE_X11_XUTIL_H)
                check_include_file("X11/keysym.h" HAVE_X11_KEYSYM_H)
                set(HWLOC_HAVE_X11_KEYSYM 1 CACHE BOOL "Define to 1 if X11 headers including Xutil.h and keysym.h are available.")
                set(hwloc_x11_keysym_happy "yes")
                set(HWLOC_X11_CPPFLAGS "-I\"${X11_X11_INCLUDE_PATH}\"")
                set(HWLOC_X11_CPPFLAGS "${HWLOC_X11_CPPFLAGS}" CACHE STRING "")
                set(HWLOC_X11_LIBS "-l\"${X11_xcb_keysyms_LIB}\" -lx11")
                set(HWLOC_X11_LIBS "${HWLOC_X11_LIBS}")
            endif ()
        endif ()
    endif ()

    # Cairo support
    set(hwloc_cairo_happy "no")
    if (ENABLE_CAIRO STREQUAL ON)
        hwloc_pkg_check_modules(CAIRO cairo cairo_fill "cairo.h")
        if (HAVE_CAIRO)
            set(hwloc_cairo_happy "yes")
        else ()
            set(hwloc_cairo_happy "no")
        endif ()
    endif ()

    if (hwloc_cairo_happy STREQUAL "yes")
        set(HWLOC_HAVE_CAIRO 1 CACHE BOOL "Define to 1 if you have the `cairo' library.")
        message(CHECK_START "Checking whether lstopo Cairo/X11 interactive graphical output is supported")

        if (hwloc_x11_keysym_happy STREQUAL "yes")
            set(CMAKE_REQUIRED_FLAGS_SAVE ${CMAKE_REQUIRED_FLAGS})
            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} ${HWLOC_CAIRO_CFLAGS} ${HWLOC_X11_CPPFLAGS}")

            set(CMAKE_REQUIRED_LIBS_SAVE ${CMAKE_REQUIRED_LIBS})
            set(CMAKE_REQUIRED_LIBS "${CMAKE_REQUIRED_LIBS} ${HWLOC_CAIRO_LIBS} ${HWLOC_X11_LIBS}")

            check_c_source_compiles("
                #include <cairo.h>
                #ifndef CAIRO_HAS_XLIB_SURFACE
                #error
                #endif
                int main(){return 0;}
            " LSTOPO_HAVE_X11)

            if (LSTOPO_HAVE_X11)
                message(CHECK_PASS "yes")
                set(lstopo_have_x11 "yes")
                set(LSTOPO_HAVE_X11 1 CACHE BOOL "Define if lstopo Cairo/X11 interactive graphical output is supported")
            else ()
                message(CHECK_FAIL " (missing CAIRO_HAS_XLIB_SURFACE)")
            endif ()

            set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS_SAVE}")
            set(CMAKE_REQUIRED_LIBS "${CMAKE_REQUIRED_LIBS_SAVE}")
        endif ()
    else ()
        if (ENABLE_CAIRO STREQUAL ON)
            message(WARNING "--enable-cairo requested, but Cairo/X11 support was not found")
            message(FATAL_ERROR "Cannot continue")
        endif ()
    endif ()

    check_type_size(wchar_t HAVE_WCHAR_T)

    if (HAVE_WCHAR_T)
        check_symbol_exists("putwc" "wchar.h" HAVE_PUTWC)
    endif ()

    set(HWLOC_XML_LOCALIZED 1)
    check_include_file("locale.h" HAVE_LOCALE_H)

    if (HAVE_LOCALE_H)
        set(local_header "locale.h")
    endif ()

    check_include_file("xlocale.h" HAVE_XLOCALE_H)

    if (HAVE_XLOCALE_H)
        set(local_header "xlocale.h")
    endif ()

    if (HAVE_LOCALE_H OR HAVE_XLOCALE_H)
        check_symbol_exists("setlocale" ${local_header} HAVE_SETLOCALE)
        check_symbol_exists("uselocale" ${local_header} HAVE_USELOCALE)
        if (NOT HAVE_USELOCALE)
            set(HWLOC_XML_LOCALIZED 0)
        endif ()
    endif ()

    set(HWLOC_XML_LOCALIZED ${HWLOC_XML_LOCALIZED} CACHE BOOL "")

    check_include_file("langinfo.h" HAVE_LANGINFO_H)
    if (HAVE_LANGINFO_H)
        check_symbol_exists("nl_langinfo" "langinfo.h" HAVE_NL_LANGINFO)
    endif ()

endfunction()