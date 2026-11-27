cmake_minimum_required(VERSION 3.24)
project(honhon_firmware LANGUAGES C ASM)

include(../hw/memory_map.cmake)

set(HONHON_FIRMWARE_NAME uart_echo CACHE STRING "Firmware target name")
set(HONHON_FIRMWARE_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/example/uart_echo/main.c"
  CACHE FILEPATH "Firmware application source")
set(firmware_target "${HONHON_FIRMWARE_NAME}")

set(generated "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(uart_hjson "${OPENTITAN_ROOT}/hw/ip/uart/data/uart.hjson")
set(uart_regs "${generated}/hw/top/uart_regs.h")
set(dif_dir "${generated}/sw/device/lib/dif/autogen")
set(uart_autogen "${dif_dir}/dif_uart_autogen.c")

configure_file(device/honhon.h.in "${generated}/honhon.h" @ONLY)
configure_file(device/honhon.ld.in "${generated}/honhon.ld" @ONLY)
configure_file(device/dt_uart.h "${generated}/hw/top/dt/uart.h" COPYONLY)

# Reuse the Python dependencies already fetched for OpenTitan if available.
file(GLOB cached_python_deps LIST_DIRECTORIES true
  "${OPENTITAN_ROOT}/bazel-opentitan/external/*ot_python_deps_*/site-packages")
if(NOT "$ENV{PYTHONPATH}" STREQUAL "")
  list(APPEND cached_python_deps "$ENV{PYTHONPATH}")
endif()
list(JOIN cached_python_deps ":" python_path)

set(regtool "${OPENTITAN_ROOT}/util/regtool.py")
set(autogen_dif "${OPENTITAN_ROOT}/util/autogen_dif.py")
file(GLOB reggen_sources "${OPENTITAN_ROOT}/util/reggen/*.py")
file(GLOB dif_templates "${OPENTITAN_ROOT}/util/make_new_dif/templates/dif_autogen*")
add_custom_command(
  OUTPUT "${uart_regs}" "${uart_autogen}" "${dif_dir}/dif_uart_autogen.h"
  BYPRODUCTS "${dif_dir}/dif_uart_autogen_unittest.cc"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${dif_dir}"
  COMMAND ${CMAKE_COMMAND} -E env "PYTHONPATH=${python_path}"
    "${HONHON_PYTHON}" -B "${regtool}" -D "${uart_hjson}" -o "${uart_regs}"
  COMMAND ${CMAKE_COMMAND} -E env "PYTHONPATH=${python_path}"
    "${HONHON_PYTHON}" -B "${autogen_dif}" -i "${uart_hjson}" -o "${dif_dir}"
  DEPENDS "${uart_hjson}" "${regtool}" "${autogen_dif}" ${reggen_sources} ${dif_templates}
  COMMENT "Generating OpenTitan UART register and DIF definitions"
  VERBATIM
)

add_executable(${firmware_target}
  device/startup_honhon.S
  device/system_honhon.c
  drivers/hal/src/honhon_hal_uart.c
  "${HONHON_FIRMWARE_SOURCE}"
  "${uart_regs}"
  "${uart_autogen}"
  "${OPENTITAN_ROOT}/sw/device/lib/base/math.c"
  "${OPENTITAN_ROOT}/sw/device/lib/dif/dif_uart.c"
)
set_target_properties(${firmware_target} PROPERTIES SUFFIX ".elf")
target_include_directories(${firmware_target} PRIVATE
  "${generated}"
  drivers/hal/include
  "${OPENTITAN_ROOT}"
  "${OPENTITAN_ROOT}/sw/device/lib/base/freestanding"
  "${OPENTITAN_ROOT}/sw/device/lib/dif"
)
set(riscv_flags -march=rv32imc_zicsr -mabi=ilp32)
target_compile_options(${firmware_target} PRIVATE
  ${riscv_flags} -Os -ffreestanding -ffunction-sections -fdata-sections)
target_link_options(${firmware_target} PRIVATE
  ${riscv_flags} -fuse-ld=lld -nostdlib -Wl,--gc-sections "-T${generated}/honhon.ld")
set_property(TARGET ${firmware_target} APPEND PROPERTY LINK_DEPENDS "${generated}/honhon.ld")

set(srec_cat "${SRECORD_ROOT}/bin/srec_cat")
if(NOT EXISTS "${srec_cat}")
  message(FATAL_ERROR "Set SRECORD_ROOT to the SRecord installation containing srec_cat")
endif()

set(rom "${CMAKE_CURRENT_BINARY_DIR}/${firmware_target}.vmem")
set(binary "${CMAKE_CURRENT_BINARY_DIR}/${firmware_target}.bin")
add_custom_command(
  OUTPUT "${rom}"
  BYPRODUCTS "${binary}"
  COMMAND "${CMAKE_OBJCOPY}" -O binary "$<TARGET_FILE:${firmware_target}>" "${binary}"
  COMMAND ${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=${SRECORD_ROOT}/lib:${SRECORD_ROOT}/lib64"
    "${srec_cat}" "${binary}" -Binary
    -fill 0x00 -within "${binary}" -Binary -range-pad 4
    -byte-swap 4 -o "${rom}" -VMem 32
  DEPENDS ${firmware_target}
  COMMENT "Creating the honhon UART example ROM image"
  VERBATIM
)
add_custom_target(${firmware_target}_rom ALL DEPENDS "${rom}")
