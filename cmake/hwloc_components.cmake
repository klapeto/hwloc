# Copyright © 2012-2020 Inria.  All rights reserved.
# See COPYING in top-level directory.


# HWLOC_PREPARE_FILTER_COMPONENTS
#
# Given a list of names, define hwloc_<name>_component_maybeplugin=1.
#
# $1 = space-separated list of components to build as plugins
#
function(hwloc_prepare_filter_components components)
    string(REPLACE " " ";" component_list "${components}")

    foreach(component ${component_list})
        set(hwloc_${component}_component_wantplugin 1 PARENT_SCOPE)
    endforeach()
endfunction()

# HWLOC_FILTER_COMPONENTS
#
# For each component in hwloc_components,
# check if hwloc_<name>_component_wantplugin=1,
# and check if hwloc_<name>_component_maybeplugin=1.
# Add <name> to hwloc_[static|plugin]_components accordingly.
# And set hwloc_<name>_component=[static|plugin] accordingly.
#
function(hwloc_filter_components)
    string(REPLACE " " ";" component_list "${hwloc_components}")

    foreach(name ${component_list})
        set(maybeplugin ${hwloc_${name}_component_maybeplugin})
        set(wantplugin ${hwloc_${name}_component_wantplugin})

        if (hwloc_have_plugins STREQUAL "yes" AND maybeplugin AND wantplugin)
            set(hwloc_plugin_components "${hwloc_plugin_components} ${name}")
            set(hwloc_${name}_component plugin PARENT_SCOPE)
        else ()
            set(hwloc_static_components "${hwloc_static_components} ${name}")
            set(hwloc_${name}_component static PARENT_SCOPE)
        endif ()
    endforeach()

    set(hwloc_static_components ${hwloc_static_components} PARENT_SCOPE)
    set(hwloc_plugin_components ${hwloc_plugin_components} PARENT_SCOPE)
endfunction()

# HWLOC_LIST_STATIC_COMPONENTS
#
# Append to file $1 an array of components by listing component names in $2.
#
# $1 = filename
# $2 = list of component names
#
function(hwloc_list_static_components filename components)
    file(APPEND ${filename} "#include <private/internal-components.h>\n")
    file(APPEND ${filename} "static const struct hwloc_component * hwloc_static_components[] = {\n")

    foreach(comp IN LISTS components)
        file(APPEND ${filename} "  &hwloc_${comp}_component,\n")
    endforeach()

    file(APPEND ${filename} "  NULL\n")
    file(APPEND ${filename} "};\n")
endfunction()