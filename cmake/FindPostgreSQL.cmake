# Find the PostgreSQL installation.
#
# ----------------------------------------------------------------------------
# Usage:
# In your CMakeLists.txt file do something like this:
# ...
# # PostgreSQL
# FIND_PACKAGE(PostgreSQL)
# ...
# if( PostgreSQL_FOUND )
#   include_directories(${PostgreSQL_INCLUDE_DIRS})
#   link_directories(${PostgreSQL_LIBRARY_DIRS})
# endif( PostgreSQL_FOUND )
# ...
# Remember to include ${PostgreSQL_LIBRARIES} in the target_link_libraries() statement.
#
#
# In Windows, we make the assumption that, if the PostgreSQL files are installed, the default directory
# will be C:\Program Files\PostgreSQL.
#
# ----------------------------------------------------------------------------
# History:
# This module is derived from the module originally found in the VTK source tree.
#
# ----------------------------------------------------------------------------
# Note:
# PostgreSQL_ADDITIONAL_VERSIONS is a variable that can be used to set the
# version mumber of the implementation of PostgreSQL.
# In Windows the default installation of PostgreSQL uses that as part of the path.
# E.g C:\Program Files\PostgreSQL\8.4.
# Currently, the following version numbers are known to this module:
# "9.1" "9.0" "8.4" "8.3" "8.2" "8.1" "8.0"
#
# To use this variable just do something like this:
# set(PostgreSQL_ADDITIONAL_VERSIONS "9.2" "8.4.4")
# before calling FIND_PACKAGE(PostgreSQL) in your CMakeLists.txt file.
# This will mean that the versions you set here will be found first in the order
# specified before the default ones are searched.
#
# ----------------------------------------------------------------------------
# You may need to manually set:
#  PostgreSQL_INCLUDE_DIR  - the path to where the PostgreSQL include files are.
#  PostgreSQL_LIBRARY_DIR  - The path to where the PostgreSQL library files are.
# If FindPostgreSQL.cmake cannot find the include files or the library files.
#
# ----------------------------------------------------------------------------
# The following variables are set if PostgreSQL is found:
#  PostgreSQL_FOUND         - Set to true when PostgreSQL is found.
#  PostgreSQL_INCLUDE_DIRS  - Include directories for PostgreSQL
#  PostgreSQL_LIBRARY_DIRS  - Link directories for PostgreSQL libraries
#  PostgreSQL_LIBRARIES     - The PostgreSQL libraries.
#
# ----------------------------------------------------------------------------
# If you have installed PostgreSQL in a non-standard location.
# (Please note that in the following comments, it is assumed that <Your Path>
# points to the root directory of the include directory of PostgreSQL.)
# Then you have three options.
# 1) After CMake runs, set PostgreSQL_INCLUDE_DIR to <Your Path>/include and
#    PostgreSQL_LIBRARY_DIR to wherever the library pq (or libpq in windows) is
# 2) Use CMAKE_INCLUDE_PATH to set a path to <Your Path>/PostgreSQL<-version>. This will allow find_path()
#    to locate PostgreSQL_INCLUDE_DIR by utilizing the PATH_SUFFIXES option. e.g. In your CMakeLists.txt file
#    SET(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "<Your Path>/include")
# 3) Set an environment variable called ${PostgreSQL_ROOT} that points to the root of where you have
#    installed PostgreSQL, e.g. <Your Path>.
#
# ----------------------------------------------------------------------------

set(PostgreSQL_INCLUDE_PATH_DESCRIPTION "top-level directory containing the PostgreSQL include directories. E.g /usr/local/include/PostgreSQL/8.4 or C:/Program Files/PostgreSQL/8.4/include")
set(PostgreSQL_INCLUDE_DIR_MESSAGE "Set the PostgreSQL_INCLUDE_DIR cmake cache entry to the ${PostgreSQL_INCLUDE_PATH_DESCRIPTION}")
set(PostgreSQL_LIBRARY_PATH_DESCRIPTION "top-level directory containing the PostgreSQL libraries.")
set(PostgreSQL_LIBRARY_DIR_MESSAGE "Set the PostgreSQL_LIBRARY_DIR cmake cache entry to the ${PostgreSQL_LIBRARY_PATH_DESCRIPTION}")
set(PostgreSQL_ROOT_DIR_MESSAGE "Set the PostgreSQL_ROOT system variable to where PostgreSQL is found on the machine E.g C:/Program Files/PostgreSQL/8.4")

# Only versions with extensions
set(PostgreSQL_KNOWN_VERSIONS ${PostgreSQL_ADDITIONAL_VERSIONS}
    "9.5" "9.4" "9.3" "9.2" "9.1")

set(PostgreSQL_ROOT_DIRECTORIES
    ENV PostgreSQL_ROOT
    ${PostgreSQL_ROOT}
    )


# Define additional search paths for root directories.
if ( WIN32 )
    foreach (suffix ${PostgreSQL_KNOWN_VERSIONS} )
        set(ADDITIONAL_SEARCH_PATHS ${ADDITIONAL_SEARCH_PATHS} "C:/Program Files/PostgreSQL/${suffix}" )
    endforeach(suffix)
