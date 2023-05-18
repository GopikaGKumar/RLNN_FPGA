//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : adder_tree.sv
// Module      : adder_tree
// Author      : Jiachen Xu
// Date        : 24 Feb 2023
// Description : 7 stages adder tree to reduce 128 additions
// Parameters  : W : Data width of the addends
//             : L : No: of operands to reduce       
// Input Ports : en_adder_tree -> Control signal to enable the adder tree output
//             : A -> The group of operands to reduce
//             : Bias -> Input Bias to be added to the reduced output
// Output Ports: C -> Reduced Output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module adder_tree_trial #(
    parameter W = 16,
    parameter L = 128)(
    input                           en_adder_tree,
    input   logic [(W*L)-1:0]       A_in ,
    input   logic [W-1:0]           Bias,
    output  logic [W-1:0]           C
  );

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

  logic [L/2-1:0]   [W-1:0]     layer1;
  logic [L/4-1:0]   [W-1:0]     layer2;
 /*logic [L/8-1:0]  [W-1:0]     layer3;
  logic [L/16-1:0]  [W-1:0]     layer4;
  logic [L/32-1:0]  [W-1:0]     layer5;
  logic [L/64-1:0]  [W-1:0]     layer6;
  logic [W-1:0]                 layer7;*/
  logic [W-1:0]                 regular_output;
  logic [W-1:0]                 all_zero = 'b0;
 // integer                       j;
  logic [L-1:0][W-1:0] A;

//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------


    always_comb begin
        
        for (int j=0; j<L; j=j+1) begin 
            for(int k=0; k< W; k=k+1) begin
                A[j][k] = A_in[(j*W) + k];
        end
    end
    end

  	genvar i;
	generate
      for (i=0; i<L/2; i=i+1) begin : tree_layer1
    	adder #(.W(W)) 
        inst_adder_layer1(
          .A(A[i*2]),
          .B(A[i*2+1]),
          .C(layer1[i]));
       end
      
    /*  for (i=0; i<L/4; i=i+1) begin : tree_layer2 
    	adder #(.W(W)) 
        inst_adder_layer2(
          .A(layer1[i*2]),
          .B(layer1[i*2+1]),
          .C(layer2[i]));
       end
      for (i=0; i<L/8; i=i+1) begin : tree_layer3 
    	adder #(.W(W)) 
        inst_adder_layer3(
          .A(layer2[i*2]),
          .B(layer2[i*2+1]),
          .C(layer3[i]));
       end
      for (i=0; i<L/16; i=i+1) begin : tree_layer4 
    	adder #(.W(W)) 
        inst_adder_layer4(
          .A(layer3[i*2]),
          .B(layer3[i*2+1]),
          .C(layer4[i]));
       end
      for (i=0; i<L/32; i=i+1) begin : tree_layer5 
    	adder #(.W(W)) 
        inst_adder_layer5(
          .A(layer4[i*2]),
          .B(layer4[i*2+1]),
          .C(layer5[i]));
       end
      for (i=0; i<L/64; i=i+1) begin : tree_layer6
    	  adder #(.W(W)) 
        inst_adder_layer6(
          .A(layer5[i*2]),
          .B(layer5[i*2+1]),
          .C(layer6[i]));
       end*/
      adder #(.W(W)) inst_adder_layer2(.A(layer1[0]),.B(layer1[1]),.C(layer2));
      adder #(.W(W)) inst_adder_bias(.A(layer2),.B(Bias),.C(regular_output));

     assign C = (en_adder_tree && regular_output[W-1]) ? all_zero:regular_output;

    //assign C = (en_adder_tree && regular_output[W-1]) ? regular_output : all_zero;


  /*    always @* begin
        for(int i=0; i<4; i++) begin
          $display("layer5[%d]: %f", i, $itor(signed'(layer5[i])*(2.0**-4.0)));
        end
        for(int i=0; i<2; i++) begin
          $display("layer6[%d]: %f", i, $itor(signed'(layer6[i])*(2.0**-4.0)));
        end
      end*/

	endgenerate 

    
endmodule: adder_tree_trial



