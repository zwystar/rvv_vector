module vec_vrf #(
    parameter WPORT = 4,
    parameter RPORT = 4,
    parameter XLEN  = 512
) (
    input  clk,
    input  rst_n,
    
    input  [WPORT-1:0] wr_en，
    input  [WPORT-1:0][XLEN-1:0] wr_be,
    input  [WPORT-1:0][5-1:0] wr_addr,
    input  [WPORT-1:0][XLEN-1:0] wr_data,
    
    input  [RPORT-1:0] rd_en,
    input  [RPORT-1:0][5-1:0] rd_addr,
    output [RPORT-1:0][XLEN-1:0] rd_data
);

genvar ii,kk,jj;

logic [31:0][XLEN-1:0] vrf_ram;
logic [31:0][XLEN-1:0] vrf_ram_next;
logic [31:0][XLEN-1:0] vrf_ram_wr;
    
always_comb begin
    vrf_ram_next = '0;
    vrf_ram_wr = '0;
    for(int k=0;k<XLEN;k++)
        for(int i=0;i<32;i++)
            for(int j=0;j<WPORT;j++)begin
                if(wr_en[j] & wr_be[k] & (wr_addr[j]==j[5-1:0]))begin
                    vrf_ram_next[i][k] = wr_data[j][k];
                    vrf_ram_wr[i][k] = 1'b1;
                end
            end
end
    
for(kk=0;kk<XLEN;kk++)
for(ii=0;ii<32;ii++)begin    
    
always @(posedge clk or negedge rst_n) begin : proc_wr
    if(~rst_n) begin
        vrf_ram[ii][kk] <= '0;
    end else if(vrf_ram_wr[ii][kk]) begin
        vrf_ram[ii][kk] <= vrf_ram_next[ii][kk];
    end
end

end

////////////////////////////////////////////////////////////////////
// just forward the one cycle exe instruction,and it must be the write port 0
logic [RPORT-1:0][XLEN-1:0]  forward_flg;

always_comb begin : proc_bypass
    forward_flg = '0;
    for(int k=0;k<XLEN;k++)
    for(int i=0;i<RPORT;i++)begin
        if(wr_en[0] & (wr_addr[0]==rd_addr[i]) & wr_be[0][k])begin
            forward_flg[i][k] = 1'b1;
        end
    end
end
    

for(ii=0;ii<RPORT;ii++)begin
    
always @(posedge clk or negedge rst_n) begin : proc_rd
    if(~rst_n) begin
        rd_data[ii] <= '0;
    end else if(rd_en[ii]) begin
        for(int k=0;k<XLEN;k++)begin
            rd_data[ii][k] <= forward_flg[ii][k] ? wr_data[0][k] : vrf_ram[rd_addr[ii]][k];
        end
    end
end
    
end

endmodule
