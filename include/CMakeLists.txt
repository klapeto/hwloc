if (HWLOC_BUILD_STANDALONE)
    set(include_HEADERS hwloc.h)
    set(include_hwloc_HEADERS
            hwloc/bitmap.h
            hwloc/helper.h
            hwloc/inlines.h
            hwloc/memattrs.h
            hwloc/cpukinds.h
            hwloc/diff.h
            hwloc/shmem.h
            hwloc/distances.h
            hwloc/export.h
            hwloc/openfabrics-verbs.h
            hwloc/opencl.h
            hwloc/cuda.h
            hwloc/cudart.h
            hwloc/nvml.h
            hwloc/rsmi.h
            hwloc/levelzero.h
            hwloc/plugins.h
            hwloc/gl.h
            hwloc/rename.h
            hwloc/deprecated.h
    )
    set(include_hwloc_autogendir $(includedir)/hwloc/autogen)
    set(nodist_include_hwloc_autogen_HEADERS hwloc/autogen/config.h)
    set(noinst_HEADERS
            private/private.h
            private/debug.h
            private/misc.h
            private/xml.h
            private/components.h
            private/internal-components.h
            private/cpuid-x86.h
            private/windows.h
    )

    if (HWLOC_HAVE_LINUX)
        list(APPEND include_hwloc_HEADERS
                hwloc/linux.h
                hwloc/linux-libnuma.h
        )
    endif()

    if (HWLOC_HAVE_SOLARIS)
        list(APPEND include_hwloc_HEADERS
                private/solaris-chiptype.h
        )
    endif()

    if (HWLOC_HAVE_SOLARIS)
        list(APPEND include_hwloc_HEADERS
                hwloc/glibc-sched.h
        )
    endif()

    if (HWLOC_HAVE_SOLARIS)
        list(APPEND include_hwloc_HEADERS
                hwloc/windows.h
        )
    endif()
endif ()