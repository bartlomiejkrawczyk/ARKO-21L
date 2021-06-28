cmake_minimum_required(VERSION 3.9)
project(x86_64 C)

set(CMAKE_C_STANDARD 99)

enable_language(ASM_NASM)
set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")


add_compile_options(
        "$<$<COMPILE_LANGUAGE:ASM_NASM>:-f $<IF:$<BOOL:$<TARGET_PROPERTY:NASM_OBJ_FORMAT>>, \
    $<TARGET_PROPERTY:NASM_OBJ_FORMAT>, ${CMAKE_ASM_NASM_OBJECT_FORMAT}>>"
)


set(CMAKE_ASM_NASM_FLAGS_DEBUG "-g -Fdwarf")
add_executable(x86_64 main.c scale.asm)
set_target_properties(x86_64 PROPERTIES
        NASM_OBJ_FORMAT elf64
        RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_SOURCE_DIR}
        RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_SOURCE_DIR})
#=============================================================

target_link_libraries(x86_64 PRIVATE allegro
        /usr/lib/x86_64-linux-gnu/liballegro_image.so.5.2.6
        /usr/lib/x86_64-linux-gnu/liballegro_primitives.so.5.2)

#TARGET_LINK_LIBRARIES(x86_64  -lmingw32  -lallegro-5.0.10-monolith-md-debug)
