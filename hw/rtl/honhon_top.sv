module honhon_top (
  input logic clk_i,
  input logic rst_ni,
  input logic uart_rx_i,
  output logic uart_tx_o,
  output logic cpu_fault_o
);
  import honhon_soc_pkg::*;
  import ibex_pkg::*;
  import prim_mubi_pkg::*;
  import tlul_pkg::*;

  tl_h2d_t host_request [2], device_request [3];
  tl_d2h_t host_response [2], device_response [3];

  logic [1:0] cpu_req, cpu_gnt, cpu_valid, cpu_err, tl_integrity_error;
  logic [31:0] cpu_addr [2], cpu_wdata [2], cpu_rdata [2];
  logic [6:0] cpu_rdata_integrity [2];
  logic [3:0] cpu_be [2];
  logic [1:0] cpu_we;
  logic cpu_internal_fault, cpu_bus_fault, cpu_double_fault;

  assign cpu_we[0] = 1'b0;
  assign cpu_wdata[0] = '0;
  assign cpu_be[0] = '1;
  assign cpu_fault_o = cpu_internal_fault | cpu_bus_fault | cpu_double_fault |
                       (|tl_integrity_error);

  ibex_top #(.PMPEnable(1'b1)) u_cpu (
    .clk_i, .rst_ni,
    .test_en_i(1'b0),
    .ram_cfg_icache_tag_i('0), .ram_cfg_icache_tag_o(),
    .ram_cfg_icache_data_i('0), .ram_cfg_icache_data_o(),
    .cheriot_enable_i(IbexMuBiOff),
    .hart_id_i('0), .boot_addr_i(RomBase),
    .trvk_heap_base_addr_i('0),
    .instr_req_o(cpu_req[0]), .instr_gnt_i(cpu_gnt[0]),
    .instr_rvalid_i(cpu_valid[0]), .instr_addr_o(cpu_addr[0]), .instr_rdata_i(cpu_rdata[0]),
    .instr_rdata_intg_i(cpu_rdata_integrity[0]), .instr_err_i(cpu_err[0]),
    .data_req_o(cpu_req[1]), .data_gnt_i(cpu_gnt[1]), .data_rvalid_i(cpu_valid[1]),
    .data_we_o(cpu_we[1]), .data_be_o(cpu_be[1]), .data_addr_o(cpu_addr[1]),
    .data_wdata_o(cpu_wdata[1]), .data_rdata_i(cpu_rdata[1]),
    .data_wdata_intg_o(), .data_tag_o(),
    .data_rdata_intg_i(cpu_rdata_integrity[1]), .data_tag_i(1'b0), .data_err_i(cpu_err[1]),
    .trvk_revbm_req_o(), .trvk_revbm_gnt_i(1'b0), .trvk_revbm_rvalid_i(1'b0),
    .trvk_revbm_addr_o(),
    .trvk_revbm_rdata_i('0), .trvk_revbm_rdata_intg_i('0), .trvk_revbm_err_i(1'b0),
    .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0),
    .irq_fast_i('0), .irq_nm_i(1'b0),
    .scramble_key_valid_i(1'b0), .scramble_key_i('0), .scramble_nonce_i('0), .scramble_req_o(),
    .debug_req_i(1'b0), .crash_dump_o(), .double_fault_seen_o(cpu_double_fault),
    .fetch_enable_i(IbexMuBiOn), .mcounteren_writable_i(IbexMuBiOff),
    .alert_minor_o(), .core_sleep_o(),
    .alert_major_internal_o(cpu_internal_fault), .alert_major_bus_o(cpu_bus_fault),
    .scan_rst_ni(1'b1), .lockstep_cmp_en_o(),
    .data_req_shadow_o(), .data_we_shadow_o(), .data_be_shadow_o(),
    .data_addr_shadow_o(), .data_wdata_shadow_o(), .data_wdata_intg_shadow_o(),
    .instr_req_shadow_o(), .instr_addr_shadow_o()
  );

  for (genvar port_id = 0; port_id < 2; port_id++) begin : gen_host
    tlul_adapter_host #(
      .EnableDataIntgGen(1'b1),
      .EnableRspDataIntgCheck(1'b1)
    ) u_host (
      .clk_i, .rst_ni,
      .req_i(cpu_req[port_id]), .gnt_o(cpu_gnt[port_id]),
      .addr_i(cpu_addr[port_id]), .we_i(cpu_we[port_id]), .wdata_i(cpu_wdata[port_id]),
      .wdata_intg_i('0), .be_i(cpu_be[port_id]), .user_rsvd_i('0),
      .instr_type_i(port_id == 0 ? MuBi4True : MuBi4False),
      .valid_o(cpu_valid[port_id]), .rdata_o(cpu_rdata[port_id]),
      .rdata_intg_o(cpu_rdata_integrity[port_id]), .err_o(cpu_err[port_id]),
      .intg_err_o(tl_integrity_error[port_id]),
      .tl_o(host_request[port_id]), .tl_i(host_response[port_id])
    );
  end

  honhon_bus u_bus (
    .clk_i, .rst_ni,
    .host_i(host_request), .host_o(host_response),
    .device_o(device_request), .device_i(device_response)
  );

  localparam int RomWords = RomSize / 4;
  logic rom_req, rom_valid;
  logic [$clog2(RomWords)-1:0] rom_address;
  logic [31:0] rom_data;

  tlul_adapter_sram #(
    .SramAw($clog2(RomWords)), .SramBusBankAW($clog2(RomWords)), .SramDepth(RomWords),
    .ErrOnWrite(1'b1), .CmdIntgCheck(1'b1),
    .EnableRspIntgGen(1'b1), .EnableDataIntgGen(1'b1)
  ) u_rom_adapter (
    .clk_i, .rst_ni, .tl_i(device_request[0]), .tl_o(device_response[0]),
    .en_ifetch_i(MuBi4True), .req_o(rom_req), .gnt_i(1'b1), .addr_o(rom_address),
    .req_type_o(), .we_o(), .wdata_o(), .wmask_o(), .intg_error_o(), .user_rsvd_o(),
    .rdata_i(rom_data), .rvalid_i(rom_valid), .rerror_i('0),
    .compound_txn_in_progress_o(), .readback_error_o(),
    .readback_en_i(MuBi4False), .wr_collision_i(1'b0), .write_pending_i(1'b0)
  );

  prim_rom #(.Depth(RomWords)) u_rom (
    .clk_i, .rst_ni, .req_i(rom_req), .addr_i(rom_address),
    .rvalid_o(rom_valid), .rdata_o(rom_data), .cfg_i('0), .cfg_o()
  );

  localparam int SramWords = SramSize / 4;
  logic sram_req, sram_write, sram_valid;
  logic [$clog2(SramWords)-1:0] sram_address;
  logic [31:0] sram_wdata, sram_mask, sram_rdata;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) sram_valid <= 1'b0;
    else sram_valid <= sram_req && !sram_write;
  end

  tlul_adapter_sram #(
    .SramAw($clog2(SramWords)), .SramBusBankAW($clog2(SramWords)), .SramDepth(SramWords),
    .CmdIntgCheck(1'b1), .EnableRspIntgGen(1'b1), .EnableDataIntgGen(1'b1)
  ) u_sram_adapter (
    .clk_i, .rst_ni, .tl_i(device_request[1]), .tl_o(device_response[1]),
    .en_ifetch_i(MuBi4False), .req_o(sram_req), .gnt_i(1'b1),
    .we_o(sram_write), .addr_o(sram_address), .wdata_o(sram_wdata), .wmask_o(sram_mask),
    .req_type_o(), .intg_error_o(), .user_rsvd_o(),
    .rdata_i(sram_rdata), .rvalid_i(sram_valid), .rerror_i('0),
    .compound_txn_in_progress_o(), .readback_error_o(),
    .readback_en_i(MuBi4False), .wr_collision_i(1'b0), .write_pending_i(1'b0)
  );

  prim_ram_1p #(.Depth(SramWords), .DataBitsPerMask(8)) u_sram (
    .clk_i, .rst_ni, .req_i(sram_req), .write_i(sram_write), .addr_i(sram_address),
    .wdata_i(sram_wdata), .wmask_i(sram_mask), .rdata_o(sram_rdata), .cfg_i('0), .cfg_o()
  );

  uart #(.AlertAsyncOn('0)) u_uart (
    .clk_i, .rst_ni,
    .tl_i(device_request[2]), .tl_o(device_response[2]),
    .alert_rx_i({uart_reg_pkg::NumAlerts{prim_alert_pkg::ALERT_RX_DEFAULT}}), .alert_tx_o(),
    .racl_policies_i('0), .racl_error_o(), .lsio_trigger_o(),
    .cio_rx_i(uart_rx_i), .cio_tx_o(uart_tx_o), .cio_tx_en_o(),
    .intr_tx_watermark_o(), .intr_tx_empty_o(), .intr_tx_done_o(),
    .intr_rx_watermark_o(), .intr_rx_overflow_o(), .intr_rx_frame_err_o(),
    .intr_rx_break_err_o(), .intr_rx_timeout_o(), .intr_rx_parity_err_o()
  );
endmodule
