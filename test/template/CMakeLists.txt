#############################################################################################################################
# file:  CMakeLists.txt
# brief: Template "CMakeLists.txt" for building Unit test modules.
#
# usage:
#        For build using Unix Makefiles:
#          	1. cmake -S./ -B out -G"Unix Makefiles"
#			2. enter the "out" folder
#          	3. make all -o template_test.o (-jXX additionaly to speed up)
#        For build using Ninja:
#          	1. cmake -S./ -B out -G"Ninja"
# 			2. enter the "out" folder
#         	3. ninja -C out -o template_test.o (optional with -V )
# additional custom targets for this project:
# 		If lizard is installed and you are in the out folder:
# 			1. make ccm -> code complexity metrix print in console
# 			2. make ccmr -> code complexity metrics report generation
# 		If cppcheck is installed and you are in the out folder
# 			1. make cppcheck -> static analize  for src and test folders printed in console
# 		If gcovr is installed and you are in the out folder
#			1. make ccC -> code coverage check - print resoults in console
# 			2. make ccr -> code coverage report generation 
# 
#############################################################################################################################
cmake_minimum_required(VERSION 3.10)

project(template_test C)

# --- UNITY FRAMEWORK ---
add_subdirectory(../unity unity)
# --- CMOCK FRAMEWORK ---
add_subdirectory(../CMock/src cmock)

# --- CUSTOM TARGETS FILE ---
set(CUSTOM_TARGETS_FILE_DIR ./custom_targets.cmake)
include(${CUSTOM_TARGETS_FILE_DIR})

# --- MOCK FUNCTION GENERATOR INCLUDE ---
include(generate_mock.cmake)

# --- COMPILER FLAGS ---
set(CMAKE_C_FLAGS  "${CMAKE_CXX_FLAGS} -Wall -Wextra")
if ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fdiagnostics-color=always")
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcolor-diagnostics")
endif()

#  --- CHECK AND DEFINE libm IF REQUIRED ---
include(CheckLibraryExists)
CHECK_LIBRARY_EXISTS(m sin "" HAVE_LIB_M)  

# --- SET -g3 FLAG FOR DEBUG ON DEVELOPING MACHINE ---
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g3")

# --- INCLUDE SRC DIRECTORIES ---
set(INCLUDE_DIRS
	../../src
)

# --- INCLUDE TEST DIRECTORIES ---
set(TEST_INCLUDE_DIRS
	..
	.
)

# --- MOCK GENERATION SETTINGS---
set(MOCK_HEADERS 
	# here add paths to header files that you want to generate the mocks
	# ../../../src/MODULE/module.h 
)
set(MOCK_TARGET_NAME generate_mocks)
set(MOCK_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/../cmocks)

# --- MOCK GENERATION ---
generate_mock(${MOCK_HEADERS} ${MOCK_TARGET_NAME} ${MOCK_OUTPUT_DIR} MOCK_C_FILES)

# --- SOURCES ---
set(SRCS
	#../../src/tested_module_folder/tested_module.c
)

# --- TEST SOURCES ---
set(TEST_SRCS
    template_test_main.c
    template_test_runner.c
    template_test.c
	#mock_module.c
)

# --- DEFINES ---
set(GLOBAL_DEFINES
	-DUNIT_TESTS
)
add_definitions(${GLOBAL_DEFINES})

# --- LIST OF LINKED LIBS ---
set(LINKED_LIBS
	unity
	cmock
)

if(HAVE_LIB_M)
    list(APPEND LINKED_LIBS m)
endif()

# --- EXECUTABLE ---
add_executable(${PROJECT_NAME} ${SRCS} ${TEST_SRCS})

# --- LIBRARY LINKING ---
target_link_libraries(${PROJECT_NAME} PRIVATE ${LINKED_LIBS})

# --- INCLUDE TARGET DIR ---
target_include_directories(${PROJECT_NAME} PRIVATE
    ${INCLUDE_DIRS}
    ${TEST_INCLUDE_DIRS}
    ${MOCK_OUTPUT_DIR}  
)

# --- CODE COVERAGE OPTIONS ---
target_compile_options(${PROJECT_NAME} PRIVATE -fprofile-arcs -ftest-coverage -O0)
target_link_options(${PROJECT_NAME} PRIVATE -fprofile-arcs -O0)