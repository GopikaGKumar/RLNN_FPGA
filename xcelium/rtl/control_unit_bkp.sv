//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : control_unit.sv
// Module      : control_unit
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : The main control unit that sequences the operation of the computational units
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent registers for parallelism
//             : NEURON_INPUT_LAYER : Number of neurons in the input layer
//             : NEURON_LAYER2 : Number of neurons in the second(first hidden) layer
//             : NEURON_LAYER3 : Number of neurons in the third(second hidden) layer
//             : NEURON_LAYER4 : Number of neurons in the fourth(third hidden) layer
//             : NEURON_OUTPUT_LAYER : Number of neurons in the output layer
//             : LAYER_COUNT : Total number of layers in the neural network
//             : ADDR_BITS : Number of bits to reference the address of memory location
//             : COUNTER_LEN : Length of the counter registers
//             : N : Count of the input memory file
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : use_target -> User input to use target NN parameters
//             : is_training -> User input to decide the training and inference phases
//             : loss -> User input that gets the loss between target and model output
//             : int_out_q -> Intermediate layer output after computation
// Output Ports: mux_piso_in -> Mux select to decide the input of the Parallel in Serial out shift register
//             : mux_mult_inp_2 -> Mux select to decide the multiplier input
//             : mux_add_inp -> Mux select to decide the addend input of the compute unit
//             : piso_load -> Control signal for loading data into the Parallel in Serial out shift register
//             : piso_shift -> Control signal for shifting the data out serially out of the Parallel in Serial out shift register
//             : mux_accm_inp -> Control signal for deciding the intial value of the accumulator
//             : accm_en -> Control signal for enabling the accumulator 
//             : rst_accm_b -> Control signal for reseting the accumulator
//             : target_fwd_done -> Flag that signifies that the target forward propagation is done
//             : model_fwd_done -> Flag that signifies that model forward propagation is done
//             : target_weight_mem_en : Control signal to enable the target weights memory
//             : target_weight_mem_addr : Address generator for reading the weights
//             : target_weight_mem_write_en : Control signal to write data into the target weights memory
//             : target_weight_mem_data_in : Data to be written into the target weight memory
//             : model_weight_mem_en : Control signal to enable the model weights memory
//             : model_weight_mem_write_en : Control signal to read data into the model weights memory
//             : model_weight_mem_addr : Address generator for reading the weights
//             : target_weight_mem_data_in : Data to be written into the target weight memory
//             : target_bias_mem_en : Control signal to enable the target bias memory
//             : target_bias_mem_write_en : Control signal to write data into the target bias memory
//             : target_bias_mem_addr : Address generator for reading the bias
//             : model_bias_mem_en : Control signal to enable the model bias memory
//             : model_bias_mem_write_en : Control signal to write data into the model bias memory
//             : model_bias_mem_addr : Address generator for reading the bias
//             : model_grad_weight_mem_en : Control signal to enable the target grad_weights memory
//             : modelt_grad_weight_mem_write_en : Control signal to write data into the target grad_weights memory
//             : model_grad_weight_mem_addr : Address generator for reading the grad_weights
//             : int_op_mem_en : Control signal to enable the intermediate outputs memory
//             : int_op_mem_addr : Address generator for reading the intermediate outputs
//             : int_op_mem_write_en : Control signal to write data into the intermediate outputs memory
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module control_unit #( 
   parameter COUNT = 128,
   parameter DATA_WIDTH = 16,
   parameter NEURON_INPUT_LAYER = 128,
   parameter NEURON_LAYER2 = 128,
   parameter NEURON_LAYER3 = 128,
   parameter NEURON_LAYER4 = 128,
  // parameter NEURON_OUTPUT_LAYER = 128,
   parameter LAYER_COUNT = 5,
   parameter MAX_WT_ADDR_BITS = 9,
   parameter MAX_BIAS_ADDR_BITS = 2,
   parameter MAX_INT_OP_ADDR_BITS = 2)(

   input 		                         clk,
   input 		                         rst_b,
   input                                 use_target,
   input                                 is_training,
   input [(DATA_WIDTH*COUNT)-1:0]        loss,

   input [(DATA_WIDTH*COUNT)-1:0]        int_out_q,
   input [(2*DATA_WIDTH*COUNT)-1:0]      partial_out,
   input [DATA_WIDTH-1:0]                partial_out_reduced,

   input [(DATA_WIDTH*COUNT)-1:0]        dldA,

  output reg [1:0]                        mux_piso_in,
  output reg [1:0]                        mux_mult_inp_1,
  output reg [1:0]                        mux_mult_inp_2,
  output reg [1:0]                        mux_add_inp,
  output reg                              piso_load,
  output reg                              piso_shift,
  output reg                              mux_accm_inp,
  output reg                              sipo_shift,
  output reg                              accm_en,
  output reg                              rst_accm_b,
  output reg                              en_adder_tree,
  output reg                              target_fwd_done,
  output reg                              model_fwd_done,
  output reg                              training_done,




  output reg [MAX_WT_ADDR_BITS-1:0]       target_weight_mem_addr,
  output reg                              target_weight_mem_en,
  output reg                              target_weight_mem_write_en,
  output reg [(DATA_WIDTH*COUNT)-1:0]     target_weight_mem_data_in,


  output reg [MAX_WT_ADDR_BITS-1:0]       model_weight_mem_addr,
  output reg                              model_weight_mem_en,
  output reg                              model_weight_mem_write_en,
  output reg [(DATA_WIDTH*COUNT)-1:0]     model_weight_mem_data_in,



  output reg  [MAX_BIAS_ADDR_BITS-1:0]    model_bias_mem_addr,
  output reg                              model_bias_mem_en,
  output reg                              model_bias_mem_write_en,
  output reg [(2*DATA_WIDTH*COUNT)-1:0]   model_bias_mem_data_in,



  output reg  [MAX_BIAS_ADDR_BITS-1:0]    target_bias_mem_addr,
  output reg                              target_bias_mem_en,
  output reg                              target_bias_mem_write_en,
  output reg [(2*DATA_WIDTH*COUNT)-1:0]   target_bias_mem_data_in,



  output reg [MAX_WT_ADDR_BITS-1:0]       model_grad_weight_mem_addr,
  output reg                              model_grad_weight_mem_en,
  output reg                              model_grad_weight_mem_write_en,
  output reg [(2*DATA_WIDTH*COUNT)-1:0]   model_grad_weight_mem_data_in,

  output reg [MAX_BIAS_ADDR_BITS-1:0]     model_grad_bias_mem_addr,
  output reg                              model_grad_bias_mem_en,
  output reg                              model_grad_bias_mem_write_en,
  output reg [(2*DATA_WIDTH*COUNT)-1:0]   model_grad_bias_mem_data_in,



  output reg [MAX_INT_OP_ADDR_BITS-1:0]   int_op_mem_addr,
  output reg                              int_op_mem_en,
  output reg                              int_op_mem_write_en,
  output reg [(DATA_WIDTH*COUNT)-1:0]     int_op_mem_data_in,


  output reg [(DATA_WIDTH*COUNT)-1:0]      dldz
  
 );


