#ifndef HONHON_DT_UART_H_
#define HONHON_DT_UART_H_

#include "honhon.h"
#include "hw/top/uart_regs.h"

typedef enum {
  kDtUart0,
  kDtUartCount,
} dt_uart_t;

typedef enum {
  kDtUartIrqTxWatermark = UART_INTR_STATE_TX_WATERMARK_BIT,
  kDtUartIrqRxWatermark = UART_INTR_STATE_RX_WATERMARK_BIT,
  kDtUartIrqTxDone = UART_INTR_STATE_TX_DONE_BIT,
  kDtUartIrqRxOverflow = UART_INTR_STATE_RX_OVERFLOW_BIT,
  kDtUartIrqRxFrameErr = UART_INTR_STATE_RX_FRAME_ERR_BIT,
  kDtUartIrqRxBreakErr = UART_INTR_STATE_RX_BREAK_ERR_BIT,
  kDtUartIrqRxTimeout = UART_INTR_STATE_RX_TIMEOUT_BIT,
  kDtUartIrqRxParityErr = UART_INTR_STATE_RX_PARITY_ERR_BIT,
  kDtUartIrqTxEmpty = UART_INTR_STATE_TX_EMPTY_BIT,
  kDtUartIrqCount,
} dt_uart_irq_t;

static inline uintptr_t dt_uart_primary_reg_block(dt_uart_t uart) {
  return uart == kDtUart0 ? HONHON_UART0_BASE : 0;
}

#endif
