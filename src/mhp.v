`timescale 1ns/1ns

module mhp(
  //  sys
  input           i_clk,      i_rst,
  //  ctrl
  input           i_send,
  output          o_done,
  output				o_ready, // are we ready?!
  //  eth
  input   [7:0]   i_rdata,
  input           i_rready,
  output          o_rreq,
  output  [7:0]   o_wdata,
  input           i_wready,
  output          o_wvalid, 
  //T-MAN
  output	reg [6:0]	o_rType,
  output reg [7:0]	o_rData,
  output reg [15:0]	o_rSize,
  
  input [6:0]		i_wType,
  input [7:0]		i_wData,
  input [15:0]		i_wSize,
  
  output reg 		o_link,
  
  // DBG port
  output reg [7:0] o_dbg_wdata,
  output  		o_dbg_wvalid
);

//  fsm
reg   [7:0] state       = 0;
localparam  IDLE        = 0;
localparam  READ        = 1;
localparam  WRITE       = 2;
localparam  WAIT_FOR_DATA	= 12;
//write states
localparam  W_DST1		= 13;
localparam  W_DST2		= 14;
localparam  W_SRC1		= 15;
localparam  W_SRC2		= 16;
localparam  W_SIZE1		= 17;
localparam  W_SIZE2		= 18;
localparam  W_DTYPE		= 19;
localparam  W_PAYLOAD	= 20;
localparam  W_SCS1		= 21;
localparam  W_SCS2		= 22;
//read states
localparam  R_DST1		= 3;
localparam  R_DST2		= 4;
localparam  R_SRC1		= 5;
localparam  R_SRC2		= 6;
localparam  R_SIZE1		= 7;
localparam  R_SIZE2		= 8;
localparam  R_DTYPE		= 9;
localparam  R_PAYLOAD	= 10;
localparam  R_SCS1		= 11;
localparam  R_SCS2		= 23;
//  local regs
reg           done      = 0;
//  read regs
reg           r_req     = 0;
//  write regs
reg   [7:0]   w_data    = 0;
reg           w_valid   = 0;

reg [15:0] 		our_ddr 	= 0;
reg [15:0] 		judge_ddr = 16'hffff;
reg [15:0] 		size = 0;
reg 				dir = 0;
reg [6:0]		type = 0;

//  dbg
assign o_dbg_wvalid = 1;

//temp
reg [15:0] iter_read  = 0;
reg [15:0] scs_acc  = 0;
reg [1:0] scs_bit_sel = 0;

wire send;
assign send = i_send;


always @(posedge i_clk) begin
  if (i_rst) begin
    done    <= 0;
    w_data  <= 1;
    w_valid <= 0;
    state   <= IDLE;
  end
  else begin
    case (state)
      IDLE: begin
			scs_acc <= 0;
			scs_bit_sel <= 0;
        w_data  <= 0;
        w_valid <= 0;
        done    <= 0;
		  o_link  <= 0;
		  o_dbg_wdata <= "I";
        if (i_rready) begin // received frame's payload ready
          r_req   <= 1;     // r_req set before read state, so we can expect valid data in READ state
          state   <= R_DST1;
        end else
          r_req   <= 0;
			 
			if (send && i_wready) begin
				state <= W_DST1;
			end
      end
		// READ STATES
		R_DST1: begin
			r_req   <= 1;
			our_ddr[15:8] <= i_rdata;
			state <= R_DST2;
		  o_dbg_wdata <= "1";
		end
		R_DST2: begin
			our_ddr[7:0] <= i_rdata;
		  o_dbg_wdata <= "2";
			if(our_ddr == 0) begin
				state <= READ;
			end else 
				state <= R_SRC1;
		end
		R_SRC1: begin
			judge_ddr[15:8] <= i_rdata;
			state <= R_SRC2;
		end
		R_SRC2: begin
			judge_ddr[7:0] <= i_rdata;
			state <= R_SIZE1;
		end
		R_SIZE1: begin
			size [15:8] <= i_rdata;
			state <= R_SIZE2;
		end
		R_SIZE2: begin
			size [7:0] <= i_rdata;
			state <= R_DTYPE;
		end
		R_DTYPE: begin
			dir <= i_rdata[7];
			type <= i_rdata[6:0];
			iter_read <= 0;
			if(size == 0)
				state <= R_SCS1;
			else
				state <= R_PAYLOAD;
		end
		R_PAYLOAD: begin
			o_rData <= i_rdata;
			if (iter_read == size-1) begin //TODO: write specific flags
				state <= R_SCS1;
			end
		end
		R_SCS1: begin
//			size [15:8] <= i_rdata; why would we care about scs?
			state <= R_SCS2;
		end
		R_SCS2: begin
//			size [7:0] <= i_rdata; why would we care about scs?
			if(!i_rready) begin
				r_req <= 0;// we're not accepting more data
				state <= WAIT_FOR_DATA;
			end
		end
		WAIT_FOR_DATA: begin
		scs_acc <= 0;
		scs_bit_sel <= 0;
		if(send && i_wready) // mamy dane do przeslania i modul jest gotowy
			state <= W_DST1;
		end
		// WRITE STATES
		W_DST1: begin
			o_link <= 1;
			w_data <= judge_ddr[15:8];
			state <= W_DST2;
			scs_acc <= scs_acc + judge_ddr[15:8]<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_DST2: begin
			w_data <= judge_ddr[7:0];
			state <= W_SRC1;
			scs_acc <= scs_acc + judge_ddr[7:0]<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_SRC1: begin
			w_data <= our_ddr[15:8];
			state <= W_SRC2;
			scs_acc <= scs_acc + our_ddr[15:8]<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_SRC2: begin
			w_data <= our_ddr[7:0];
			state <= W_SIZE1;
			scs_acc <= scs_acc + our_ddr[7:0]<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_SIZE1: begin
			w_data <= size[15:8];
			state <= W_SIZE2;
			scs_acc <= scs_acc + size[15:8]<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_SIZE2: begin
			w_data <= size[7:0];
			state <= W_DTYPE;
			scs_acc <= scs_acc + size[7:0]<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_DTYPE: begin
//			w_data <= {dir, type};
			w_data <= 8'h83;
			state <= W_PAYLOAD;
//			scs_acc <= scs_acc + {dir, type}<<scs_bit_sel;
			scs_acc <= scs_acc + 8'h83 << scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
		end
		W_PAYLOAD: begin
			w_data <= i_wData;
			scs_acc <= scs_acc + i_wData<<scs_bit_sel;
			scs_bit_sel <= scs_bit_sel + 1;
			if (iter_read == size-1) begin //TODO: write specific flags
				state <= W_SCS1;
			end
		end
		W_SCS1: begin
			w_data <= scs_acc[15:8];
			state <= W_SCS2;
		end
		W_SCS2: begin
			w_data <= scs_acc[7:0];
			state <= IDLE;
		end
      READ: begin
		  o_dbg_wdata <= "R";
        if (i_rready) // clear fifo
          r_req   <= 1;
			 
			 // <= data out
        else begin
          r_req   <= 0;
          done    <= 1;
          state   <= WRITE;
        end
      end
      WRITE: begin    //  write data
		  o_dbg_wdata <= "W";
        if (i_wready) begin
          w_valid <= 1;
          state   <=  IDLE;
        end
      end
    endcase
  end
end

assign    o_done   = done;
assign    o_rreq   = r_req;
assign    o_wdata  = w_data;
assign    o_wvalid = w_valid;

endmodule
