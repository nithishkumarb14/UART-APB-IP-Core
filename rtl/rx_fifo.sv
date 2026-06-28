`timescale 1ns / 1ps

module rx_fifo
(
input clk,
input reset_n,
input wrt_en,
input rd_en,
input [7:0] rx_data_in,
output rx_fifo_empty,
output rx_fifo_full,
output rx_fifo_overflow,
output rx_fifo_underflow,
output logic [7:0] rx_fifo_data_output
);

logic [3:0] wrt_ptr,rd_ptr;
logic [7:0] rx_fifo [0:7];
integer i;

assign rx_fifo_empty = (wrt_ptr == rd_ptr);
assign rx_fifo_full = ( wrt_ptr[2:0] == rd_ptr[2:0] && (wrt_ptr[3] != rd_ptr[3]));
assign rx_fifo_overflow = (wrt_en &&rx_fifo_full);
assign rx_fifo_underflow = (rd_en && rx_fifo_empty);

always_ff @(posedge clk) begin
    if(!reset_n) begin
        wrt_ptr <= 4'd0;
        rd_ptr <= 4'd0;
       rx_fifo_data_output <= 8'd0;
       for(i=0; i<8; i=i+1) begin 
        rx_fifo[i] = 8'd0;
       end
       i=0;
    end
    
    else begin
        if(wrt_en && !rx_fifo_full) begin
            rx_fifo[wrt_ptr[2:0]] <= rx_data_in;
            wrt_ptr <= wrt_ptr + 1'b1;
          end
          
          if(rd_en && !rx_fifo_empty) begin 
            rx_fifo_data_output <= rx_fifo[rd_ptr[2:0]];
            rd_ptr <= rd_ptr + 1'b1;
          end
     end
 end
 
 property p_empty_full;
    @(posedge clk) disable iff(!reset_n)
    !(rx_fifo_empty && rx_fifo_full);
 endproperty
 
   property no_write_fifo_full;
        @(posedge clk) disable iff(!reset_n)
        (wrt_en && rx_fifo_full) |=> $stable(wrt_ptr);
    endproperty
    
    property no_read_fifo_empty;
        @(posedge clk) disable iff(!reset_n)
        (rd_en && rx_fifo_empty) |=> $stable(rd_ptr);
    endproperty
 
 assert property (p_empty_full)
    else $error("RX_FIFO CANT EMPTY AND FULL AT SAME TIME");
        
 assert property(no_write_fifo_full)
        else $error("WRITE CANT INCREMENT WHEN THE RX_FIFO IS FULL");
        
  assert property(no_read_fifo_empty)
        else $error("READ CANT INCREMENT WHEN THE RX_FIFO IS EMPTY");



endmodule
