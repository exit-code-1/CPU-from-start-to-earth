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



module MLU(
  input wire clk,
  input wire resetn,
  input wire mul_sign,
  input wire mul_start_i,
  output reg mul_ready,
  input wire [31:0] mul_op1,
  input wire [31:0] mul_op2,
  output reg [63:0] result
    );
  wire [31:0] mul_sel1;
  wire [31:0] mul_sel2;
  reg   [31:0] tree1 [31:0];
  reg [33:0] tree2_1;
  reg [33:0] tree2_2;
  reg [33:0] tree2_3;
  reg [33:0] tree2_4;
  reg [33:0] tree2_5;
  reg [33:0] tree2_6;
  reg [33:0] tree2_7;
  reg [33:0] tree2_8;
  reg [33:0] tree2_9;
  reg [33:0] tree2_10;
  reg [33:0] tree2_11;
  reg [33:0] tree2_12;
  reg [33:0] tree2_13;
  reg [33:0] tree2_14;
  reg [33:0] tree2_15;
  reg [33:0] tree2_16;
  reg [36:0] tree3_1;
  reg [36:0] tree3_2;
  reg [36:0] tree3_3;
  reg [36:0] tree3_4;
  reg [36:0] tree3_5;
  reg [36:0] tree3_6;
  reg [36:0] tree3_7;
  reg [36:0] tree3_8;
  reg [41:0] tree4_1;
  reg [41:0] tree4_2;
  reg [41:0] tree4_3;
  reg [41:0] tree4_4;
  reg [50:0] tree5_1;
  reg [50:0] tree5_2;
  reg [63:0] tree6_out;
  integer loop;
  reg [2:0]state;
  assign mul_sel1=(mul_op1[31]&mul_sign)? ~mul_op1+1 : mul_op1;
  assign mul_sel2=(mul_op2[31]&mul_sign)? ~mul_op2+1 : mul_op2;
  always @(posedge clk)
  begin
       if(!resetn | !mul_start_i )begin
         for (loop=0;loop<32;loop=loop+1)
         begin
            tree1[loop] <=0;
         end
         state <=0;
         mul_ready<=0;
       end
       else 
       begin           
            case(state)
            3'b000:begin
            state<=1;
            end
            3'b001:begin
            state<=2;
            end
            3'b010:begin
            state<=3;
            end
            3'b011:begin
            state<=4;
            end
            3'b100:begin
            state<=5;
            end
            3'b101:begin
            state<=6;
            end
            default:begin
            state<=7;
            mul_ready<=1;
            end
            endcase
       end
 end
always @(posedge clk)begin
if(mul_start_i&state==0)begin
            mul_ready<=0;
for (loop=0;loop<32;loop=loop+1)
            begin
            tree1[loop] <= mul_sel2[loop]? mul_sel1:0;
            end
 end
 else begin
           for (loop=0;loop<32;loop=loop+1)
            begin
            tree1[loop] <= 0;
            end
 end
end
 always @(posedge clk)begin
 if(state==1)begin
        mul_ready<=0;
        tree2_1<= tree1[0]+{tree1[1],1'b0} ;
        tree2_2<= tree1[2]+{tree1[3],1'b0} ;
        tree2_3<= tree1[4]+{tree1[5],1'b0} ;
        tree2_4<= tree1[6]+{tree1[7],1'b0} ;
        tree2_5<= tree1[8]+{tree1[9],1'b0} ;
        tree2_6<= tree1[10]+{tree1[11],1'b0} ;
        tree2_7<= tree1[12]+{tree1[13],1'b0} ;
        tree2_8<= tree1[14]+{tree1[15],1'b0} ;
        tree2_9<= tree1[16]+{tree1[17],1'b0} ;
        tree2_10<= tree1[18]+{tree1[19],1'b0} ;
        tree2_11<= tree1[20]+{tree1[21],1'b0} ;
        tree2_12<= tree1[22]+{tree1[23],1'b0} ;
        tree2_13<= tree1[24]+{tree1[25],1'b0} ;
        tree2_14<= tree1[26]+{tree1[27],1'b0} ;
        tree2_15<= tree1[28]+{tree1[29],1'b0} ;
        tree2_16<= tree1[30]+{tree1[31],1'b0} ;
       end
       else begin
        tree2_1<=0 ;
         tree2_2<=0 ;
         tree2_3<=0 ;
         tree2_4<=0 ;
         tree2_5<=0 ;
         tree2_6<=0 ;
         tree2_7<=0 ;
         tree2_8<=0 ;
         tree2_9<=0 ;
         tree2_10<=0 ;
         tree2_11<=0 ;
         tree2_12<=0 ;
         tree2_13<=0 ;
         tree2_14<=0 ;
         tree2_15<=0 ;
         tree2_16<=0 ;
 end
 end
  always @(posedge clk)begin
if(state==2)begin
        mul_ready<=0;
        tree3_1<= tree2_1+{tree2_2,2'b0} ;
        tree3_2<= tree2_3+{tree2_4,2'b0} ;
        tree3_3<= tree2_5+{tree2_6,2'b0} ;
        tree3_4<= tree2_7+{tree2_8,2'b0} ;
        tree3_5<= tree2_9+{tree2_10,2'b0} ;
        tree3_6<= tree2_11+{tree2_12,2'b0} ;
        tree3_7<= tree2_13+{tree2_14,2'b0} ;
        tree3_8<= tree2_15+{tree2_16,2'b0} ;
       end
       else begin
         mul_ready<=0;
         tree3_1<=0 ;
         tree3_2<=0 ;
         tree3_3<=0 ;
         tree3_4<=0 ;
         tree3_5<=0 ;
         tree3_6<=0 ;
         tree3_7<=0 ;
         tree3_8<=0 ;
 end
 end
 always @(posedge clk)begin
if(state==3)begin
        mul_ready<=0;
        tree4_1<= tree3_1+{tree3_2,4'b0} ;
        tree4_2<= tree3_3+{tree3_4,4'b0} ;
        tree4_3<= tree3_5+{tree3_6,4'b0} ;
        tree4_4<= tree3_7+{tree3_8,4'b0} ;
        end
       else begin
         tree4_1<=0 ;
         tree4_2<=0 ;
         tree4_3<=0 ;
         tree4_4<=0 ;
 end
 end
  always @(posedge clk)begin
if(state==4)begin
         mul_ready<=0;
         tree5_1<= tree4_1+{tree4_2,8'b0} ;
         tree5_2<= tree4_3+{tree4_4,8'b0} ;
       end
       else begin
         tree5_1<=0 ;
         tree5_2<=0 ;
 end
 end
  always @(posedge clk)begin
 if(state==5)begin
        mul_ready<=0;
        tree6_out<=tree5_1+{tree5_2,16'b0};
       end
       else begin
        tree6_out <=0;
 end
 end
   always @(posedge clk)begin
 if(state==6)begin
       result<=(mul_sign&(mul_op1[31]^mul_op2[31]))? ~tree6_out+1 : tree6_out;
       mul_ready<=1;
       end
       else begin
       result <=0;
 end
 end

endmodule
