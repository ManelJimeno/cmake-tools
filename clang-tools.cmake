#
# clang tools configs
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

option(USE_STATIC_ANALYSIS "Use code static analysis on build" ON)

if(USE_STATIC_ANALYSIS)
    message(STATUS "Using clang-tidy on build")
    file(RELATIVE_PATH PATH_REGEX "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
    set(PATH_REGEX "${CMAKE_CURRENT_BINARY_DIR}/${PATH_REGEX}(include|src)/.*")
    set(CMAKE_CXX_CLANG_TIDY clang-tidy -header-filter=${PATH_REGEX})
    set(CMAKE_C_CLANG_TIDY clang-tidy -header-filter=${PATH_REGEX})
endif()
