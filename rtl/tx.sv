module tx
(
input clk,
input reset_n,
input start,
input baud_tick,
input baud_half_tick,
input tx_fifo_empty,
input [7:0] tx_data_in,
output logic tx_fifo_rd_en,
output logic tx_done,
output logic  tx_data_out
);

logic [2:0] bit_cnt=3'd0;
logic [7:0] shift_reg;

/*typedef enum logic [2:0]{
    IDLE = 3'b000,
    LOAD = 3'b001,
    START = 3'b010,
    DATA = 3'b011,
    STOP = 3'b100
} state_t;*/

typedef enum logic [2:0]{
    IDLE = 3'b000,
   // TEMP = 3'b111,
    LOAD = 3'b001,
    START = 3'b010,
    DATA = 3'b011,
    STOP = 3'b100
} state_t;

state_t curr_state,next_state;

//assign tx_done = (curr_state==STOP) ? 1 : 0;

always_ff @(posedge clk) begin
    if(!reset_n) 
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

always_comb begin
    case(curr_state) 
        IDLE : begin
            tx_done = 1'b0;
            if(!tx_fifo_empty && start) begin
                   // next_state = TEMP;
                   next_state = LOAD;
              end
                 
             else
                next_state = IDLE;
         end
         
       /*  TEMP : begin
            next_state = LOAD;
         end*/
         
         LOAD : begin 
            tx_done = 1'b0;
            next_state = START;
        end
         
         START : begin
            tx_done = 1'b0;
            if(baud_half_tick) 
                next_state = DATA;
            else
              next_state = START;
        end
        
        DATA : begin 
            tx_done = 1'b0;
            if(baud_tick && bit_cnt == 3'd7) 
                next_state = STOP;
             else
                next_state = DATA;
        end
        
        STOP : begin   
            tx_done = 1'b0;
            if(baud_tick) begin
                tx_done = 1'b1;
                next_state = IDLE;
             end
             else
                next_state = STOP;

         end
       default : next_state = IDLE;
    endcase
 end
 
 
 always_ff @(posedge clk) begin
    if(!reset_n) begin
         bit_cnt <= 3'd0;
        shift_reg <= 8'd0;
        tx_fifo_rd_en <= 1'b0;
        tx_data_out <= 1'd1;
    end
    
    else begin 
        case(curr_state) 
            IDLE : begin
                 bit_cnt <= 8'd0;
                 tx_data_out <= 1'd1;
                if(!tx_fifo_empty) begin
                    tx_fifo_rd_en <= 1'b1;
                  
                  /*if(!tx_fifo_empty ) begin
                    tx_fifo_rd_en <= 1'b1;*/
                    
                end
            end
            
           /* TEMP : begin
                //steup time
            end*/
            
            LOAD : begin
                shift_reg <= tx_data_in;
                tx_fifo_rd_en <= 1'b0;
            end
                
            
            START : begin
                   shift_reg <= tx_data_in;
                  tx_data_out <= 1'b0;
                  tx_fifo_rd_en <= 1'b0;
                 
            end 
            
            DATA : begin 
                 tx_fifo_rd_en <= 1'b0;
                tx_data_out <= shift_reg[0];
                if(baud_tick)begin
                     bit_cnt <= bit_cnt + 1'b1;
                     shift_reg <= shift_reg >> 1;
                 end
             end
             
             STOP : begin
                 tx_fifo_rd_en <= 1'b0;
                 tx_data_out <= 1'b1;
             end
             
         endcase
     end
 end
             
             
property tx_done_check;
    @(posedge clk)  disable iff(!reset_n)
    (tx_done) |=> !(tx_done)
endproperty

property start_state_data_out;
    @(posedge clk) disable iff(!reset_n)
    (curr_state == START) |-> !(tx_data_out)
endproperty

property stop_state_data_out;
    @(posedge clk) disable iff(!reset_n)
    (curr_state == STOP) |-> (tx_data_out)
endproperty


assert property(tx_done_check)   
    else $error("Tx_done not one for one event");
    
 assert property(start_state_data_out)   
    else $error("tx_data_out not 0 for that clk cycle");
 
 assert property(stop_state_data_out)   
    else $error("tx_data_out not 1 for that clk cycle");
    
    
             
        
        
   

endmodule
