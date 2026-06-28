
import uart_pkg::*;

module uart_top(
input clk,
input reset_n,
input start,
input [31:0] PADDR,
input [31:0] PWDATA,
input PSEL,
input PENABLE,
input PWRITE,
output logic [31:0]PRDATA,
output logic irq
);

logic [20:0] baud_rate_reg;
logic baud_tick_half;
logic baud_tick;
logic [7:0] control_reg;
logic [7:0] status_reg;
logic tx_wrt_en;
logic tx_rd_en;
logic [7:0] tx_data_reg;
logic tx_underflow;
logic [7:0] tx_fifo_data_output;
logic  tx_data_out;
logic rx_fifo_wrt_en;
logic [7:0] rx_data;
logic [7:0] rx_data_out;
logic rx_rd_en;

logic tx_done;
logic rx_done;
logic tx_fifo_empty;
logic tx_fifo_full;
logic rx_fifo_empty;
logic rx_fifo_full;
logic tx_fifo_overflow;
logic rx_fifo_overflow;


assign status_reg[0] = tx_done;
assign status_reg[1] = rx_done;
assign status_reg[2] = tx_fifo_empty;
assign status_reg[3] = tx_fifo_full;
assign status_reg[4] = rx_fifo_empty;
assign status_reg[5] = rx_fifo_full;
assign status_reg[6] = tx_fifo_overflow;
assign status_reg[7] = rx_fifo_overflow;

baud_rate br (clk,reset_n,start,baud_rate_reg,baud_tick_half,baud_tick);

interrupt it (control_reg[0],control_reg[1],control_reg[2],control_reg[3],control_reg[4],control_reg[5],control_reg[6],control_reg[7],
              tx_done,rx_done,tx_fifo_empty,tx_fifo_full,rx_fifo_empty,rx_fifo_full,tx_fifo_overflow,rx_fifo_overflow,irq);

tx_fifo tx_fifo_1 (clk,reset_n,tx_wrt_en,tx_rd_en,tx_data_reg,tx_fifo_empty,tx_fifo_full,tx_fifo_overflow,tx_underflow,tx_fifo_data_output);

tx tx_1 (clk,reset_n,start,baud_tick,baud_tick_half,tx_fifo_empty,tx_fifo_data_output,tx_rd_en,tx_done,tx_data_out);

rx rx_1 (clk,reset_n,baud_tick_half,baud_tick,tx_data_out,rx_fifo_full,rx_done,rx_fifo_wrt_en,rx_data);

rx_fifo rx_fifo (clk,reset_n,rx_fifo_wrt_en,rx_rd_en,rx_data,rx_fifo_empty,rx_fifo_full,rx_fifo_overflow,rx_fifo_overflow,rx_data_out);

uart_wrapper uart_wrapper_1 (clk,reset_n,PADDR,PWDATA,PSEL,PENABLE,PWRITE,status_reg,rx_data_out,tx_data_reg,control_reg,baud_rate_reg,tx_wrt_en,rx_rd_en,PRDATA);


endmodule
