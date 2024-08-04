module filo_tb;
wire [7:0]y;
reg clk,filo_en,rst;
reg [7:0]x;

filo f1(x, filo_en, rst, clk, y);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1'b1;

    #10 rst = 1'b0; 
    #10 filo_en = 1'b1;
    #10 x = 8'b11001100;
    #10 x = 8'b11011000;
    #10 x = 8'b10001000;
    #20
    filo_en = 0;

    #50 filo_en = 1'b1;
    #20;
    #20;
    #20;
end
endmodule