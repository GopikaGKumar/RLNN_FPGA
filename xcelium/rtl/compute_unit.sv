// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : compute_unit.sv
// Module      : compute_unit
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Combination of MAC units, Accumulator and Quantization unit
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent units for parallelism
// Input Ports : clk -> Clock
//             : rst_accm_b -> Active low reset for the accumulator flop
//             : accm_en -> Accumulator enable
//             : mux_accm_inp -> Mux select to choose the input of the accumulator addend 
//               input between the accumulator output or the add_inp 
//             : mult_inp_1 -> Multiplicand
//             : mult_inp_2 -> Multiplier
//             : add_inp -> Addition input from other sources other than accumulator output 
// Output Ports: partial_out_q -> Quantized output after an accumulation cycle
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps


module compute_unit #(
    parameter COUNT = 128,
    parameter DATA_WIDTH = 16 )(
	input 					                        clk,
    input                                           rst_b,
   	input					                        rst_accm_b,
    input                                           accm_en,
    input                                           mux_accm_inp,
    input                                           en_adder_tree,
    input                                           sipo_shift,
    input       [(DATA_WIDTH*COUNT)-1:0]            mult_inp_1,
    input       [(DATA_WIDTH*COUNT)-1:0]            mult_inp_2,
    input       [(2*DATA_WIDTH*COUNT)-1:0]          add_inp,
    output reg  [(DATA_WIDTH*COUNT)-1:0]		    partial_out_q,
    output reg  [(2*DATA_WIDTH*COUNT)-1:0]          partial_out,
    output reg  [DATA_WIDTH-1:0]                    partial_out_reduced,
    output reg  [(DATA_WIDTH*COUNT)-1:0]            dldA

  );


//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

 reg [(2*DATA_WIDTH*COUNT)-1:0] partial_in,accm_out;

 assign partial_in = (mux_accm_inp == 1'b1) ? accm_out : add_inp;

//---------------------------------------------------------------------------------------
// Module Instantiations 
//---------------------------------------------------------------------------------------


 mac_array #(.COUNT(COUNT),.DATA_WIDTH(DATA_WIDTH)) INST_MAC (.a_in(mult_inp_1),.w_in(mult_inp_2),.y_in(partial_in),.y_out(partial_out));

 accumulator #(.COUNT(COUNT),.DATA_WIDTH(2*DATA_WIDTH)) INST_ACC (.clk(clk),.rst_b(rst_accm_b),.en(accm_en),.A_in(partial_out),.A_out(accm_out));

 quantizer_array #(.COUNT(COUNT),.DATA_WIDTH(DATA_WIDTH)) INST_QUANT (.Q_in(partial_out),.Q_out(partial_out_q));

 adder_tree #(.DATA_WIDTH(DATA_WIDTH),.COUNT(COUNT)) INST_ADDER_TREE (.en_adder_tree(en_adder_tree),.A(partial_out_q),.Bias(16'b0),.C(partial_out_reduced));

 //adder_tree_trial #(.W(DATA_WIDTH),.L(COUNT)) INST_ADDER_TREE (.en_adder_tree(en_adder_tree),.A_in(partial_out_q),.Bias(4'b0),.C(partial_out_reduced));

 sipo #(.DATA_WIDTH(DATA_WIDTH),.COUNT(COUNT)) INST_SIPO (.clk(clk),.rst_b(rst_b),.en(sipo_shift),.A_in(partial_out_reduced),.A_out(dldA)); 

endmodule
