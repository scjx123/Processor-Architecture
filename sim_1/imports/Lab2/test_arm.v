`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2021 18:35:17
// Design Name: 
// Module Name: test_arm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_arm(

    );
    reg CLK = 0;
    reg RESET = 0;
    //input Interrupt,  // for optional future use
    reg [31:0] Instr;
    reg [31:0] ReadData;
    wire MemWrite;
    wire [31:0] PC;
    wire [31:0] ALUResult;
    wire [31:0] WriteData;
    
    ARM dut(CLK, RESET, Instr, ReadData, MemWrite, PC, ALUResult, WriteData);
    
    initial begin 
        #10; Instr = 32'hE59F1214; ReadData = 32'h2;    // LDR R1, constant(=2)
        #10; Instr = 32'hE59F2214; ReadData = 32'h4;    // LDR R2, constant(=4)
        #10; Instr = 32'hE2424008; ReadData = 32'hx;    // SUB R4, R2, #8
        //#10; Instr = 32'hE0030291; ReadData = 32'hx;    // MUL R3, R1, R2 (8)
        #10; Instr = 32'hE0130194; ReadData = 32'hx;    // MUL R3, R4, R1 (-8)
    end
    
    always begin 
        #5; CLK = ~CLK;
    end
    
endmodule
