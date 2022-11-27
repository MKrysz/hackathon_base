module task_manager(
  //  sys
  input           i_clk,      i_rst,
  output          o_link,
  //  eth
  input   [7:0]   i_rdata,
  input           i_rready,
  output          o_rreq,
  output  [7:0]   o_wdata,
  input           i_wready,
  output          o_wvalid,
  //  dbg
  output [7:0] 	o_dbg_wdata,
  output 			o_dbg_wvalid
);

//  fsm - add task control here
reg [1:0]     state     = 0;
localparam    IDLE      = 0;
localparam    CONNECTED = 1;
localparam    LINKED    = 2;

wire          done;
wire 				link;
reg           send     = 0;


always @(posedge i_clk) begin
//  if (i_rst) begin
////    link  <= 0;
////    send  <= 0;
//    state <= IDLE;
//  end
//  else begin
//    case (state)
//      IDLE: begin
////        link <= 0;
//        if  (done) begin
////          send  <=  1;
//          state <= CONNECTED;
//        end
//      end
//      CONNECTED: begin
//        if (done)
//          state <= LINKED;
//        else
//          send  <=  0;
//      end
//      LINKED: begin
//        if (done) begin
////          link  <= 0;
////          send  <= 1;
//          state <= CONNECTED;
//        end
////          link <= 1; // change to 1 to enable MHP protocol ethertype usage
//      end
//    endcase
//  end
end

mhp protocol(
  //  sys
  .i_clk    (i_clk),
  .i_rst    (i_rst),
  //  ctrl
  .i_send   (0),
  .o_done   (done),
  //  eth
  .i_rdata  (i_rdata),
  .i_rready (i_rready),
  .o_rreq   (o_rreq),
  .o_wdata  (o_wdata),
  .i_wready (i_wready),
  .o_wvalid (o_wvalid),
  .o_link (link),
  .o_dbg_wdata(o_dbg_wdata),
  .o_dbg_wvalid(o_dbg_wvalid)
);

assign  o_link  = link;

endmodule