import uart_pkg::*;

module uart_wrapper
(
input clk,
input reset_n,
input [31:0] PADDR,
input [31:0] PWDATA,
input PSEL,
input PENABLE,
input PWRITE,
input logic [7:0] status_reg,
input logic [7:0] rx_fifo_data_output,
output logic [7:0] tx_data_reg,
output logic [7:0] control_reg,
output logic [20:0] baud_rate_reg,
output logic tx_wrt_en,
output logic rx_rd_en,
//output logic PREADY,
output logic [31:0]PRDATA
 );
 


 
 typedef enum logic [1:0]{
        IDLE = 2'b00,
        SETUP = 2'b01,
        ACCESS = 2'b10
} state_t;

state_t curr_state,next_state;


always_ff @(posedge clk) begin 
    if(!reset_n) 
        curr_state <= IDLE;
    else
        curr_state <= next_state;
 end
 
 always_comb begin 
    case(curr_state)
        IDLE : begin
           // PREADY = 1'b0;
            if(PSEL)
                next_state = SETUP;
             else
                next_state = IDLE;
        end
        
        SETUP : begin 
            //PREADY = 1'b0;
            if(PSEL && PENABLE)
                next_state = ACCESS;
            else if(PSEL && !PENABLE)
                next_state = SETUP;
            else 
               next_state = IDLE;
         end
         
         ACCESS : begin
               // PREADY = 1'b1;
                next_state = IDLE;
         end
         
         default : next_state = IDLE;
    endcase
 end
 
 
 always_ff @(posedge clk) begin
    if(!reset_n) begin
        control_reg <= 8'd0;
        baud_rate_reg <= 8'd0;
        tx_data_reg <= 8'd0;
        tx_wrt_en <= 1'b0;
        rx_rd_en <= 1'b0;
        PRDATA <= 32'd0; 
    end
    
    
    else begin
        case(curr_state) 
            IDLE : begin
                tx_wrt_en <= 1'b0;
                rx_rd_en <= 1'b0;
            end
            
            SETUP : begin
               // for set up time
            end
            
            ACCESS : begin
                if(PWRITE) begin 
                    if(PADDR == CONTROL_REG_ADDR)
                        control_reg <= PWDATA[7:0];
                        
                    else if(PADDR == BAUD_REG_ADDR)
                        baud_rate_reg <= PWDATA[21:0];
                        
                    else if(PADDR == TX_DATA_REG_ADDR) begin
                       tx_wrt_en <= 1'b1;
                       tx_data_reg <= PWDATA[7:0];
                    end    
                end
                
                else  begin
                    if(PADDR == STATUS_REG_ADDR) begin
                        PRDATA[7:0] <= status_reg[7:0];
                        PRDATA[31:8] <= 24'd0;
                     end
                     
                    else if(PADDR == RX_DATA_REG_ADDR) begin
                        rx_rd_en <= 1'b1;
                        PRDATA[7:0] <= rx_fifo_data_output[7:0];
                        PRDATA[31:8] <= 24'd0;
                    end
                    
                    else
                       PRDATA <= 32'd0; 
              end         
         end
       endcase
      end 
    end 
endmodule
