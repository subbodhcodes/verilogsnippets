module fifo_tb;
wire [7:0]y;
reg clk,fifo_en,rst;
reg [7:0]x;

fifo f1(x, fifo_en, rst, clk, y);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1'b1;
    #10 rst = 1'b0; 
    fifo_en = 1'b1;
    #10 x = 8'b11001100;
    #30 x = 8'b11011000;
    #30 x = 8'b10001000;
    #30 x = 8'b11011110;
end
endmodule