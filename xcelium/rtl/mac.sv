//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : mac.sv
// Module      : mac
// Author      : Jiachen Xu
// Date        : 24 Feb 2023
// Description : Multiply accumulate unit with capability for positive and 
//               negative overflow detection
// Parameters  : W_A : bit width of the multiplicand
//             : W_W : bit width of the multiplier
//             : W_Y : bit width of the addend input and final output          
// Input Ports : a_in -> Multiplicand
//             : w_in -> Multiplier
//             : y_in -> Addition input
// Output Ports: y_out -> (a_in * w_in) + y_in
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

(* use_dsp = "yes" *) module mac #(
    parameter W_W = 8, 
    parameter W_A = 8,
    parameter W_Y = 16)(
    input   logic   [W_A-1:0]           a_in,
    input   logic   [W_W-1:0]           w_in,
    input   logic   [W_Y-1:0]           y_in,
    output  logic   [W_Y-1:0]           y_out
    );

//---------------------------------------------------------------------------------------
// Local variables
//---------------------------------------------------------------------------------------


  	logic signed [W_Y-1:0]  pos_ovf_num = {1'b0, {(W_Y-1) {1'b1}}};
  	logic signed [W_Y-1:0]  neg_ovf_num = {1'b1, {(W_Y-1) {1'b0}}};
  	logic signed [W_Y-1:0]  result;
  
  	logic                   pos_ovf, neg_ovf, sign_after_mult;

   wire [W_A:0] as_in = {a_in[W_A-1]&1'b1, a_in};
   wire [W_W:0] ws_in = {w_in[W_W-1]&1'b1, w_in};
   wire [W_Y:0] ys_in = {y_in[W_Y-1]&1'b1, y_in};



//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------

  	assign sign_after_mult = a_in[W_A-1] ^ w_in[W_W-1];
  	assign pos_ovf = !sign_after_mult && !y_in[W_Y-1] && result[W_Y-1];
  	assign neg_ovf =  sign_after_mult &&  y_in[W_Y-1] && !result[W_Y-1];


    assign result = $signed(as_in) * $signed(ws_in) + $signed(ys_in);
  
    always_comb begin
		if (pos_ovf)
      		y_out = pos_ovf_num;
    	else if (neg_ovf)
      		y_out = neg_ovf_num;
    	else
      		y_out = result;
    end
  

endmodule: mac
