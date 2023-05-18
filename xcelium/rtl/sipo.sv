//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : sipo.sv
// Module      : sipo
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Serial in Parallel out Shift Register
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent units for parallelism
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : en -> control signal to shift the data serially
//             : sipo_load -> control signal to load the shifted input to the parallel output
//             : A_in-> Data to be loaded serially into the Shift register
// Output Ports: A_out -> Parallel output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps


module sipo #(
    parameter COUNT = 128,
    parameter DATA_WIDTH = 16)(
	input 					                clk,
   	input					                rst_b,
	input 					                en, 
    input   [DATA_WIDTH-1:0]		        A_in,
   	output	[(DATA_WIDTH*COUNT)-1:0] 	    A_out
  );

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------


    reg [(DATA_WIDTH*COUNT)-1:0] load_data;


//---------------------------------------------------------------------------------------
// Module Definition 
//---------------------------------------------------------------------------------------


   assign A_out = load_data;
  
    always_ff @(posedge clk or negedge rst_b) begin
         if(~rst_b)
                load_data        <= 0;
        else begin
            if(en)
                load_data       <= {load_data[(DATA_WIDTH*COUNT)-2:0],A_in};
            end
    end

endmodule
