# Copyright © 2012-2020 Inria.  All rights reserved.
# See COPYING in top-level directory.

function(hwloc_prepare_filter_components components)
    string(REPLACE " " ";" component_list "${components}")

    foreach(component ${component_list})
        set(hwloc_${component}_component_wantplugin 1 CACHE BOOL "")
    endforeach()
endfunction()

function(hwloc_filter_components)
    foreach(name IN LISTS hwloc_components)
        set(maybeplugin ${hwloc_${name}_component_maybeplugin})
        set(wantplugin ${hwloc_${name}_component_wantplugin})

        if (HWLOC_HAVE_PLUGINS AND maybeplugin AND wantplugin)
            set(hwloc_plugin_components "${hwloc_plugin_components} ${name}")
            set(hwloc_${name}_component plugin CACHE INTERNAL "")
        else ()
            set(hwloc_static_components "${hwloc_static_components} ${name}")
            set(hwloc_${name}_component static CACHE INTERNAL "")
        endif ()
    endforeach()
endfunction()

function(hwloc_list_static_components filename components)
    file(APPEND ${filename} "#include <private/internal-components.h>\n")
    file(APPEND ${filename} "static const struct hwloc_component * hwloc_static_components[] = {\n")

    foreach(comp IN LISTS components)
        file(APPEND ${filename} "  &hwloc_${comp}_component,\n")
    endforeach()

    file(APPEND ${filename} "  NULL\n")
    file(APPEND ${filename} "};\n")
endfunction()