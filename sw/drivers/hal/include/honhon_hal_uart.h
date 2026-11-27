#ifndef HONHON_HAL_UART_H_
#define HONHON_HAL_UART_H_

#include <stddef.h>
#include <stdint.h>

typedef enum {
  HAL_OK,
  HAL_ERROR,
} HAL_StatusTypeDef;

typedef struct {
  uintptr_t Instance;
  uint32_t ClockHz;
  uint32_t BaudRate;
} UART_HandleTypeDef;

HAL_StatusTypeDef HAL_UART_Init(const UART_HandleTypeDef *uart);

// Blocking polling transfers, with lengths expressed in bytes.
HAL_StatusTypeDef HAL_UART_Transmit(const UART_HandleTypeDef *uart,
                                    const uint8_t *data, size_t length);
HAL_StatusTypeDef HAL_UART_Receive(const UART_HandleTypeDef *uart,
                                   uint8_t *data, size_t length);

#endif
