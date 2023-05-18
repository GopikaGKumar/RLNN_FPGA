//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : adder.sv
// Module      : adder
// Author      : Jiachen Xu
// Date        : 24 Feb 2023
// Description : Adder implementation with overflow detection
// Parameters  : W : Data width of the operands         
// Input Ports : A -> First addition operand
//             : B -> Second Addition operand
// Output Ports: C -> Output of the addition 
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

(* use_dsp = "yes"*) module adder #(
    parameter W = 16)(
    input   logic   [W-1:0]   A, B,
    output  logic   [W-1:0]   C
  );

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

  logic carry_out;
  logic pos_ovf, neg_ovf;
  logic [W-1:0]result;
  logic signed [W-1:0] pos_of_num = {1'b0, {(W-1) {1'b1}}};
  logic signed [W-1:0] neg_of_num = {1'b1, {(W-1) {1'b0}}};

//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------

  assign {carry_out,result} = A + B;
  
  assign pos_ovf = !A[W-1] && !B[W-1] && result[W-1];
  assign neg_ovf =  A[W-1] &&  B[W-1] && !result[W-1];
  always_comb begin
    if (pos_ovf)
      C = pos_of_num;
    else if (neg_ovf)
      C = neg_of_num;
    else
      C = result;
  end
endmodule: adder
