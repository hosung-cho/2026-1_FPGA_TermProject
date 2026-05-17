`timescale 1 ns / 1 ns

module data_memory #(
    parameter DEPTH = 16384,
    parameter INIT_HEX = "dmem.hex"
) (
    input               clock,
    input               enable,
    input               wren,           // write enable
    input      [13:0]   address,        // 16384 words (64KB)
    input      [31:0]   write_data,
    input      [3:0]    byteena,        // byte enable
    output reg [31:0]   read_data
);

    // Force LUTRAM inference for the initial Ultra96 bring-up path.
    (* ram_style = "block" *) reg [31:0] mem [0:DEPTH-1];
    
    integer i;

    // Initialize data memory
    initial begin
        // Initialize all memory to 0
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        
        // Load initial data from file
        $readmemh(INIT_HEX, mem);
        
        $display("Data Memory initialized at time %t", $time);
    end

    // Synchronous write, asynchronous read
    always @(posedge clock) begin
        if (enable && wren) begin
            // Byte-addressable write
            if (byteena[0]) mem[address][7:0]   <= write_data[7:0];
            if (byteena[1]) mem[address][15:8]  <= write_data[15:8];
            if (byteena[2]) mem[address][23:16] <= write_data[23:16];
            if (byteena[3]) mem[address][31:24] <= write_data[31:24];
        end
    end
    
    // Asynchronous read for better timing
    always @(posedge clock) begin
        if (enable)
            read_data = mem[address];
        else
            read_data = 32'h00000000;
    end

endmodule