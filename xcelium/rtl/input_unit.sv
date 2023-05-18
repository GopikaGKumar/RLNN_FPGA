//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : input_unit.sv
// Module      : input_unit
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Input selection unit for compute unit and 
//               Parallel-in Serial out Shift Register control 
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent units for parallelism
//             : NEURON_INPUT_LAYER : Number of neurons in the input layer
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : nn_input -> Input to the first input layer
//             : mux_piso_in -> Mux select that decides the input to the Parallel-in
//               serial out shift register for different modes of operation
//             : layer_output -> The quantized output of the compute unit
//             : int_op_mem_data_out : Data from the intermediate layer output memory
//             : target_weight_mem_data_out : Data from the target weights memory
//             : model_weight_mem_data_out : Data from the model weights memory
//             : target_bias_mem_data_out : Data from the target bias memory
//             : model_bias_mem_data_out : Data from the model bias memory
//             : model_grad_weight_mem_data_out : Data from the gradient weights memory
//             : dldz -> Back propagated loss gradients 
//             : mux_mult_inp_2 -> Mux select for the multiplier input of compute unit
//             : mux_add_inp -> Mux select for the addend input of compute unit
//             : piso_load -> Control signal to load into the Parallel in Serial out Reg
//             : piso_shift -> Control signal to shift the contents of Parallel in
//               Serial out shift register serially out
//             : use_target -> Use the target NN parameters instead of the model parameters
// Output Ports: mult_inp_1 -> Multiplicand input to the compute unit
//             : mult_inp_2 -> Multiplier input to the compute unit
//             : add_inp -> Addend input to the compute unit
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module input_unit #(
    parameter COUNT = 128,
    parameter DATA_WIDTH = 16,
    parameter NEURON_INPUT_LAYER = 10)(
	input 					                            clk,
   	input					                            rst_b,
    input	    [(DATA_WIDTH*NEURON_INPUT_LAYER)-1:0]   nn_input,
    input       [1:0]                                   mux_piso_in,
    input       [(DATA_WIDTH*COUNT)-1:0]                layer_output,
    input       [(DATA_WIDTH*COUNT)-1:0]                int_op_mem_data_out,
    input       [(DATA_WIDTH*COUNT)-1:0]                target_weight_mem_data_out,
    input       [(DATA_WIDTH*COUNT)-1:0]                model_weight_mem_data_out,
    input       [(2*DATA_WIDTH*COUNT)-1:0]              target_bias_mem_data_out,
    input       [(2*DATA_WIDTH*COUNT)-1:0]              model_bias_mem_data_out,
    input       [(2*DATA_WIDTH*COUNT)-1:0]              model_grad_weight_mem_data_out,
    input       [(2*DATA_WIDTH*COUNT)-1:0]              model_grad_bias_mem_data_out,    
    input       [(DATA_WIDTH*COUNT)-1:0]                dldz,
    input       [1:0]                                   mux_mult_inp_2,
    input       [1:0]                                   mux_mult_inp_1,
    input       [1:0]                                   mux_add_inp,
    input                                               piso_load,
    input                                               piso_shift,
    input                                               use_target,
    output reg  [(DATA_WIDTH*COUNT)-1:0]		        mult_inp_1,
    output reg  [(DATA_WIDTH*COUNT)-1:0]                mult_inp_2,
    output reg  [(2*DATA_WIDTH*COUNT)-1:0]              add_inp
  );


//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

    logic [(DATA_WIDTH*COUNT)-1:0]        piso_in;
    logic [DATA_WIDTH-1:0]                piso_shift_out;

//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------

always_comb begin

    case(mux_mult_inp_1)

    2'b00 : mult_inp_1 = {COUNT{piso_shift_out}};
    2'b01 : mult_inp_1 = {COUNT{4'd1}}; //TODO Change it to 16 radix
    2'b10 : mult_inp_1 = model_weight_mem_data_out;
    default : mult_inp_1 = 0;
    endcase
end
//---------------------------------------------------------------------------------------
// Multiplexer for PISO Input
//---------------------------------------------------------------------------------------


always_comb begin

 case(mux_piso_in)

    2'b00 : piso_in = {{((COUNT-NEURON_INPUT_LAYER)*DATA_WIDTH){1'b0}},nn_input};
    2'b01 : piso_in = layer_output;
    2'b10 : piso_in = int_op_mem_data_out;

    default : piso_in = 0;
    endcase

    end

//---------------------------------------------------------------------------------------
// Multiplexer for Compute unit Input 2
//---------------------------------------------------------------------------------------



always_comb begin


 case(mux_mult_inp_2)

    2'b00 : mult_inp_2 = (use_target == 1'b1) ? target_weight_mem_data_out : model_weight_mem_data_out;
    2'b01 : mult_inp_2 = dldz;

    default : mult_inp_2 = 0;
    endcase

    end

//---------------------------------------------------------------------------------------
// Multiplexer for Compute unit Addend Input 
//---------------------------------------------------------------------------------------


always_comb begin


 case(mux_add_inp)

    2'b00 : add_inp = (use_target == 1'b1) ? target_bias_mem_data_out : model_bias_mem_data_out;
    2'b01 : add_inp = model_grad_weight_mem_data_out;
    2'b10 : add_inp = model_grad_bias_mem_data_out;
    2'b11 : add_inp = 0;

    default : add_inp = 0;
    endcase

    end

//---------------------------------------------------------------------------------------
// Parallel In Serial Out Shift register Instantiation 
//---------------------------------------------------------------------------------------


piso #(.COUNT(COUNT),.DATA_WIDTH(DATA_WIDTH)) INST_PISO (.clk(clk),.rst_b(rst_b),.piso_load(piso_load),.en(piso_shift),.A_in(piso_in),.A_shift_out(piso_shift_out)); 

endmodule