endif( WIN32 )

set( PostgreSQL_ROOT_DIRECTORIES
    ${ADDITIONAL_SEARCH_PATHS}
    ${PostgreSQL_ROOT_DIRECTORIES}
    ${PostgreSQL_ROOT}
    )


#
# Look for an installation.
#
if (NOT EXISTS "${PostgreSQL_INCLUDE_DIR}")
    find_path(PostgreSQL_INCLUDE_DIR
        NAMES libpq-fe.h
        PATHS
        # Look in other places.
        ${PostgreSQL_ROOT_DIRECTORIES}
        PATH_SUFFIXES
        pgsql
        postgresql
        include
        # Help the user find it if we cannot.
        DOC "The ${PostgreSQL_INCLUDE_DIR_MESSAGE}"
        )


    # find where the includes fliles are installed for the particular version os postgreSQL
    if ( UNIX )
        foreach (suffix ${PostgreSQL_KNOWN_VERSIONS} )
            set(postgresql_additional_search_paths ${postgresql_additional_search_paths} "${PostgreSQL_INCLUDE_DIR}/${suffix}/server" )
        endforeach()

        #
        # Look for THE installation.
        #
        find_path(PostgreSQL_TYPE_INCLUDE_DIR
            NAMES catalog/pg_type.h
            PATHS
            # Look in other places.
            ${postgresql_additional_search_paths}
            ${PostgreSQL_ROOT_DIRECTORIES}
            PATH_SUFFIXES
            postgresql
            pgsql/server
            postgresql/server
            include/server
            # Help the user find it if we cannot.
            DOC "The ${PostgreSQL_INCLUDE_DIR_MESSAGE}"
            )
        set (PostgreSQL_INCLUDE_DIR ${PostgreSQL_TYPE_INCLUDE_DIR})
        unset(postgresql_additional_search_paths)

    endif()
endif()


# The PostgreSQL library.
set (PostgreSQL_LIBRARY_TO_FIND "pq")

# Setting some more prefixes for the library
set (PostgreSQL_LIB_PREFIX "")

if ( WIN32 )
    set (PostgreSQL_LIB_PREFIX ${PostgreSQL_LIB_PREFIX} "lib")
    set ( PostgreSQL_LIBRARY_TO_FIND ${PostgreSQL_LIB_PREFIX}${PostgreSQL_LIBRARY_TO_FIND})
endif()

if (NOT EXISTS "$(PostgreSQL_LIBRARY_DIR}")

    find_library( PostgreSQL_LIBRARY
        NAMES ${PostgreSQL_LIBRARY_TO_FIND}
        PATHS
        ${PostgreSQL_ROOT_DIRECTORIES}
        PATH_SUFFIXES
        lib
        )

    get_filename_component(PostgreSQL_LIBRARY_DIR ${PostgreSQL_LIBRARY} PATH)



    # find where the libraries are installed for the particular version os postgreSQL
    if ( UNIX )
        foreach (suffix ${PostgreSQL_KNOWN_VERSIONS} )
            set(postgresql_lib_additional_search_paths ${postgresql_lib_additional_search_paths} "${PostgreSQL_LIBRARY_DIR}/postgresql/${suffix}" )
        endforeach()

        find_library( postgresql_new_library
            NAMES "worker_spi.so"
            PATHS
            ${postgresql_lib_additional_search_paths}
            ${PostgreSQL_ROOT_DIRECTORIES}
            PATH_SUFFIXES
            lib
            )

        get_filename_component(PostgreSQL_LIBRARY_DIR ${postgresql_new_library} PATH)

        unset (postgresql_lib_additional_search_paths)
        unset (postgresql_new_library)

    endif()
endif()


if (NOT EXISTS PostgreSQL_EXTENSION_DIR)
    # find where the extensions are installed for the particular version os postgreSQL
    if ( UNIX )

        foreach (suffix ${PostgreSQL_KNOWN_VERSIONS} )
            set(PostgreSQL_EXT_ADDITIONAL_SEARCH_PATHS ${PostgreSQL_EXT_ADDITIONAL_SEARCH_PATHS} "/usr/share/postgresql/${suffix}" )
        endforeach()

        find_path(PostgreSQL_EXTENSION_DIR
            NAMES plpgsql.control
            PATHS
            # Look in other places.
            ${PostgreSQL_EXT_ADDITIONAL_SEARCH_PATHS}
            #            ${PostgreSQL_ROOT_DIRECTORIES}
            PATH_SUFFIXES
            extension
            )
    endif()
endif()



if (EXISTS ${PostgreSQL_INCLUDE_DIR} AND EXISTS "${PostgreSQL_INCLUDE_DIR}/pg_config.h")
    file(STRINGS "${PostgreSQL_INCLUDE_DIR}/pg_config.h" pgsql_version_str
        REGEX "^#define[\t ]+PG_VERSION[\t ]+\".*\"")

    string(REGEX REPLACE "^#define[\t ]+PG_VERSION[\t ]+\"([^\"]*)\".*" "\\1"
        PostgreSQL_VERSION_STRING "${pgsql_version_str}")
    unset(pgsql_version_str)
