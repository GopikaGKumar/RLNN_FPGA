//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : relu_rounding.sv
// Module      : relu_rounding
// Author      : Jiachen Xu
// Date        : 24 Feb 2023
// Description : Unit that performs the Rectified Linear Operation as well as rounding 
// Parameters  : DATA_WIDTH : Bit width for the intermediate inputs
//             : Q : Bit width for the intermediate outputs
//             : D_POINT : Decimal bit position
// Input Ports : Q_in -> Input from the accumulator
// Output Ports: Q_out -> Rounded quantized output
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps



module relu_rounding #(
    parameter DATA_WIDTH = 32,
    parameter Q = 16,
    parameter D_POINT = 8)(
    input   logic   [DATA_WIDTH-1:0]      Q_in,
    output  logic   [Q-1:0]               Q_out
  );


//---------------------------------------------------------------------------------------
// Local variables
//---------------------------------------------------------------------------------------



  localparam TRUNC_FRONT = DATA_WIDTH - D_POINT;
  localparam TRUNC_REAR = Q - D_POINT;
  logic                     rounded_cout;
  logic [DATA_WIDTH-1:0]    rounded_in;
  logic signed [Q-1:0]      pos_of_num = {1'b0, {(Q-1) {1'b1}}};
  logic signed  [Q-1:0]     neg_of_num = {1'b1, {(Q-1) {1'b0}}};
  logic [DATA_WIDTH-1:0]    C;
  
//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------


  assign C[DATA_WIDTH-1:TRUNC_REAR-1] = '0;
  assign C[TRUNC_REAR-2:0] = '1;

  assign {rounded_cout,rounded_in} = Q_in + C + Q_in[DATA_WIDTH-1];

   always_comb begin

            if ((|rounded_in[DATA_WIDTH-1:TRUNC_FRONT-1] && !rounded_in[DATA_WIDTH-1]) || (rounded_in[DATA_WIDTH-1] && !Q_in[DATA_WIDTH-1]))
                    Q_out[Q-1:0] = pos_of_num;
            else if ((!(&rounded_in[DATA_WIDTH-1:TRUNC_FRONT-1]) && rounded_in[DATA_WIDTH-1]))
                    Q_out[Q-1:0] = neg_of_num;
             else
                    Q_out[Q-1:0] = rounded_in[TRUNC_FRONT-1:TRUNC_REAR];
   end
   
endmodule


