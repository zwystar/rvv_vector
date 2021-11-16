module dp_stage
  #( ) (
    input              clk,
    input              rst_n,
    //with dec 
    input  logic       dec_req_valid,
    output logic       dec_req_ready,
    input  dec_req_t   dec_req,
    //with exu
    input  logic       alu_resp_vd_valid,
    input  logic       alu_resp_vs_valid,
    input  logic [2:0] alu_resp_id,
    input  logic       mac_resp_vd_valid,
    input  logic       mac_resp_vs_valid,
    input  logic [2:0] mac_resp_id,
    input  logic       vld_resp_vd_valid,
    input  logic       vld_resp_vs_valid,
    input  logic [2:0] vld_resp_id,
    input  logic       vst_resp_vd_valid,
    input  logic       vst_resp_vs_valid,
    input  logic [2:0] vst_resp_id,
    input  logic       msk_resp_vd_valid,
    input  logic       msk_resp_vs_valid,
    input  logic [2:0] msk_resp_id,
    input  logic       sld_resp_vd_valid,
    input  logic       sld_resp_vs_valid,
    input  logic [2:0] sld_resp_id,
    //with is_stage
    input  logic       alu_req_ready,
    output logic       alu_req_valid,
    input  logic       mac_req_ready,
    output logic       mac_req_valid,
    input  logic       ld_req_ready,
    output logic       ld_req_valid,
    input  logic       st_req_ready,
    output logic       st_req_valid,
    input  logic       msk_req_ready,
    output logic       msk_req_valid,
    input  logic       sld_req_ready,
    output logic       sld_req_valid,
    output dec_req_t   dp_req
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
  end
  ////////////////////////////////////////////////////////
  //issue
  ////////////////////////////////////////////////////////
  always_comb begin
    
    
  end
  
  
  
  
  
  
  
    genvar ii;
  /////////////////////////////////////////////////////////////////////////////////////////////////
  //score board req write
  /////////////////////////////////////////////////////////////////////////////////////////////////
    
    //the insn can issue when nRAW & nWAW & nWAW
    // nRAW : dp.chaning[i] && scb_q[i].issue or (dp.raw[i] ? scb_q[i].vd_wr : 1'b1)
    // nWAW : (dp.waw[i] ? scb_q[i].vd_wr : 1'b1)
    // nWAR : (dp.war[i] ? scb_q[i].vs_rd : 1'b1)

    typedef struct packed {
      logic            valid;
      logic [SN-1:0]   age;

      logic [SN-1:0]   byp;
      logic [SN-1:0]   raw;//
      logic [SN-1:0]   waw;
      logic [SN-1:0]   war;
      logic            issue;
      logic [31:0]     vs_ohot;
      logic [31:0]     vd_ohot;
      dec_req_t        req;
    } scb_t;
  
  logic [SN-1:0] scb_valid_q;
  logic [SN-1:0] scb_sel_d;
  scb_t [SN-1:0] scb_q;
  scb_t scb_d;
  
  
  
  for(ii=0;ii<SN;ii++)begin
    always @(posedge clk or negedge rst_n)begin
      if(!rst_n)begin
        scb_q[ii] <= '0;
      end
      else if(dec_req_valid & dec_req_ready & scb_sel_d[ii])begin
        scb_q[ii] <= scb_d;
      end
    end
    assign scb_valid[ii] = scb_q[ii].valid;
  end

  always_comb begin
    dec_req_ready = ~&scb_valid;
    scb_sel_d     = (~scb_valid_q) & (scb_valid_q+1'b1);
    
    scb_d         = '0;
    scb_d.age     = scb_valid;
    scb_d.req     = dec_req;
    scb_d.valid   = 1'b1;
    for(int i=0;i<SN;i++)begin
      for(int j=0;j<SN;j++)begin
          scb_d.raw[i] = (|(scb_d.vs_ohot & scb_q[j].vd_ohot)) & scb_d.age[j];//
          scb_d.waw[i] = (|(scb_d.vd_ohot & scb_q[j].vd_ohot)) & scb_d.age[j];//
          scb_d.war[i] = (|(scb_d.vd_ohot & scb_q[j].vs_ohot)) & scb_d.age[j];//
          scb_d.byp[i] = scb_d.req.nblk & scb_q[j].req.nblk;//
      end
    end
    
  end

  logic [SN-1:0][SN-1:0] age_dp,age_cur;
  always_comb begin
    age_next = age_cur;

  end

  ///////////////////////////////////////////////////////////////////////////////////
  //sel the no hzd
  ///////////////////////////////////////////////////////////////////////////////////
  logic [SN-1:0] hzd_ohot;
  logic [SN-1:0][SN-1:0] age_tmp;
  logic [DP_ID_WIDTH-1:0] older_nhzd_id;
  always_comb begin
    age_tmp = age_scb;
    for(int i=0;i<SN;i++)begin
      hzd_ohot[i] = ((|scb_q[i].raw) | (|scb_q[i].waw) | (|scb_q[i].war) | (scb_q[i].issue==1'b0);

      if((scb_q[i].req.fu==ALU) & (alu_req_empty==1'b0)) hzd_ohot[i] = 1'b1;
      if((scb_q[i].req.fu==MAC) & (alu_req_empty==1'b0)) hzd_ohot[i] = 1'b1;
      if((scb_q[i].req.fu==SLD) & (alu_req_empty==1'b0)) hzd_ohot[i] = 1'b1;
      if((scb_q[i].req.fu==LD ) & (alu_req_empty==1'b0)) hzd_ohot[i] = 1'b1;
      if((scb_q[i].req.fu==ST ) & (alu_req_empty==1'b0)) hzd_ohot[i] = 1'b1;
      if((scb_q[i].req.fu==MSK) & (alu_req_empty==1'b0)) hzd_ohot[i] = 1'b1;

      if(hzd_ohot[i])begin
        for(int j=0;j<SN;j++)begin
          age_tmp[j][i] = (j==i);
        end
      end
    end

    older_nhzd_id = '0;
    for(int j=0;j<SN;j++)begin
        if(age_tmp[j] == 'd0) older_nhzd_id = j;
    end

    alu_req_wr = (scb_q[older_nhzd_id].req.fu==ALU) & (|hzd_ohot);
    mac_req_wr = (scb_q[older_nhzd_id].req.fu==MAC) & (|hzd_ohot);
    ld_req_wr  = (scb_q[older_nhzd_id].req.fu==SLD) & (|hzd_ohot);
    st_req_wr  = (scb_q[older_nhzd_id].req.fu==LD ) & (|hzd_ohot);
    msk_req_wr = (scb_q[older_nhzd_id].req.fu==ST ) & (|hzd_ohot);
    sld_req_wr = (scb_q[older_nhzd_id].req.fu==MSK) & (|hzd_ohot);
    dp_req     = (scb_q[older_nhzd_id].req;

  end
  ///////////////////////////////////////////////////////////////////////////////////
  //age updata
  ///////////////////////////////////////////////////////////////////////////////////


endmodule
