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

module top_module #(
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
    //output                                          output_ndddddn_opt3
);

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------


 //logic [(NEURON_INPUT_LAYER*DATA_WIDTH)-1:0]        nn_input;
 logic [MAX_WT_ADDR_BITS-1:0]                          target_weight_mem_addr;
 logic [MAX_WT_ADDR_BITS-1:0]                          model_weight_mem_addr;
 logic [MAX_BIAS_ADDR_BITS-1:0]                        target_bias_mem_addr;
 logic [MAX_BIAS_ADDR_BITS-1:0]                        model_bias_mem_addr;
 logic [MAX_INT_OP_ADDR_BITS-1:0]                      int_op_mem_addr;
 logic [MAX_WT_ADDR_BITS-1:0]                          model_grad_weight_mem_addr;
 logic [MAX_BIAS_ADDR_BITS-1:0]                        model_grad_bias_mem_addr;



 logic [(2*DATA_WIDTH*COUNT)-1:0]                   target_bias_mem_data_in,target_bias_mem_data_out;
 logic [(2*DATA_WIDTH*COUNT)-1:0]                   model_bias_mem_data_in,model_bias_mem_data_out;
 logic [(DATA_WIDTH*COUNT)-1:0]                     target_weight_mem_data_in,target_weight_mem_data_out;
 logic [(DATA_WIDTH*COUNT)-1:0]                     model_weight_mem_data_in,model_weight_mem_data_out;
 logic [(DATA_WIDTH*COUNT)-1:0]                     int_op_mem_data_in,int_op_mem_data_out;
 logic [(2*DATA_WIDTH*COUNT)-1:0]                   model_grad_weight_mem_data_in,model_grad_weight_mem_data_out;
 logic [(2*DATA_WIDTH*COUNT)-1:0]                   model_grad_bias_mem_data_in,model_grad_bias_mem_data_out;
 logic [DATA_WIDTH-1:0]                             partial_out_reduced;


 logic [(2*DATA_WIDTH*COUNT)-1:0]                    add_inp,partial_out;

 logic  [(DATA_WIDTH*COUNT)-1:0]                     mult_inp_1,mult_inp_2,partial_out_q,dldz,dldA,intermediate_reg;
 logic                                               target_weight_mem_en,target_weight_mem_write_en,target_weight_mem_read_en;
 logic                                               model_weight_mem_en,model_weight_mem_write_en,model_weight_mem_read_en;
 logic                                               model_grad_weight_mem_en,model_grad_weight_mem_write_en,model_grad_weight_mem_read_en;
 logic                                               target_bias_mem_en,target_bias_mem_write_en,target_bias_mem_read_en;
 logic                                               int_op_mem_en,int_op_mem_write_en,int_op_mem_read_en;
 logic                                               model_bias_mem_en,model_bias_mem_write_en,model_bias_mem_read_en;
 logic                                               rst_accm_b, accm_en,mux_accm_inp,piso_load,piso_shift,en_adder_tree,sipo_shift,intermediate_reg_en;
 logic  [1:0]                                        mux_piso_in,mux_mult_inp_1,mux_mult_inp_2,mux_add_inp;


