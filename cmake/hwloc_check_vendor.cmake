function(hwloc_check_cc_option flag additionalFlags)

    message(CHECK_START "Checking if gcc supports ${flag}")

    set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
    set(CMAKE_REQUIRED_QUIET TRUE)
    set(CMAKE_REQUIRED_FLAGS "${flag} -Werror")

    check_c_source_compiles(
            "int i;"
            HWLOC_HAVE_CC_FLAG
    )

    if (HWLOC_HAVE_CC_FLAG)
        message(CHECK_PASS Yes)
        set(${additionalFlags} "${${additionalFlags}} ${flag}" PARENT_SCOPE)
        if (ARGV2)
            add_definitions(-D${ARGV2}=1)
            set(${ARGV2} 1 CACHE INTERNAL "")
        endif ()
    else ()
        message(CHECK_PASS No)
    endif ()

endfunction()