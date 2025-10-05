function(hwloc_check_cc_option flag additionalFlags pass_flag)

    message(CHECK_START "Checking if gcc supports ${flag}")

    #set(CMAKE_REQUIRED_QUIET TRUE)
    set(CMAKE_REQUIRED_FLAGS_BAK ${CMAKE_REQUIRED_FLAGS})
    set(CMAKE_REQUIRED_FLAGS "${flag} -Werror")

    check_c_source_compiles(
            "int main(){int i; return 0;}"
            HWLOC_HAVE_CC_FLAG
    )

    if (HWLOC_HAVE_CC_FLAG)
        message(CHECK_PASS "yes")
        set(${additionalFlags} "${${additionalFlags}} ${flag}" PARENT_SCOPE)
        if (pass_flag)
            set(${pass_flag} 1 PARENT_SCOPE)
        endif ()
    else ()
        message(CHECK_FAIL "no")
        if (pass_flag)
            set(${pass_flag} 0 PARENT_SCOPE)
        endif ()
    endif ()
endfunction()