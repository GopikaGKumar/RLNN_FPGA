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
// Parameters  : DATA_WIDTH : Data width of the addends
//             : COUNT : No: of operands to reduce       
// Input Ports : en_adder_tree -> Control signal to enable the adder tree output
//             : A -> The group of operands to reduce
//             : Bias -> Input Bias to be added to the reduced output
// Output Ports: C -> Reduced Output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module adder_tree #(
    parameter DATA_WIDTH = 16,
    parameter COUNT = 128)(
    input                                           en_adder_tree,
    input   logic [COUNT-1:0] [DATA_WIDTH-1:0]      A ,
    input   logic [DATA_WIDTH-1:0]                  Bias,
    output  logic [DATA_WIDTH-1:0]                  C
  );

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

  logic [COUNT/2-1:0]       [DATA_WIDTH-1:0]     layer1;
  logic [COUNT/4-1:0]       [DATA_WIDTH-1:0]     layer2;
  logic [COUNT/8-1:0]       [DATA_WIDTH-1:0]     layer3;
  logic [COUNT/16-1:0]      [DATA_WIDTH-1:0]     layer4;
  logic [COUNT/32-1:0]      [DATA_WIDTH-1:0]     layer5;
  logic [COUNT/64-1:0]      [DATA_WIDTH-1:0]     layer6;
  logic [DATA_WIDTH-1:0]                         layer7;
  logic [DATA_WIDTH-1:0]                         regular_output;
  logic [DATA_WIDTH-1:0]                         all_zero = 'b0;


//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------

  	genvar i;
	generate
      for (i=0; i<COUNT/2; i=i+1) begin : tree_layer1
    	adder #(.W(DATA_WIDTH)) 
        inst_adder_layer1(
          .A(A[i*2]),
          .B(A[i*2+1]),
          .C(layer1[i]));
       end
      
      for (i=0; i<COUNT/4; i=i+1) begin : tree_layer2 
    	adder #(.W(DATA_WIDTH)) 
        inst_adder_layer2(
          .A(layer1[i*2]),
          .B(layer1[i*2+1]),
          .C(layer2[i]));
       end
      for (i=0; i<COUNT/8; i=i+1) begin : tree_layer3 
    	adder #(.W(DATA_WIDTH)) 
        inst_adder_layer3(
          .A(layer2[i*2]),
          .B(layer2[i*2+1]),
          .C(layer3[i]));
       end
      for (i=0; i<COUNT/16; i=i+1) begin : tree_layer4 
    	adder #(.W(DATA_WIDTH)) 
        inst_adder_layer4(
          .A(layer3[i*2]),
          .B(layer3[i*2+1]),
          .C(layer4[i]));
       end
      for (i=0; i<COUNT/32; i=i+1) begin : tree_layer5 
    	adder #(.W(DATA_WIDTH)) 
        inst_adder_layer5(
          .A(layer4[i*2]),
          .B(layer4[i*2+1]),
          .C(layer5[i]));
       end
      for (i=0; i<COUNT/64; i=i+1) begin : tree_layer6
    	  adder #(.W(DATA_WIDTH)) 
        inst_adder_layer6(
          .A(layer5[i*2]),
          .B(layer5[i*2+1]),
          .C(layer6[i]));
       end
      adder #(.W(DATA_WIDTH)) inst_adder_layer7(.A(layer6[0]),.B(layer6[1]),.C(layer7));
      adder #(.W(DATA_WIDTH)) inst_adder_bias(.A(layer7),.B(Bias),.C(regular_output));

      assign C = (en_adder_tree && regular_output[DATA_WIDTH-1]) ? all_zero:regular_output;

      
	endgenerate 

    
endmodule: adder_tree



