#include "honhon_hal_uart.h"

#include "sw/device/lib/dif/dif_uart.h"

static dif_result_t uart_handle(const UART_HandleTypeDef *uart, dif_uart_t *dif) {
  if (uart == NULL || uart->Instance == 0) {
    return kDifBadArg;
  }
  return dif_uart_init(mmio_region_from_addr(uart->Instance), dif);
}

HAL_StatusTypeDef HAL_UART_Init(const UART_HandleTypeDef *uart) {
  dif_uart_t dif;
  if (uart_handle(uart, &dif) != kDifOk || uart->ClockHz == 0 || uart->BaudRate == 0) {
    return HAL_ERROR;
  }

  const dif_uart_config_t config = {
      .baudrate = uart->BaudRate,
      .clk_freq_hz = uart->ClockHz,
      .parity_enable = kDifToggleDisabled,
      .parity = kDifUartParityEven,
      .tx_enable = kDifToggleEnabled,
      .rx_enable = kDifToggleEnabled,
  };
  return dif_uart_configure(&dif, config) == kDifOk ? HAL_OK : HAL_ERROR;
}

HAL_StatusTypeDef HAL_UART_Transmit(const UART_HandleTypeDef *uart,
                                    const uint8_t *data, size_t length) {
  dif_uart_t dif;
  if (data == NULL || uart_handle(uart, &dif) != kDifOk) {
    return HAL_ERROR;
  }

  for (size_t i = 0; i < length; ++i) {
    if (dif_uart_byte_send_polled(&dif, data[i]) != kDifOk) {
      return HAL_ERROR;
    }
  }
  return HAL_OK;
}

HAL_StatusTypeDef HAL_UART_Receive(const UART_HandleTypeDef *uart,
                                   uint8_t *data, size_t length) {
  dif_uart_t dif;
  if (data == NULL || uart_handle(uart, &dif) != kDifOk) {
    return HAL_ERROR;
  }

  for (size_t i = 0; i < length; ++i) {
    if (dif_uart_byte_receive_polled(&dif, &data[i]) != kDifOk) {
      return HAL_ERROR;
    }
  }
  return HAL_OK;
}
