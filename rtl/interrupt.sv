`timescale 1ns / 1ps


module interrupt
(
input tx_done_en,
input rx_done_en,
input tx_fifo_emp_en,
input tx_fifo_full_en,
input rx_fifo_emp_en,
input rx_fifo_full_en,
input tx_fifo_overflow_en,
input rx_fifo_overflow_en,
input tx_done,
input rx_done,
input tx_fifo_emp,
input tx_fifo_full,
input rx_fifo_emp,
input rx_fifo_full,
input tx_fifo_overflow,
input rx_fifo_overflow,
output logic irq
);

always_comb begin
        
    if((tx_done_en && tx_done) || (rx_done_en && rx_done) || (tx_fifo_emp_en && tx_fifo_emp) || (tx_fifo_full_en && tx_fifo_full) || (rx_fifo_emp_en && rx_fifo_emp)||
        (rx_fifo_full_en && rx_fifo_full) || (tx_done_en && tx_done) || (rx_done_en && rx_done) || (tx_fifo_overflow_en && tx_fifo_overflow) || (rx_fifo_overflow_en && rx_fifo_overflow))   
        irq = 1'b1;
    else
        irq = 1'b0;
     

 end     
      
endmodule
