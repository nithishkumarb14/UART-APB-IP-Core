package uart_pkg;

    localparam logic [31:0] CONTROL_REG_ADDR = 32'h0000_0000;
    localparam logic [31:0] STATUS_REG_ADDR  = 32'h0000_0004;
    localparam logic [31:0] BAUD_REG_ADDR    = 32'h0000_0008;
    localparam logic [31:0] TX_DATA_REG_ADDR = 32'h0000_000C;
    localparam logic [31:0] RX_DATA_REG_ADDR = 32'h0000_0010;

endpackage
