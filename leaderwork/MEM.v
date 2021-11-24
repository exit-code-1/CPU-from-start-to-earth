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
    wire inst_sw,inst_lw;
    
    assign {
        mem_pc,        // 107:76+8
       data_sram_en,    // 75
        data_sram_wen,   // 74:71
        sel_rf_res,     // 70
        rf_we,          // 69
        rf_waddr,       // 68:64
        ld_and_st_op, //63:32
        ex_result       // 31:0
    } =  ex_to_mem_bus_r;

    assign inst_sw=(ld_and_st_op==`SW);
    assign inst_lw=(ld_and_st_op==`LW);
    assign mem_result=  inst_lw? data_sram_rdata:32'b0;
    
    assign rf_wdata = sel_rf_res ? mem_result : ex_result;
    
    assign mem_to_wb_bus = {
        mem_pc,     // 41:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata    // 31:0
    };
   assign mem_to_id_bus= { 
        rf_we,
        rf_waddr,
        rf_wdata
    };



endmodule