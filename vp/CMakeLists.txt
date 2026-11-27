if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()
if(EXISTS "$ENV{VERILATOR_ROOT}/share/verilator/verilator-config.cmake")
  set(ENV{VERILATOR_ROOT} "$ENV{VERILATOR_ROOT}/share/verilator")
endif()
find_package(verilator CONFIG REQUIRED HINTS ENV VERILATOR_ROOT)

foreach(name IN ITEMS ROM_BASE ROM_SIZE SRAM_BASE SRAM_SIZE UART0_BASE UART0_SIZE AES_BASE AES_SIZE)
  math(EXPR HONHON_${name}_DEC "${HONHON_${name}}")
endforeach()
configure_file(../hw/rtl/honhon_soc_pkg.sv.in honhon_soc_pkg.sv @ONLY)

add_executable(honhon-vp src/main.cpp src/uart_pty.cpp)
target_compile_features(honhon-vp PRIVATE cxx_std_17)
target_link_libraries(honhon-vp PRIVATE util)
target_compile_definitions(honhon-vp PRIVATE
  "HONHON_DEFAULT_ROM=\"${HONHON_ROM}\""
  "HONHON_DEFAULT_LOG=\"${CMAKE_BINARY_DIR}/uart0.log\"")
add_dependencies(honhon-vp honhon_firmware)

verilate(honhon-vp
  PREFIX Vvp_top
  TOP_MODULE vp_top
  SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/rtl/opentitan.vlt"
    "${HONHON_OPENTITAN_DIR}/hw/ip/aes/lint/aes.vlt"
    ${OPENTITAN_RTL_PACKAGES}
    "${CMAKE_CURRENT_BINARY_DIR}/honhon_soc_pkg.sv"
    "${CMAKE_CURRENT_SOURCE_DIR}/../hw/rtl/honhon_bus.sv"
    "${CMAKE_CURRENT_SOURCE_DIR}/../hw/rtl/honhon_top.sv"
    "${HONHON_OPENTITAN_DIR}/hw/dv/dpi/uartdpi/uartdpi.sv"
    "${CMAKE_CURRENT_SOURCE_DIR}/rtl/vp_top.sv"
  VERILATOR_ARGS
    ${OPENTITAN_RTL_ARGS}
)

add_custom_target(run_vp
  COMMAND "$<TARGET_FILE:honhon-vp>"
  DEPENDS honhon-vp
  USES_TERMINAL
  VERBATIM
)

if(BUILD_TESTING AND HONHON_FIRMWARE_NAME STREQUAL "uart_echo")
  add_test(NAME honhon.uart_echo
    COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/uart_echo.py"
      "$<TARGET_FILE:honhon-vp>")
  set_tests_properties(honhon.uart_echo PROPERTIES TIMEOUT 20)
endif()
