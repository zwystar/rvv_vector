package vec_pkg;
    localparam INSTR_BITS = 32;
    localparam XLEN = 32;
    localparam VLEN = 512;
    localparam ELEN = 32; 
    // ----------------------
    // Accelerator Interface
    // ----------------------

    typedef struct packed {
      logic [INSTR_BITS-1:0]      instr;
      logic [XLEN-1:0]            rs1;
      logic [XLEN-1:0]            rs2;
      logic [TRANS_ID_BITS-1:0]   instr_id;
    } sca_req_t;

    typedef struct packed {
      logic                       err;
      logic [XLEN-1:0]            res;
      logic [TRANS_ID_BITS-1:0]   instr_id;
    } sca_resp_t;
    // ----------------------
    // dec Interface
    // ----------------------

endpackage
