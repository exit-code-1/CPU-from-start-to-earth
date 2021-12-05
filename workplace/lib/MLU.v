`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/30 18:28:26
// Design Name: 
// Module Name: MLU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MLU(
  input wire clk,
  input wire resetn,
  input wire mul_sign,
  input wire mul_start_i,
  input wire [31:0] mul_op1,
  input wire [31:0] mul_op2,
  output wire [63:0] result
    );
  wire [31:0] mul_sel1;
  wire [31:0] mul_sel2;
  reg   [31:0] tree1 [31:0];
  wire [33:0] tree2_1;
  wire [33:0] tree2_2;
  wire [33:0] tree2_3;
  wire [33:0] tree2_4;
  wire [33:0] tree2_5;
  wire [33:0] tree2_6;
  wire [33:0] tree2_7;
  wire [33:0] tree2_8;
  wire [33:0] tree2_9;
  wire [33:0] tree2_10;
  wire [33:0] tree2_11;
  wire [33:0] tree2_12;
  wire [33:0] tree2_13;
  wire [33:0] tree2_14;
  wire [33:0] tree2_15;
  wire [33:0] tree2_16;
  wire [36:0] tree3_1;
  wire [36:0] tree3_2;
  wire [36:0] tree3_3;
  wire [36:0] tree3_4;
  wire [36:0] tree3_5;
  wire [36:0] tree3_6;
  wire [36:0] tree3_7;
  wire [36:0] tree3_8;
  wire [41:0] tree4_1;
  wire [41:0] tree4_2;
  wire [41:0] tree4_3;
  wire [41:0] tree4_4;
  wire [50:0] tree5_1;
  wire [50:0] tree5_2;
  wire [63:0] tree6_out;
  integer loop;
  assign mul_sel1=(mul_op1[31]&mul_sign)? {1'b0,~mul_op1[30:0]+1} : mul_op1;
  assign mul_sel2=(mul_op2[31]&mul_sign)? {1'b0,~mul_op2[30:0]+1} : mul_op2;
  always @(posedge clk)
  begin
       if(!resetn | !mul_start_i )begin
         for (loop=0;loop<32;loop=loop+1)
         begin
            tree1[loop] <=0;
         end
       end
       else 
       begin
            for (loop=0;loop<32;loop=loop+1)
            begin
            tree1[loop] <= mul_sel2[loop]? mul_sel1:0;
            end
       end
  end
  
  assign tree2_1=mul_start_i ? tree1[0]+{tree1[1],1'b0} :0;
  assign tree2_2=mul_start_i ? tree1[2]+{tree1[3],1'b0} :0;
  assign tree2_3=mul_start_i ? tree1[4]+{tree1[5],1'b0} :0;
  assign tree2_4=mul_start_i ? tree1[6]+{tree1[7],1'b0} :0;
  assign tree2_5=mul_start_i ? tree1[8]+{tree1[9],1'b0} :0;
  assign tree2_6=mul_start_i ? tree1[10]+{tree1[11],1'b0} :0;
  assign tree2_7=mul_start_i ? tree1[12]+{tree1[13],1'b0} :0;
  assign tree2_8=mul_start_i ? tree1[14]+{tree1[15],1'b0} :0;
  assign tree2_9=mul_start_i ? tree1[16]+{tree1[17],1'b0} :0;
  assign tree2_10=mul_start_i ? tree1[18]+{tree1[19],1'b0} :0;
  assign tree2_11=mul_start_i ? tree1[20]+{tree1[21],1'b0} :0;
  assign tree2_12=mul_start_i ? tree1[22]+{tree1[23],1'b0} :0;
  assign tree2_13=mul_start_i ? tree1[24]+{tree1[25],1'b0} :0;
  assign tree2_14=mul_start_i ? tree1[26]+{tree1[27],1'b0} :0;
  assign tree2_15=mul_start_i ? tree1[28]+{tree1[29],1'b0} :0;
  assign tree2_16=mul_start_i ? tree1[30]+{tree1[31],1'b0} :0;
  assign tree3_1=mul_start_i ? tree2_1+{tree2_2,2'b0} :0;
  assign tree3_2=mul_start_i ? tree2_3+{tree2_4,2'b0} :0;
  assign tree3_3=mul_start_i ? tree2_5+{tree2_6,2'b0} :0;
  assign tree3_4=mul_start_i ? tree2_7+{tree2_9,2'b0} :0;
  assign tree3_5=mul_start_i ? tree2_9+{tree2_10,2'b0} :0;
  assign tree3_6=mul_start_i ? tree2_11+{tree2_12,2'b0} :0;
  assign tree3_7=mul_start_i ? tree2_13+{tree2_14,2'b0} :0;
  assign tree3_8=mul_start_i ? tree2_15+{tree2_16,2'b0} :0;
  assign tree4_1=mul_start_i ? tree3_1+{tree3_2,4'b0} :0;
  assign tree4_2=mul_start_i ? tree3_3+{tree3_4,4'b0} :0;
  assign tree4_3=mul_start_i ? tree3_5+{tree3_6,4'b0} :0;
  assign tree4_4=mul_start_i ? tree3_7+{tree3_8,4'b0} :0;
  assign tree5_1=mul_start_i ? tree4_1+{tree4_2,8'b0} :0;
  assign tree5_2=mul_start_i ? tree4_3+{tree4_4,8'b0} :0;
  assign tree6_out=mul_start_i ? tree15_1+{tree5_2,16'b0} :0;
  assign result=(mul_sign&(mul_op1[31]^mul_op2[31]))? ~tree6_out+1 : tree6_out;
endmodule
