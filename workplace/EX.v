`include "lib/defines.vh"
module EX(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,
    input wire [`DELAY_TO_EX_WD-1:0] is_in_delay_to_ex,
    output wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output wire [`EX_TO_ID_WD-1:0] ex_to_id_bus,
    output wire stallreq_for_ex
);

    reg [`ID_TO_EX_WD-1:0] id_to_ex_bus_r;
    reg [`DELAY_TO_EX_WD-1:0] is_in_delay_to_ex_r;
    always @ (posedge clk) begin
        if (rst) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
            is_in_delay_to_ex_r <=`DELAY_TO_EX_WD'b0;
        end
        // else if (flush) begin
        //     id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
        // end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            id_to_ex_bus_r <= `ID_TO_EX_WD'b0;
            is_in_delay_to_ex_r <=`DELAY_TO_EX_WD'b0;
        end
        else if (stall[2]==`NoStop) begin
            id_to_ex_bus_r <= id_to_ex_bus;
            is_in_delay_to_ex_r<=is_in_delay_to_ex;
        end
    end

    wire [31:0] ex_pc, inst;
    wire [11:0] alu_op;
    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [31:0] rf_rdata1, rf_rdata2;
    wire hi_we;
    wire lo_we;
    wire [31:0] hi_o;
    wire [31:0] lo_o;
    
    assign {
        ex_pc,          // 148:117
        inst,           // 116:85
        alu_op,         // 84:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_sram_en,    // 75
        hi_we,
        lo_we,
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rf_rdata1,         // 63:32
        rf_rdata2          // 31:0
    } = id_to_ex_bus_r;

    wire [31:0] imm_sign_extend, imm_zero_extend, sa_zero_extend;
    assign imm_sign_extend = {{16{inst[15]}},inst[15:0]};
    assign imm_zero_extend = {16'b0, inst[15:0]};
    assign sa_zero_extend = {27'b0,inst[10:6]};

    wire [31:0] alu_src1, alu_src2;
    wire [31:0] alu_result, ex_result;
    reg [31:0] mul_op1, mul_op2;
    wire [63:0] mul_result;
    reg mul_sign;
    reg mul_start;
    wire inst_mult,inst_multu;
    wire inst_mfhi,inst_mflo,inst_mthi,inst_mtlo;
    wire mul_ready;
    
    assign alu_src1 = sel_alu_src1[1] ? ex_pc :
                      sel_alu_src1[2] ? sa_zero_extend : rf_rdata1;

    assign alu_src2 = sel_alu_src2[1] ? imm_sign_extend :
                      sel_alu_src2[2] ? 32'd8 :
                      sel_alu_src2[3] ? imm_zero_extend : rf_rdata2;
     
    assign inst_mult=(inst[5:0]==6'b011000&inst[31:26]==6'b000000); 
    assign inst_multu=(inst[5:0]==6'b011001&inst[31:26]==6'b000000);
    assign inst_mfhi=(inst[5:0]==6'b010000&inst[31:26]==6'b000000); 
    assign inst_mflo=(inst[5:0]==6'b010010&inst[31:26]==6'b000000);           
    assign inst_mthi=(inst[5:0]==6'b010001&inst[31:26]==6'b000000); 
    assign inst_mtlo=(inst[5:0]==6'b010011&inst[31:26]==6'b000000);                         
    
    alu u_alu(
    	.alu_control (alu_op ),
        .alu_src1    (alu_src1    ),
        .alu_src2    (alu_src2    ),
        .alu_result  (alu_result  )
    );
    MLU u_MLU (
             .clk (clk),
             .resetn (~rst),
             .mul_sign (mul_sign),
             .mul_start_i (mul_start),
             .mul_ready (mul_ready),
             .mul_op1 (mul_op1),
             .mul_op2 (mul_op2),
             .result (mul_result)
              );
             
    wire is_delay_slot_i;
    wire [31:0] link_address_o;
   
    wire [5:0]ld_and_st_op;
    wire inst_sw,inst_sb,inst_sh;
    
    assign 
    { 
    is_delay_slot_i,
    link_address_o
    }=is_in_delay_to_ex_r;
    //存储或读取时向ram输入的使能和地址
    assign ld_and_st_op=data_sram_en? inst[31:26]:6'b000000;
    assign inst_sw=(ld_and_st_op==`SW);
    assign inst_sb=(ld_and_st_op==`SB);
    assign inst_sh=(ld_and_st_op==`SH);
    

    assign data_sram_addr=data_sram_en? rf_rdata1+{{16{inst[15]}},inst[15:0]}:32'b0;
    assign data_sram_wen=inst_sw? 4'b1111:(inst_sb&data_sram_addr[1:0]==2'b00)?4'b0001
    :(inst_sb&data_sram_addr[1:0]==2'b01)?4'b0010:(inst_sb&data_sram_addr[1:0]==2'b10)?4'b0100
    :(inst_sb&data_sram_addr[1:0]==2'b11)?4'b1000:(inst_sh&data_sram_addr[1:0]==2'b00)?4'b0011
    :(inst_sh&data_sram_addr[1:0]==2'b10)?4'b1100:sel_rf_res? 4'b0000:0;
    
    assign data_sram_wdata=inst_sb?{ 4{rf_rdata2[7:0]}}:
    inst_sh? {2{ rf_rdata2[15:0] }}:
    inst_sw? rf_rdata2:32'b0;
    assign ex_result = (inst_mfhi | inst_mflo )? rf_rdata1:
    is_delay_slot_i ? link_address_o:data_sram_en?data_sram_wdata:alu_result;
    assign hi_o = (inst_mult | inst_multu) ? mul_result[63:32] :(inst_div | inst_divu ) ? div_result[63:32] :inst_mthi ? rf_rdata1:0;
    assign lo_o = (inst_mult | inst_multu) ? mul_result[31:0] :(inst_div | inst_divu ) ? div_result[31:0] : inst_mtlo ? rf_rdata1:0;
    
    assign ex_to_mem_bus = {
        ex_pc,          // 115:84
        data_sram_en,    // 75
        data_sram_wen,   // 74:71
        data_sram_addr[1:0],
        sel_rf_res,     // 70
        hi_we,
        lo_we,
        rf_we,          // 69
        rf_waddr,       // 68:64
        ld_and_st_op, 
        ex_result,       // 31:0
        hi_o,
        lo_o
    };
    assign ex_to_id_bus= { 
        rf_we,
        rf_waddr,
        hi_we,
        lo_we,
        hi_o,
        lo_o,
        ld_and_st_op,
        ex_result
    };
    
    wire inst_div, inst_divu;
    wire [63:0] div_result;
    wire div_ready_i;
    reg stallreq_for_div;
    reg stallreq_for_mul;
    assign stallreq_for_ex = stallreq_for_div | stallreq_for_mul;
    assign inst_div=(inst[5:0]==6'b011010&inst[31:26]==6'b000000); 
    assign inst_divu=(inst[5:0]==6'b011011&inst[31:26]==6'b000000);
    reg [31:0] div_opdata1_o;
    reg [31:0] div_opdata2_o;
    reg div_start_o;
    reg signed_div_o;
    reg mul_already_start;

    div u_div(
    	.rst          (rst          ),
        .clk          (clk          ),
        .signed_div_i (signed_div_o ),
        .opdata1_i    (div_opdata1_o    ),
        .opdata2_i    (div_opdata2_o    ),
        .start_i      (div_start_o      ),
        .annul_i      (1'b0      ),
        .result_o     (div_result     ), // 除法结果 64bit
        .ready_o      (div_ready_i      )
    );
        always @ (*) begin
        if (rst) begin
        stallreq_for_mul= `NoStop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b0;
        mul_sign=1'b0;
        mul_already_start=1'b0;
        end
        else begin
        stallreq_for_mul= `NoStop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b0;
        mul_sign=1'b0;
        mul_already_start=1'b0;
        case({inst_mult,inst_multu})
        2'b10:begin       
        if(mul_ready==1'b0&~mul_already_start)begin
        stallreq_for_mul= `Stop;
        mul_op1=rf_rdata1;
        mul_op2=rf_rdata2;
        mul_start=1'b1;
        mul_sign=1'b1;
        mul_already_start=1'b1;
        end
        else if(mul_ready==1'b0&mul_already_start)begin
        stallreq_for_mul= `Stop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b1;
        mul_sign=1'b1;
        mul_already_start=1'b1;
        end
        else if(mul_ready==1'b1)begin
        stallreq_for_mul= `NoStop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b0;
        mul_sign=1'b1;
        mul_already_start=1'b0;
        end
        else begin
        stallreq_for_mul= `NoStop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b0;
        mul_sign=1'b0;
        mul_already_start=1'b0;
        end
        end
        2'b01:begin
        if(mul_ready==1'b0&~mul_already_start)begin
        stallreq_for_mul= `Stop;
        mul_op1=rf_rdata1;
        mul_op2=rf_rdata2;
        mul_start=1'b1;
        mul_sign=1'b0;
        mul_already_start=1'b1;
        end
        else if(mul_ready==1'b0&mul_already_start)begin
        stallreq_for_mul= `Stop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b1;
        mul_sign=1'b0;
        mul_already_start=1'b1;
        end
        else if(mul_ready==1'b1)begin
        stallreq_for_mul= `NoStop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b0;
        mul_sign=1'b0;
        mul_already_start=1'b0;
        end
        else begin
        stallreq_for_mul= `NoStop;
        mul_op1=`ZeroWord;
        mul_op2=`ZeroWord;
        mul_start=1'b0;
        mul_sign=1'b0;
        mul_already_start=1'b0;
        end
        end
        default:begin
        end
        endcase
        end
 end
    always @ (*) begin
        if (rst) begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
        end
        else begin
            stallreq_for_div = `NoStop;
            div_opdata1_o = `ZeroWord;
            div_opdata2_o = `ZeroWord;
            div_start_o = `DivStop;
            signed_div_o = 1'b0;
            case ({inst_div,inst_divu})
                2'b10:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStart;
                        signed_div_o = 1'b1;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b1;
                        stallreq_for_div = `NoStop;
                    end
                    else begin
                        div_opdata1_o = `ZeroWord;
                        div_opdata2_o = `ZeroWord;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                2'b01:begin
                    if (div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStart;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `Stop;
                    end
                    else if (div_ready_i == `DivResultReady) begin
                        div_opdata1_o = rf_rdata1;
                        div_opdata2_o = rf_rdata2;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                    else begin
                        div_opdata1_o = `ZeroWord;
                        div_opdata2_o = `ZeroWord;
                        div_start_o = `DivStop;
                        signed_div_o = 1'b0;
                        stallreq_for_div = `NoStop;
                    end
                end
                default:begin
                end
            endcase
        end
    end
    
endmodule