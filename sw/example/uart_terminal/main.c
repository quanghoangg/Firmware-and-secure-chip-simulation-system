#include <stdbool.h>

#include "honhon.h"
#include "honhon_hal_uart.h"

enum { kLineCapacity = 80 };

typedef enum {
  kInputText,
  kInputEscape,
  kInputEscapeSequence,
} InputState;

static HAL_StatusTypeDef write_text(const UART_HandleTypeDef *uart,
                                    const char *text) {
  size_t length = 0;
  while (text[length] != '\0') {
    ++length;
  }
  return HAL_UART_Transmit(uart, (const uint8_t *)text, length);
}

static bool text_equal(const char *left, const char *right) {
  while (*left == *right && *left != '\0') {
    ++left;
    ++right;
  }
  return *left == *right;
}

static HAL_StatusTypeDef run_command(const UART_HandleTypeDef *uart, char *line) {
  while (*line == ' ') {
    ++line;
  }
  if (*line == '\0') {
    return HAL_OK;
  }

  char *args = line;
  while (*args != '\0' && *args != ' ') {
    ++args;
  }
  if (*args == ' ') {
    *args = '\0';
    ++args;
    while (*args == ' ') {
      ++args;
    }
  }

  if (text_equal(line, "help")) {
    return write_text(uart, "help        Show commands\r\n"
                            "echo TEXT   Print text\r\n"
                            "clear       Clear the screen\r\n"
                            "info        Show board information\r\n");
  }
  if (text_equal(line, "echo")) {
    if (write_text(uart, args) != HAL_OK) {
      return HAL_ERROR;
    }
    return write_text(uart, "\r\n");
  }
  if (text_equal(line, "clear")) {
    return write_text(uart, "\x1b[2J\x1b[H");
  }
  if (text_equal(line, "info")) {
    return write_text(uart, "honhon RV32 on VP, UART0\r\n");
  }
  return write_text(uart, "Unknown command. Type help.\r\n");
}

int main(void) {
  const UART_HandleTypeDef console = {
      .Instance = HONHON_UART0_BASE,
      .ClockHz = SystemCoreClock,
      .BaudRate = HONHON_UART_BAUD,
  };
  static const char prompt[] = "honhon> ";
  if (HAL_UART_Init(&console) != HAL_OK ||
      write_text(&console, "honhon UART terminal\r\n"
                           "Type help for commands.\r\n") != HAL_OK ||
      write_text(&console, prompt) != HAL_OK) {
    return 1;
  }

  char line[kLineCapacity + 1];
  size_t length = 0;
  bool skip_lf = false;
  InputState input = kInputText;
  uint8_t byte;
  while (HAL_UART_Receive(&console, &byte, 1) == HAL_OK) {
    if (byte == '\n' && skip_lf) {
      skip_lf = false;
      continue;
    }
    skip_lf = byte == '\r';

    if (byte == '\r' || byte == '\n') {
      input = kInputText;
      line[length] = '\0';
      if (write_text(&console, "\r\n") != HAL_OK ||
          run_command(&console, line) != HAL_OK ||
          write_text(&console, prompt) != HAL_OK) {
        return 1;
      }
      length = 0;
    } else if (byte == 0x1b) {
      input = kInputEscape;
    } else if (input == kInputEscape) {
      input = byte == '[' || byte == 'O' ? kInputEscapeSequence : kInputText;
    } else if (input == kInputEscapeSequence) {
      // Ignore ANSI cursor keys, including their trailing printable byte.
      if (byte >= 0x40 && byte <= 0x7e) {
        input = kInputText;
      }
    } else if (byte == '\b' || byte == 0x7f) {
      if (length > 0) {
        --length;
        if (write_text(&console, "\b \b") != HAL_OK) {
          return 1;
        }
      }
    } else if (byte >= ' ' && byte <= '~') {
      if (length == kLineCapacity) {
        if (write_text(&console, "\a") != HAL_OK) {
          return 1;
        }
      } else {
        line[length++] = (char)byte;
        if (HAL_UART_Transmit(&console, &byte, 1) != HAL_OK) {
          return 1;
        }
      }
    }
  }
  return 1;
}
