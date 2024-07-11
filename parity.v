module count_ones(a,b);
input [3:0]a;
output reg [3:0]b;
reg [3:0]int;
integer n;
//initial int = 4'b0000;
always @(*) begin
    int = 4'b0000;
    for(n = 0; n<4; n = n + 1) begin
        if(a[n] == 1'b1) begin
            int = int + 1'b1;
        end
        else begin
            int = int + 0;
        end
    end
    b = int;
end
endmodule

