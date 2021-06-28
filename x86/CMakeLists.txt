cmake_minimum_required(VERSION 3.15)
project(x86 C)

set(CMAKE_C_STANDARD 99)

enable_language(ASM_NASM)
set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")


add_compile_options(
        "$<$<COMPILE_LANGUAGE:ASM_NASM>:-f $<IF:$<BOOL:$<TARGET_PROPERTY:NASM_OBJ_FORMAT>>, \
    $<TARGET_PROPERTY:NASM_OBJ_FORMAT>, ${CMAKE_ASM_NASM_OBJECT_FORMAT}>>"
)


set(CMAKE_ASM_NASM_FLAGS_DEBUG "-g -Fdwarf")
add_executable(x86 main.c scale.asm)
set_target_properties(x86 PROPERTIES
        NASM_OBJ_FORMAT elf32
        RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_SOURCE_DIR}
        RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_SOURCE_DIR})
#=============================================================
TARGET_LINK_LIBRARIES(x86  -lmingw32  -lallegro-5.0.10-monolith-md-debug)