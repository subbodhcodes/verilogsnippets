module count_ones_tb;
reg [3:0]a;
wire [3:0]b;
count_ones c1(a,b);
initial a = 4'b0000;
initial begin
    repeat (16) begin
        #10;
        a = a + 1;
    end
end
endmodule