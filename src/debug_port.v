`timescale 1ns/1ns

module debug_port(
  //  sys
  input           i_clk,      i_rst,
  //  uart rx
  input   [7:0]   i_rdata,
  input           i_rready,
  output          o_rreq,
  //  uart tx
  input           i_wready,
  output  [7:0]   o_wdata,
  output          o_wvalid,
  
  //user dbg data
  input [7:0]		i_dbg_wdata,
  input 				i_dbg_wvalid
);

localparam  _START_BYTE = 8'h2D;
localparam  _WATCHDOG   = 8'h65;
`ifdef SIMULATION
localparam  _TIME_30s   = 32'h00000fff;
`else
localparam  _TIME_30s   = 32'h00682eff;//h59682eff
`endif

reg   [7:0] state       = 0;
localparam  IDLE        = 0;
localparam  START       = 1;
localparam  CODE        = 2;
localparam  DONE        = 3;
localparam  NEWLINE		= 4;
localparam  CR				= 5;

//  ctrl
reg   [31:0]  watchdog  = 0;
//  comm
reg   [7:0]   wdata     = 0;
reg           wvalid    = 0;

always @(posedge i_clk) begin
//  if (i_rst) begin
//    state     <= 0;
//    watchdog  <= _TIME_30s;
//  end
//  else begin
		if(i_wready) begin
			wdata <= i_dbg_wdata;
			wvalid <= i_dbg_wvalid;
		end else begin
			wvalid <= 0;
		end
//  end
  
end

assign      o_wdata   = wdata;
assign      o_wvalid  = wvalid;

endmodule
