module #()
  (
    input             clk,
    input             rst_n,
    //with dec
    input  logic      dec_req_valid,
    output logic      dec_req_ready,
    input  dec_req_t  dec_req,
    //with sca
    output logic      sca_resp_valid,
    input  logic      sca_resp_ready,
    output sca_resp_t sca_resp,
    //with exu
    input  logic      lane_resp_valid,
    input  exu_resp_t lane_resp,
    input  logic      vldu_resp_valid,
    input  exu_resp_t vldu_resp,
    input  logic      vstu_resp_valid,
    input  exu_resp_t vstu_resp,
    input  logic      msk_resp_valid,
    input  exu_resp_t msk_resp,
    input  logic      vsld_resp_valid,
    input  exu_resp_t vsld_resp,
    //with rd
    output logic      dp_req_valid,
    //input  logic      dp_req_ready,
    input  dec_req_t  dp_req
  );
  
    localparam SN = 8;
  
    genvar ii;
  /////////////////////////////////////////////////////////////////////////////////////////////////
  //score board req write
  /////////////////////////////////////////////////////////////////////////////////////////////////
    typedef struct packed {
      logic [4:0]      issue;
      logic [SN-1:0]   age;
      logic            commit;
      logic [XLEN-1:0] result;
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
  end
  always_comb begin
    dec_req_ready = &scb_valid;
    scb_sel_d = (~scb_valid_q) & (scb_valid_q+1'b1);
    
    scb_d = '0;
    scb_d.age = scb_valid;
    scb_d.req = dec_req;
    case(dec_req.sew_type)
      'd0 : scb_d.issue = (dec_req.lmul+1'b1);
      'd1 : scb_d.issue = (dec_req.lmul+1'b1)*2;
      'd2 : scb_d.issue = (dec_req.lmul+1'b1)*2;
      'd3 : scb_d.issue = (dec_req.lmul+1'b1)*2;
      default : scb_d.issue = (dec_req.lmul+1'b1);
    endcase
    
  end
  
  logic [31:0] vd_busy;//long exu will updata the hzd,set 1
  
  ///////////////////////////////////////////////////////////////////////////////////
  //sel the no hzd
  ///////////////////////////////////////////////////////////////////////////////////
  
  logic [SN-1:0] scb_issue_d;
  always_comb begin
    for(int i=0;i<SN;i++)begin
      for(int j=0;j<SN;j++)begin
        if(i!=j)begin
          if(scb_q[i].age[j] & scb_valid_q[j])begin
            scb_issue_d[i] = 
            |(scb_q[i].use_vd_ohot & scb_q[j].use_vd_ohot) || //waw
            |(scb_q[i].use_vs1_ohot & scb_q[j].use_vd_ohot) || //raw
            
            |(scb_q[j].use_vs1_ohot & scb_q[i].use_vd_ohot) || //war
            ;
          end
        end
      end
    end
  end
 
  function logic func_hzd(scb_t a,scb_t b)
    logic waw_hzd,raw_hzd,war;
    
    waw_hzd = a.req.use_vd_ohot & b.req.use_vd_ohot;
    
  endfunction
  
endmodule
