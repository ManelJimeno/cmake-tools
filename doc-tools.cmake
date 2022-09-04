#
# Configure documentation for the project
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

# Configure doc
function(create_documentation_target)
    message(STATUS "Configuring documentation")

    # Loading tools
    if(WIN32)
        find_package(doxygen REQUIRED)
        find_program(
            DOXYGEN_EXECUTABLE
            NAMES doxygen.exe
            DOC "Path to doxygen executable")
    else()
        find_package(Doxygen REQUIRED)
    endif()

    find_package(PythonInterp REQUIRED)
    find_package(Sphinx REQUIRED)

    # Doxygen settings
    set(doxygen_root "${CMAKE_BINARY_DIR}/docs/doxygen")
    set(doxygen_file "${doxygen_root}/Doxyfile")
    set(doxygen_output_dir "${doxygen_root}/output")
    set(doxygen_index_file "${doxygen_output_dir}/xml/index.xml")

    set(doxygen_input_dir "${doxygen_root}")
    foreach(item IN LISTS PRODUCT_DOC_INPUT)
        set(doxygen_input_dir "${doxygen_input_dir} ${item}")
    endforeach()

    # Only regenerate Doxygen when the Doxyfile changes
    add_custom_command(
        OUTPUT ${doxygen_index_file}
        COMMAND ${DOXYGEN_EXECUTABLE} ${doxygen_file}
        MAIN_DEPENDENCY ${doxygen_file}
        WORKING_DIRECTORY ${doxygen_root}
        COMMENT "Building ${CMAKE_PROJECT_NAME} documentation with Doxygen"
        VERBATIM)

    # Sphinx settings
    set(sphinx_root "${CMAKE_BINARY_DIR}/docs/sphinx")
    set(sphinx_output_dir "${sphinx_root}/output")
    set(sphinx_input_dir ${doxygen_input_dir})
    set(sphinx_index_file ${sphinx_output_dir}/index.html)

    # Only regenerate Sphinx when:
    #
    # * Doxygen has rerun
    # * Our doc files have been updated
    # * The Sphinx config has been updated

    add_custom_command(
        OUTPUT ${sphinx_index_file}
        COMMAND ${SPHINX_EXECUTABLE} -q -b html ${sphinx_root} ${sphinx_output_dir}
        WORKING_DIRECTORY ${sphinx_root}
        DEPENDS # Other docs files you want to track should go here (or in some variable)
                ${sphinx_root}/index.rst ${doxygen_index_file}
        MAIN_DEPENDENCY ${sphinx_root}/conf.py
        COMMENT "Generating ${CMAKE_PROJECT_NAME} documentation with Sphinx")

    # Configuring files
    file(GLOB_RECURSE project_doc_templates ${PRODUCT_DOC_TEMPLATES}/*.*)
    foreach(item IN LISTS project_doc_templates)
        string(REPLACE ".in" "" item_output ${item})
        file(RELATIVE_PATH item_output ${CMAKE_SOURCE_DIR} ${item_output})
        configure_file(${item} ${CMAKE_BINARY_DIR}/${item_output} @ONLY)
    endforeach()

    # Name so we can easily create the documentation
    add_custom_target(
        project_doc ALL
        DEPENDS ${sphinx_index_file}
        COMMENT "Generating documentation with Sphinx")

    message(STATUS " Added project_doc target to build (Breathe+Sphinx+Doxygen) documentation")

endfunction()

set(PRODUCT_DOC_INPUT
    ""
    CACHE STRING "List of input folders for documentation" FORCE)

# Add target to doc
function(add_input_folder_to_doc folders)
    if(NOT PRODUCT_DOC_INPUT)
        set(PRODUCT_DOC_INPUT
            "${folders}"
            CACHE STRING "List of input folders for documentation" FORCE)
    else()
        set(PRODUCT_DOC_INPUT
            "${PRODUCT_DOC_INPUT};${folders}"
            CACHE STRING "List of input folders for documentation" FORCE)
    endif()
    mark_as_advanced(PRODUCT_DOC_INPUT)
endfunction()
