#
# Configure project and target default parameters.
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

# Populate product version from file
function(populate_product_version_from_file)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/version")
        file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/version" version_string REGEX "[0-9]+\\.[0-9]+\\.[0-9]+")
        string(REPLACE "." ";" VERSION_LIST ${version_string})
        list(GET VERSION_LIST 0 local_major)
        list(GET VERSION_LIST 1 local_minor)
        list(GET VERSION_LIST 2 local_revision)
        set(PRODUCT_VERSION_MAJOR
            ${local_major}
            PARENT_SCOPE)
        set(PRODUCT_VERSION_MINOR
            ${local_minor}
            PARENT_SCOPE)
        set(PRODUCT_VERSION_REVISION
            ${local_revision}
            PARENT_SCOPE)
        set(PRODUCT_VERSION
            "${version_string}"
            PARENT_SCOPE)
    else()
        message(FATAL_ERROR "It is mandatory to have a version of the file in the ${CMAKE_CURRENT_SOURCE_DIR} folder")
    endif()
endfunction()

# Populate product version from git info
function(populate_product_version_from_git)
    find_package(Git QUIET REQUIRED)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" log -n 1 --pretty=format:%H -- version
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE COMMAND_RESULT
            OUTPUT_VARIABLE VERSION_GIT_HASH
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        if(COMMAND_RESULT EQUAL "0")
            execute_process(
                COMMAND "${GIT_EXECUTABLE}" rev-list ${VERSION_GIT_HASH}..HEAD
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                RESULT_VARIABLE COMMAND_RESULT
                OUTPUT_VARIABLE rev_list_number
                OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
            if(COMMAND_RESULT EQUAL "0")
                string(REGEX REPLACE "\n" ";" rev_list_number "${rev_list_number}")
                list(LENGTH rev_list_number rev_list_number)

                execute_process(
                    COMMAND "${GIT_EXECUTABLE}" rev-parse --short=7 HEAD
                    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                    RESULT_VARIABLE COMMAND_RESULT
                    OUTPUT_VARIABLE CURRENT_GIT_HASH
                    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
                if(COMMAND_RESULT EQUAL "0")
                    set(PRODUCT_VERSION_LONG
                        "${PRODUCT_VERSION}.${rev_list_number}-${CURRENT_GIT_HASH}"
                        PARENT_SCOPE)
                    set(PRODUCT_REPOSITORY_COMMIT
                        "${CURRENT_GIT_HASH}"
                        PARENT_SCOPE)
                endif()
            endif()
        endif()
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" config --get remote.origin.url
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            RESULT_VARIABLE COMMAND_RESULT
            OUTPUT_VARIABLE REPOSITORY_URL
            OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
        set(PRODUCT_REPOSITORY_URL
            ${REPOSITORY_URL}
            PARENT_SCOPE)
    endif()
endfunction()

# Populate config values from file
function(populate_values_from_file)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/project_customization.txt")
        file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/project_customization.txt" entries_from_file)
        foreach(entry IN LISTS entries_from_file)
            # We only recognize as valid inputs of type name=value
            if(entry MATCHES "^([^=]+)=(.*)$")
                set(${CMAKE_MATCH_1}
                    ${CMAKE_MATCH_2}
                    PARENT_SCOPE)
            endif()
        endforeach()
    else()
        message(
            FATAL_ERROR
                "It is mandatory to have a project_customization.txt file in the ${CMAKE_CURRENT_SOURCE_DIR} folder")
    endif()
endfunction()

if(NOT PRODUCT_VERSION)
    populate_values_from_file()
    populate_product_version_from_file()
    populate_product_version_from_git()
    message(STATUS "The current version product is ${PRODUCT_VERSION_LONG}")
endif()
