`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,
    
    input wire [`EX_TO_ID_WD-1:0] ex_to_id_bus,
    
    input wire [`MEM_TO_ID_WD-1:0] mem_to_id_bus,
    
    
    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,
    
    output wire [`BR_WD-1:0] br_bus ,
    output wire [`DELAY_TO_EX_WD-1:0] is_in_delay_to_ex
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;
    wire [31:0]reg_o1;
    wire [31:0]reg_o2;
    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    wire hi_we_i;
    wire lo_we_i;
    wire hi_we_o;
    wire lo_we_o;
    wire hi_re;
    wire lo_re;
    wire [31:0] hi_o;
    wire [31:0] lo_o;
    reg id_stop;

    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
            id_stop            <= 1'b0;
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
            id_stop            <= 1'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
            id_stop            <=1'b0;
        end
        if (stall[2]==`Stop) begin
            id_stop            <= 1'b1;
        end
    end
    
  
    assign inst =  (~id_stop)?  inst_sram_rdata:inst;
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        hi_we_i,
        lo_we_i,
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata,
        hi_o,
        lo_o
    } = wb_to_rf_bus;

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_sram_en;
    wire [3:0] data_sram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;

    wire ex_to_id_we;
    wire [4:0]ex_to_id_waddr;
    wire [31:0]ex_to_id_wdata;
    wire [5:0] ex_to_id_op;
    wire ex_to_id_hi_we;
    wire ex_to_id_lo_we;
    wire [31:0] ex_to_id_hi;
    wire [31:0] ex_to_id_lo;
    
    wire mem_to_id_we;
    wire [4:0]mem_to_id_waddr;
    wire [31:0]mem_to_id_wdata;
    wire mem_to_id_hi_we;
    wire mem_to_id_lo_we;
    wire [31:0] mem_to_id_hi;
    wire [31:0] mem_to_id_lo;
    

    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  ),
        .hi_we (hi_we_i),
        .lo_we (lo_we_i),
        .hi_i (hi_o),
        .lo_i (lo_o),
        .hi_re (hi_re),
        .lo_re (lo_re)
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];
   
    assign {
        ex_to_id_we,
        ex_to_id_waddr,
        ex_to_id_hi_we,
        ex_to_id_lo_we,
        ex_to_id_hi,
        ex_to_id_lo,
        ex_to_id_op,
        ex_to_id_wdata
    }=ex_to_id_bus;

    assign {
        mem_to_id_hi_we,
        mem_to_id_lo_we,
        mem_to_id_we,
        mem_to_id_waddr,
        mem_to_id_wdata,
        mem_to_id_hi,
        mem_to_id_lo
    }=mem_to_id_bus;

    wire inst_ori, inst_lui, inst_addiu, inst_beq,inst_sudu,inst_jr,
    inst_jal,inst_sll,inst_bne,inst_sw,inst_xor,inst_sltu,inst_slt,
    inst_slti,inst_sltiu,inst_j,inst_beqz,inst_add,inst_sllv,inst_addi,
    inst_sub,inst_sra,inst_srav,inst_srl,inst_and,inst_nor,inst_andi,
    inst_xori,inst_srlv,inst_bgez,inst_bgtz,inst_blez,inst_bltz,
    inst_bltzal,inst_bgezal,inst_jalr,inst_mfhi,inst_mflo,inst_mthi,
    inst_mtlo,inst_mult,inst_multu;

    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );
    decoder_5_32 u2_decoder_5_32(
    	.in  (sa  ),
        .out (sa_d)
    );
    decoder_5_32 u3_decoder_5_32(
    	.in  (rd  ),
        .out (rd_d)
    );
 //判断操作符是那种类型
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_addi   = op_d[6'b00_1000];
    assign inst_addu   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100001];
    assign inst_add   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100000];
    assign inst_sudu   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100011];
    assign inst_sub   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100010];
    
    assign inst_or       =  op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100101];
    assign inst_and     =  op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100100];
    assign inst_andi     =  op_d[6'b00_1100];
    assign inst_nor       =  op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100111];
    assign inst_xor   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b100110];
    assign inst_xori    =  op_d[6'b00_1110];
    
    
    assign inst_sltu   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b101011];
    assign inst_slt   = op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b101010];
    assign inst_slti   = op_d[6'b00_1010];
    assign inst_sltiu   = op_d[6'b00_1011];
    
    assign inst_sll   =  op_d[6'b00_0000]&func_d[6'b000000];
    assign inst_sllv   =  op_d[6'b00_0000]&func_d[6'b000100];
    assign inst_sra   = op_d[6'b00_0000]&func_d[6'b000011];
    assign inst_srav   = op_d[6'b00_0000]&func_d[6'b000111];
    assign inst_srl   = op_d[6'b00_0000]&func_d[6'b000010];
    assign inst_srlv   = op_d[6'b00_0000]&func_d[6'b000110];
    
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_j       =  op_d[6'b00_0010];
    assign inst_jr       =  op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b001000];
    assign inst_jalr       =  op_d[6'b00_0000]&sa_d[5'b00000]&func_d[6'b001001];
    assign inst_jal    = op_d[6'b00_0011];
    assign inst_bne = op_d[6'b00_0101];
    assign inst_beqz     = op_d[6'b00_0100];
    assign inst_bgez     = op_d[6'b00_0001]&rt_d[5'b00001];
    assign inst_bgtz     = op_d[6'b00_0111];
    assign inst_blez     = op_d[6'b00_0110];
    assign inst_bltz     = op_d[6'b00_0001]&rt_d[5'b00000];
    assign inst_bltzal     = op_d[6'b00_0001]&rt_d[5'b10000];
    assign inst_bgezal     = op_d[6'b00_0001]&rt_d[5'b10001];
    
    assign inst_sw     = op_d[6'b101011];
    assign inst_lw      = op_d[6'b100011];
    
    assign inst_mult=op_d[6'b000000]&func_d[6'b011000];
    assign inst_multu=op_d[6'b000000]&func_d[6'b011001];
    
    assign inst_mfhi = op_d[6'b000000]&func_d[6'b010000];
    assign inst_mflo = op_d[6'b000000]&func_d[6'b010010];
    assign inst_mthi = op_d[6'b000000]&func_d[6'b010001];
    assign inst_mtlo = op_d[6'b000000]&func_d[6'b010011];
    
//传给ex的结果，包含数据相关
    assign reg_o1=((ce==1'b1)&&(ex_to_id_we==1'b1)&&(ex_to_id_waddr==rs))? ex_to_id_wdata 
    : ((ce==1'b1)&&(mem_to_id_we==1'b1)&&(mem_to_id_waddr==rs))? mem_to_id_wdata
    : (ex_to_id_hi_we&hi_re)? ex_to_id_hi:(ex_to_id_lo_we&lo_re) ? ex_to_id_lo
    : (mem_to_id_hi_we&hi_re)? mem_to_id_hi: (mem_to_id_lo_we&lo_re) ? mem_to_id_lo
    :(ce==1'b1)? rdata1:(ce==1'b0)? imm:`INIT;
    assign reg_o2=((ce==1'b1)&&(ex_to_id_we==1'b1)&&(ex_to_id_waddr==rt))? ex_to_id_wdata 
    : ((ce==1'b1)&&(mem_to_id_we==1'b1)&&(mem_to_id_waddr==rt))? mem_to_id_wdata
     : (ce==1'b1)? rdata2:(ce==1'b0)? imm:`INIT;

    // rs to reg1  操作数1选择是否从取rs对应地址的值
    assign sel_alu_src1[0] = inst_ori | inst_addiu | inst_sudu 
    | inst_addu | inst_or | inst_sw | inst_lw | inst_xor | inst_sltu
    | inst_slt | inst_slti | inst_sltiu | inst_add | inst_sllv | inst_addi
    | inst_sub | inst_srav | inst_and | inst_nor | inst_andi | inst_xori
    | inst_srlv | inst_bgezal | inst_bltzal | inst_jalr | inst_mthi | inst_mtlo
    | inst_mult | inst_multu;

    // pc to reg1  //操作数1选择是否取PC的值
    assign sel_alu_src1[1] = 1'b0;

    // sa_zero_extend to reg1 //取sa扩展
    assign sel_alu_src1[2] = inst_sll | inst_sra | inst_srl;
    
    // rt to reg2 操作数2选择是否从取rt对应地址的值
    assign sel_alu_src2[0] = inst_sudu | inst_addu | inst_sll | inst_or | inst_sw | inst_xor
                                              | inst_sltu | inst_slt | inst_add | inst_sllv | inst_sub | inst_sra 
                                              | inst_srav | inst_srl | inst_and | inst_nor | inst_srlv | inst_mult
                                              | inst_multu;
    
    // imm_sign_extend to reg2  操作数2选择取有符号扩展的立即数
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_slti | inst_sltiu | inst_addi;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = 1'b0;

    // imm_zero_extend to reg2  操作数2取有无符号扩展的立即数
    assign sel_alu_src2[3] = inst_ori | inst_andi | inst_xori;

//alu运算类型
    assign op_add = inst_addiu | inst_addu | inst_add | inst_addi;
    assign op_sub = inst_sudu | inst_sub;
    assign op_slt = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu;
    assign op_and = inst_and | inst_andi;
    assign op_nor = inst_nor;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xor | inst_xori;
    assign op_sll = inst_sll | inst_sllv;
    assign op_srl = inst_srl | inst_srlv;
    assign op_sra = inst_sra | inst_srav;
    assign op_lui = inst_lui;
    
    assign alu_op = {op_add, op_sub, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};



    // load and store enable 是否进行load和store操作
    assign data_sram_en = inst_sw | inst_lw;

    // write enable  写使能 0000代表load  对应位为1代表对应位写入
    assign data_sram_wen = inst_sw ? 4'b1111: 4'b0000;



    // regfile sotre enable 是否将结果写入寄存器
    assign rf_we = inst_ori | inst_lui | inst_addiu | inst_sudu | inst_jal
     | inst_addu | inst_sll | inst_or | inst_lw | inst_xor | inst_sltu | inst_slt
     | inst_slti | inst_sltiu | inst_add | inst_sllv | inst_addi | inst_sub | inst_sra
     | inst_srav | inst_srl | inst_and | inst_nor | inst_andi | inst_xori | inst_srlv
     | inst_bgezal | inst_bltzal | inst_jalr | inst_mfhi | inst_mflo;
     assign hi_re = inst_mfhi;
     assign lo_re = inst_mflo;
     
     assign hi_we_o = inst_mthi | inst_mult | inst_multu;
     assign lo_we_o = inst_mtlo | inst_mult | inst_multu;

//选择存到哪个寄存器中
    // store in [rd] 
    assign sel_rf_dst[0] = inst_sudu | inst_addu | inst_sll | inst_or | inst_xor | inst_sltu
                                           | inst_slt | inst_add | inst_sllv | inst_sub | inst_sra | inst_srav
                                           | inst_and | inst_nor | inst_srl | inst_srlv | inst_jalr | inst_mfhi
                                           | inst_mflo;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori | inst_lui | inst_addiu | inst_lw | inst_slti | inst_sltiu
                                          | inst_addi | inst_andi | inst_xori;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_bgezal | inst_bltzal;
    

    // sel for regfile address 要写入寄存器的addr
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = inst_lw;
    assign id_to_ex_bus = {
        id_pc,          // 161:130
        inst,           // 129:98
        alu_op,         // 97:86
        sel_alu_src1,   // 85:81
        sel_alu_src2,   // 80:76
        data_sram_en,    // 75
        data_sram_wen,   // 74:71
        hi_we_o,
        lo_we_o,
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        reg_o1,         // 63:32
        reg_o2        // 31:0
    };

//跳转模块
    wire br_e;
    wire [31:0] br_addr;
    wire is_delay_slot_to_ex;
    wire [31:0] link_addr_to_ex;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    wire jr,j,jal,beq,bne,beqz,bgez,bgtz,blez,bltz,bltzal,bgezal,jalr;
    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (reg_o1==reg_o2);
    //是否满足跳转条件
    assign beq=inst_beq&rs_eq_rt;
    assign jr=inst_jr;
    assign jal=inst_jal;
    assign jalr=inst_jalr;
    assign bne=inst_bne&(~rs_eq_rt);
    assign beqz=inst_beqz&(~reg_o1);
    assign j=inst_j;
    assign bgez=~reg_o1[31]&inst_bgez;
    assign bgtz=~reg_o1[31]&(reg_o1>32'b0)&inst_bgtz;
    assign blez = (reg_o1[31] | reg_o1==32'b0)&inst_blez;
    assign bltz = reg_o1[31]&inst_bltz;
    assign bgezal =~reg_o1[31]&inst_bgezal;
    assign bltzal=reg_o1[31]&inst_bltzal;
    //跳转信号 是否跳转
    assign br_e =  j | beq | jr | jal | jalr | bne | bgez | bgtz | blez | bltz | bgezal | bltzal;
    // 跳转地址
    assign br_addr = beq ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) : jr ? (reg_o1): jal?
     {pc_plus_4[31:28],inst[25:0],2'b00} :
     bne? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
     beqz? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
      j? {pc_plus_4[31:28],inst[25:0],2'b00}: 
      jalr? reg_o1:
      bgez? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
      bgtz? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
      blez? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
      bltz ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
      bltzal ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):
      bgezal ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}):32'b0;
    assign br_bus = {
        br_e,
        br_addr
    };
    // 延迟槽与 写入31号寄存器的值
    assign is_delay_slot_to_ex=j | beq | jr | jal | jalr | bne | bgez | bgtz | blez | bltz | inst_bgezal | inst_bltzal;
    assign link_addr_to_ex=jal?pc_plus_4+32'h4:
                                               jalr?pc_plus_4+32'h4:
                                               inst_bgezal?pc_plus_4+32'h4:
                                               inst_bltzal?pc_plus_4+32'h4:32'b0;
    assign is_in_delay_to_ex={
    is_delay_slot_to_ex,
    link_addr_to_ex
    };
    //暂停机制
     assign stallreq=((ex_to_id_op==6'b100011)&&(ce==1'b1)&&(ex_to_id_we==1'b1)&&(ex_to_id_waddr==rs))?
    `Stop :((ex_to_id_op==6'b100011)&&(ce==1'b1)&&(ex_to_id_we==1'b1)&&(ex_to_id_waddr==rt))? `Stop: `NoStop;

endmodule
