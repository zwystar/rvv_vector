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
        VADD   ='b000000, VSUB   ='b000010, VRSUB   ='b000011, 
        VWADDU ='b110000, VWSUBU ='b110010, VWADD   ='b110001, VWSUB    ='b110011, 
        VEXT   ='b010010,//VZEXT, VSEXT,
        VADC   ='b010000, VMADC  ='b010001, VSBC    ='b010010, VMSBC    ='b010011,
        VAND   ='b001001, VOR    ='b001010, VXOR    ='b001011,
        VSLL   ='b100101, VSRL   ='b101000, VSRA    ='b101001,
        VNSRL  ='b101100, VNSRA  ='b101101,
        VMSEQ  ='b011000, VMSNE  ='b011001, VMSLTU  ='b011010, VMSLT    ='b011011, 
        VMSLEU ='b011100, VMSLE  ='b011101, VMSGTU  ='b011110, VMSGT    ='b011111,
        VMINU  ='b000100, VMIN   ='b000101, VMAXU   ='b000110, VMAX     ='b000111, 
        VMUL            , VMULH           , VMULHU  ='b100100, VMULHSU  ='b100110,
        //VDIVU, VDIV, VREMU, VREM
        VWMUL  ='b111011, VWMULU ='b111000, VWMULSU ='b111010,
        VMACC           , VNMSAC ='b101111, VMADD            , VNMSUB   ='b101011,
        VWMACCU='b111100, VWMACC ='b111101, VWMACCSU='b111111, VWMACCUS ='b111110,
        VMV    ='b010111
        //all is 50
        //4 div op is not support
    } vec_lane_op_e;
     
    typedef enum logic [6:0] {
        VREDSUM    ='b000000, VREDMAXU     ='b000110, VREDMAX  ='b000111, VREDMINU   ='b000100, 
        VREDMIN    ='b000101, VREDAND      ='b000001, VREDOR   ='b000010, VREDXOR    ='b000011,
        VWREDSUMU  ='b110000, VWREDSUM     ='b110001,
        VMV        ='b010000,
        VSLIDEUP   ='b001110, VSLIDEDOWN   ='b001111, VSLIDE1UP='b001110, VSLIDE1DOWN='b001111,
        VRGATHER   ='b001100, VRGATHEREI16 ='b001110,
        VCOMPRESS  ='b010111
        //all is 18
    } vec_vsld_op_e
    
    typedef enum logic [6:0] {
        VLD,
        VST
        //all is 26
    } vec_vlsu_op_e
    
    typedef enum logic [6:0] {
        VMAND    ='b011001, VMNAND ='b011101, VMANDN ='b011000, VMXOR   ='b011011, 
        VMOR     ='b011010, VMNOR  ='b011110, VMORN  ='b011100, VMXNOR  ='b011111,
        VCPOP             , VFIRST          , VMSBF  ='b010100, VMSIF            , 
        VMSOF             , VIOTA           , VID             
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
