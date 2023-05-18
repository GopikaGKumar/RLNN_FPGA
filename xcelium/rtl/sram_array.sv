//=======================================================================================
// Carnegie Mellon University - Copyright 2023
//
// These are the RTL modules and files for research project of Reinforcement Learning
// Accelerator conducted in Spring 2023. Any use of the files for other purposes 
// unless prior permission from the members of the team 
// is a copyright violation. Please contact the team for futher details at 
//   ggeethak@andrew.cmu.edu
//
// File name   : sram_array.sv
// Module      : sram_array
// Author      : Gopika Geetha Kumar (ggeethak)
// Date        : 24 Feb 2023
// Description : An array of the SRAM memory units of the required bit width and number
// Parameters  : DATA_WIDTH : for configuring the data width of the input and output ports
//             : COUNT : Number of independent MAC units for parallelism
//             : HEIGHT : Number of rows in the memory
//             : ADDR_BITS : Number of bits to represent the address for the memory       
// Input Ports : clk -> Clock
//             : rst_b -> Active low Global reset
//             : addr -> Address for referencing the memory location
//             : mem_data_in -> Data input into the memory
//             : mem_en -> Enable read or write into the memory
//             : mem_write_en -> Enable write into the memory through mem_data_in
//             : mem_read_en -> Enable read out from the memory into the mem_data_out
// Output Ports: mem_data_out -> Data out from the memory
//=======================================================================================


//`default_nettype none
`timescale 1ns/1ps

module sram_array #(
    parameter COUNT = 128,
   	parameter DATA_WIDTH = 16,
    parameter HEIGHT = 128,
    parameter ADDR_BITS = 7,
    parameter memory_type = "MEM")(
    input                                   clk,
    input                                   rst_b,
    input  [ADDR_BITS-1:0]                  addr,
    input  [(DATA_WIDTH*COUNT)-1:0]         mem_data_in,
    input                                   mem_en,
    input                                   mem_write_en,
    output [(DATA_WIDTH*COUNT)-1:0]         mem_data_out
  );

//---------------------------------------------------------------------------------------
// Generate loop that creates instances of a chain of sram memory banks
//---------------------------------------------------------------------------------------
 
  generate
  genvar i;
    for (i=0; i<COUNT; i=i+1) begin : sram_bank
      localparam file_name = $sformatf("./data_example/%s_%0d.mem",memory_type,i);
      sram_model #(.DATA_WIDTH(DATA_WIDTH),.HEIGHT(HEIGHT),.ADDR_BITS(ADDR_BITS),.init_file(file_name)) INST_SRAM (
            .clk(clk),
            .rst_b(rst_b),
            .addr(addr),
            .data_in(mem_data_in[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH]),
            .data_out(mem_data_out[((i+1)*DATA_WIDTH)-1:i*DATA_WIDTH]),
            .mem_en(mem_en),
            .mem_write_en(mem_write_en)
    );
  end
  endgenerate

endmodule
