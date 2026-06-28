`timescale 1ns / 1ps

import uart_pkg::*;

module cpu_tb ();

logic clk;
logic reset_n;
logic start;
logic [31:0] PADDR;
logic [31:0] PWDATA;
logic PSEL;
logic PENABLE;
logic PWRITE;
logic [31:0]PRDATA;
logic irq;

uart_top uart_top_1 (clk,reset_n,start,PADDR,PWDATA,PSEL,PENABLE,PWRITE,PRDATA,irq);

initial begin
    {clk,reset_n,start,PSEL,PENABLE,PWRITE} = 1'b0;
    {PADDR,PWDATA} = 32'd0;
end
  
initial forever #100 clk = ~clk; 

task automatic apb_write(
    input [31:0] addr,
    input [31:0] data
);
begin
    @(negedge clk)
    PSEL = 1;
    
    @(negedge clk)
    PENABLE = 1;
    PADDR = addr;
    PWDATA = data;
    
    @(negedge clk)
    PWRITE = 1;
    
    @(negedge clk)
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
end
endtask

initial begin
    @(negedge clk)
    reset_n = 0;
    
    
    repeat(5) @(negedge clk)
    reset_n = 1;
      
    apb_write(CONTROL_REG_ADDR,32'd255);
    apb_write(BAUD_REG_ADDR,32'd9600);
    apb_write(TX_DATA_REG_ADDR,32'd127);
    
    @(negedge clk)
    start = 1'b1;
    
    apb_write(TX_DATA_REG_ADDR,32'd123);
    
    apb_write(TX_DATA_REG_ADDR,32'd125);
    
    apb_write(TX_DATA_REG_ADDR,32'd168);
    
    apb_write(TX_DATA_REG_ADDR,32'd148);
    
    apb_write(TX_DATA_REG_ADDR,32'd103);
    
   /* @(negedge clk)
    PSEL = 1;
    
    @(negedge clk)
    PENABLE = 1;
    PADDR = CONTROL_REG_ADDR;
    PWDATA = 32'd255;
    
    @(negedge clk)
    PWRITE = 1;
    
    @(negedge clk)
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    
    @(negedge clk)
    PSEL = 1;
    
    @(negedge clk)
    PENABLE = 1;
    PADDR = BAUD_REG_ADDR;
    PWDATA = 32'd9600;
    
    @(negedge clk)
    PWRITE = 1;
    
    @(negedge clk)
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;
    
    @(negedge clk)
    PSEL = 1;
    
    @(negedge clk)
    PENABLE = 1;
    PADDR = TX_DATA_REG_ADDR;
    PWDATA = 32'd2;
    
    @(negedge clk)
    PWRITE = 1;
    
    @(negedge clk)
    PSEL = 0;
    PENABLE = 0;
    PWRITE = 0;*/
    
   
    
    
end
endmodule
