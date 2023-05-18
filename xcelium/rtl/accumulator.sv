//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : accumulator.sv
// Module      : accumulator
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Register chain for accumulating the output of the Multiply * Accumulate Unit
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent registers for parallelism
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : en -> Register enable
//             : A_in-> Flipflop Input
// Output Ports: A_out -> Flipflop Output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps


module accumulator #(
    parameter DATA_WIDTH = 32,                     
    parameter COUNT = 128)(
    input 				                    clk,
   	input				                    rst_b,
	input				                    en,
   	input	    [DATA_WIDTH*COUNT-1:0] 	    A_in,
    output reg	[DATA_WIDTH*COUNT-1:0]	    A_out	
    );

//---------------------------------------------------------------------------------------
// Generate loop that creates instances of a chain of registers
//---------------------------------------------------------------------------------------
   
  generate
      genvar i;
        for (i=0; i<COUNT; i=i+1) begin : reg_32
          register #(.WL(DATA_WIDTH)) INST_REG_ACCM (
           .clk(clk),
           .rst_b(rst_b),
            .d(A_in[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH]),
            .q(A_out[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH]),
            .wen(en)
          );
      end
  endgenerate

endmodule
