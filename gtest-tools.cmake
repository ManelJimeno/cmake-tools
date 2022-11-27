#
# Unit test module
#
# Part of https://github.com/ManelJimeno/cmake-tools (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: https://www.opensource.org/licenses/mit-license.php MIT
#

include(GoogleTest)
enable_testing()

# Create a unit test target
function(add_cpp_test)
    set(oneValueArgs TARGET)
    set(multiValueArgs LIBRARIES)
    cmake_parse_arguments(CONFIG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    config_target(
        CPP
        WITH_CONSOLE
        TARGET
        ${CONFIG_TARGET}
        SOURCES
        ${CONFIG_TARGET}.cpp
        PRIVATE_LIBRARIES
        ${CONFIG_LIBRARIES}
        GTest::gtest
        GTest::gtest_main
        GTEST)

    set_target_properties(${test_name} PROPERTIES FOLDER "test")
    add_test(NAME ${CONFIG_TARGET} COMMAND $<TARGET_FILE:${CONFIG_TARGET}>)

endfunction()
