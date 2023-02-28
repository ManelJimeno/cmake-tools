#
# Configure conan with modules-cmake.
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

option(GENERATE_CMAKE_PRESETS "Automatic generation of CMakePresets.json file" OFF)

set(CONAN_CMAKE_VERSION
    "0.18.1"
    CACHE STRING "Conan cmake script version")
option(CONAN_BUILD_MISSING "Automatically build all missing dependencies" OFF)

# Add entry to the list
macro(APPEND_ENTRY)
    if(WIN32)
        string(REPLACE "/" "\\" ${ARGV2} ${${ARGV2}})
        string(FIND ${${ARGV2}} "%${${ARGV1}}%" found_substring)
        if(NOT ${found_substring} EQUAL -1)
            string(REPLACE "%${${ARGV1}}%" "" ${ARGV2} ${${ARGV2}})
            set(CONAN_ENTRY_${${ARGV1}}_END_VAR "%${${ARGV1}}%")
        endif()
    else()
        string(FIND ${${ARGV2}} "\${${${ARGV1}}:+:\$${${ARGV1}}}" found_substring)
        if(${found_substring} GREATER_EQUAL 0)
            string(REPLACE "\${${${ARGV1}}:+:\$${${ARGV1}}}" "" ${ARGV2} ${${ARGV2}})
            string(REPLACE ":" ";" ${ARGV2} ${${ARGV2}})
            set(CONAN_ENTRY_${${ARGV1}}_END_VAR "\${${${ARGV1}}:+:\$${${ARGV1}}}")
        endif()
    endif()
    foreach(item IN LISTS ${ARGV2})
        if(NOT "${item}" IN_LIST ${ARGV3})
            if(DEFINED ${ARGV3})
                string(APPEND ${ARGV3} "!${item}")
            else()
                string(APPEND ${ARGV3} ${item})
            endif()
        endif()
    endforeach()
endmacro()

# Load values from disk
macro(LOAD_VALUES_FROM_DISK)
    if(WIN32)
        set(type_to_export bat)
        set(types_to_generate project_env.bat project_env.ps1)
    else()
        set(type_to_export sh)
        set(types_to_generate project_env.sh)
    endif()

    if(GENERATE_CMAKE_PRESETS)
        list(APPEND types_to_generate CMakePresets.json)
    endif()

    set(sources "${CMAKE_BINARY_DIR}/environment.${type_to_export}.env"
                "${CMAKE_BINARY_DIR}/environment_run.${type_to_export}.env")

    foreach(entry IN LISTS ${ARGV1})
        list(JOIN entry "!" entry)
        list(APPEND entries_to_file ${entry})
    endforeach()

    foreach(file_name IN LISTS sources)
        message(STATUS "\tLoading entries from ${file_name}")
        file(STRINGS "${file_name}" entries)
        if(WIN32)
            foreach(entry IN LISTS entries)
                list(JOIN entry "!" entry)
                list(APPEND entries_to_file ${entry})
            endforeach()
        else()
            list(APPEND entries_to_file ${entries})
        endif()
    endforeach()

    foreach(entry IN LISTS entries_to_file)
        # We only recognize as valid inputs of type name=value
        if(entry MATCHES "^([^=]+)=(.*)$")
            set(name_entry ${CMAKE_MATCH_1})
            set(value_entry ${CMAKE_MATCH_2})
            if(NOT ${name_entry} IN_LIST ${ARGV0})
                list(APPEND ${ARGV0} ${name_entry})
            endif()
            append_entry(entry name_entry value_entry "CONAN_ENTRY_${name_entry}")
        endif()
    endforeach()

endmacro()

# Format output variables
macro(FORMAT_VARIABLES_FOR_OUTPUT)
    if(${ARGV0} MATCHES "^([^=]+)\\.(.*)$")
        set(type_to_generate ${CMAKE_MATCH_2})
    endif()

    set(project_environment)
    foreach(entry_name IN LISTS ${ARGV1})
        set(entry_copy ${CONAN_ENTRY_${entry_name}})
        if(DEFINED CONAN_ENTRY_${entry_name}_END_VAR)
            if(${type_to_generate} STREQUAL "sh")
                string(REPLACE "!" ":" entry_copy ${entry_copy})
                string(APPEND entry_copy ${CONAN_ENTRY_${entry_name}_END_VAR})
            elseif(${type_to_generate} STREQUAL "json")
                list(APPEND entry_copy $ENV{${entry_name}})
            else()
                string(REPLACE "!" ";" entry_copy ${entry_copy})
                list(APPEND entry_copy ${CONAN_ENTRY_${entry_name}_END_VAR})
            endif()
        endif()

        if(NOT WIN32)
            list(JOIN entry_copy ":" entry_copy)
        endif()

        if(${type_to_generate} STREQUAL "ps1")
            string(APPEND ${ARGV2} "Set-Item \$env:${entry_name} -Value \"${entry_copy}\"")
        elseif(${type_to_generate} STREQUAL "bat")
            string(APPEND ${ARGV2} "SET ${entry_name}=${entry_copy}\n")
        elseif(${type_to_generate} STREQUAL "env")
            string(APPEND ${ARGV2} "${entry_name}=${entry_copy}\n")
        elseif(${type_to_generate} STREQUAL "json")
            string(REPLACE "\"" "" tmp_string ${entry_copy})
            string(APPEND ${ARGV2} "\"${entry_name}\": \"${tmp_string}\",\n")
        else()
            string(APPEND ${ARGV2} "export ${entry_name}=${entry_copy}\n")
        endif()
    endforeach()