endif()


# Did we find the things needed for pgRouting?
if (UNIX)
    set( PostgreSQL_FOUND FALSE )
    if (
            EXISTS "${PostgreSQL_INCLUDE_DIR}" AND
            EXISTS "${PostgreSQL_LIBRARY_DIR}" AND
            EXISTS "${PostgreSQL_EXTENSION_DIR}" )
        set( PostgreSQL_FOUND TRUE )
        set( PostgreSQL_INCLUDE_DIRS ${PostgreSQL_TYPE_INCLUDE_DIR})
        set( PostgreSQL_LIBRARY_DIRS ${PostgreSQL_LIBRARY_DIR})
        set( PostgreSQL_EXTENSION_DIRS ${PostgreSQL_EXTENSION_DIR})

        if(PostgreSQL_DEBUG)
            message("PostgreSQL_VERSION_STRING: ${PostgreSQL_VERSION_STRING}")
            message("PostgreSQL_INCLUDE_DIRS: ${PostgreSQL_INCLUDE_DIRS}")
            message("PostgreSQL_LIBRARY_DIRS: ${PostgreSQL_LIBRARY_DIRS}")
            message("PostgreSQL_EXTENSION_DIRS: ${PostgreSQL_EXTENSION_DIRS}")
            message("PostgreSQL_LIBRARY: ${PostgreSQL_LIBRARY}")
        endif()

    else()
        message(FATAL_ERROR "PostgreSQL was not found. ${PostgreSQL_DIR_MESSAGE}
        PostgreSQL_VERSION_STRING: ${PostgreSQL_VERSION_STRING}
        PostgreSQL_INCLUDE_DIR: ${PostgreSQL_INCLUDE_DIR}
        PostgreSQL_LIBRARY_DIR: ${PostgreSQL_LIBRARY_DIR}
        PostgreSQL_EXTENSION_DIR: ${PostgreSQL_EXTENSION_DIR}
        PostgreSQL_LIBRARY: ${PostgreSQL_LIBRARY}")
    endif()

else(UNIX)
    set( PostgreSQL_FOUND FALSE )
    if ( EXISTS "${PostgreSQL_INCLUDE_DIR}" AND EXISTS "${PostgreSQL_LIBRARY_DIR}" )
        set( PostgreSQL_FOUND TRUE )
    else ( EXISTS "${PostgreSQL_INCLUDE_DIR}" AND EXISTS "${PostgreSQL_LIBRARY_DIR}" )
        if ( POSTGRES_REQUIRED )
            message( FATAL_ERROR "PostgreSQL is required. ${PostgreSQL_ROOT_DIR_MESSAGE}" )
        endif ( POSTGRES_REQUIRED )
    endif (EXISTS "${PostgreSQL_INCLUDE_DIR}" AND EXISTS "${PostgreSQL_LIBRARY_DIR}" )
    # Now try to get the include and library path.
    if(PostgreSQL_FOUND)

        if(EXISTS "${PostgreSQL_INCLUDE_DIR}")
            set(PostgreSQL_INCLUDE_DIRS
                ${PostgreSQL_INCLUDE_DIR}
                )
        endif(EXISTS "${PostgreSQL_INCLUDE_DIR}")

        if(EXISTS "${PostgreSQL_LIBRARY_DIR}")
            set(PostgreSQL_LIBRARY_DIRS
                ${PostgreSQL_LIBRARY_DIR}
                )
            set(PostgreSQL_LIBRARIES ${PostgreSQL_LIBRARY_TO_FIND})
        endif(EXISTS "${PostgreSQL_LIBRARY_DIR}")

        if(PostgreSQL_DEBUG)
            message("PostgreSQL_VERSION_STRING: ${PostgreSQL_VERSION_STRING}")
            message("PostgreSQL_INCLUDE_DIRS: ${PostgreSQL_INCLUDE_DIRS}")
            message("PostgreSQL_LIBRARY_DIRS: ${PostgreSQL_LIBRARY_DIRS}")
            message("PostgreSQL_EXTENSION_DIRS: ${PostgreSQL_EXTENSION_DIRS}")
            message("PostgreSQL_LIBRARY: ${PostgreSQL_LIBRARY}")
        endif()


    else(PostgreSQL_FOUND)
        message(FATAL_ERROR "PostgreSQL was not found. ${PostgreSQL_DIR_MESSAGE}
        PostgreSQL_VERSION_STRING: ${PostgreSQL_VERSION_STRING}
        PostgreSQL_INCLUDE_DIR: ${PostgreSQL_INCLUDE_DIR}
        PostgreSQL_LIBRARY_DIR: ${PostgreSQL_LIBRARY_DIR}
        PostgreSQL_EXTENSION_DIR: ${PostgreSQL_EXTENSION_DIR}
        PostgreSQL_LIBRARY: ${PostgreSQL_LIBRARY}")
    endif()
endif(UNIX)
