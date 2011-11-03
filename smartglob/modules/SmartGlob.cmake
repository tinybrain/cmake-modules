# SmartGlob.cmake
#
# Copyright (C) 2011 by a llama.  All rights reserved.
# This code is licensed under the MIT License.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

include(CMakeParseArguments)

function(sdbg)
    if(SMARTGLOB_DEBUG)
        message(">  " ${ARGN})
    endif()
endfunction()

function(smartglob_format_prefix out_result path)

    cmake_parse_arguments("" "TARGET" "" "" ${ARGN})
    
    string(TOLOWER ${path} prefix)
    string(REGEX REPLACE "/" "-" prefix ${prefix})
    string(REGEX REPLACE " " "_" prefix ${prefix})
    
    if (TARGET)
        set(prefix smartglob-${prefix})
    endif()

    set(${out_result} ${prefix} PARENT_SCOPE)

endfunction()

function(smartglob_glob path pattern out_filelist)

    sdbg("begin smartglob_glob()")

    file(GLOB all_files ${path}/*.*)
    
    sdbg("globbing path:${path} pattern:${pattern}")

    foreach(file ${all_files})

        get_filename_component(filename ${file} NAME)
        string(REGEX MATCH ${pattern} match_result ${filename})

        if(match_result)
            set(result ${result} ${file})
            sdbg("    match: ${file}")
        endif()

    endforeach()

    set(${out_filelist} ${result} PARENT_SCOPE)
    
    sdbg("end smartglob_glob()")

endfunction()

function(smartglob_build_extension_filter out_pattern extensions)

    string(REGEX REPLACE "[ ,]+" ";" extensions ${extensions})

    foreach(ext ${extensions})
        string(REGEX REPLACE "\\." "\\\\." ext ${ext})
        set(pattern ${pattern}.*${ext}$|)
    endforeach()

    string(REGEX REPLACE "\\|$" "" pattern ${pattern})
    
    set(${out_pattern} ${pattern} PARENT_SCOPE)

endfunction()

function(smartglob out_filelist path)

    sdbg("begin smartglob()")

    ## parse args
    
    set(option)
    set(single REGEX)
    set(multi EXTENSIONS)
    
    cmake_parse_arguments(SMARTGLOB "${option}" "${single}" "${multi}" ${ARGN})
    
    ## configure the regex from from a list of extensions or an explicit expression
    
    if(SMARTGLOB_REGEX)
    
        sdbg("SMARTGLOB_REGEX: ${SMARTGLOB_REGEX}")
        set(pattern ${SMARTGLOB_REGEX})
        
    elseif(SMARTGLOB_EXTENSIONS)

        sdbg("SMARTGLOB_EXTENSIONS: ${SMARTGLOB_EXTENSIONS}")
        smartglob_build_extension_filter(pattern ${SMARTGLOB_EXTENSIONS})
        
    else()
    
        set(extensions ".h .hpp .hxx .c .cpp .cxx .m .mm")
        sdbg("extensions: ${extensions}")
        smartglob_build_extension_filter(pattern ${extensions})        
    
    endif()
    
    sdbg("pattern: ${pattern}")
    
    ## setup definition header
    
    smartglob_format_prefix(prefix ${path})    
    sdbg("prefix: ${prefix}")
    
    set(cache_text ${CMAKE_SOURCE_DIR}\n${path}\n${pattern}\n)

    ## glob the files in given path and filter them
    
    smartglob_glob(${path} ${pattern} glob)

    ## export the cache file

    set(cache_file ${CMAKE_BINARY_DIR}/smartglob/${prefix}.globdef)    
    sdbg("cache_file: ${cache_file}")

    foreach(file ${glob})
        set(cache_text ${cache_text}${file}\n)
    endforeach()

    file(WRITE ${cache_file} ${cache_text})
    
    sdbg("cache_text:\n\n${cache_text}")
    
    ## export results to parent scope
    
    set(${out_filelist} ${glob} PARENT_SCOPE)
    
    ## some introspection
    
    find_file(module_path "SmartGlob.cmake" PATHS ${CMAKE_MODULE_PATH})
    sdbg("module_path: ${module_path}")
    
    if(NOT module_path)
        message(FATAL_ERROR "Could not determine the location of SmartGlob.cmake; please set CMAKE_MODULE_PATH accordingly.")
    endif()
    
    ## add a custom preflight target
    
    add_custom_target(smartglob-${prefix}
        COMMAND cmake -DSMARTGLOB_PREFLIGHT_CACHE_FILE=${cache_file} -P ${module_path}
        )

    set(SMARTGLOB_PREFLIGHT_TARGETS ${SMARTGLOB_PREFLIGHT_TARGETS} smartglob-${prefix} PARENT_SCOPE)
    
    sdbg("end smartglob()")

endfunction()

function(smartglob_add_dependencies target)

    sdbg("begin smartglob_add_dependencies()")
    
    sdbg("target: ${target}")
    sdbg("SMARTGLOB_PREFLIGHT_TARGETS: ${SMARTGLOB_PREFLIGHT_TARGETS}")
    
    if (SMARTGLOB_PREFLIGHT_TARGETS)
        sdbg("setting targets...")
        add_dependencies(${target} ${SMARTGLOB_PREFLIGHT_TARGETS})    
        set(SMARTGLOB_PREFLIGHT_TARGETS "" PARENT_SCOPE)
    endif()
    
    sdbg("end smartglob_add_dependencies()")

endfunction()

function(smartglob_preflight cache_file)

    sdbg("begin smartglob_preflight()")

    ## open the cache file

    if(NOT EXISTS ${cache_file})
        message(FATAL_ERROR "Could not find smartglob cache file : ${cache_file}")
    endif()

    file(STRINGS ${cache_file} last_glob)

    list(GET last_glob 0 source_dir)
    list(GET last_glob 1 path)
    list(GET last_glob 2 pattern)
    
    list(REMOVE_AT last_glob 0 1 2)
    
    sdbg("source_dir: ${source_dir}")
    sdbg("path: ${path}")
    sdbg("pattern: ${pattern}")

    ## glob directory and diff with the last generated glob definition

    smartglob_glob(${source_dir}/${path} ${pattern} this_glob)

    set(a ${last_glob})
    set(b ${this_glob})

    list(REMOVE_ITEM a ${this_glob})
    list(REMOVE_ITEM b ${last_glob})

    set(diff ${a} ${b})

    if(diff)
        
        execute_process(COMMAND cmake -E touch ${source_dir}/CMakeLists.txt)
        
        message(WARNING "*** SmartGlob Warning ***")
        
        message("SmartGlob detected a glob change!!  Rebuild to update projects and caches.")
        
        foreach(file ${a})
            message("  Removed: ${file}")
        endforeach()

        foreach(file ${b})
            message("  Added: ${file}")
        endforeach()
        
        message(\n)
        
    endif()
    
    sdbg("end smartglob_preflight()")

endfunction()

## preflight

if(SMARTGLOB_PREFLIGHT_CACHE_FILE)
    smartglob_preflight(${SMARTGLOB_PREFLIGHT_CACHE_FILE})
endif()