//---------------------------------------------------------------------------------------
// States
//---------------------------------------------------------------------------------------
 

  

  reg [4:0] state,next_state;
  localparam RESET = 5'b00000;
  localparam SETUP = 5'b00001;
  localparam FWD_LOAD_INP = 5'b00010;
  localparam FWD_LOAD_TARGET_MEM =5'b00011;  
  localparam FWD_LOAD_MODEL_MEM = 5'b00100;
  localparam FWD_ACC = 5'b00101;
  localparam TRAIN_LOAD_INT_OUT_GRAD_MEM = 5'b00110;
  localparam LOSS_CALC = 5'b00111;
  localparam LOAD_INT_OP_MEMORY = 5'b01000;
  localparam TRAIN_GRAD_PARAM_SETUP = 5'b01001;
  localparam GRAD_WT_ACC = 5'b01010;
  localparam GRAD_WT_STORE = 5'b01011;
  localparam GRAD_BIAS_ACC = 5'b01100;
  localparam GRAD_BIAS_STORE = 5'b01101;
  localparam TRAIN_LOAD_MODEL_MEM = 5'b01110;
  localparam TRAIN_BACK_PROP_SETUP = 5'b01111;
  localparam BACK_PROP_ACC = 5'b10000;



 

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

  bit [2:0] layer_count;
  bit [7:0] count;


  integer layer[LAYER_COUNT-2:0] =            {NEURON_LAYER4,NEURON_LAYER3,NEURON_LAYER2,NEURON_INPUT_LAYER};
  integer weight_base_addr[LAYER_COUNT-2:0] = {(NEURON_LAYER3 + NEURON_LAYER2 + NEURON_INPUT_LAYER),(NEURON_LAYER2 + NEURON_INPUT_LAYER),NEURON_INPUT_LAYER,0};
  integer bias_base_addr[LAYER_COUNT-2:0] =   {3,2,1,0};
  integer int_op_base_addr[LAYER_COUNT-2:0] = {3,2,1,0};