endmacro()

# Write shell with environment
function(write_conan_environment_file)
    set(oneValueArgs OUTPUT_FOLDER)
    set(multiValueArgs SET)
    cmake_parse_arguments(CONFIG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    message(STATUS "Writing environment files")

    set(entries_to_file)
    set(entries_list)

    load_values_from_disk(entries_list CONFIG_SET)

    foreach(type_to_generate IN LISTS types_to_generate)
        set(output_file "${CONFIG_OUTPUT_FOLDER}/${type_to_generate}")
        set(input_file "${CMAKE_TOOLS_HOME}/scripts/${type_to_generate}.in")
        message(STATUS "\tWriting ${CONFIG_OUTPUT_FOLDER}/${type_to_generate}")
        format_variables_for_output(type_to_generate entries_list project_environment)
        if("${type_to_generate}" STREQUAL "json")
            string(LENGTH ${project_environment} remove_last_enter)
            math(EXPR remove_last_enter "${remove_last_enter}-2")
            string(SUBSTRING ${project_environment} 0 ${remove_last_enter} project_environment)
        endif()
        configure_file(${input_file} ${output_file} @ONLY)
    endforeach()

endfunction()

# Conan's libraries setting helper
macro(CONAN_CONFIGURE)
    set(multiValueArgs REQUIRES OPTIONS FIND_PACKAGES REMOTES)
    cmake_parse_arguments(CONFIG "" "" "${multiValueArgs}" ${ARGN})

    if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan_paths.cmake")
        # Set config values
        if(CONAN_BUILD_MISSING)
            set(build_option missing)
        else()
            set(build_option never)
        endif()
        set(generators_option cmake cmake_find_package cmake_paths virtualenv virtualbuildenv virtualrunenv)

        # Create conanfile.txt
        conan_cmake_configure(
            REQUIRES
            ${CONFIG_REQUIRES}
            GENERATORS
            ${generators_option}
            IMPORTS
            "lib, *.dylib* -> ./lib"
            "bin, *.dll -> ./lib"
            "lib, *.so* -> ./lib"
            OPTIONS
            ${CONFIG_OPTIONS})

        # Load settings from environment
        conan_cmake_autodetect(settings)

        # Remove cppstd option
        string(REPLACE ";compiler.cppstd=20" "" settings "${settings}")

        # Install conan packages
        conan_cmake_install(PATH_OR_REFERENCE . BUILD ${build_option} SETTINGS ${settings})

        # Include install packages
        if(EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo_multi.cmake)
            include(${CMAKE_BINARY_DIR}/conanbuildinfo_multi.cmake)
        else()
            include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
        endif()

        # Config project
        conan_basic_setup(NO_OUTPUT_DIRS TARGETS)

        conan_set_vs_runtime()
        conan_set_libcxx()
        conan_output_dirs_setup()

        # Setting install binaries dependencies
        if(WIN32)
            file(GLOB BINARY_DEPENDENCIES "${CMAKE_BINARY_DIR}/lib/*.dll")
        else()
            file(GLOB BINARY_DEPENDENCIES "${CMAKE_BINARY_DIR}/lib/*.so*")
        endif()

        install(
            FILES ${BINARY_DEPENDENCIES}
            DESTINATION ${INSTALL_LIBDIR}
            COMPONENT ${COMPONENT_LIBRARY})
    endif()

    # Include cmake module paths
    include(${CMAKE_BINARY_DIR}/conan_paths.cmake)

    # Load packages
    foreach(package IN LISTS CONFIG_FIND_PACKAGES)
        find_package(${package} REQUIRED)
        message(STATUS "\tPackage ${package} loaded")
    endforeach()

    message(STATUS "Conan's libraries setting ${settings}")
endmacro()

# Download conan module
if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/${CONAN_CMAKE_VERSION}/conan.cmake"
         "${CMAKE_BINARY_DIR}/conan/conan.cmake" TLS_VERIFY ON)
endif()
include(${CMAKE_BINARY_DIR}/conan/conan.cmake)
conan_check(VERSION 1.52.0 REQUIRED)

# We don't support Conand version 2.x
set(CONAN_VERSION "2.0.0")
string(REGEX MATCH ".*Conan version ([0-9]+\\.[0-9]+\\.[0-9]+)" FOO "${CONAN_VERSION_OUTPUT}")
if(${CMAKE_MATCH_1} VERSION_GREATER_EQUAL ${CONAN_VERSION})
    message(FATAL_ERROR "Conan v2 is not supported. Installed: ${CMAKE_MATCH_1}, \
        required: ${CONAN_VERSION}. Consider downgrading via 'pip \
        install conan==${CONAN_VERSION}'.")
endif()
message(STATUS "Conan module loaded")
