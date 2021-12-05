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
    output wire [`EX_TO_ID_WD-1:0] ex_to_id_bus
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
    wire [4:0] sel_alu_src1;
    wire [4:0] sel_alu_src2;
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
        data_sram_wen,   // 74:71
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
    wire [31:0] mul_op1, mul_op2;
    wire [63:0] mul_result;
    wire mul_sign;
    wire mul_start;
    assign alu_src1 = sel_alu_src1[1] ? ex_pc :
                      sel_alu_src1[2] ? sa_zero_extend : rf_rdata1;

    assign alu_src2 = sel_alu_src2[1] ? imm_sign_extend :
                      sel_alu_src2[2] ? 32'd8 :
                      sel_alu_src2[3] ? imm_zero_extend : rf_rdata2;
                      
    assign mul_op1 = sel_alu_src1[0] ? rf_rdata1:0;
    assign mul_op2 = sel_alu_src2[0] ? rf_rdata2:0;
    
    alu u_alu(
    	.alu_control (alu_op ),
        .alu_src1    (alu_src1    ),
        .alu_src2    (alu_src2    ),
        .alu_result  (alu_result  )
    );
    MLU u_MLU (
             .clk (clk),
             .resten (~rst),
             .mul_sign (mul_sign),
             .mul_start_i (mul_start),
             .mul_op1 (rf_rdata1),
             .mul_op2 (rf_rdata2),
             .result (mul_result)
              );
             
    wire is_delay_slot_i;
    wire [31:0] link_address_o;
   
    wire [5:0]ld_and_st_op;
    
    assign 
    { 
    is_delay_slot_i,
    link_address_o
    }=is_in_delay_to_ex_r;
    //存储或读取时向ram输入的使能和地址
    assign ld_and_st_op=data_sram_en? inst[31:26]:6'b000000;
    assign data_sram_addr=data_sram_en? rf_rdata1+{{16{inst[15]}},inst[15:0]}:32'b0;
    assign data_sram_wdata=data_sram_en?rf_rdata2:32'b0;
    assign ex_result =is_delay_slot_i ? link_address_o:data_sram_en?data_sram_wdata:alu_result;
    assign hi_o = hi_we ? rf_rdata1:0;
    assign lo_o = lo_we? rf_rdata1:0;
    
    assign ex_to_mem_bus = {
        ex_pc,          // 115:84
        data_sram_en,    // 75
        data_sram_wen,   // 74:71
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
    
    
endmodule