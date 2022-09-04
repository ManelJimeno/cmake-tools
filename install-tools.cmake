#
# Install the pre-commit tool and set up the git hook.
#
# Part of https://github.com/ManelJimeno/bootstrap (C) 2022
#
# Authors: Manel Jimeno <manel.jimeno@gmail.com>
#
# License: http://www.opensource.org/licenses/mit-license.php MIT
#

# Configure the installation to Linux platform
macro(CONFIGURE_INSTALL_LINUX)
    if(CMAKE_SYSTEM_NAME MATCHES Linux)
        set(CPACK_PACKAGING_INSTALL_PREFIX /opt)
        set(CMAKE_INSTALL_RPATH /opt)
        set(CPACK_GENERATOR "DEB")
        set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CONFIG_AUTHOR_PROJECT}")
        set(CPACK_DEBIAN_PACKAGE_SECTION "utils")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "python3")
    endif()
endmacro()

# Configure the installation to Windows platform
macro(CONFIGURE_INSTALL_WINDOWS)
    if(WIN32 OR MINGW)
        set(INSTALL_LIBDIR ".")
        set(INSTALL_BINDIR ".")
        set(INSTALL_DOCDIR docs)

        # Install program files
        foreach(target ${CONFIG_TARGETS})
            get_target_property(target_type ${target} TYPE)
            set(extension "dll")
            if(target_type STREQUAL "EXECUTABLE")
                set(extension "exe")
            endif()
            install(FILES ${PROJECT_BINARY_DIR}/bin/${target}.${extension} DESTINATION ${INSTALL_BINDIR})
        endforeach()

        set(CPACK_NSIS_MUI_ICON "${CMAKE_TOOLS_HOME}/images/install.ico")
        set(CPACK_NSIS_MUI_UNIICON "${CMAKE_TOOLS_HOME}/images/uninstall.ico")
        set(CPACK_PACKAGE_ICON "${CMAKE_TOOLS_HOME}/images\\\\logo.png")
        set(CPACK_NSIS_INSTALLED_ICON_NAME "${CMAKE_BINARY_DIR}/bin\\\\${CONFIG_PROGRAM_NAME}.exe")
        set(CPACK_NSIS_CREATE_ICONS
            "CreateShortCut '\$DESKTOP\\\\${CONFIG_PROGRAM_NAME}.lnk' '\$INSTDIR\\\\${CONFIG_PROGRAM_NAME}.exe'")
        set(CPACK_NSIS_DELETE_ICONS_EXTRA "Delete '\$DESKTOP\\\\${CONFIG_PROGRAM_NAME}.lnk'")
        set(CPACK_NSIS_MODIFY_PATH OFF)
        set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
        set(CPACK_NSIS_MUI_FINISHPAGE_RUN "${CONFIG_PROGRAM_NAME}.exe")
        set(CPACK_NSIS_IGNORE_LICENSE_PAGE ON)
        set(CPACK_GENERATOR "NSIS")
        set(CPACK_NSIS_PACKAGE_NAME "${PROJECT_NAME}")
        set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
        set(CPACK_CREATE_DESKTOP_LINKS "${CONFIG_PROGRAM_NAME}")
        set(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\\\${CONFIG_PROGRAM_NAME}.exe")
        set(CPACK_SOURCE_IGNORE_FILES "${PROJECT_BINARY_DIR};/.git/;.gitignore")
    endif()
endmacro()

# Configure the installation to MAC OS platform
macro(CONFIGURE_INSTALL_MAC_OS)
    if(APPLE)
        set(CPACK_GENERATOR "Bundle")
        set(CPACK_BUNDLE_NAME "${PROJECT_NAME}")
        configure_file("${CMAKE_TOOLS_HOME}/osx_bundle/Info.plist.in" Info.plist @ONLY)
        set(CPACK_BUNDLE_PLIST ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
        set(CPACK_BUNDLE_ICON "${CMAKE_TOOLS_HOME}/osx_bundle/application.icns")
        set(CPACK_BUNDLE_STARTUP_COMMAND "${CMAKE_TOOLS_HOME}/osx_bundle/launch.sh")
        set(CPACK_PACKAGE_EXECUTABLES "${CONFIG_PROGRAM_NAME}" "${CONFIG_PROGRAM_NAME}")
        set(CPACK_CREATE_DESKTOP_LINKS "${CONFIG_PROGRAM_NAME}")
    endif()
endmacro()

# Configure the installation info of the project
macro(CONFIGURE_INSTALLER)
    set(oneValueArgs PROGRAM_NAME)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(CONFIG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    message(STATUS "Configuring installer creation")

    set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
    if(EXISTS "${PROJECT_SOURCE_DIR}/INSTALL.md")
        set(CPACK_PACKAGE_DESCRIPTION_FILE "${PROJECT_SOURCE_DIR}/INSTALL.md")
    endif()
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
    if(EXISTS "${PROJECT_SOURCE_DIR}/LICENSE")
        set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/LICENSE")
    endif()

    set(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
    set(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
    set(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_VERSION_PATCH}")
    set(CPACK_PACKAGE_VERSION
        "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

    set(CPACK_SOURCE_GENERATOR "ZIP;TGZ")
    set(CPACK_GENERATOR "ZIP;TGZ")

    configure_install_linux()
    configure_install_windows()
    configure_install_mac_os()

    message(STATUS "\tCPack generators: ${CPACK_GENERATOR}")
    include(CPack)

    add_custom_target(
        build_installer_${PROJECT_NAME}
        "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target package
        COMMENT "Create installer for ${PROJECT_NAME}")

endmacro()

# Common section
enable_language(CXX)
include(GNUInstallDirs)

# Definition of default values
set(COMPONENT_LIBRARY lib)
set(COMPONENT_ARCHIVE lib)
set(COMPONENT_RUNTIME bin)
set(COMPONENT_DOCUMENTATION doc)

set(INSTALL_LIBDIR
    ${CMAKE_INSTALL_LIBDIR}
    CACHE PATH "Installation directory for libraries")
set(INSTALL_BINDIR
    ${CMAKE_INSTALL_BINDIR}
    CACHE PATH "Installation directory for executables")
set(INSTALL_DOCDIR
    ${CMAKE_INSTALL_DOCDIR}
    CACHE PATH "Installation directory for documentation")

foreach(install_path LIB BIN DOC)
    file(TO_NATIVE_PATH ${CMAKE_INSTALL_PREFIX}/${INSTALL_${install_path}DIR} _path)
    message(STATUS "\tInstalling ${install_path} components to ${_path}")
    unset(_path)
endforeach()
