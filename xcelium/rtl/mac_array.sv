//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : mac_array.sv
// Module      : mac_array
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Array of the Multiply Accumulate modules for parallelism
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent MAC units for parallelism
// Input Ports : a_in -> Multiplicand
//             : w_in -> Multiplier
//             : y_in -> Addition input
// Output Ports: y_out -> (a_in * w_in) + y_in
//=======================================================================================

//`default_nettype none
`timescale 1ns/1ps


module mac_array #(
    parameter COUNT = 128,
   	parameter DATA_WIDTH = 16)(
    input       [(DATA_WIDTH*COUNT)-1:0]             a_in,
    input       [(DATA_WIDTH*COUNT)-1:0]             w_in,
    input       [(2*DATA_WIDTH*COUNT)-1:0]           y_in,
    output reg  [(2*DATA_WIDTH*COUNT)-1:0]           y_out 
  );

//---------------------------------------------------------------------------------------
// Generate loop that creates instances of a chain of MAC units
//--------------------------------------------------------------------------------------

  
  generate
  genvar i;
    for (i=0; i<COUNT; i=i+1) begin : mac_128
      mac #(.W_W(DATA_WIDTH),.W_A(DATA_WIDTH),.W_Y(2*DATA_WIDTH)) INST_MAC (
        .a_in(a_in[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH]),
        .w_in(w_in[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH]),
        .y_in(y_in[(2*(i+1)*DATA_WIDTH)-1:2*i*DATA_WIDTH]),
        .y_out(y_out[(2*(i+1)*DATA_WIDTH)-1:2*i*DATA_WIDTH])
      );
  end
endgenerate

endmodule
