`timescale 1ns / 1ps


module baud_rate
(
input clk,
input reset_n,
input start,
input logic [20:0] baud_rate_hex,
output logic baud_tick_half,
output logic baud_tick
);

logic [20:0] cycle;
localparam integer clk_freq = 50000000;

always_comb begin
    if(baud_rate_hex != 21'd0)
     cycle = clk_freq/baud_rate_hex; //5208
    else
     cycle = 21'd434;
end

logic [12:0] counter;

always_ff @(posedge clk) begin
    if(!reset_n) begin 
        baud_tick_half <= 1'b0;
        baud_tick <= 1'b0;
        counter <= 12'd0;
    end
    
    else if(start) begin  
    
       
       if(counter == cycle - 1) begin
            counter <= 12'd0;
            baud_tick <= 1'b1;
            baud_tick_half <= 1'b0;
        end
    
      else if(counter == (cycle/2)-1) begin
            baud_tick_half <= 1'b1;
            baud_tick <= 1'b0;
            counter <= counter + 1'b1;
        end
        
        else  begin
            counter <= counter + 1'b1;
            baud_tick <= 1'b0;
            baud_tick_half <= 1'b0;
         end
     
     
       
end
end


property baud_tick_one;
    @(posedge clk) disable iff(!reset_n)
    (counter == cycle - 1 ) |=> baud_tick;
 endproperty
 
 property baud_tick_zero;
    @(posedge clk) disable iff(!reset_n)
    baud_tick |=> !(baud_tick);
 endproperty
 
 property baud_tick_half_one;
    @(posedge clk) disable iff(!reset_n)
    (counter == (cycle/2)-1) |=> (baud_tick_half);
 endproperty
 
  property baud_tick_half_zero;
    @(posedge clk) disable iff(!reset_n)
    baud_tick_half |=> !(baud_tick_half);
 endproperty
 
 property no_simultaneous_ticks;
    @(posedge clk) disable iff(!reset_n)
    !(baud_tick && baud_tick_half);
  endproperty
 
 assert property(baud_tick_one)
    else $error("Baud_Tick not going to 1");
    
 assert property(baud_tick_zero)
    else $error("Baud_Tick not going to 0");
 
 assert property(baud_tick_half_one)
    else $error("Baud Tick Half is one");   
    
 assert property(baud_tick_half_zero)
    else $error("Baud Tick Half is Zero");  
  
  assert property(no_simultaneous_ticks)  
    else $error("Baud_tick = 1 && baud_tick_half = 1");

endmodule
