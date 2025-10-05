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

    option(ENABLE_IO "Disable I/O discovery build entirely (PCI, LinuxIO, CUDA, OpenCL, NVML, RSMI, LevelZero, GL) instead of only disabling it at runtime by default" OFF)
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

    option(ENABLE_PLUGINS "Build the given components as dynamically-loaded plugins" ON)

    set(HWLOC_PLUGINS_PATH "$<TARGET_FILE_DIR:hwloc>" CACHE PATH "Colon-separated list of plugin directories. Default: '$<TARGET_FILE_DIR:hwloc>'. Plugins will be installed in the first directory. They will be loaded from all of them, in order.")

    option(ENABLE_PLUGIN_DLOPEN "Do not use dlopen for loading plugins." ON)
    option(ENABLE_PLUGIN_LTDL "Do not use ltdl for loading plugins." OFF)
endfunction()