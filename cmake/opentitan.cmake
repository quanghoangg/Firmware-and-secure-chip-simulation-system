get_filename_component(_opentitan_default
  "${CMAKE_CURRENT_LIST_DIR}/../../secure_chip/opentitan" ABSOLUTE)
set(OPENTITAN_ROOT "${_opentitan_default}" CACHE PATH "OpenTitan checkout")
if(NOT EXISTS "${OPENTITAN_ROOT}/hw/ip/uart/rtl/uart.sv")
  message(FATAL_ERROR "Set OPENTITAN_ROOT to the OpenTitan checkout containing the UART IP")
endif()

get_filename_component(_tools_default "${OPENTITAN_ROOT}/../tools" ABSOLUTE)
set(OPENTITAN_TOOLS "${_tools_default}" CACHE PATH "Installed OpenTitan tools")
set(SRECORD_ROOT "${OPENTITAN_TOOLS}/srecord-install" CACHE PATH "SRecord installation")
set(verilator_DIR "${OPENTITAN_TOOLS}/verilator-5.048/share/verilator"
  CACHE PATH "Directory containing verilator-config.cmake")

# The older OpenTitan environment sets this to the installation prefix.
# The packaged simulator uses the corresponding share/verilator directory.
set(VERILATOR_ROOT "${verilator_DIR}" CACHE PATH "Verilator runtime directory")
set(ENV{VERILATOR_ROOT} "${VERILATOR_ROOT}")
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()
find_package(verilator CONFIG REQUIRED)
find_package(Python3 REQUIRED COMPONENTS Interpreter)

file(GLOB _cached_riscv LIST_DIRECTORIES true
  "${OPENTITAN_ROOT}/bazel-opentitan/external/*lowrisc*rv32imcb*toolchain*")
foreach(candidate IN LISTS _cached_riscv)
  if(EXISTS "${candidate}/bin/riscv32-unknown-elf-clang")
    set(_riscv_default "${candidate}")
    break()
  endif()
endforeach()
set(RISCV_TOOLCHAIN_ROOT "${_riscv_default}" CACHE PATH "lowRISC LLVM/RV32 toolchain")
if(NOT EXISTS "${RISCV_TOOLCHAIN_ROOT}/bin/riscv32-unknown-elf-clang")
  message(FATAL_ERROR "Set RISCV_TOOLCHAIN_ROOT to a lowRISC RV32 LLVM toolchain")
endif()

set(_prim "hw/ip/prim/rtl")
set(_generic "hw/ip/prim_generic/rtl")
set(_tlul "hw/ip/tlul/rtl")
set(_ibex "hw/vendor/lowrisc_ibex/rtl")
set(_uart "hw/ip/uart/rtl")

# Packages are compiled in dependency order. Verilator resolves RTL modules
# from the same IP directories below as it elaborates the design.
set(_packages
  "${_prim}/prim_util_pkg.sv"
  "${_prim}/prim_mubi_pkg.sv"
  "${_prim}/prim_secded_pkg.sv"
  "${_prim}/prim_alert_pkg.sv"
  "${_prim}/prim_count_pkg.sv"
  "${_prim}/prim_subreg_pkg.sv"
  "${_prim}/prim_cipher_pkg.sv"
  "${_generic}/prim_pkg.sv"
  "${_generic}/prim_ram_1p_pkg.sv"
  "${_generic}/prim_rom_pkg.sv"
  "hw/top_earlgrey/rtl/top_pkg.sv"
  "hw/top_earlgrey/rtl/autogen/top_racl_pkg.sv"
  "${_tlul}/tlul_pkg.sv"
  "${_uart}/uart_reg_pkg.sv"
  "${_ibex}/ibex_pkg.sv"
  "${_ibex}/ibex_cheriot_pkg.sv"
)
list(TRANSFORM _packages PREPEND "${OPENTITAN_ROOT}/")
set(OPENTITAN_RTL_PACKAGES ${_packages})
foreach(directory IN ITEMS "${_prim}" "${_generic}" "${_tlul}" "${_ibex}" "${_uart}")
  list(APPEND OPENTITAN_RTL_ARGS -y "${OPENTITAN_ROOT}/${directory}"
    "-I${OPENTITAN_ROOT}/${directory}")
endforeach()
list(APPEND OPENTITAN_RTL_ARGS "-I${OPENTITAN_ROOT}/hw/dv/sv/dv_utils" +libext+.sv)
