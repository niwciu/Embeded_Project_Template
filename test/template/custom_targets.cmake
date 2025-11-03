#############################################################################################################################
# FILE:    custom_targets.cmake
# BRIEF:   Defines project-specific custom build targets (unit tests, static analysis, complexity, coverage, formatting)
#
# USAGE:
#   List available targets:
#       cmake --build out --target help
#
#   Run a specific target (works with any generator):
#       cmake --build out --target run         # run unit tests
#       cmake --build out --target cppcheck    # static analysis
#       cmake --build out --target ccmr        # code complexity HTML report
#       cmake --build out --target ccr         # code coverage report
#       cmake --build out --target format      # format code
#
#   or directly (if using Ninja or Make):
#       ninja -C out run
#       make  -C out ccr
#
# NOTE:
#   Relative paths below are intentional for cleaner console output.
#   WORKING_DIRECTORY guarantees they resolve correctly at runtime.
#############################################################################################################################

#############################################################################################################################
# 1) RUN UNIT TESTS
#############################################################################################################################
add_custom_target(run
    COMMAND ${CMAKE_COMMAND} -E echo "Running unit tests..."
    COMMAND ctest --output-on-failure --verbose
    COMMENT "Executing all unit tests via CTest"
)
message(STATUS "To run unit tests, use predefined target: run")

#############################################################################################################################
# 2) CODE COMPLEXITY (LIZARD)
#############################################################################################################################
find_program(LIZARD_EXECUTABLE lizard)
if(LIZARD_EXECUTABLE)
    message(STATUS "Lizard found — predefined targets available: ccm, ccmr")

    add_custom_target(ccm
        COMMAND ${LIZARD_EXECUTABLE}
            ../../src/
            --CCN 12 
			-Tnloc=30 
			-a 4
            --languages cpp
            -V 
			-i 1
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running Lizard complexity metrics (console output)"
        VERBATIM
    )

    add_custom_target(ccmr
        COMMAND ${CMAKE_COMMAND} -E make_directory ../../reports/CCM/
        COMMAND ${LIZARD_EXECUTABLE}
            ../../src/
            --CCN 12 
			-Tnloc=30 
			-a 4
            --languages cpp
            -V 
			-o ../../reports/CCM/template.html
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating Lizard HTML complexity report"
        VERBATIM
    )
else()
    message(STATUS "Lizard not found — install it to enable ccm / ccmr targets.")
endif()

#############################################################################################################################
# 3) STATIC ANALYSIS (CPPCHECK)
#############################################################################################################################
find_program(CPPCHECK_EXECUTABLE cppcheck)
if(CPPCHECK_EXECUTABLE)
    message(STATUS "CppCheck found — predefined target available: cppcheck")

    add_custom_target(cppcheck
        COMMAND ${CPPCHECK_EXECUTABLE}
            ../../../src/template
            ../../../test/template
            -i../../test/template/out
            --enable=all
            --force
            --std=c99
            --suppress=missingIncludeSystem
            --suppress=missingInclude
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Running CppCheck static analysis for src & test directories"
        VERBATIM
    )
else()
    message(STATUS "CppCheck was not found — install it to enable cppcheck target.")
endif()

#############################################################################################################################
# 4) CODE COVERAGE (GCOVR)
#############################################################################################################################
find_program(GCOVR_EXECUTABLE gcovr)
if(GCOVR_EXECUTABLE)
    message(STATUS "Gcovr found — predefined targets available: ccc, ccr, ccca, ccra")

    set(REPORT_DIR ../../reports/CCR)
    set(REPORT_JSON_DIR ${REPORT_DIR}/JSON_ALL)
    set(REPORT_COMMON_HTML_DIR ${REPORT_JSON_DIR}/HTML_OUT)
    set(REPORT_MODULE_DIR ${REPORT_DIR}/template)

    add_custom_target(ccr
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORT_DIR}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORT_JSON_DIR}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORT_MODULE_DIR}
        COMMAND ${GCOVR_EXECUTABLE}
            -r ../../src/template
            --json ${REPORT_JSON_DIR}/coverage_template.json
            --json-base src/template
            --html-details ${REPORT_DIR}/template/template_report.html
            --html-theme github.dark-green
            .
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating Code Coverage report for module"
        VERBATIM
    )

    add_custom_target(ccc
        COMMAND ${GCOVR_EXECUTABLE}
            -r ../../src/template
            --fail-under-line 90
            .
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Performing Code Coverage check (min 90%)"
        VERBATIM
    )

    add_custom_target(ccca
        COMMAND ${GCOVR_EXECUTABLE}
            -r ../../
            --json-add-tracefile "${REPORT_JSON_DIR}/coverage_*.json"
            .
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Aggregating Code Coverage data from all modules"
        VERBATIM
    )

    add_custom_target(ccra
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORT_DIR}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORT_JSON_DIR}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${REPORT_COMMON_HTML_DIR}
        COMMAND ${GCOVR_EXECUTABLE}
            -r ../../
            --json-add-tracefile "${REPORT_JSON_DIR}/coverage_*.json"
            --html-details -o ${REPORT_COMMON_HTML_DIR}/project_coverage.html
            --html-theme github.dark-green
            .
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Generating aggregated Code Coverage HTML report"
        VERBATIM
    )

    add_dependencies(ccra ccr)
    add_dependencies(ccca ccr)
else()
    message(STATUS "Gcovr not found — install it to enable code coverage targets.")
endif()

#############################################################################################################################
# 5) CODE FORMATTING (CLANG-FORMAT) — GLOB zamiast '*'
#############################################################################################################################
# CMake nie rozwija gwiazdek. Używamy file(GLOB ...) by zbudować listę plików,
# a potem wstrzykujemy ją do polecenia z COMMAND_EXPAND_LISTS (modern CMake).
find_program(CLANG_FORMAT_EXECUTABLE clang-format)
if(CLANG_FORMAT_EXECUTABLE)
    message(STATUS "clang-format found — predefined targets: format, format_test")

    # Zbierz pliki źródłowe do formatowania (ścieżki RELATIVE dla krótszego outputu)
    file(GLOB FORMAT_SOURCES
        RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
        ../../src/template/*.c
        ../../src/template/*.h
    )

    file(GLOB FORMAT_TEST_SOURCES
        RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
        ./*.c
        ./*.h
    )

    add_custom_target(format
        COMMAND ${CLANG_FORMAT_EXECUTABLE} -i -style=file ${FORMAT_SOURCES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Formatting source files using clang-format"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    add_custom_target(format_test
        COMMAND ${CLANG_FORMAT_EXECUTABLE} -i -style=file ${FORMAT_TEST_SOURCES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Formatting test files using clang-format"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )
else()
    message(STATUS "clang-format was not found — install it to enable code formatting targets.")
endif()

#############################################################################################################################
# END OF FILE
#############################################################################################################################
