#
# Configure conan with modules-cmake.
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

option(CMAKE_TOOLS_BUILD_DOC "Build documentation" ON)
option(CMAKE_TOOLS_BUILD_INSTALLER "Build the installer for the current platform" ON)
option(CMAKE_TOOLS_USE_CODE_WARNINGS_AS_ERRORS "Use code warnings as errors" ON)

include(version-tools)
include(install-tools)
include(conan-tools)
include(pre-commit)
include(settings-tools)
include(gtest-tools)
include(doc-tools)

set(CMAKE_TOOLS_HOME "${CMAKE_CURRENT_LIST_DIR}")
