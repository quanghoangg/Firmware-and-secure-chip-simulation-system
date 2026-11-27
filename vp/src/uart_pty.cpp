#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <pty.h>
#include <termios.h>
#include <unistd.h>

#include "Vvp_top__Dpi.h"

namespace {

struct UartPty {
  int master;
  int slave;
  FILE *log;
  char received;
};

[[noreturn]] void Fail(const char *operation) {
  std::perror(operation);
  std::exit(EXIT_FAILURE);
}

}  // namespace

// The OpenTitan SystemVerilog model handles serial timing. These DPI functions
// connect its bytes to a Linux terminal and a separately flushed log.
void *uartdpi_create(const char *name, const char *log_file_path, const char *) {
  auto *uart = new UartPty{};
  if (openpty(&uart->master, &uart->slave, nullptr, nullptr, nullptr) < 0) {
    Fail("uart openpty");
  }

  termios terminal;
  if (tcgetattr(uart->slave, &terminal) < 0) {
    Fail("uart tcgetattr");
  }
  cfmakeraw(&terminal);
  if (tcsetattr(uart->slave, TCSANOW, &terminal) < 0) {
    Fail("uart tcsetattr");
  }

  const int flags = fcntl(uart->master, F_GETFL);
  if (flags < 0 || fcntl(uart->master, F_SETFL, flags | O_NONBLOCK) < 0) {
    Fail("uart fcntl");
  }

  char device[128];
  const int name_error = ttyname_r(uart->slave, device, sizeof(device));
  if (name_error != 0) {
    errno = name_error;
    Fail("uart ttyname_r");
  }

  uart->log = std::fopen(log_file_path, "wb");
  if (uart->log == nullptr) {
    Fail(log_file_path);
  }

  std::printf("UART %s: %s\nUART log: %s\n", name, device, log_file_path);
  std::fflush(stdout);
  return uart;
}

void uartdpi_close(void *context) {
  auto *uart = static_cast<UartPty *>(context);
  if (uart != nullptr) {
    std::fclose(uart->log);
    close(uart->slave);
    close(uart->master);
    delete uart;
  }
}

int uartdpi_can_read(void *context) {
  auto *uart = static_cast<UartPty *>(context);
  ssize_t bytes;
  do {
    bytes = read(uart->master, &uart->received, 1);
  } while (bytes < 0 && errno == EINTR);

  if (bytes < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
    Fail("uart read");
  }
  return bytes == 1;
}

char uartdpi_read(void *context) {
  return static_cast<UartPty *>(context)->received;
}

int uartdpi_write(void *context, int data) {
  auto *uart = static_cast<UartPty *>(context);
  const auto byte = static_cast<unsigned char>(data);
  if (std::fputc(byte, uart->log) == EOF || std::fflush(uart->log) == EOF) {
    Fail("uart log");
  }

  ssize_t bytes;
  do {
    bytes = write(uart->master, &byte, 1);
  } while (bytes < 0 && errno == EINTR);

  // A full PTY must never stall the simulator or discard bytes from the log.
  if (bytes < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
    Fail("uart write");
  }
  return 0;
}
