cmake_minimum_required(VERSION 2.8)
project(ftx)

#-------------------------------------------------------------------------------
# Build options
#-------------------------------------------------------------------------------
option(ftx_BUILD_DEBUG    "Build for debug"          OFF)

#-------------------------------------------------------------------------------
# ftx paths
#-------------------------------------------------------------------------------
set(ftx_INCLUDE_DIRS "${ftx_SOURCE_DIR}/include")

#-------------------------------------------------------------------------------
# Platform-specific settings
#-------------------------------------------------------------------------------

###################
# Building on OSX #
###################
if(APPLE)

  # Clang only
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "CLANG")

    # OSX Framework dependencies
    if(NOT ftx_BUILD_SHARED)
      include_directories( "/System/Library/Frameworks" )
      find_library (COCOA_LIBRARIES Cocoa)
      find_library (IOKIT_LIBRARIES IOkit)
      find_library (COREVIDEO_LIBRARIES CoreVideo)
    endif()

    # Clang configuration
    if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")

      set(CLANG_CXX_FLAGS "-std=c++11 -m64")

      if(ftx_BUILD_DEBUG)
        set(CMAKE_BUILD_TYPE Debug)
      else(ftx_BUILD_DEBUG)
        set(CLANG_CXX_FLAGS "${CLANG_CXX_FLAGS} -O3")
        set(CLANG_CXX_FLAGS "${CLANG_CXX_FLAGS} -funroll-loops")
        set(CLANG_CXX_FLAGS "${CLANG_CXX_FLAGS} -Wno-narrowing")
        set(CLANG_CXX_FLAGS "${CLANG_CXX_FLAGS} -Wno-deprecated-register")
      endif(ftx_BUILD_DEBUG)

      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CLANG_CXX_FLAGS}")

    endif()

    # GCC configuration
    if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")

      set(GCC_CXX_FLAGS "-std=gnu++11 -m64")

      if(ftx_BUILD_DEBUG)
        set(CMAKE_BUILD_TYPE Debug)
      else(ftx_BUILD_DEBUG)
        set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -O3")
        set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -fopenmp")
      endif(ftx_BUILD_DEBUG)

      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_CXX_FLAGS}")

    endif()

  endif()

endif(APPLE)

##################
# Build on Linux #
##################
set(LINUX UNIX AND NOT APPLE)
if(LINUX)

  # GCC only
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")

    set(GCC_CXX_FLAGS "-std=gnu++11 -m64")

    # X11 Dependencies
    if(NOT ftx_BUILD_SHARED)
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXi")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXxf86vm")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXinerama")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXcursor")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXfixes")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXrandr")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXext")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXrender")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lX11")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lpthread")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lxcb")
      set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -lXau")
    endif()

    # Debug configuration
    if(ftx_BUILD_DEBUG)
        set(CMAKE_BUILD_TYPE Debug)
    else(ftx_BUILD_DEBUG)
        set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -O3")
        set(GCC_CXX_FLAGS "${GCC_CXX_FLAGS} -fopenmp")
    endif(ftx_BUILD_DEBUG)

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${GCC_CXX_FLAGS}")

  endif()

endif(LINUX)

####################
# Build on Windows #
####################
if(WIN32)

  if(MSVC)

    set(MSVC_CXX_FLAGS "-std=gnu++11")

    if(ftx_BUILD_DEBUG)
        set(CMAKE_BUILD_TYPE Debug)
    else(ftx_BUILD_DEBUG)
    endif(ftx_BUILD_DEBUG)

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MSVC_CXX_FLAGS}")

  endif(MSVC)

  if(MINGW)

    set(MSVC_CXX_FLAGS "-std=gnu++11")

    if(ftx_BUILD_DEBUG)
        set(CMAKE_BUILD_TYPE Debug)
    else(ftx_BUILD_DEBUG)
    endif(ftx_BUILD_DEBUG)

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${MSVC_CXX_FLAGS}")

  endif(MINGW)

endif(WIN32)

#-------------------------------------------------------------------------------
# Find dependencies
#-------------------------------------------------------------------------------

include_directories(include)

# Required packages
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)

# Use pkg-config for GLEW & GLFW if available
find_package(PkgConfig QUIET)
pkg_search_module(GLFW REQUIRED glfw3)

#-------------------------------------------------------------------------------
# Set include directories
#-------------------------------------------------------------------------------
include_directories(
  ${ftx_INCLUDE_DIRS}
  ${GLEW_INCLUDE_DIRS}
  ${GLFW_INCLUDE_DIRS}
  ${FREETYPE_INCLUDE_DIRS}
)

#-------------------------------------------------------------------------------
# Set link directories
#-------------------------------------------------------------------------------
link_directories(
  ${GLEW_LIBRARY_DIRS}
  ${GLFW_LIBRARY_DIRS}
  ${FREETYPE_LIBRARY_DIRS}
)

#-------------------------------------------------------------------------------
# Add subdirectories
#-------------------------------------------------------------------------------

# ftx library source directory
add_subdirectory(src)
target_include_directories(ftx PUBLIC ${ftx_INCLUDE_DIRS})

#-------------------------------------------------------------------------------
# Packing
#-------------------------------------------------------------------------------

# Install settings
set(CMAKE_INSTALL_PREFIX "${ftx_SOURCE_DIR}")
