//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : piso.sv
// Module      : piso
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Parallel in Serial out Shift Register
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent units for parallelism
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : piso_load -> Control signal to load the input data into the shift register
//             : en -> control signal to shift the data serially
//             : A_in-> Data to be loaded into the Shift register
// Output Ports: A_shift_out -> Serial shifted output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps


module piso #(
    parameter COUNT = 128,
    parameter DATA_WIDTH = 16)(
	input 					                clk,
   	input					                rst_b,
    input					                piso_load,
	input 					                en, 
   	input	    [(DATA_WIDTH*COUNT)-1:0] 	A_in,
   output reg   [DATA_WIDTH-1:0]		    A_shift_out
  );

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------


    reg [(DATA_WIDTH*COUNT)-1:0] load_data;


//---------------------------------------------------------------------------------------
// Module Definition 
//---------------------------------------------------------------------------------------


    assign A_shift_out = load_data[(DATA_WIDTH*COUNT)-1:DATA_WIDTH*(COUNT-1)];

  
    always_ff @(posedge clk or negedge rst_b) begin
         if(~rst_b)
                load_data        <= 0;
        else begin
            if(piso_load == 1'b1)
                load_data       <= A_in;
            else if(en & (piso_load == 1'b0)) begin
                load_data       <= {load_data[(DATA_WIDTH*(COUNT-1))-1:0],{DATA_WIDTH{1'b0}}};
                end
        end
    end

endmodule
