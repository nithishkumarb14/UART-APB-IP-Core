`timescale 1ns / 1ps


module rx
(
input clk,
input reset_n,
input baud_half_tick,
input baud_tick,
input rx,
input rx_fifo_full,
output logic rx_done,
output logic rx_fifo_wrt_en,
output [7:0] rx_data_shifted
);
logic [7:0] rx_data;

assign rx_fifo_wrt_en = rx_done;

//assign rx_data_shifted = rx_data >> 1;
assign rx_data_shifted = rx_data ;

logic [2:0] bit_ctn = 3'd0;

typedef enum logic [1:0] {
    IDLE = 2'b00,
    START_CHECKER = 2'b01,
    RECEIVE = 2'b10,
    STOP = 2'b11
} state_t;

state_t curr_state,next_state;


always_comb begin
    case(curr_state)
        IDLE : begin
            rx_done = 1'b0;
          /*  if(rx == 1'b0 && baud_half_tick)
                next_state = START_CHECKER;*/
              if(rx == 1'b0)
                next_state = START_CHECKER;
            else
                next_state = IDLE;
        end
        
        START_CHECKER : begin
            rx_done = 1'b0;
            if(rx == 1'b0 && baud_half_tick) 
                next_state = RECEIVE;
        /*    if(rx == 1'b0)
              next_state = RECEIVE;*/
             else if(rx == 1'b0 && !baud_half_tick)
                next_state = START_CHECKER;
            else
                next_state = IDLE;
         end
         
         RECEIVE : begin
            rx_done = 1'b0;
            if(baud_tick && bit_ctn == 3'd7) 
                next_state = STOP;
             else
                next_state = RECEIVE;
        end
        
        STOP : begin
            rx_done = 1'b0;
            if(rx == 1'b1 && baud_tick) begin
                  rx_done = 1'b1;
                  next_state = IDLE;
            end
            else if(rx != 1'b1 && baud_tick) begin
                rx_done = 1'b1;
                next_state = IDLE;
             end
            else 
                next_state = STOP;
        end
        
        default : next_state = IDLE;
  endcase
 end
 
 always_ff @(posedge clk) begin
    if(!reset_n) 
         curr_state <= IDLE;
    else
         curr_state <= next_state;
 end  
 
 always_ff @(posedge clk) begin
    if(!reset_n) begin
        bit_ctn <= 3'd0;
        rx_fifo_wrt_en <= 1'b0;
        rx_data <= 8'd0;
    end
    
    else begin
        case(curr_state) 
            IDLE : begin
                bit_ctn <= 3'd0;
                //rx_fifo_wrt_en <= 1'b0;
           end
           
           START_CHECKER : begin
               //rx_fifo_wrt_en <= 1'b0;
           end
           
           RECEIVE : begin 
               rx_fifo_wrt_en <= 1'b0;
               if(baud_tick) begin
                    rx_data[bit_ctn] <= rx;
                    bit_ctn <= bit_ctn + 1'b1;
               end
           end
           
           STOP : begin 
       
           /* if(rx == 1'b1 && baud_tick) 
                
               if(!rx_fifo_full) begin
                    rx_fifo_wrt_en <= 1'b1;
                    //rx_data <= rx_data << 1;
                end
                */
         end
     endcase       
   end
end

property bit_cnt_checker;
    @(posedge clk) disable iff(!reset_n)
    (bit_ctn <= 3'd7)
endproperty 


property fifo_wrt_checker;
    @(posedge clk) disable iff(!reset_n)
    (rx_fifo_wrt_en) |-> (curr_state == STOP)
endproperty

property rx_done_checker;
    @(posedge clk) disable iff(!reset_n)
    !(rx_done) |=> rx_done
endproperty

assert property(bit_cnt_checker)
    else $error("bit_cnt_checker is greater than 7");
 
 assert property(fifo_wrt_checker)
    else $error("fifo_wrt_checker is not enabled at stop");
 
 
 assert property(rx_done_checker)
    else $error("rx_done is not going to 0");

endmodule
