//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : sram_model.sv
// Module      : sram_model
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : Model of a SRAM memory bank with resettable data output
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : HEIGHT : Number of rows in the memory
//             : ADDR_BITS : Number of bits to represent the address for the memory  
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : addr -> Address for referencing the memory location
//             : data_in -> Data input into the memory
//             : mem_en -> Enable read or write into the memory
//             : mem_write_en -> Enable write into the memory through mem_data_in
//             : mem_read_en -> Enable read out from the memory into the mem_data_out
// Output Ports: data_out -> Data out from the memory
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps


module sram_model #(
    parameter DATA_WIDTH = 16,
    parameter HEIGHT    = 128,
    parameter ADDR_BITS  = 7,
    parameter init_file = "ram_init_file.mem" )(
    input                               clk,
    input                               rst_b,
    input      [ADDR_BITS-1:0]          addr,
    input      [DATA_WIDTH-1:0]         data_in,
    output reg [DATA_WIDTH-1:0]         data_out,
    input                               mem_en,
    input                               mem_write_en
);

//---------------------------------------------------------------------------------------
// Local Variables
//---------------------------------------------------------------------------------------

    (*ram_style = "block"*) reg [DATA_WIDTH-1:0] memory_file [HEIGHT];

   //initial begin    
    //    $readmemb(init_file, memory_file);
    //end
    
    always @(posedge clk) begin

        if(mem_en) begin
            if(mem_write_en)
                memory_file[addr] <= data_in;
            else begin
                if(!rst_b)
                    data_out <= 0;
                else
                    data_out <= memory_file[addr];
            end
        end
       
    end
endmodule