//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------

   //assign nn_inf_output = (model_fwd_done | target_fwd_done) ? intermediate_reg[(NEURON_OUTPUT_LAYER*DATA_WIDTH)-1:0] : {NEURON_OUTPUT_LAYER*DATA_WIDTH{1'b0}};
     assign nn_inf_output = intermediate_reg[(NEURON_OUTPUT_LAYER*DATA_WIDTH)-1:0] ;


   assign output_nn_opt1 = &((target_fwd_done == 1'b1) ? partial_out_q[(DATA_WIDTH*COUNT)-1:DATA_WIDTH*(COUNT-NEURON_LAYER5)] : 0);
   assign output_nn_opt2 = &((training_done == 1'b1) ? partial_out_q[(DATA_WIDTH*COUNT)-1:DATA_WIDTH*(COUNT-NEURON_LAYER5)] : 0);
   //assign output_nn_opt3 = &((model_fwd_done == 1'b1) ? partial_out_q[(DATA_WIDTH*COUNT)-1:DATA_WIDTH*(COUNT-NEURON_LAYER5)] : 0);
    //assign nn_input = 12'b000100100011;


//---------------------------------------------------------------------------------------
// Module Instantiations
//---------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------
// Compute Unit
//---------------------------------------------------------------------------------------


compute_unit #(.COUNT(COUNT),.DATA_WIDTH(DATA_WIDTH)) INST_MAC 
(.mult_inp_1(mult_inp_1),
.mult_inp_2(mult_inp_2),
.add_inp(add_inp),
.en_adder_tree(en_adder_tree),
.clk(clk),
.rst_b(rst_b),
.sipo_shift(sipo_shift),
.rst_accm_b(rst_accm_b),
.accm_en(accm_en),
.mux_accm_inp(mux_accm_inp),
.partial_out_q(partial_out_q),
.partial_out(partial_out),
.partial_out_reduced(partial_out_reduced),
.dldA(dldA)
);

//---------------------------------------------------------------------------------------
// Input Unit
//---------------------------------------------------------------------------------------


input_unit #(.COUNT(COUNT),.DATA_WIDTH(DATA_WIDTH),.NEURON_INPUT_LAYER(NEURON_INPUT_LAYER)) INST_INP_SHIFT 
(.clk(clk),
.rst_b(rst_b),
.nn_input(nn_input),
.mux_piso_in(mux_piso_in),
.layer_output(intermediate_reg),
.int_op_mem_data_out(int_op_mem_data_out),
.target_weight_mem_data_out(target_weight_mem_data_out),
.model_weight_mem_data_out(model_weight_mem_data_out),
.target_bias_mem_data_out(target_bias_mem_data_out),
.model_bias_mem_data_out(model_bias_mem_data_out),
.model_grad_weight_mem_data_out(model_grad_weight_mem_data_out),
.model_grad_bias_mem_data_out(model_grad_bias_mem_data_out),
.dldz(dldz),
.mux_mult_inp_2(mux_mult_inp_2),
.mux_mult_inp_1(mux_mult_inp_1),
.mux_add_inp(mux_add_inp),
.piso_load(piso_load),
.piso_shift(piso_shift),
.use_target(use_target),
.mult_inp_1(mult_inp_1),
.mult_inp_2(mult_inp_2),
.add_inp(add_inp));

//---------------------------------------------------------------------------------------
// Memory Arrays
//---------------------------------------------------------------------------------------


sram_array #(.DATA_WIDTH(DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_WT_HEIGHT),.ADDR_BITS(MAX_WT_ADDR_BITS),.memory_type("target_weight")) INST_TARGET_WEIGHT_MEM
 (.clk(clk),
.rst_b(rst_b),
.addr(target_weight_mem_addr),
.mem_data_in(target_weight_mem_data_in),
.mem_data_out(target_weight_mem_data_out),
.mem_en(target_weight_mem_en),
.mem_write_en(target_weight_mem_write_en));

sram_array #(.DATA_WIDTH(2*DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_BIAS_HEIGHT),.ADDR_BITS(MAX_BIAS_ADDR_BITS),.memory_type("target_bias")) INST_TARGET_BIAS_MEM
 (.clk(clk),
.rst_b(rst_b),
.addr(target_bias_mem_addr),
.mem_data_in(target_bias_mem_data_in),
.mem_data_out(target_bias_mem_data_out),
.mem_en(target_bias_mem_en),
.mem_write_en(target_bias_mem_write_en));

sram_array #(.DATA_WIDTH(DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_WT_HEIGHT),.ADDR_BITS(MAX_WT_ADDR_BITS),.memory_type("model_weight")) INST_MODEL_WEIGHT_MEM
 (.clk(clk),
.rst_b(rst_b),
.addr(model_weight_mem_addr),
.mem_data_in(model_weight_mem_data_in),
.mem_data_out(model_weight_mem_data_out),
.mem_en(model_weight_mem_en),
.mem_write_en(model_weight_mem_write_en)); 

sram_array #(.DATA_WIDTH(2*DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_BIAS_HEIGHT),.ADDR_BITS(MAX_BIAS_ADDR_BITS),.memory_type("model_bias")) INST_MODEL_BIAS_MEM
 (.clk(clk),
.rst_b(rst_b),
.addr(model_bias_mem_addr),
.mem_data_in(model_bias_mem_data_in),
.mem_data_out(model_bias_mem_data_out),
.mem_en(model_bias_mem_en),
.mem_write_en(model_bias_mem_write_en));



sram_array_dist #(.DATA_WIDTH(2*DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_WT_HEIGHT),.ADDR_BITS(MAX_WT_ADDR_BITS),.memory_type("grad_weight")) INST_GRAD_WEIGHT_MEM
 (.clk(clk),
//.rst_b(rst_b),
.addr(model_grad_weight_mem_addr),
.mem_data_in(model_grad_weight_mem_data_in),
.mem_data_out(model_grad_weight_mem_data_out),
.mem_en(model_grad_weight_mem_en),
.mem_write_en(model_grad_weight_mem_write_en)); 


sram_array_dist #(.DATA_WIDTH(2*DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_BIAS_HEIGHT),.ADDR_BITS(MAX_BIAS_ADDR_BITS),.memory_type("grad_bias")) INST_GRAD_BIAS_MEM
 (.clk(clk),
//.rst_b(rst_b),
.addr(model_grad_bias_mem_addr),
.mem_data_in(model_grad_bias_mem_data_in),
.mem_data_out(model_grad_bias_mem_data_out),
.mem_en(model_grad_bias_mem_en),
.mem_write_en(model_grad_bias_mem_write_en)); 



sram_array #(.DATA_WIDTH(DATA_WIDTH),.COUNT(COUNT),.HEIGHT(MAX_INT_OP_HEIGHT),.ADDR_BITS(MAX_INT_OP_ADDR_BITS),.memory_type("int_op")) INST_INT_OP_MEM
 (.clk(clk),
.rst_b(rst_b),
.addr(int_op_mem_addr),
.mem_data_in(int_op_mem_data_in),
.mem_data_out(int_op_mem_data_out),
.mem_en(int_op_mem_en),
.mem_write_en(int_op_mem_write_en)); 
 

//---------------------------------------------------------------------------------------
// Control Unit
//---------------------------------------------------------------------------------------


control_unit  #(.NEURON_LAYER1(NEURON_LAYER1),.NEURON_LAYER2(NEURON_LAYER2),.NEURON_LAYER3(NEURON_LAYER3),.NEURON_LAYER4(NEURON_LAYER4),.NEURON_LAYER5(NEURON_LAYER5),.LAYER_COUNT(LAYER_COUNT),.MAX_WT_ADDR_BITS(MAX_WT_ADDR_BITS),.MAX_BIAS_ADDR_BITS(MAX_BIAS_ADDR_BITS),.MAX_INT_OP_ADDR_BITS(MAX_INT_OP_ADDR_BITS),.COUNT(COUNT),.DATA_WIDTH(DATA_WIDTH)) INST_CU 
(.clk(clk),
.rst_b(rst_b),
.use_target(use_target),
.is_training(is_training),
.input_enable(input_enable),
.loss({COUNT{loss}}),
.partial_out(partial_out),
//.partial_out_reduced(partial_out_reduced),
.mux_piso_in(mux_piso_in),
.mux_mult_inp_2(mux_mult_inp_2),
.mux_mult_inp_1(mux_mult_inp_1),
.mux_add_inp(mux_add_inp),
.piso_load(piso_load),
.piso_shift(piso_shift),
.sipo_shift(sipo_shift),
.mux_accm_inp(mux_accm_inp),
.accm_en(accm_en),
.rst_accm_b(rst_accm_b),
.en_adder_tree(en_adder_tree),
.intermediate_reg(intermediate_reg),
.intermediate_reg_en(intermediate_reg_en),
.target_fwd_done(target_fwd_done),
.model_fwd_done(model_fwd_done),
.training_done(training_done),

.target_weight_mem_addr(target_weight_mem_addr),
.target_weight_mem_en(target_weight_mem_en),
.target_weight_mem_write_en(target_weight_mem_write_en),
.target_weight_mem_data_in(target_weight_mem_data_in),

.model_weight_mem_addr(model_weight_mem_addr),
.model_weight_mem_en(model_weight_mem_en),
.model_weight_mem_write_en(model_weight_mem_write_en),
.model_weight_mem_data_in(model_weight_mem_data_in),


.model_bias_mem_addr(model_bias_mem_addr),
.model_bias_mem_en(model_bias_mem_en),
.model_bias_mem_write_en(model_bias_mem_write_en),
.model_bias_mem_data_in(model_bias_mem_data_in),

.target_bias_mem_addr(target_bias_mem_addr),
.target_bias_mem_en(target_bias_mem_en),
.target_bias_mem_write_en(target_bias_mem_write_en),
.target_bias_mem_data_in(target_bias_mem_data_in),

.model_grad_weight_mem_addr(model_grad_weight_mem_addr),
.model_grad_weight_mem_en(model_grad_weight_mem_en),
.model_grad_weight_mem_write_en(model_grad_weight_mem_write_en),
.model_grad_weight_mem_data_in(model_grad_weight_mem_data_in),

.model_grad_bias_mem_addr(model_grad_bias_mem_addr),
.model_grad_bias_mem_en(model_grad_bias_mem_en),
.model_grad_bias_mem_write_en(model_grad_bias_mem_write_en),
.model_grad_bias_mem_data_in(model_grad_bias_mem_data_in),


.int_op_mem_addr(int_op_mem_addr),
.int_op_mem_en(int_op_mem_en),
.int_op_mem_write_en(int_op_mem_write_en),
.int_op_mem_data_in(int_op_mem_data_in),

.dldz(dldz),
.dldA(dldA)

);

 register #(.WL(DATA_WIDTH*COUNT)) INST_REG_INT_REG (
           .clk(clk),
           .rst_b(rst_b),
            .d(partial_out_q),
            .q(intermediate_reg),
            .wen(intermediate_reg_en)
          );


                 
endmodule

