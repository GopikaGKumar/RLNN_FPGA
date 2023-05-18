//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : counter.sv
// Module      : counter
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Counter used to keep tab of the memory entries
// Parameters  : WL : Sets the width of the counter registers
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : cnt_en -> Register enable
//             : cnt_rst -> Reset the countr to zero
// Output Ports: cnt -> Incrementing counter output value
//=======================================================================================

`default_nettype none
`timescale 1ns/1ps

module counter #(
    parameter WL = 16)(
    input   logic               clk,
    input   logic               rst_b,
    input   logic               cnt_en,
    input   logic               cnt_rst,
    output  logic   [WL-1:0]    cnt
    );

//---------------------------------------------------------------------------------------
// Local variables
//---------------------------------------------------------------------------------------
 
    logic   [WL-1:0]    cnt_nxt;


//---------------------------------------------------------------------------------------
// Counter Definition
//---------------------------------------------------------------------------------------

    always_comb begin
        if (cnt_rst) 
            cnt_nxt = 0;
        else 
            cnt_nxt = cnt + 1;
    end

//---------------------------------------------------------------------------------------
// Sequential Element Instantiation
//---------------------------------------------------------------------------------------


    register #(.WL(WL)) INST_REG_CNT (.clk(clk), .rst_b(rst_b), .d(cnt_nxt), .q(cnt), .wen(cnt_en));


endmodule: counter
