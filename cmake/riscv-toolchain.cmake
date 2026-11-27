set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES RISCV_TOOLCHAIN_ROOT)

if(RISCV_TOOLCHAIN_ROOT)
  set(_llvm_hint "${RISCV_TOOLCHAIN_ROOT}/bin")
endif()
find_program(HONHON_RISCV_CLANG NAMES riscv32-unknown-elf-clang clang
  NAMES_PER_DIR HINTS ${_llvm_hint} REQUIRED)
get_filename_component(_riscv_bin "${HONHON_RISCV_CLANG}" DIRECTORY)
find_program(HONHON_RISCV_LLD NAMES ld.lld riscv32-unknown-elf-ld.lld
  NAMES_PER_DIR HINTS "${_riscv_bin}" REQUIRED)
find_program(HONHON_RISCV_OBJCOPY NAMES llvm-objcopy riscv32-unknown-elf-objcopy
  NAMES_PER_DIR HINTS "${_riscv_bin}" REQUIRED)

set(CMAKE_C_COMPILER "${HONHON_RISCV_CLANG}")
set(CMAKE_ASM_COMPILER "${CMAKE_C_COMPILER}")
set(CMAKE_C_COMPILER_TARGET riscv32-unknown-elf)
set(CMAKE_ASM_COMPILER_TARGET riscv32-unknown-elf)
set(CMAKE_OBJCOPY "${HONHON_RISCV_OBJCOPY}")
