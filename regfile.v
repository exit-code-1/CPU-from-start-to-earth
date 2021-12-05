`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    
    input wire hi_we,
    input wire lo_we,
    input wire hi_re,
    input wire lo_re,
    input wire [31:0] hi_i,
    input wire [31:0] lo_i,
);
    reg [31:0] reg_array [31:0];
    reg [31:0] hi_o;
    reg [31:0] lo_o;
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
        else  begin
        if(hi_we) begin
            hi_o <= hi_i;
        end
        if(lo_we) begin
            lo_o <= lo_i;
        end
        end
    end
//增加了相隔三条的数据相关
    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 :(hi_re&hi_we)? hi_i : hi_re? hi_o :(lo_re&lo_we)? lo_i : lo_re? lo_o:
    (raddr1==waddr) ? wdata: reg_array[raddr1];

    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : (raddr2==waddr) ? wdata: reg_array[raddr2];
endmodule