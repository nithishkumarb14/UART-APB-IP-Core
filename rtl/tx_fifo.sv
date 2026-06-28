`timescale 1ns / 1ps

module tx_fifo
(
input clk,
input reset_n,
input wrt_en,
input rd_en,
input [7:0] tx_fifo_data_in,
output tx_fifo_empty,
output tx_fifo_full,
output tx_fifo_overflow,
output tx_fifo_underflow,
output logic [7:0] tx_fifo_data_output
);
logic [7:0] tx_fifo [0:7];

logic [3:0] read_ptr,write_ptr;


//logic [3:0] counter = 4'd0;

assign tx_fifo_empty = (read_ptr == write_ptr);
assign tx_fifo_full = ((read_ptr[2:0] == write_ptr[2:0]) && (read_ptr[3]!=write_ptr[3]));
assign tx_fifo_overflow = (wrt_en && tx_fifo_full);
assign tx_fifo_underflow = (rd_en && tx_fifo_empty);

//assign tx_fifo_overflow = wrt_en ? (counter == 4'd8 ? 1'b1 : 1'b0 ) : 1'b0 ;



always_ff @(posedge clk) begin
    if(!reset_n) begin
        tx_fifo_data_output <= 8'd0;
        read_ptr <= 4'd0;
        write_ptr <= 4'd0;
    end 
    
    else begin 
        if(!tx_fifo_full && wrt_en) begin            
            tx_fifo[write_ptr[2:0]] <= tx_fifo_data_in;
            write_ptr <= write_ptr + 1'b1;
        end
         if(!tx_fifo_empty && rd_en) begin
            tx_fifo_data_output <= tx_fifo[read_ptr[2:0]];
            read_ptr <= read_ptr + 1'b1;
         end

     end
        
end
    property p_empty_full;
        @(posedge clk) disable iff(!reset_n)
        !(tx_fifo_empty && tx_fifo_full);
    endproperty 
    
    property no_write_fifo_full;
        @(posedge clk) disable iff(!reset_n)
        (wrt_en && tx_fifo_full) |=> $stable(write_ptr);
    endproperty
    
    property no_read_fifo_empty;
        @(posedge clk) disable iff(!reset_n)
        (rd_en && tx_fifo_empty) |=> $stable(read_ptr);
    endproperty
    
    assert property(p_empty_full)
        else $error("TX_FIFO CANT EMPTY AND FULL AT SAME TIME");
        
    assert property(no_write_fifo_full)
        else $error("WRITE CANT INCREMENT WHEN THE TX_FIFO IS FULL");
        
    assert property(no_read_fifo_empty)
        else $error("READ CANT INCREMENT WHEN THE TX_FIFO IS EMPTY");
     
        

endmodule