//---------------------------------------------------------------------------------------
// Module Definition
//---------------------------------------------------------------------------------------

 

//---------------------------------------------------------------------------------------
// Finite State Machine
//---------------------------------------------------------------------------------------


	always_ff @(posedge clk or negedge rst_b) begin
		if (!rst_b)
			state <= RESET;
		else
			state <= next_state;
	end

//---------------------------------------------------------------------------------------
// State Transition Table
//---------------------------------------------------------------------------------------


    always_comb begin

        next_state = state;

        case(state)


  RESET                     :       begin
                                    next_state = SETUP;
                                    end

  SETUP                     :       begin
                                        if(is_training == 1'b1)
                                            next_state = LOSS_CALC;
                                        else if(is_training == 0)
                                            next_state = FWD_LOAD_INP;
                                    end

  FWD_LOAD_INP              :       begin
                                        if(use_target == 1'b1)
                                             next_state = FWD_LOAD_TARGET_MEM;
                                        else
                                             next_state = FWD_LOAD_MODEL_MEM;
                                    end

  FWD_LOAD_TARGET_MEM       :       begin
                                        if(layer_count == LAYER_COUNT)
                                              next_state = SETUP;
                                        else
                                            next_state = FWD_ACC;
                                    end

  FWD_LOAD_MODEL_MEM        :       begin
                                        if(layer_count == LAYER_COUNT)
                                              next_state = SETUP;
                                        else
                                            next_state = FWD_ACC;
                                    end

  FWD_ACC                   :       begin
                                        if(count == layer[layer_count]-2)
                                            next_state = FWD_LOAD_INP;
                                    end


  LOSS_CALC                 :       begin
                                        next_state = TRAIN_LOAD_INT_OUT_GRAD_MEM;
                                    end
                                    

  TRAIN_LOAD_INT_OUT_GRAD_MEM :    begin
                                        next_state = TRAIN_GRAD_PARAM_SETUP;
                                    end

  TRAIN_GRAD_PARAM_SETUP    :      begin
                                        next_state = GRAD_WT_ACC;
                                    end

  GRAD_WT_ACC               :      begin
                                        next_state = GRAD_WT_STORE;
                                    end

  GRAD_WT_STORE             :      begin
                                        if(count == layer[LAYER_COUNT - layer_count])
                                            next_state = GRAD_BIAS_ACC;
                                        else
                                            next_state = GRAD_WT_ACC;
                                    end
  GRAD_BIAS_ACC             :      begin
                                        next_state = GRAD_BIAS_STORE;
                                    end

  GRAD_BIAS_STORE           :      begin
                                        next_state = TRAIN_LOAD_MODEL_MEM;
                                    end

  TRAIN_LOAD_MODEL_MEM      :      begin
                                        next_state = TRAIN_BACK_PROP_SETUP;
                                    end

  TRAIN_BACK_PROP_SETUP     :      begin
                                        next_state = BACK_PROP_ACC;
                                    end

  BACK_PROP_ACC             :      begin
                                        if(count == layer[LAYER_COUNT - layer_count]-1) begin
                                            next_state = SETUP;
                                        end
                                    end
   default                  :      next_state = RESET;


        endcase

    end

   
//---------------------------------------------------------------------------------------
// State based Output Signal control
//---------------------------------------------------------------------------------------




    always_comb begin


        case(state)


         RESET:                 begin

                                target_fwd_done = 1'b0;
                                model_fwd_done = 1'b0;
                                piso_load = 1'b0;
                                piso_shift = 1'b0;
                                mux_accm_inp = 1'b0;
                                rst_accm_b = 1'b0;
                                accm_en = 1'b0;
                                sipo_shift = 1'b0;
                                en_adder_tree = 1'b0;


                                target_weight_mem_en = 1'b0;
                                target_weight_mem_write_en = 1'b0;
                                target_bias_mem_en = 1'b0;
                                target_bias_mem_write_en = 1'b0;

                                model_weight_mem_en = 1'b0;
                                model_weight_mem_write_en = 1'b0;
                                model_bias_mem_en = 1'b0;
                                model_bias_mem_write_en = 1'b0;

                                model_grad_weight_mem_en = 1'b0;
                                model_grad_weight_mem_write_en = 1'b0;
                                model_grad_bias_mem_en = 1'b0;
                                model_grad_bias_mem_write_en = 1'b0;



                                int_op_mem_en = 1'b0;
                                int_op_mem_write_en = 1'b0;
             

                                mux_piso_in = 2'b00;
                                mux_mult_inp_1 = 2'b00;
                                mux_mult_inp_2 = 2'b00;
                                mux_add_inp = 2'b00;                          
    
   
                                                 
                                end

         SETUP:           begin

                                target_fwd_done = 1'b0;
                                training_done   = 1'b0;
                                model_fwd_done = 1'b0;
                                piso_load = 1'b0;
                                piso_shift = 1'b0;
                                mux_accm_inp = 1'b0;
                                rst_accm_b = 1'b0;
                                accm_en = 1'b0;
                                sipo_shift = 1'b0;
                                int_op_mem_en = 1'b0;
                                en_adder_tree = 1'b0;
                                int_op_mem_write_en = 1'b0;


                                target_weight_mem_en = 1'b0;
                                target_weight_mem_write_en = 1'b0;
                                target_bias_mem_en = 1'b0;
                                target_bias_mem_write_en = 1'b0;

                                model_weight_mem_en = 1'b0;
                                model_weight_mem_write_en = 1'b0;
                                model_bias_mem_en = 1'b0;
                                model_bias_mem_write_en = 1'b0;

                                model_grad_weight_mem_en = 1'b0;
                                model_grad_weight_mem_write_en = 1'b0;

                                model_grad_bias_mem_en = 1'b0;
                                model_grad_bias_mem_write_en = 1'b0;


              

                                if(is_training == 1'b1) begin
                                    mux_piso_in = 2'b10;
                                    mux_mult_inp_2 = 2'b01;
                                    mux_add_inp = 2'b01;
                                    mux_mult_inp_2 = 2'b01;
                                end

                                else begin
                                     mux_piso_in = 2'b00;
                                     mux_mult_inp_2 = 2'b00;
                                     mux_add_inp = 2'b00;        
                                    mux_mult_inp_2 = 2'b00;
                                end    
    
   
                                                 
                                end


          FWD_LOAD_INP:         begin  
                             
                                if(layer_count == LAYER_COUNT-1) begin
                                        if(use_target == 1'b1)
                                            target_fwd_done = 1'b1;
                                        else
                                            model_fwd_done = 1'b1;
                                end
                                else begin       
                                        piso_load = 1'b1;
                                        piso_shift = 1'b0; 
                                end                               
                                rst_accm_b = 1'b0;
                                accm_en = 1'b0;

                                end


          FWD_LOAD_TARGET_MEM :  begin
                               
                               target_weight_mem_en = 1'b1;
                               target_weight_mem_write_en = 1'b0;
                               piso_load = 1'b0;
                             if(layer_count != LAYER_COUNT-1) begin

                                target_bias_mem_en = 1'b1;
                                target_bias_mem_write_en = 1'b0;
                                end

                              else begin

                                target_bias_mem_en = 1'b1;
                                target_bias_mem_write_en = 1'b0;
                                end


                             end

          FWD_LOAD_MODEL_MEM :     begin
                               
                               model_weight_mem_en = 1'b1;
                               model_weight_mem_write_en = 1'b0;
                               piso_load = 1'b0;

                             if(layer_count != LAYER_COUNT-1) begin

                                model_bias_mem_en = 1'b1;
                                model_bias_mem_write_en = 1'b0;
                                end

                              else begin

                                model_bias_mem_en = 1'b1;
                                model_bias_mem_write_en = 1'b0;
                                end

                             if(layer_count > 1) begin

                                int_op_mem_en = 1'b1;
                                int_op_mem_write_en = 1'b1;
                             end


                             end



            LOSS_CALC :     begin

                            target_weight_mem_en = 1'b0;
                            target_weight_mem_write_en = 1'b0;
                            model_weight_mem_en = 1'b0;
                            model_weight_mem_write_en = 1'b0;
                           

                            end




   
            FWD_ACC:              begin

                                if(use_target == 1'b1) begin
                                    target_bias_mem_en = 1'b0;
                                    target_bias_mem_write_en = 1'b0;
                                end
                                else begin
                                    model_bias_mem_en = 1'b0;
                                    model_bias_mem_write_en = 1'b0;
                                end

                        

                                int_op_mem_en = 1'b0;
                                int_op_mem_write_en = 1'b0;
                            


                                piso_shift = 1'b1;
                                piso_load = 1'b0;
                                rst_accm_b = 1'b1;
                                accm_en = 1'b1;
                                                  

                                if(count !=0)
                                    mux_accm_inp = 1'b1;
                                else
                                    mux_accm_inp = 1'b0;

                                if(count == layer[layer_count]-2)                                   
                                    mux_piso_in = 2'b01;
                                end

     TRAIN_LOAD_INT_OUT_GRAD_MEM :      begin
                                rst_accm_b = 1'b0;
                                accm_en = 1'b0;
                                int_op_mem_en = 1'b1;
                                int_op_mem_write_en = 1'b0;
                                model_grad_weight_mem_en = 1'b1;
                                model_grad_weight_mem_write_en = 1'b0;
                                end

    TRAIN_GRAD_PARAM_SETUP :          begin
                                piso_load = 1'b1;
                                piso_shift = 1'b0;
                                end

     GRAD_WT_ACC :              begin
                                piso_load = 1'b0;
                                piso_shift = 1'b0;   

                                model_grad_weight_mem_en = 1'b1;
                                model_grad_weight_mem_write_en = 1'b0;

                        
                                end


    GRAD_WT_STORE :             begin
                                piso_load = 1'b0;
                                piso_shift = 1'b1;    

                                model_grad_weight_mem_en = 1'b1;
                                model_grad_weight_mem_write_en = 1'b1;
                                end

   GRAD_BIAS_ACC :              begin
                                mux_mult_inp_1 = 2'b01;
                                mux_add_inp = 2'b10;

                                model_grad_bias_mem_en = 1'b1;
                                model_grad_bias_mem_write_en = 1'b0;

                                end 

    GRAD_BIAS_STORE :           begin
                                model_grad_bias_mem_en = 1'b1;
                                model_grad_bias_mem_write_en = 1'b1;
                                end

    TRAIN_LOAD_MODEL_MEM :     begin

                                model_weight_mem_en = 1'b1;
                                model_weight_mem_write_en = 1'b0;
                                 
                                end

    TRAIN_BACK_PROP_SETUP :     begin
                                mux_mult_inp_1 = 2'b10;
                                mux_mult_inp_2 = 2'b01;
                                mux_add_inp = 2'b11;
                                en_adder_tree = 1'b1;  
                                end


    BACK_PROP_ACC :             begin                              
                                sipo_shift = 1'b1;    
                                if(count == layer[LAYER_COUNT - layer_count]-1) begin
                                     training_done = 1'b1;
                                end
                                end

                                
        default :               begin
                                mux_piso_in = 2'b00;
                                target_fwd_done = 1'b0;
                                model_fwd_done = 1'b0;
                                piso_load = 1'b0;
                                piso_shift = 1'b0;
                                mux_mult_inp_2 = 2'b00;
                                mux_add_inp = 2'b00;
                                mux_accm_inp = 1'b0;
                                rst_accm_b = 1'b0;
                                accm_en = 1'b0;
                                end


        endcase

    end



//---------------------------------------------------------------------------------------
// Counters
//---------------------------------------------------------------------------------------



	always_ff @(posedge clk)
	begin

        if(!rst_b) begin
            count <= 0;
            layer_count <= 0;
             dldz <= 0;
        end

        else begin
        

        case(state)

        RESET :             begin
	 			            count <= 0;
			                layer_count <= 0;
                            end
        SETUP :        begin
	 			            count <= 0;
			                layer_count <= 0;
                            end
        FWD_LOAD_INP :   begin
                            layer_count <= layer_count + 1;
                            count <= 0;
                            end
        FWD_LOAD_TARGET_MEM : begin
                            layer_count <= layer_count;
                            count <= count;
                            end
        FWD_LOAD_MODEL_MEM : begin
                            layer_count <= layer_count;
                            count <= count;
                            end

        LOSS_CALC :         dldz <= loss;
		
        FWD_ACC :               begin
                            count <= count + 1;
                            end

        TRAIN_LOAD_INT_OUT_GRAD_MEM : begin
                            layer_count<= layer_count + 1;
                            end

         GRAD_WT_ACC :         begin
                            count <= count + 1;
                            end

        GRAD_WT_STORE:      begin

                            count <= count;
                            layer_count <= layer_count;
                            end

         GRAD_BIAS_ACC :         begin
                            count <= count;
                            layer_count <= layer_count;
                            end

        GRAD_BIAS_STORE:      begin

                            count <= count;
                            layer_count <= layer_count;
                            end


        TRAIN_GRAD_PARAM_SETUP : begin
                            layer_count<= layer_count;
                            count <= count;
                            end

   TRAIN_LOAD_MODEL_MEM:    begin
                           count <= 0; 
                           layer_count <= layer_count;
                           end

     TRAIN_BACK_PROP_SETUP: begin
                           count <= 0; 
                           layer_count <= layer_count;
                           end


        BACK_PROP_ACC :   begin
                            count <= count + 1;
                            layer_count <= layer_count;
                            end

			
        default :           begin
	 			            count <= 0;
			                layer_count <= 0;
                            end
     
		endcase
        end
	end	



//---------------------------------------------------------------------------------------
// Memory Data Control Loop based on negative edge of clock
//---------------------------------------------------------------------------------------



always_ff @(posedge clk) begin

        
    case(state)

        RESET :             begin
    
                            target_weight_mem_addr <= 0;
                            target_bias_mem_addr <= 0;
                            model_weight_mem_addr <= 0;
                            model_bias_mem_addr <= 0;
                            int_op_mem_addr <= 0;
                            target_weight_mem_data_in <= 0;
                            target_bias_mem_data_in <= 0;
                            model_weight_mem_data_in <= 0;
                            model_bias_mem_data_in <= 0;
                            int_op_mem_data_in <= 0;
                            model_grad_weight_mem_data_in <= 0;
                            model_grad_weight_mem_addr <= 0;
                            model_grad_bias_mem_data_in <= 0;
                            model_grad_bias_mem_addr <= 0;


                            end

        SETUP :        begin

                
                            int_op_mem_addr <= 0;
                            target_weight_mem_data_in <= 0;
                            target_bias_mem_data_in <= 0;
                            model_weight_mem_data_in <= 0;
                            model_bias_mem_data_in <= 0;
                            int_op_mem_data_in <= 0;

                            end

        FWD_LOAD_INP :   begin

                           
                             
                            if(layer_count !=0) begin
                             
                               if(layer_count == 1)
                                    int_op_mem_addr <= 0;
                               else
                                    int_op_mem_addr <= int_op_mem_addr + 1;

                            int_op_mem_data_in <= int_out_q;

                            end

                            else begin

                            if(use_target == 1'b1) begin
                                target_weight_mem_addr <= weight_base_addr[layer_count];
                                target_bias_mem_addr <= bias_base_addr[layer_count];
                            end
                            else begin
                                model_weight_mem_addr <= weight_base_addr[layer_count];
                                model_bias_mem_addr <= bias_base_addr[layer_count];
                            end

                            end

                            
                            end

        FWD_LOAD_TARGET_MEM:        begin

                             target_weight_mem_addr <= target_weight_mem_addr + 1;
                             target_bias_mem_addr <= target_bias_mem_addr + 1;
                            
                            end

        FWD_LOAD_MODEL_MEM:        begin

                             model_weight_mem_addr <= model_weight_mem_addr + 1;
                             model_bias_mem_addr <= model_bias_mem_addr + 1;
                            
                            end

		
        FWD_ACC :               begin

                            if(count != layer[layer_count]-1) 
                                if(use_target == 1'b1)
                                    target_weight_mem_addr <= target_weight_mem_addr + 1;
                                else
                                    model_weight_mem_addr <= model_weight_mem_addr + 1;

		                    end

       TRAIN_LOAD_INT_OUT_GRAD_MEM :   begin
                                                   
                           

                            end    

       LOSS_CALC :   begin
                            int_op_mem_addr <= int_op_base_addr[LAYER_COUNT - layer_count -2];
                            model_grad_weight_mem_addr <= weight_base_addr[LAYER_COUNT - layer_count-2];
                            model_grad_bias_mem_addr <= bias_base_addr[LAYER_COUNT - layer_count-2];
                            end           

      TRAIN_GRAD_PARAM_SETUP :   begin
                            end                                        
 

        GRAD_WT_ACC :          begin

                           // if(count != layer[LAYER_COUNT - layer_count]-1) 
                                  model_grad_weight_mem_data_in <= partial_out;

		                    end

        GRAD_WT_STORE  :   begin

                            if(count != layer[LAYER_COUNT - layer_count]) 
                                     model_grad_weight_mem_addr <= model_grad_weight_mem_addr + 1;
                            end

       GRAD_BIAS_ACC :          begin

                           // if(count != layer[LAYER_COUNT - layer_count]-1) 
                                  model_grad_bias_mem_data_in <= partial_out;

		                    end

        GRAD_BIAS_STORE  :   begin

                           
 			                end

    TRAIN_LOAD_MODEL_MEM :    begin
                            model_weight_mem_addr <= weight_base_addr[LAYER_COUNT - layer_count-1];
                                              
                            end


    TRAIN_BACK_PROP_SETUP :    begin
                                    model_weight_mem_addr <= model_weight_mem_addr + 1;                                      
                            end


        BACK_PROP_ACC :    begin
                            model_weight_mem_addr <= model_weight_mem_addr + 1;
                            end

        default :           begin
                            target_weight_mem_addr <= 0;
                            target_bias_mem_addr <= 0;
                            model_weight_mem_addr <= 0;
                            model_bias_mem_addr <= 0;
                            int_op_mem_addr <= 0;
                            model_grad_weight_mem_addr <= 0;
                            target_weight_mem_data_in <= 0;
                            target_bias_mem_data_in <= 0;
                            int_op_mem_data_in <= 0;
                            model_weight_mem_data_in <= 0;
                            model_bias_mem_data_in <= 0;
                            model_grad_weight_mem_data_in <= 0;




		                    end
     
		endcase

   
end

			
				
endmodule



