# --- GENERATE_MOCK FUNCTION (MODERN CMAKE STYLE) ---
function(generate_mock HEADERS TARGET_NAME OUTPUT_DIR OUT_VAR)
    # --- ENSURE OUTPUT DIRECTORY EXISTS ---
    file(MAKE_DIRECTORY ${OUTPUT_DIR})

    set(GENERATED_MOCKS)

    foreach(HEADER ${HEADERS})
        get_filename_component(HEADER_ABS "${HEADER}" ABSOLUTE)
        get_filename_component(HEADER_NAME "${HEADER_ABS}" NAME_WE)
        set(MOCK_FILE "${OUTPUT_DIR}/mock_${HEADER_NAME}.c")
        set(YAML_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmock_config/${HEADER_NAME}.yml")

        if(NOT EXISTS ${YAML_FILE})
            file(WRITE ${YAML_FILE}
                ":cmock:
                :mock_prefix: \"mock_\"
                :callback: true
                :plugins:
                    - expect
                    - ignore
                    - return_thru_ptr
                    - callback
                "
            )
        endif()

        add_custom_command(
            OUTPUT ${MOCK_FILE}
            COMMAND ${RUBY_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/../CMock/lib/cmock.rb
                    ${HEADER_ABS} --mock_path=${OUTPUT_DIR} -o${YAML_FILE}
            DEPENDS ${HEADER_ABS} ${CMAKE_CURRENT_SOURCE_DIR}/../CMock/lib/cmock.rb ${YAML_FILE}
            BYPRODUCTS ${MOCK_FILE}
            COMMENT "Generating mock for ${HEADER_NAME}.h"
            VERBATIM
        )

        list(APPEND GENERATED_MOCKS ${MOCK_FILE})
    endforeach()


    # --- DEFINE A TARGET THAT AGGREGATES ALL GENERATED MOCKS ---
    add_custom_target(${TARGET_NAME}
        DEPENDS ${GENERATED_MOCKS}
        COMMENT "Ensuring all mock files are up to date"
    )

    # --- CLEAN GENERATED MOCKS ON 'MAKE CLEAN' ---
    set_directory_properties(PROPERTIES
        ADDITIONAL_MAKE_CLEAN_FILES "${OUTPUT_DIR}"
    )

    # --- RETURN GENERATED FILE LIST TO CALLER ---
    set(${OUT_VAR} ${GENERATED_MOCKS} PARENT_SCOPE)
endfunction()
