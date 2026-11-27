cmake_minimum_required(VERSION 3.24)
project(honhon_firmware LANGUAGES C ASM)

include(../hw/memory_map.cmake)

set(HONHON_FIRMWARE_NAME uart_echo CACHE STRING "Firmware target name")
set(HONHON_FIRMWARE_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/example/uart_echo/main.c"
  CACHE FILEPATH "Firmware application source")
set(firmware_target "${HONHON_FIRMWARE_NAME}")

set(generated "${CMAKE_CURRENT_BINARY_DIR}/generated")
get_filename_component(opentitan_dir "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/opentitan" ABSOLUTE)

configure_file(device/honhon.h.in "${generated}/honhon.h" @ONLY)
configure_file(device/honhon.ld.in "${generated}/honhon.ld" @ONLY)
configure_file(device/dt_uart.h "${generated}/hw/top/dt/uart.h" COPYONLY)

add_executable(${firmware_target}
  device/startup_honhon.S
  device/system_honhon.c
  drivers/hal/src/honhon_hal_uart.c
  "${HONHON_FIRMWARE_SOURCE}"
  "${opentitan_dir}/sw/device/lib/dif/autogen/dif_uart_autogen.c"
  "${opentitan_dir}/sw/device/lib/base/math.c"
  "${opentitan_dir}/sw/device/lib/dif/dif_uart.c"
)
set_target_properties(${firmware_target} PROPERTIES SUFFIX ".elf")
target_include_directories(${firmware_target} PRIVATE
  "${opentitan_dir}"
  "${generated}"
  drivers/hal/include
  "${opentitan_dir}/sw/device/lib/base/freestanding"
  "${opentitan_dir}/sw/device/lib/dif"
)
set(riscv_flags -march=rv32imc_zicsr -mabi=ilp32)
target_compile_options(${firmware_target} PRIVATE
  ${riscv_flags} -Os -ffreestanding -ffunction-sections -fdata-sections)
target_link_options(${firmware_target} PRIVATE
  ${riscv_flags} "--ld-path=${HONHON_RISCV_LLD}" -nostdlib -Wl,--gc-sections "-T${generated}/honhon.ld")
set_property(TARGET ${firmware_target} APPEND PROPERTY LINK_DEPENDS "${generated}/honhon.ld")

set(rom "${CMAKE_CURRENT_BINARY_DIR}/${firmware_target}.vmem")
set(binary "${CMAKE_CURRENT_BINARY_DIR}/${firmware_target}.bin")
set(bin_to_vmem "${CMAKE_CURRENT_SOURCE_DIR}/bin_to_vmem.py")
add_custom_command(
  OUTPUT "${rom}"
  BYPRODUCTS "${binary}"
  COMMAND ${HONHON_OBJCOPY_COMMAND} -O binary "$<TARGET_FILE:${firmware_target}>" "${binary}"
  COMMAND "${HONHON_PYTHON}" "${bin_to_vmem}" "${binary}" "${rom}"
  DEPENDS ${firmware_target} "${bin_to_vmem}"
  COMMENT "Creating the honhon UART example ROM image"
  VERBATIM
)
add_custom_target(${firmware_target}_rom ALL DEPENDS "${rom}")
