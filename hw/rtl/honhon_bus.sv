module honhon_bus (
  input logic clk_i,
  input logic rst_ni,
  input tlul_pkg::tl_h2d_t host_i [2],
  output tlul_pkg::tl_d2h_t host_o [2],
  output tlul_pkg::tl_h2d_t device_o [honhon_soc_pkg::NumDevices],
  input tlul_pkg::tl_d2h_t device_i [honhon_soc_pkg::NumDevices]
);
  import honhon_soc_pkg::*;
  import tlul_pkg::*;

  tl_h2d_t request;
  tl_d2h_t response;
  localparam int SelectWidth = $clog2(NumDevices + 1);
  logic [SelectWidth-1:0] select_device;

  tlul_socket_m1 #(.M(2)) u_arbiter (
    .clk_i, .rst_ni,
    .tl_h_i(host_i), .tl_h_o(host_o),
    .tl_d_o(request), .tl_d_i(response)
  );

  always_comb begin
    if (request.a_address >= RomBase && request.a_address < RomBase + RomSize) begin
      select_device = SelectWidth'(0);
    end else if (request.a_address >= SramBase && request.a_address < SramBase + SramSize) begin
      select_device = SelectWidth'(1);
    end else if (request.a_address >= Uart0Base && request.a_address < Uart0Base + Uart0Size) begin
      select_device = SelectWidth'(2);
    end else if (request.a_address >= AesBase && request.a_address < AesBase + AesSize) begin
      select_device = SelectWidth'(3);
    end else begin
      select_device = SelectWidth'(NumDevices);
    end
  end

  tlul_socket_1n #(.N(NumDevices)) u_decoder (
    .clk_i, .rst_ni,
    .tl_h_i(request), .tl_h_o(response),
    .tl_d_o(device_o), .tl_d_i(device_i),
    .dev_select_i(select_device)
  );
endmodule
