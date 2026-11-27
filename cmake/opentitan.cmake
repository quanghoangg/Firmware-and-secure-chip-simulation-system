get_filename_component(HONHON_OPENTITAN_DIR
  "${CMAKE_CURRENT_LIST_DIR}/../third_party/opentitan" ABSOLUTE)

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
list(TRANSFORM _packages PREPEND "${HONHON_OPENTITAN_DIR}/")
set(OPENTITAN_RTL_PACKAGES ${_packages})
foreach(directory IN ITEMS "${_prim}" "${_generic}" "${_tlul}" "${_ibex}" "${_uart}")
  list(APPEND OPENTITAN_RTL_ARGS -y "${HONHON_OPENTITAN_DIR}/${directory}"
    "-I${HONHON_OPENTITAN_DIR}/${directory}")
endforeach()
list(APPEND OPENTITAN_RTL_ARGS "-I${HONHON_OPENTITAN_DIR}/hw/dv/sv/dv_utils" +libext+.sv)
