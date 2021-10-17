module vec_vrf #(
    parameter WPORT = 4,
    parameter RPORT = 4,
    parameter XLEN  = 512
) (
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

reg [31:0][XLEN-1:0] vrf_ram;

for(int j=0;j<XLEN;j++)begin

for(int i=0;i<WPORT;i++)begin

always @(posedge clk or negedge rst_n) begin : proc_wr
    if(~rst_n) begin
        vrf_ram <= '0;
    end else if(wr_en[i]&wr_be[i][j]) begin
        vrf_ram[wr_addr[i]] <= wr_data[i];
    end
end

end
end

////////////////////////////////////////////////////////////////////
// just forward the one cycle exe instruction,and it must be the write port 0
logic [RPORT-1:0] forward_flg;

always_comb begin : proc_bypass
    forward_flg = '0;
    for(int i=0;i<RPORT;i++)begin
        if(wr_en[0] & (wr_addr[0]==rd_addr[i]))begin
            forward_flg[i] = 1'b1;
        end
    end
end

for(int i=0;i<RPORT;i++)begin
always @(posedge clk or negedge rst_n) begin : proc_rd
    if(~rst_n) begin
        rd_data[i] <= '0;
    end else if(rd_en[i]) begin
        rd_data[i] <= forward_flg[i] ? wr_data[0] : vrf_ram[rd_addr[i]];
    end
end
end

endmodule
