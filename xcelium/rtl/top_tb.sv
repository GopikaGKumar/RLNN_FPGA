module top_tb();

    parameter DATA_WIDTH = 4;
    parameter COUNT = 4;
    parameter MAX_WT_HEIGHT = 16;
    parameter NEURON_INPUT_LAYER = 2;
    parameter NEURON_LAYER1 = 4;
    parameter NEURON_LAYER2 = 4;
    parameter NEURON_LAYER3 = 4;
    parameter NEURON_LAYER4 = 4;
    parameter NEURON_LAYER5 = 4;
    parameter NEURON_OUTPUT_LAYER = 2;



    logic                                           clk, rst_b;
    logic                                           is_training;
    logic [(COUNT*DATA_WIDTH)-1:0]                  loss;
    logic [(NEURON_INPUT_LAYER*DATA_WIDTH)-1:0]     nn_input;
    logic [(NEURON_OUTPUT_LAYER*DATA_WIDTH)-1:0]    nn_inf_output;
    logic                                           use_target, target_fwd_done, model_fwd_done,training_done,output_nn_opt1,output_nn_opt2,input_enable;


//---------------------------------------------------------------------------------------
// Top Module under test
//---------------------------------------------------------------------------------------
 

    top_module_wrapper
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


//---------------------------------------------------------------------------------------
// TestBench
//---------------------------------------------------------------------------------------

  
    initial begin
        clk = 0;    
        forever begin
        #5;
        clk = ~clk;
        end
    end


    initial begin
        rst_b = 0;
        nn_input=8'b00100001; 
        is_training =0;
        input_enable=0;
        use_target = 0;
        loss=5;
        #10;
        rst_b = 1;
        #50;
        input_enable=1;

        /*fork
            begin
                #1800;
                $finish;
            end
            begin
                @(model_fwd_done) #20  use_target = 1'b1;
                #20;
                @(target_fwd_done) #10 is_training = 1'b1;
                #1500;
                $finish;
            end

        join*/
        #100;
        input_enable=0;
        #100;
        nn_input = 8'b00010010;
        input_enable = 1;
        #1000;
        $finish;


       /* fork
            begin
                #1800;
                $finish;
            end
            begin
                @(model_fwd_done) #20  use_target = 1'b1;
                #20;
                @(target_fwd_done) #10 is_training = 1'b1;
                #1500;
                $finish;
            end

        join*/
    end


   /* initial begin
       // $readmemb("./data/target_weights.data", INST_TARGET.INST_TARGET_WEIGHT_MEM.input_mem);  


    end
    
   
*/ 
    initial begin
        $dumpfile("chip.vcd");
        $dumpvars(4);
    end



endmodule: top_tb
