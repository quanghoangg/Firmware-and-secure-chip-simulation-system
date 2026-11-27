#include <charconv>
#include <csignal>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <string>
#include <string_view>

#include "Vvp_top.h"
#include "Vvp_top__Dpi.h"

namespace {

volatile std::sig_atomic_t stop_requested = 0;

void Stop(int) { stop_requested = 1; }

struct Options {
  std::string rom = HONHON_DEFAULT_ROM;
  std::string uart_log = HONHON_DEFAULT_LOG;
  std::uint64_t cycles = 0;
};

void PrintUsage(std::ostream &out) {
  out << "Usage: honhon-vp [--rom FILE] [--uart-log FILE] [--cycles COUNT]\n";
}

bool ParseOptions(int argc, char **argv, Options &options) {
  for (int i = 1; i < argc; ++i) {
    const std::string_view option = argv[i];
    if (i + 1 == argc) {
      return false;
    }
    const std::string_view value = argv[++i];
    if (option == "--rom") {
      options.rom = value;
    } else if (option == "--uart-log") {
      options.uart_log = value;
    } else if (option == "--cycles") {
      const auto parsed = std::from_chars(value.begin(), value.end(), options.cycles);
      if (parsed.ec != std::errc{} || parsed.ptr != value.end()) {
        return false;
      }
    } else {
      return false;
    }
  }
  return true;
}

}  // namespace

int main(int argc, char **argv) {
  if (argc == 2 && std::string_view(argv[1]) == "--help") {
    PrintUsage(std::cout);
    return 0;
  }

  Options options;
  if (!ParseOptions(argc, argv, options)) {
    PrintUsage(std::cerr);
    return 2;
  }
  if (!std::filesystem::is_regular_file(options.rom)) {
    std::cerr << "Cannot open ROM image: " << options.rom << '\n';
    return 2;
  }

  std::signal(SIGINT, Stop);
  std::signal(SIGTERM, Stop);

  VerilatedContext context;
  const std::string uart_plusarg = "+UARTDPI_LOG_uart0=" + options.uart_log;
  const char *sim_args[] = {argv[0], uart_plusarg.c_str()};
  context.commandArgs(2, sim_args);

  Vvp_top top{&context};
  top.clk_i = 0;
  // Drive a reset edge even when Ibex is holding its internal clock gated.
  top.rst_ni = 1;
  top.eval();
  top.rst_ni = 0;
  top.eval();

  const svScope scope = svGetScopeFromName("TOP.vp_top");
  if (scope == nullptr) {
    std::cerr << "Cannot locate the ROM loader in vp_top\n";
    top.final();
    return 1;
  }
  svSetScope(scope);
  honhon_load_rom(options.rom.c_str());

  constexpr std::uint64_t reset_cycles = 8;
  int result = 0;
  for (std::uint64_t cycle = 0; !stop_requested && !context.gotFinish(); ++cycle) {
    if (cycle == reset_cycles) {
      top.rst_ni = 1;
    }

    context.timeInc(1);
    top.clk_i = 1;
    top.eval();
    context.timeInc(1);
    top.clk_i = 0;
    top.eval();

    if (top.rst_ni && top.cpu_fault_o) {
      std::cerr << "Ibex reported a fault at cycle " << cycle << '\n';
      result = 1;
      break;
    }
    if (options.cycles != 0 && cycle + 1 == options.cycles) {
      break;
    }
  }

  top.final();
  return result;
}
