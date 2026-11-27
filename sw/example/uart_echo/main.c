#include "honhon.h"
#include "honhon_hal_uart.h"

int main(void) {
  const UART_HandleTypeDef console = {
      .Instance = HONHON_UART0_BASE,
      .ClockHz = SystemCoreClock,
      .BaudRate = HONHON_UART_BAUD,
  };

  static const uint8_t banner[] = "Hello from honhon\r\n";
  if (HAL_UART_Init(&console) != HAL_OK ||
      HAL_UART_Transmit(&console, banner, sizeof(banner) - 1) != HAL_OK) {
    return 1;
  }

  uint8_t byte;
  while (HAL_UART_Receive(&console, &byte, 1) == HAL_OK &&
         HAL_UART_Transmit(&console, &byte, 1) == HAL_OK) {
  }
  return 1;
}
