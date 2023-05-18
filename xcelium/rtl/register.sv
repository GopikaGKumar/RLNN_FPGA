// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : register.sv
// Module      : register
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : A simple D-Flip flop
// Parameters  : WL : Data Width of the register
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : en -> Register enable
//             : A_in-> Flipflop Input
// Output Ports: A_out -> Flipflop Output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module register #(
    parameter WL = 1)(
    input   logic               clk,
    input   logic               rst_b,
    input   logic   [WL-1:0]    d,
    output  logic   [WL-1:0]    q,
    input   logic               wen);

//---------------------------------------------------------------------------------------
// Register Definition 
//---------------------------------------------------------------------------------------


    always_ff @(posedge clk) begin
        if (~rst_b)
            q <= 'b0;
        else begin
            if (wen)
                q <= d;
        end
    end

endmodule: register
