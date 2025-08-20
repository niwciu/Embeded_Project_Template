#############################################################################################################################
# file:  CMakeLists.txt
# brief: Template "CMakeLists.txt" for building of executables and static libraries.
#
# usage: Edit MCPU-Variable to suit STM32 project requirements.
#        For debug build using Unix Makefiles:
#          cmake -S ./ -B Debug -G"Unix Makefiles" -DBUILD_TYPE=Debug
#          make -C Debug all (optional with VERBOSE=1  and -jxx ->xx numnber of cores)
#        For debug build using Ninja:
#          cmake -S ./ -B Debug -G"Ninja" -DBUILD_TYPE=Debug
#          ninja -C Debug (optional with -V)
# 
#        For release build Unix Makefiles:
#          cmake -S ./ -B Release -G"Unix Makefiles" -DBUILD_TYPE=Release
#          make all -C Release VERBOSE=1 -j12 (optional with VERBOSE=1  and -jxx ->xx numnber of cores)
#        For Release build using Ninja:
#          cmake -S ./ -B Release -G"Ninja" -DBUILD_TYPE=Release
#          ninja -C Release (optional -V)
#############################################################################################################################
cmake_minimum_required(VERSION 3.10)

set(CMAKE_TOOLCHAIN_FILE ../config/STM32/Toolchain-arm-gcc.cmake)
project(STM32G070RB_TEMPLATE)

# Allow assembler
enable_language(ASM)

set(CMAKE_COLOR_DIAGNOSTIC ON)
# json file compilation base generation -> usefull for cppcheck
set(CMAKE_EXPORT_COMPILE_COMMANDS OFF)

# project specific define 
if(NOT DEFINED BUILD_TYPE)
    set(BUILD_TYPE Debug)
endif()


# Informational messages for the user
message(STATUS "")
message(STATUS "================================================================")
message(STATUS " STM32G070RB_TEMPLATE project configuration")
message(STATUS "----------------------------------------------------------------")
message(STATUS " Available options:")
message(STATUS "   BUILD_TYPE              : <Debug, Release> (default: Debug)")
message(STATUS "")
message(STATUS " Current configuration:")
message(STATUS "   BUILD_TYPE              = ${BUILD_TYPE}")
message(STATUS "===============================================================")
set(INCLUDE_DIRS
Core
Core/Inc
Core/Startup

Drivers
Drivers/CMSIS
Drivers/CMSIS/Device
Drivers/CMSIS/Include
Drivers/CMSIS/STM32G0_Drivers


../src

../lib

.
)

set(C_SRCS
    Core/Src/main.c
    Core/Src/syscalls.c
    Core/Src/sysmem.c
    Core/Src/core_init.c

	
)

set(ASM_SRCS
    Core/Startup/startup_stm32g070rbtx.s
)

set(GLOBAL_DEFINES
    -DSTM32G070xx
    -DBUILD_TYPE=${BUILD_TYPE}
)

set(LINKED_LIBS
    # xxx_lib  
)

# link lib directory - complied library *.a files dir 
link_directories(

)

include_directories(${INCLUDE_DIRS})
add_definitions(${GLOBAL_DEFINES})

set(MCPU "-mcpu=cortex-m0plus")
set(LD_FILE "linker.ld")
include(    ../config/STM32/compiler_flags.cmake)

message(STATUS "C flags: ${CMAKE_C_FLAGS}")
message(STATUS "C++ flags: ${CMAKE_CXX_FLAGS}")

# add lib directory - lib to compile
# add_subdirectory(../../lib/XXX xxx_lib)

# generate elf file
add_arm_executable(${CMAKE_PROJECT_NAME} ${C_SRCS} ${ASM_SRCS})

arm_link_libraries(${CMAKE_PROJECT_NAME} ${LINKED_LIBS})
