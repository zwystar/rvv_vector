module vec_dec
(
    input  clk,    // Clock
    input  clk_en, // Clock Enable
    input  rst_n,  // Asynchronous reset active low
    
    input  [WPORT-1:0] wr_en，
    input  [WPORT-1:0][XLEN-1:0] wr_be,
    input  [WPORT-1:0][5-1:0] wr_addr,
    input  [WPORT-1:0][XLEN-1:0] wr_data,
    
    input  [RPORT-1:0] rd_en,
    input  [RPORT-1:0][5-1:0] rd_addr,
    output [RPORT-1:0][XLEN-1:0] rd_data,
);



endmodule
