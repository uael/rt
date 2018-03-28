cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
cmake_policy(SET CMP0054 OLD)
cmake_policy(SET CMP0045 OLD)

project(rt C)
add_subdirectory(libft)

include_directories(~/.brew/include)
link_directories(~/.brew/lib)

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}
  -fno-omit-frame-pointer -fsanitize=address")
set(CMAKE_LINKER_FLAGS_DEBUG "${CMAKE_STATIC_LINKER_FLAGS_DEBUG}
  -fno-omit-frame-pointer -fsanitize=address")

file(GLOB_RECURSE rt_HDRS include/rt.h include/rt/*.h)
file(GLOB_RECURSE rt_SRCS ${rt_SRCS} src/*.c)

add_executable(rt ${rt_HDRS} ${rt_SRCS})
set_property(TARGET rt PROPERTY C_STANDARD 90)
target_include_directories(rt PUBLIC include)
target_link_libraries(rt PUBLIC debug ft glfw "-framework OpenGL")

target_compile_definitions(rt
  PRIVATE $<$<CONFIG:Debug>:DEBUG>$<$<CONFIG:Release>:NDEBUG>)
target_compile_options(rt
  PRIVATE -Wall -Werror -Wextra
  PRIVATE -O$<$<CONFIG:Debug>:0 -g3>$<$<CONFIG:Release>:2>)
