package vec_pkg;
    localparam INSTR_BITS = 32;
    localparam XLEN = 32;
    localparam VLEN = 512;
    localparam ELEN = 32; 
    
    // ----------------------
    // fu op
    // ----------------------
    
    //support all 109 op for fu
    typedef enum logic [6:0] {
        VADD, VSUB, VRSUB, 
        VWADDU, VWSUBU, VWADD, VWSUB, 
        VZEXT, VSEXT,
        VADC, VMADC, VSBC, VMSBC,
        VAND, VOR, VXOR,
        VSLL, VSRL, VSRA,
        VNSRL, VNSRA,
        VMSEQ, VMSNE, VMSLTU, VMSLT, VMSLEU, VMSLE, VMSGTU, VMSGT,
        VMINU, VMIN, VMAXU, VMAX, 
        VMUL, VMULH, VMULHU, VMULHSU,
        //VDIVU, VDIV, VREMU, VREM
        VWMUL, VWMULU, VWMULSU,
        VMACC, VNMSAC, VMADD, VNMSUB,
        VWMACCU, VWMACC, VWMACCSU, VWMACCUS,
        VMERGE,
        VMV
        //all is 50
        //4 div op is not support
    } vec_lane_op_e;
     
    typedef enum logic [6:0] {
        VREDSUM, VREDMAXU, VREDMAX, VREDMINU, VREDMIN, VREDAND, VREDOR, VREDXOR,
        VWREDSUMU, VWREDSUM,
        VMV,
        VSLIDEUP, VSLIDEDOWN,VSLIDE1UP, VSLIDE1DOWN,
        VRGATHER, VRGATHEREI16,
        VCOMPRESS
        //all is 18
    } vec_vsld_op_e
    
    typedef enum logic [6:0] {
        VLD,
        VST
        //all is 26
    } vec_vlsu_op_e
    
    typedef enum logic [6:0] {
        VMAND, VMNAND, VMANDN, VMXOR, VMOR, VMNOR, VMORN, VMXNOR,
        VCPOP, VFIRST, VMSBF, VMSIF, VMSOF, VIOTA, VID
        //all is 15
    } ara_msk_op_e;
    
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
