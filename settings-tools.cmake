#
# Configure project and target default parameters.
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY HELPSTRING "Choose build type")
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug;Release")

# Check the CMakeLists.txt location
if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt")
    message(
        FATAL_ERROR
            "In-source builds are not allowed, please create a 'build' subfolder and use `cmake ..` inside it.\n"
            "NOTE: cmake will now create CMakeCache.txt and CMakeFiles/*.\n"
            "You must delete them, or cmake will refuse to work.")
endif()

# Check if the Generator is multi configuration
get_property(IS_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTI_CONFIG)
    message(STATUS "Multi-config generator detected")
    set(CMAKE_CONFIGURATION_TYPES
        "Debug;Release"
        CACHE STRING "" FORCE)
else()
    if(NOT CMAKE_BUILD_TYPE)
        message(STATUS "Setting build type to Debug by default")
        set(CMAKE_BUILD_TYPE
            "Debug"
            CACHE STRING "" FORCE)
    endif()
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY HELPSTRING "Choose build type")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug;Release")
endif()

# Setting build type constraints
if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to Debug by default")
    set(CMAKE_BUILD_TYPE
        "Debug"
        CACHE STRING "" FORCE)
endif()

# Create the target specified
function(create_target)
    set(oneValueArgs TARGET LIBRARY STATIC WITH_CONSOLE)
    set(multiValueArgs SOURCES)
    cmake_parse_arguments(CONFIG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(CONFIG_LIBRARY)
        if(CONFIG_STATIC)
            message(STATUS "Creating ${CONFIG_TARGET}, which is a static library")
            add_library(${CONFIG_TARGET} STATIC ${CONFIG_SOURCES})
        else()
            message(STATUS "Creating ${CONFIG_TARGET}, which is a shared library")
            add_library(${CONFIG_TARGET} SHARED ${CONFIG_SOURCES})
            set_target_properties(${CONFIG_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
        endif()
    else()
        add_executable(${CONFIG_TARGET} ${CONFIG_SOURCES})
        if(CONFIG_WITH_CONSOLE)
            message(STATUS "Creating ${CONFIG_TARGET}, which is an executable")
        else()
            message(STATUS "Creating ${CONFIG_TARGET}, which is an executable without console")
            set_target_properties(${CONFIG_TARGET} PROPERTIES WIN32_EXECUTABLE ON MACOSX_BUNDLE ON)
        endif()
        set_target_properties(${CONFIG_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
    endif()
endfunction()

# Setup the target
function(config_gtest_properties gtest_param)
    if(gtest_param)
        if(MSVC)
            if(MSVC_VERSION AND (MSVC_VERSION EQUAL 1910 OR MSVC_VERSION GREATER 1910))
                add_definitions(-DGTEST_LANG_CXX11=1 -DGTEST_HAS_TR1_TUPLE=0 -DGTEST_LINKED_AS_SHARED_LIBRARY=1)
            endif()
        endif()
    endif()
endfunction()

# Setup the RPATH
function(config_rpath)
    set(oneValueArgs TARGET LIBRARY)
    cmake_parse_arguments(CONFIG "" "${oneValueArgs}" "" ${ARGN})

    file(RELATIVE_PATH _rel ${CMAKE_INSTALL_PREFIX}/${INSTALL_BINDIR} ${CMAKE_INSTALL_PREFIX})
    if(APPLE)
        set(rpath "@loader_path/${_rel}")
    else()
        set(rpath "\$ORIGIN/${_rel}")
    endif()
    file(TO_NATIVE_PATH "${rpath}/${INSTALL_LIBDIR}" message_RPATH)

    if(NOT CONFIG_LIBRARY)
        message(STATUS "\tSetting rpath for ${CONFIG_TARGET} to ${message_RPATH}")
        set_target_properties(
            ${CONFIG_TARGET}
            PROPERTIES MACOSX_RPATH TRUE
                       SKIP_BUILD_RPATH FALSE
                       BUILD_WITH_INSTALL_RPATH FALSE
                       INSTALL_RPATH "${message_RPATH}"
                       INSTALL_RPATH_USE_LINK_PATH TRUE)
    endif()
endfunction()

# Setup the target_compile_options
function(set_target_compile_options config_target config_cpp)
    if(MSVC)
        set(custom_compile_options /W4 /WX)
        if(${config_cpp})
            list(APPEND custom_compile_options /wd4996)
            target_compile_options(${config_target} PUBLIC "/Zc:__cplusplus")
        endif()
    else()
        set(custom_compile_options -Wall -Wextra -Werror)
    endif()

    if(USE_CODE_WARNINGS_AS_ERRORS)
        message(STATUS "\tCompile options            : ${custom_compile_options}")
        target_compile_options(${config_target} PRIVATE ${custom_compile_options})
    endif()
endfunction()

# Setup the target specified
function(config_target)
    set(options LIBRARY STATIC GTEST CPP WITH_CONSOLE)
    set(oneValueArgs TARGET)
    set(multiValueArgs
        AUTOGEN_SOURCES
        PUBLIC_HEADERS
        PUBLIC_LIBRARIES
        PRIVATE_LIBRARIES
        PRIVATE_DEFINITIONS
        SOURCES
        PRIVATE_INCLUDE_DIRECTORIES
        PUBLIC_INCLUDE_DIRECTORIES)
    cmake_parse_arguments(CONFIG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    create_target(
        WITH_CONSOLE
        ${CONFIG_WITH_CONSOLE}
        TARGET
        ${CONFIG_TARGET}
        LIBRARY
        ${CONFIG_LIBRARY}
        STATIC
        ${CONFIG_STATIC}
        SOURCES
        ${CONFIG_SOURCES})

    config_rpath(TARGET ${CONFIG_TARGET} LIBRARY ${CONFIG_LIBRARY})
    config_gtest_properties(${CONFIG_GTEST})

    if(CONFIG_CPP)
        message(STATUS "\tSetting as CXX target")
        set_target_properties(
            ${CONFIG_TARGET}
            PROPERTIES LINKER_LANGUAGE CXX
                       CXX_STANDARD 17
                       CXX_EXTENSIONS OFF)
    else()
        message(STATUS "\tSetting as C target")
        set_target_properties(
            ${CONFIG_TARGET}
            PROPERTIES LINKER_LANGUAGE C
                       C_STANDARD 99
                       C_EXTENSIONS OFF)
    endif()

    if(DEFINED CONFIG_PRIVATE_DEFINITIONS)
        message(STATUS "\tPrivate definitions        : ${CONFIG_PRIVATE_DEFINITIONS}")
        target_compile_definitions(${CONFIG_TARGET} PRIVATE ${PRIVATE_DEFINITIONS})
    endif()

    if(DEFINED CONFIG_AUTOGEN_SOURCES)
        message(STATUS "\tAutogen sources            : ${CONFIG_AUTOGEN_SOURCES}")
        foreach(item IN LISTS AUTOGEN_SOURCES)
            string(REGEX REPLACE "\\.[^.]*$" "" SRC ${item})
            configure_file(${item} ${SRC} @ONLY)
            target_sources(${CONFIG_TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/${SRC})
        endforeach()
    endif()

    if(DEFINED CONFIG_PUBLIC_LIBRARIES)
        message(STATUS "\tPublic libraries           : ${CONFIG_PUBLIC_LIBRARIES}")
        target_link_libraries(${CONFIG_TARGET} PUBLIC ${CONFIG_PUBLIC_LIBRARIES})
    endif()

    if(DEFINED CONFIG_PRIVATE_LIBRARIES)
        message(STATUS "\tPrivate libraries          : ${CONFIG_PRIVATE_LIBRARIES}")
        target_link_libraries(${CONFIG_TARGET} PUBLIC ${CONFIG_PRIVATE_LIBRARIES})
    endif()

    if(DEFINED CONFIG_PUBLIC_HEADERS)
        message(STATUS "\tPublic headers             : ${CONFIG_PUBLIC_HEADERS}")
        target_sources(${CONFIG_TARGET} PUBLIC FILE_SET HEADERS FILES ${CONFIG_PUBLIC_HEADERS})
    endif()

    if(DEFINED CONFIG_PRIVATE_INCLUDE_DIRECTORIES)
        message(STATUS "\tPrivate include directories: ${CONFIG_PRIVATE_INCLUDE_DIRECTORIES}")
        target_include_directories(${CONFIG_TARGET} PRIVATE ${CONFIG_PRIVATE_INCLUDE_DIRECTORIES})
    endif()

    if(DEFINED CONFIG_PUBLIC_INCLUDE_DIRECTORIES)
        message(STATUS "\tPublic include directories : ${CONFIG_PUBLIC_INCLUDE_DIRECTORIES}")
        target_include_directories(${CONFIG_TARGET} PUBLIC ${CONFIG_PUBLIC_INCLUDE_DIRECTORIES})
    endif()

endfunction()

# Default policies
message(STATUS "Setting default policies")
if(APPLE)
    message(STATUS "\tCMP0042 NEW")
    cmake_policy(SET CMP0042 NEW)
    message(STATUS "\tCMP0068 NEW")
    cmake_policy(SET CMP0068 NEW)
endif()
