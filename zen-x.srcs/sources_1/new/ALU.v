`timescale 1ns / 1ps
`default_nettype none

module ALU #(
    parameter WIDTH = 16
)(
    input wire [2:0] op, // operation
    input wire signed [WIDTH-1:0] a, // first operand
    input wire signed [WIDTH-1:0] b, // second operand
    output reg [WIDTH-1:0] result, // result of a op b
    output reg zf, // enabled if result is zero
    output reg nf // enabled if result is negative
);

always @(*) begin
//      $display("   * : ALU: (op,a,b)=(%d,%d,%d)", op, a, b);
    `ifdef DBG
        $display("   * : ALU");
    `endif

    case(op)
    3'b000: result = b + a;
    3'b001: result = b - a;
    3'b010: result = b | a;
    3'b011: result = b ^ a;
    3'b100: result = b & a;
    3'b101: result = ~a;
    3'b110: result = a;
    3'b111: result = a < 0 ? b <<< -a : b >>> (a + 1);
    endcase
    
    zf = (result == 0);
    nf = result[WIDTH-1];
end

endmodule

`default_nettype wire