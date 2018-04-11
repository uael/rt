cmake_minimum_required(VERSION 2.8)

# ftx library source files
set(ftx_SOURCE
    v3.c
)

#-------------------------------------------------------------------------------
# Building static library (always)
#-------------------------------------------------------------------------------
add_library(ftx STATIC ${ftx_SOURCE})

target_link_libraries(
  ftx
  ${GLEW_LIBRARIES}
  ${GLFW_LIBRARIES}
  ${OPENGL_LIBRARIES}
  ${FREETYPE_LIBRARIES}
)

#-------------------------------------------------------------------------------
# Building shared library
#-------------------------------------------------------------------------------
if(ftx_BUILD_SHARED)
  add_library(ftx_SHARED SHARED ${ftx_SOURCE})
  target_link_libraries(
    ftx_SHARED
    ${GLEW_LIBRARIES}
    ${GLFW_LIBRARIES}
    ${OPENGL_LIBRARIES}
    ${FREETYPE_LIBRARIES}
  )
endif()

#-------------------------------------------------------------------------------
# Platform-specific target configurations
#-------------------------------------------------------------------------------

###################
# Building on OSX #
###################
if (APPLE)

  # Clang options
  target_compile_options(ftx PRIVATE -Wno-constant-conversion)

  # Framework dependencies
  target_link_libraries(ftx
    ${COCOA_LIBRARIES}
    ${IOKIT_LIBRARIES}
    ${COREVIDEO_LIBRARIES})

  # Output name
  if(ftx_BUILD_DEBUG)
    set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx_osx_d)
    if(ftx_BUILD_SHARED)
      set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx_osx_d)
    endif()
  else(ftx_BUILD_DEBUG)
    set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx_osx)
    if(ftx_BUILD_SHARED)
      set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx_osx)
    endif()
  endif(ftx_BUILD_DEBUG)

endif(APPLE)

##################
# Build on Linux #
##################
set(LINUX UNIX AND NOT APPLE)
if(LINUX)
  if(ftx_BUILD_DEBUG)
    set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx_d)
    if(ftx_BUILD_SHARED)
      set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx_d)
    endif()
  else(ftx_BUILD_DEBUG)
    set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx)
    if(ftx_BUILD_SHARED)
      set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx)
    endif()
  endif(ftx_BUILD_DEBUG)
endif(LINUX)

####################
# Build on Windows #
####################
if(WIN32)

  if(MSVC)
    if(ftx_BUILD_DEBUG)
      set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx_d)
      if(ftx_BUILD_SHARED)
        set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx_d)
      endif()
    else(ftx_BUILD_DEBUG)
      set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx)
      if(ftx_BUILD_SHARED)
        set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx)
      endif()
    endif(ftx_BUILD_DEBUG)
  endif(MSVC)

  if(MINGW)
    if(ftx_BUILD_DEBUG)
      set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx_d)
      if(ftx_BUILD_SHARED)
        set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx_d)
      endif()
    else(ftx_BUILD_DEBUG)
      set_target_properties(ftx PROPERTIES OUTPUT_NAME ftx)
      if(ftx_BUILD_SHARED)
        set_target_properties(ftx_SHARED PROPERTIES OUTPUT_NAME ftx)
      endif()
    endif(ftx_BUILD_DEBUG)
  endif(MINGW)

endif(WIN32)

#-------------------------------------------------------------------------------
# Installation configurations
#-------------------------------------------------------------------------------
install(TARGETS ftx DESTINATION lib)
if(ftx_BUILD_SHARED)
  install(TARGETS ftx_SHARED DESTINATION lib)
endif()

# install headers
install(FILES ${ftx_HEADER} DESTINATION include/ftx)
