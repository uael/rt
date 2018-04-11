cmake_minimum_required(VERSION 2.8.7)
project(rt)

cmake_policy(SET CMP0057 OLD)
if(POLICY CMP0059)
  cmake_policy(SET CMP0059 OLD)  # Needed until cmake 2.8.12. #4389
endif()

# Point CMake at any custom modules we may ship
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

# Prefer our bundled versions of dependencies.
if(DEFINED ENV{DEPS_BUILD_DIR})
  set(DEPS_PREFIX "$ENV{DEPS_BUILD_DIR}/usr" CACHE PATH "Path prefix for finding dependencies")
else()
  set(DEPS_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/.deps/usr" CACHE PATH "Path prefix for finding dependencies")
endif()
if(CMAKE_CROSSCOMPILING AND NOT UNIX)
  list(INSERT CMAKE_FIND_ROOT_PATH 0 ${DEPS_PREFIX})
  list(INSERT CMAKE_PREFIX_PATH 0 ${DEPS_PREFIX}/../host/bin)
else()
  list(INSERT CMAKE_PREFIX_PATH 0 ${DEPS_PREFIX})
  set(ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH}:${DEPS_PREFIX}/lib/pkgconfig")
endif()

# used for check_c_compiler_flag
include(CheckCCompilerFlag)

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  # CMake tries to treat /sw and /opt/local as extension of the system path, but
  # that doesn't really work out very well.  Once you have a dependency that
  # resides there and have to add it as an include directory, then any other
  # dependency that could be satisfied from there must be--otherwise you can end
  # up with conflicting versions.  So, let's make them more of a priority having
  # them be included as one of the first places to look for dependencies.
  list(APPEND CMAKE_PREFIX_PATH /sw /opt/local)

  # Work around some old, broken detection by CMake for knowing when to use the
  # isystem flag.  Apple's compilers have supported this for quite some time
  # now.
  if(CMAKE_COMPILER_IS_GNUCC)
    set(CMAKE_INCLUDE_SYSTEM_FLAG_C "-isystem ")
  endif()
  if(CMAKE_COMPILER_IS_GNUCXX)
    set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")
  endif()

  include_directories($ENV{HOME}/.brew)
endif()

if(WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  # Enable fixing case-insensitive filenames for Windows and Mac.
  set(USE_FNAME_CASE TRUE)
endif()

# Set default build type.
if(NOT CMAKE_BUILD_TYPE)
  message(STATUS "CMAKE_BUILD_TYPE not given, defaulting to 'Debug'.")
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build." FORCE)
endif()

# Set available build types for CMake GUIs.
# A different build type can still be set by -DCMAKE_BUILD_TYPE=...
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY
  STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")

# If not in a git repo (e.g., a tarball) these tokens define the complete
# version string, else they are combined with the result of `git describe`.
set(RT_VERSION_MAJOR 0)
set(RT_VERSION_MINOR 0)
set(RT_VERSION_PATCH 1)
set(RT_VERSION_PRERELEASE "-dev") # for package maintainers

# API level
set(RT_API_LEVEL 0)         # Bump this after any API change.
set(RT_API_LEVEL_COMPAT 0)  # Adjust this after a _breaking_ API change.
set(RT_API_PRERELEASE true)

set(RT_VERSION_BUILD_TYPE "${CMAKE_BUILD_TYPE}")
# RT_VERSION_CFLAGS set further below.

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Default to -O2 on release builds.
if(CMAKE_C_FLAGS_RELEASE MATCHES "-O3")
  message(STATUS "Replacing -O3 in CMAKE_C_FLAGS_RELEASE with -O2.")
  string(REPLACE "-O3" "-O2" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
endif()

# Minimize logging for release-type builds.
if(NOT CMAKE_C_FLAGS_RELEASE MATCHES DMIN_LOG_LEVEL)
  set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -DMIN_LOG_LEVEL=3")
endif()
if(NOT CMAKE_C_FLAGS_MINSIZEREL MATCHES DMIN_LOG_LEVEL)
  set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} -DMIN_LOG_LEVEL=3")
endif()
if(NOT CMAKE_C_FLAGS_RELWITHDEBINFO MATCHES DMIN_LOG_LEVEL)
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -DMIN_LOG_LEVEL=3")
endif()

if(CMAKE_COMPILER_IS_GNUCC)
  check_c_compiler_flag(-Og HAS_OG_FLAG)
else()
  set(HAS_OG_FLAG 0)
endif()

#
# Build-type: RelWithDebInfo
#
if(HAS_OG_FLAG)
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -Og -g")
endif()
# We _want_ assertions in RelWithDebInfo build-type.
if(CMAKE_C_FLAGS_RELWITHDEBINFO MATCHES DNDEBUG)
  string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
endif()

# Enable -Wconversion.
if(NOT MSVC)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wconversion")
endif()

# gcc 4.0+ sets _FORTIFY_SOURCE=2 automatically.  This currently
# does not work with Neovim due to some uses of dynamically-sized structures.
# https://github.com/neovim/neovim/issues/223
include(CheckCSourceCompiles)

# Include the build type's default flags in the check for _FORTIFY_SOURCE,
# otherwise we may incorrectly identify the level as acceptable and find out
# later that it was not when optimizations were enabled.  CFLAGS is applied
# even though you don't see it in CMAKE_REQUIRED_FLAGS.
set(INIT_FLAGS_NAME CMAKE_C_FLAGS_${CMAKE_BUILD_TYPE})
string(TOUPPER ${INIT_FLAGS_NAME} INIT_FLAGS_NAME)
if(${INIT_FLAGS_NAME})
  set(CMAKE_REQUIRED_FLAGS "${${INIT_FLAGS_NAME}}")
endif()

# Remove --sort-common from linker flags, as this seems to cause bugs (see #2641, #3374).
# TODO: Figure out the root cause.
if(CMAKE_EXE_LINKER_FLAGS MATCHES "--sort-common" OR
  CMAKE_SHARED_LINKER_FLAGS MATCHES "--sort-common" OR
  CMAKE_MODULE_LINKER_FLAGS MATCHES "--sort-common")
  message(STATUS "Removing --sort-common from linker flags.")
  string(REGEX REPLACE ",--sort-common(=[^,]+)?" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
  string(REGEX REPLACE ",--sort-common(=[^,]+)?" "" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
  string(REGEX REPLACE ",--sort-common(=[^,]+)?" "" CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}")

  # If no linker flags remain for a -Wl argument, remove it.
  # '-Wl$' will match LDFLAGS="-Wl,--sort-common",
  # '-Wl ' will match LDFLAGS="-Wl,--sort-common -Wl,..."
  string(REGEX REPLACE "-Wl($| )" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
  string(REGEX REPLACE "-Wl($| )" "" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
  string(REGEX REPLACE "-Wl($| )" "" CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}")
endif()

if(MSVC)
  # XXX: /W4 gives too many warnings. #3241
  add_definitions(/W3 -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_DEPRECATE)
  add_definitions(-DWIN32)
else()
  add_definitions(-Wall -Wextra -Wno-unused-parameter)

  check_c_compiler_flag(-Wimplicit-fallthrough HAS_WIMPLICIT_FALLTHROUGH_FLAG)
  if(HAS_WIMPLICIT_FALLTHROUGH_FLAG)
    add_definitions(-Wimplicit-fallthrough)
  endif()

  # On FreeBSD 64 math.h uses unguarded C11 extension, which taints clang
  # 3.4.1 used there.
  if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" AND CMAKE_C_COMPILER_ID MATCHES "Clang")
    add_definitions(-Wno-c11-extensions)
  endif()
endif()

if(MINGW)
  # Use POSIX compatible stdio in Mingw
  add_definitions(-D__USE_MINGW_ANSI_STDIO)
endif()
if(WIN32)
  # Windows Vista is the minimum supported version
  add_definitions(-D_WIN32_WINNT=0x0600)
endif()

if(UNIX)
  # -fstack-protector breaks non Unix builds even in Mingw-w64
  check_c_compiler_flag(-fstack-protector-strong HAS_FSTACK_PROTECTOR_STRONG_FLAG)
  check_c_compiler_flag(-fstack-protector HAS_FSTACK_PROTECTOR_FLAG)

  if(HAS_FSTACK_PROTECTOR_STRONG_FLAG)
    add_definitions(-fstack-protector-strong)
  elseif(HAS_FSTACK_PROTECTOR_FLAG)
    add_definitions(-fstack-protector --param ssp-buffer-size=4)
  endif()
endif()

check_c_compiler_flag(-fdiagnostics-color=auto HAS_DIAG_COLOR_FLAG)
if(HAS_DIAG_COLOR_FLAG)
  add_definitions(-fdiagnostics-color=auto)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  # 1. Array-bounds testing is broken in some GCC versions before 4.8.5.
  #    https://gcc.gnu.org/bugzilla/show_bug.cgi?id=56273
  # 2. But _Pragma("...ignored") is broken (unresolved) in GCC 5+:
  #    https://gcc.gnu.org/bugzilla/show_bug.cgi?id=66099
  # So we must disable -Warray-bounds globally for GCC (for kbtree.h, #7083).
  check_c_compiler_flag(-Wno-array-bounds HAS_NO_ARRAY_BOUNDS_FLAG)
  if(HAS_NO_ARRAY_BOUNDS_FLAG)
    add_definitions(-Wno-array-bounds)
  endif()
endif()

if(CMAKE_BUILD_TYPE MATCHES Debug)
  set(DEBUG 1)
else()
  set(DEBUG 0)
endif()

option(LOG_LIST_ACTIONS "Add list actions logging" OFF)

add_definitions(-DINCLUDE_GENERATED_DECLARATIONS)

if(CMAKE_COMPILER_IS_GNUCXX AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--no-undefined")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--no-undefined")

  # For O_CLOEXEC, O_DIRECTORY, and O_NOFOLLOW flags on older systems
  # (pre POSIX.1-2008: glibc 2.11 and earlier). #4042
  add_definitions(-D_GNU_SOURCE)
endif()

if(CMAKE_COMPILER_IS_GNUCXX AND CMAKE_SYSTEM_NAME STREQUAL "SunOS")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--no-undefined -lsocket")
endif()

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})

# Required packages
find_package(OpenGL REQUIRED)
find_package(Threads REQUIRED)
find_package(CUDA REQUIRED)

add_subdirectory(ext)

set(rt_HDRS ${CMAKE_SOURCE_DIR}/include/rt.h)
file(GLOB_RECURSE rt_SRCS ${rt_SRCS} ${CMAKE_CURRENT_LIST_DIR}/src/*.c)
file(GLOB_RECURSE rt_HDRS ${rt_HDRS} ${CMAKE_CURRENT_LIST_DIR}/src/*.h)
file(GLOB_RECURSE rt_HDRS ${rt_HDRS} ${CMAKE_CURRENT_LIST_DIR}/include/*.h)
add_executable(rt ${rt_SRCS} ${rt_HDRS})
target_include_directories(rt PUBLIC ${CMAKE_CURRENT_LIST_DIR}/include)
target_link_libraries(rt ft ftx)
