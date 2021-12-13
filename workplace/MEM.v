`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0]data_sram_rdata,

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    output wire [`MEM_TO_ID_WD-1:0] mem_to_id_bus
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;
    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    wire [31:0] mem_pc;
    wire data_sram_en;
    wire [3:0] data_sram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    wire [5:0]ld_and_st_op;
    wire inst_lw,inst_lb,inst_lbu,inst_lh,inst_lhu;
    wire hi_we;
    wire lo_we;
    wire [31:0]hi_o;
    wire [31:0]lo_o;
    wire [1:0]ldaddr;
    assign {
        mem_pc,        // 107:76+8
       data_sram_en,    // 75
        data_sram_wen,   // 74:71
        ldaddr,
        sel_rf_res,     // 70
        hi_we,
        lo_we,
        rf_we,          // 69
        rf_waddr,       // 68:64
        ld_and_st_op, //63:32
        ex_result,       // 31:0
        hi_o,
        lo_o
    } =  ex_to_mem_bus_r;

    assign inst_lw=(ld_and_st_op==`LW);
    assign inst_lh=(ld_and_st_op==`LH);
    assign inst_lhu=(ld_and_st_op==`LHU);
    assign inst_lb=(ld_and_st_op==`LB);
    assign inst_lbu=(ld_and_st_op==`LBU);
    assign mem_result=  inst_lw? data_sram_rdata:(inst_lb&ldaddr==2'b00)? {{24{ data_sram_rdata[7]}},data_sram_rdata[7:0]}
    :(inst_lb&ldaddr==2'b01)? {{24{ data_sram_rdata[15]}},data_sram_rdata[15:8]}
    :(inst_lb&ldaddr==2'b10)? {{24{ data_sram_rdata[23]}},data_sram_rdata[23:16]}
    :(inst_lb&ldaddr==2'b11)? {{24{ data_sram_rdata[31]}},data_sram_rdata[31:24]}
    :(inst_lbu&ldaddr==2'b00)? {{24{1'b0}},data_sram_rdata[7:0]}
    :(inst_lbu&ldaddr==2'b01)? {{24{1'b0}},data_sram_rdata[15:8]}
    :(inst_lbu&ldaddr==2'b10)? {{24{1'b0}},data_sram_rdata[23:16]}
    :(inst_lbu&ldaddr==2'b11)? {{24{1'b0}},data_sram_rdata[31:24]}
    :(inst_lh&ldaddr==2'b00)? {{16{ data_sram_rdata[15]}},data_sram_rdata[15:0]}
    :(inst_lh&ldaddr==2'b10)? {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]}
    :(inst_lhu&ldaddr==2'b00)? {{16{1'b0}},data_sram_rdata[15:0]}
    :(inst_lhu&ldaddr==2'b10)? {{16{1'b0}},data_sram_rdata[31:16]}
    :32'b0;
    
    assign rf_wdata = sel_rf_res ? mem_result : ex_result;
    
    assign mem_to_wb_bus = {
        mem_pc,     // 41:38
        hi_we,
        lo_we,
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata,    // 31:0
        hi_o,
        lo_o
    };
   assign mem_to_id_bus= { 
        hi_we,
        lo_we,
        rf_we,
        rf_waddr,
        rf_wdata,
        hi_o,
        lo_o
    };



endmodule