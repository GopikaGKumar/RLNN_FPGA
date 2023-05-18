//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : quantizer_array.sv
// Module      : quantizer_array
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Array of quantization units for rounding the accumulated output
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent units for parallelism
// Input Ports : Q_in -> Original input from the accumulator
// Output Ports: Q_out -> Quantized Output which is half the bit width of the input
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps


module quantizer_array #(
    parameter DATA_WIDTH = 16,
    parameter COUNT = 128) (
    input      [(2*DATA_WIDTH*COUNT)-1:0]       Q_in,
    output reg [(DATA_WIDTH*COUNT)-1:0]         Q_out 
  );

//---------------------------------------------------------------------------------------
// Generate loop that creates instances of a chain of rounding units
//---------------------------------------------------------------------------------------
  
  generate
  genvar i;
    for (i=0; i<COUNT; i=i+1) begin : Quant_128
        relu_rounding #(.Q(DATA_WIDTH),.DATA_WIDTH(2*DATA_WIDTH),.D_POINT(DATA_WIDTH/2)) INST_QUANT(
        .Q_in(Q_in[(2*(i+1)*DATA_WIDTH)-1:2*i*DATA_WIDTH]),
        .Q_out(Q_out[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH])
      );

   end
   endgenerate

endmodule
