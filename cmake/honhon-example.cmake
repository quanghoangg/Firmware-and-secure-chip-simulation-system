include("${CMAKE_CURRENT_LIST_DIR}/opentitan.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../hw/memory_map.cmake")
include(ExternalProject)
include(CTest)

function(honhon_add_example HONHON_FIRMWARE_NAME firmware_source)
  get_filename_component(honhon_root "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/.." ABSOLUTE)
  set(firmware_dir "${CMAKE_CURRENT_BINARY_DIR}/sw")
  set(HONHON_ROM "${firmware_dir}/${HONHON_FIRMWARE_NAME}.vmem")

  ExternalProject_Add(honhon_firmware
    SOURCE_DIR "${honhon_root}/sw"
    BINARY_DIR "${firmware_dir}"
    CMAKE_ARGS
      "-DCMAKE_TOOLCHAIN_FILE=${honhon_root}/cmake/riscv-toolchain.cmake"
      "-DOPENTITAN_ROOT=${OPENTITAN_ROOT}"
      "-DRISCV_TOOLCHAIN_ROOT=${RISCV_TOOLCHAIN_ROOT}"
      "-DSRECORD_ROOT=${SRECORD_ROOT}"
      "-DHONHON_PYTHON=${Python3_EXECUTABLE}"
      "-DHONHON_FIRMWARE_NAME=${HONHON_FIRMWARE_NAME}"
      "-DHONHON_FIRMWARE_SOURCE=${firmware_source}"
    BUILD_ALWAYS TRUE
    BUILD_BYPRODUCTS "${HONHON_ROM}"
    INSTALL_COMMAND ""
  )

  add_subdirectory("${honhon_root}/vp" vp)
endfunction()
