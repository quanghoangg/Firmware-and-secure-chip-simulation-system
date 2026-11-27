module vp_top (
  input logic clk_i,
  input logic rst_ni,
  output logic cpu_fault_o
);
  import honhon_soc_pkg::*;

  logic uart_rx, uart_tx;

  honhon_top u_chip (
    .clk_i, .rst_ni, .cpu_fault_o,
    .uart_rx_i(uart_rx), .uart_tx_o(uart_tx)
  );

  uartdpi #(.FREQ(ClockHz), .BAUD(UartBaud)) u_uart (
    .clk_i, .rst_ni, .active(1'b1),
    .tx_o(uart_rx), .rx_i(uart_tx)
  );

  export "DPI-C" task honhon_load_rom;
  task honhon_load_rom(input string path);
    u_chip.u_rom.simutil_memload(path);
  endtask
endmodule
