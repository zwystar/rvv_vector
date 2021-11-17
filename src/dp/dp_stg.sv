module dp_stage
  #( ) (
    input  logic                    clk,
    input  logic                    rst_n,
    //with dec 
    input  logic                    dec_req_valid,
    output logic                    dec_req_ready,
    input  dec_req_t                dec_req,
    //with exu
    input  logic [FUN_NUM-1:0]      fu_resp_vd_wr,
    input  logic [FUN_NUM-1:0]      fu_resp_vs_wr,
    input  logic [FUN_NUM-1:0][2:0] fu_resp_vd_id,
    input  logic [FUN_NUM-1:0][2:0] fu_resp_vs_id,
    //with is_stage
    input  logic [FUN_NUM-1:0]      fu_req_busy,
    output logic [FUN_NUM-1:0]      fu_req_wr,
    output dec_req_t                fu_req
  );
  
    localparam SN = 8;
  
    typedef struct packed {
      logic [SN-1:0]           valid;
      logic [SN-1:0][SN-1:0]   age;
      
      logic [SN-1:0][SN-1:0]   raw;
      logic [SN-1:0][SN-1:0]   waw;
      logic [SN-1:0][SN-1:0]   war;
      logic [SN-1:0][SN-1:0]   vm_war;//dp will updata to 0
      
      logic [SN-1:0][SN-1:0]   raw_nblk;//1 can clear the raw when the hzd insn dp
      logic [SN-1:0][SN-1:0]   waw_nblk;
      logic [SN-1:0][SN-1:0]   war_nblk;
      
      logic [SN-1:0]           vd_st;//1 wait vd write back
      logic [SN-1:0]           vs_st;//1 wait vs read
      logic [SN-1:0]           dp_st;//1 wait disp
      dec_req_t [SN-1:0]       req;
    } scb_t;
  logic [SN-1:0] scb_st;
  ////////////////////////////////////////////////////////
  //define
  ////////////////////////////////////////////////////////
  
  scb_t scb_dec_cur,scb_dec_next;
  logic [2:0] scb_dec_id;
  logic [SN-1:0] dec_vs1_raw,dec_vs2_raw,dec_vd_raw,dec_vm_raw,dec_vd_waw,dec_vs1_war,dec_vs2_war,dec_vd_war,dec_vm_war,dec_raw_nblk,dec_waw_nblk,dec_war_nblk;
  logic dec_ok;
    
  scb_t scb_iss_cur,scb_iss_next;
  logic [2:0] older_nhzd_id;
  logic [SN-1:0] scb_iss_hzd;
  logic [SN-1:0][SN-1:0] iss_age;
  logic                  iss_ok;
  
  scb_t scb_vs_cur,scb_vs_next;
  logic vs_resp_ok;
  
  scb_t scb_vd_cur,scb_vd_next;
  logic vd_resp_ok;
  ////////////////////////////////////////////////////////
  //dec->scb LOGIC
  ////////////////////////////////////////////////////////
  always_comb begin
      dec_req_ready =~&scb_dec_cur.vd_st;
      scb_dec_id = (~scb_dec_cur.vd_st) & (scb_dec_cur.vd_st+1'b1);
      
      for(int i=0;i<SN;i++)begin
        dec_vs1_raw[i] = dec_req.use_vs1 & scb_dec_cur.vd_st[i] & (~(dec_req.vs1>scb_dec_cur.req[i].vd_end)|(dec_req.vs1_end<scb_dec_cur.req[i].vd)));
        dec_vs2_raw[i] = dec_req.use_vs2 & scb_dec_cur.vd_st[i] & (~(dec_req.vs2>scb_dec_cur.req[i].vd_end)|(dec_req.vs2_end<scb_dec_cur.req[i].vd)));
        dec_vd_raw [i] = dec_req.use_vd  & scb_dec_cur.vd_st[i] & (~(dec_req.vd >scb_dec_cur.req[i].vd_end)|(dec_req.vd_end <scb_dec_cur.req[i].vd)));
        dec_vm_raw [i] = dec_req.vm & scb_dec_cur.vd_st[i] & (scb_dec_cur.req.vd[i]=='d0);
        
        dec_vd_waw [i] = dec_req.wr_vd & scb_dec_cur.vd_st[i] & (~(dec_req.vd >scb_dec_cur.req[i].vd_end)|(dec_req.vd_end <scb_dec_cur.req[i].vd)));
        
        dec_vs1_war[i] = scb_dec_cur.vs_st[i] & dec_req.wr_vd & (~(dec_req.vd >scb_dec_cur.req[i].vs1_end)|(dec_req.vd_end <scb_dec_cur.req[i].vs1)));
        dec_vs2_war[i] = scb_dec_cur.vs_st[i] & dec_req.wr_vd & (~(dec_req.vd >scb_dec_cur.req[i].vs2_end)|(dec_req.vd_end <scb_dec_cur.req[i].vs2)));
        dec_vd_war [i] = scb_dec_cur.vs_st[i] & dec_req.wr_vd & (~(dec_req.vd >scb_dec_cur.req[i].vd_end )|(dec_req.vd_end <scb_dec_cur.req[i].vd)));
        dec_vm_war [i] = scb_dec_cur.dp_st[i] & dec_req.wr_vd & scb_dec_cur.req[i].vm & (dec_req.vd=='d0);
        
        dec_raw_nblk[i]= dec_req.nblk & scb_dec_cur.req[i].nblk & (dec_req.lmul==scb_dec_cur.req[i].lmul) & 
          (dec_vs1_raw[i] ? (dec_req.vs1_sew==scb_dec_cur.req[i].vd_sew):1'b0) &
          (dec_vs2_raw[i] ? (dec_req.vs2_sew==scb_dec_cur.req[i].vd_sew):1'b0) &
          (dec_vd_raw [i] ? (dec_req.vd_sew ==scb_dec_cur.req[i].vd_sew):1'b0) ;
        dec_waw_nblk[i]= dec_req.nblk & scb_dec_cur.req[i].nblk & (dec_req.lmul==scb_dec_cur.req[i].lmul) & (dec_req.vd_sew==scb_dec_cur.req[i].vd_sew);
        dec_war_nblk[i]= dec_req.nblk & scb_dec_cur.req[i].nblk & (dec_req.lmul==scb_dec_cur.req[i].lmul) & 
          (dec_vs1_war[i] ? (dec_req.vd_sew==scb_dec_cur.req[i].vs1_sew):1'b0) &
          (dec_vs2_war[i] ? (dec_req.vd_sew==scb_dec_cur.req[i].vs2_sew):1'b0) &
          (dec_vd_war[i]  ? (dec_req.vd_sew==scb_dec_cur.req[i].vd_sew):1'b0) ;
      end
      
      scb_dec_next = scb_dec_cur;
      scb_dec_next.valid[scb_dec_id] = 1'b1;
      scb_dec_next.age[scb_dec_id] = scb_dec_cur.valid;
      scb_dec_next.raw[scb_dec_id] = dec_vs1_raw | dec_vs2_raw | dec_vd_raw | dec_vm_raw;
      scb_dec_next.waw[scb_dec_id] = dec_vd_waw;
      scb_dec_next.war[scb_dec_id] = dec_vs1_war | dec_vs2_war | dec_vd_war | dec_vm_war;
      scb_dec_next.raw_nblk[scb_dec_id] = dec_raw_nblk;
      scb_dec_next.waw_nblk[scb_dec_id] = dec_waw_nblk;
      scb_dec_next.war_nblk[scb_dec_id] = dec_war_nblk;
      scb_dec_next.vd_st[scb_dec_id] = dec_req.wr_vd;
      scb_dec_next.vs_st[scb_dec_id] = 1'b1;
      scb_dec_next.dp_st[scb_dec_id] = 1'b1;
      scb_dec_next.req[scb_dec_id] = dec_req;
    
      dec_ok = dec_req_ready & dec_req_valid;
  end
  ////////////////////////////////////////////////////////
  //issue
  ////////////////////////////////////////////////////////
  always_comb begin
    iss_age = scb_iss_cur.age;
    //sel no hzd
    for(int i=0;i<SN;i++)begin
      scb_iss_hzd[i] = |scb_iss_cur.raw[i];
      scb_iss_hzd[i] = |scb_iss_cur.waw[i];
      scb_iss_hzd[i] = |scb_iss_cur.war[i];
      scb_iss_hzd[i] = |(scb_iss_cur.req[i].fu & fu_req_busy);//struct hzd
      
      if(scb_iss_hzd[i])begin
          for(int j=0;j<SN;j++)begin
          iss_age[j][i] = (j==i);
          end
        end
    end
    
    older_nhzd_id = '0;
    for(int j=0;j<SN;j++)begin
        if(iss_age[j] == 'd0) older_nhzd_id = j;
    end
    iss_ok = &scb_iss_hzd;
    fu_req_wr = scb_iss_cur.req[older_nhzd_id].fu & {FU_NUM{iss_ok}};
    //updata scb
    scb_iss_next = scb_iss_cur;
    scb_iss_next.dp_st[older_nhzd_id] = 1'b0;
    for(int i=0;i<SN;i++)begin
      if(scb_iss_cur.raw_nblk[i][older_nhzd_id])begin
        scb_iss_next.raw[i][older_nhzd_id] = 1'b0;
      end
      if(scb_iss_cur.waw_nblk[i][older_nhzd_id])begin
        scb_iss_next.waw[i][older_nhzd_id] = 1'b0;
      end
      if(scb_iss_cur.war_nblk[i][older_nhzd_id])begin
        scb_iss_next.war[i][older_nhzd_id] = 1'b0;
      end
      scb_iss_next.vm_war[i][older_nhzd_id] = 1'b0;
    end
  end
  ////////////////////////////////////////////////////////
  //vs resp
  ////////////////////////////////////////////////////////
  always_comb begin
    scb_vs_next = scb_vs_cur;
    for(int i=0;i<FU_NUM;i++)begin
      if(fu_vs_resp[i])begin
        scb_vs_next.vs_st[fu_vs_resp_id[i]] = 1'b0;
        scb_vs_next.war[i][fu_vs_resp_id[i]] = 1'b0;
      end
    end
    vs_resp_ok = |fu_vs_resp;
  end
  ////////////////////////////////////////////////////////
  //vd resp
  ////////////////////////////////////////////////////////
  always_comb begin
    scb_vd_next = scb_vd_cur;
    for(int i=0;i<FU_NUM;i++)begin
      if(fu_vd_resp[i])begin
        scb_vd_next.vd_st[fu_vd_resp_id[i]] = 1'b0;
        scb_vd_next.raw[i][fu_vd_resp_id[i]] = 1'b0;
        scb_vd_next.waw[i][fu_vd_resp_id[i]] = 1'b0;
        scb_vd_next.valid[i][fu_vd_resp_id[i]] = 1'b0;
      end
    end
    vd_resp_ok = |fu_vd_resp;
  end
  ////////////////////////////////////////////////////////
  //scb updata
  ////////////////////////////////////////////////////////
  logic scb_ok;
  always_comb begin
    scb_vd_cur = scb_q;
    scb_d = scb_q;
    if(vd_resp_ok)begin
      scb_d = scb_vd_next;
      scb_ok = 1'b1;
    end
    scb_vs_cur = scb_q;
    if(vs_resp_ok)begin
      scb_d = scb_vs_next;
      scb_ok = 1'b1;
    end
    scb_iss_cur = scb_q;
    if(iss_ok)begin
      scb_d = scb_iss_next;
      scb_ok = 1'b1;
    end
    scb_dec_cur = scb_q;
    if(dec_ok)begin
      scb_d = scb_dec_next;
      scb_ok = 1'b1;
    end
  end
  
  always_ff@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        scb_q <= '0;
    else if(scb_ok)
      scb_q <= scb_d;
  end
  

endmodule
