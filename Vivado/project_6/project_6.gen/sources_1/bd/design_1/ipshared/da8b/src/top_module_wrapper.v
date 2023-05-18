//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : top_module.sv
// Module      : top_module
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Top level of the RL system
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent registers for parallelism
//             : NEURON_INPUT_LAYER : Number of neurons in the input layer
//             : NEURON_LAYER2 : Number of neurons in the second(first hidden) layer
//             : NEURON_LAYER3 : Number of neurons in the third(second hidden) layer
//             : NEURON_LAYER4 : Number of neurons in the fourth(third hidden) layer
//             : NEURON_LAYER5 : Number of neurons in the fifth(fourth hidden) layer
//             : NEURON_OUTPUT_LAYER : Number of neurons in the output layer
//             : LAYER_COUNT : Total number of layers in the neural network
//             : MAX_ADDR_BITS : Maximum number of bits to reference the address of memory location
//             : COUNTER_LEN : Length of the counter registers
//             : N : Count of the input memory file
//             : MAX_HEIGHT : Maximum height of the memory stack
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : use_target -> User input to use target NN parameters
//             : is_training -> User input to decide the training and inference phases
//             : loss -> User input that gets the loss between target and model output
//             : int_out_q -> Intermediate layer output after computation
// Output Ports: mux_piso_in -> Mux select to decide the input of the Parallel in Serial out shift register
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module top_module_wrapper #(
  parameter DATA_WIDTH = 16,
  parameter COUNT = 128,
  parameter NEURON_INPUT_LAYER = 10,
  parameter NEURON_LAYER1 = 128,
  parameter NEURON_LAYER2 = 128,
  parameter NEURON_LAYER3 = 128,
  parameter NEURON_LAYER4 = 128,
  parameter NEURON_LAYER5 = 128,
  parameter NEURON_OUTPUT_LAYER = 30,
  parameter LAYER_COUNT = 5,
  parameter MAX_WT_HEIGHT = 512,
  parameter MAX_WT_ADDR_BITS = $clog2(MAX_WT_HEIGHT),
  parameter MAX_BIAS_HEIGHT = 4,
  parameter MAX_BIAS_ADDR_BITS = $clog2(MAX_BIAS_HEIGHT),
  parameter MAX_INT_OP_HEIGHT = 4,
  parameter MAX_INT_OP_ADDR_BITS = $clog2(MAX_INT_OP_HEIGHT))(
  input 				                            clk,
  input 				                            rst_b,
  input                                             is_training,
  input                                             input_enable,
  input [DATA_WIDTH-1:0]                            loss,
  input [(NEURON_INPUT_LAYER*DATA_WIDTH)-1:0]       nn_input,
  input                                             use_target,
  output 	                                        target_fwd_done,
  output                                            model_fwd_done,
  output                                            training_done,
  output [(NEURON_OUTPUT_LAYER*DATA_WIDTH)-1:0]     nn_inf_output,
  output                                            output_nn_opt1,
  output                                            output_nn_opt2
   );



//---------------------------------------------------------------------------------------
// Module Instantiations
//---------------------------------------------------------------------------------------


top_module
 #(
.DATA_WIDTH(DATA_WIDTH),
.COUNT(COUNT),
.NEURON_INPUT_LAYER(NEURON_INPUT_LAYER),
.NEURON_OUTPUT_LAYER(NEURON_OUTPUT_LAYER),
.NEURON_LAYER1(NEURON_LAYER1),
.NEURON_LAYER2(NEURON_LAYER2),
.MAX_WT_HEIGHT(MAX_WT_HEIGHT),
.NEURON_LAYER3(NEURON_LAYER3),
.NEURON_LAYER4(NEURON_LAYER4),
.NEURON_LAYER5(NEURON_LAYER5)) 
INST_TARGET (.clk(clk),
.nn_input(nn_input),
.rst_b(rst_b),
.use_target(use_target),
.input_enable(input_enable),
.target_fwd_done(target_fwd_done),
.model_fwd_done(model_fwd_done),
.training_done(training_done),
.is_training(is_training),
.loss(loss),
.output_nn_opt1(output_nn_opt1),
.output_nn_opt2(output_nn_opt2),
.nn_inf_output(nn_inf_output)
);

                 
endmodule

