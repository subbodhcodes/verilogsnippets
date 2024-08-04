module fifo(x, fifo_en, rst, clk, y);
input [7:0]x;
input clk, fifo_en, rst;
output reg[7:0]y;

parameter s1 = 2'b00, s2 = 2'b01;
reg [1:0]ns, cs;
reg [7:0]temp1, temp;
reg g_in, i_in;

//assign x[7:0] = temp1[7:0];

always@(posedge clk or posedge rst) begin
    if(rst == 1)begin
        cs <= s1;
        temp = 8'b0;
        temp1 = 8'b0;
        g_in = 1'b0;
        i_in = 1'b0;
        y = 8'b0;
    end
    else begin
        cs <= ns;
    end
end

always@(*)begin
    if(fifo_en == 1) begin
        case(cs)
            s1: begin
                i_in = 1'b1;
                g_in = 1'b0;
                ns = s2;
            end
            s2: begin
                i_in = 1'b0;
                g_in = 1'b1;
                ns = s1;
            end
            default: begin
                ns = s1;
            end
        endcase
    end
    else begin
        ns = s1;
    end
end

always @(posedge clk) begin
    if(i_in == 1'b1)
    temp1 <= x;
end


always @(posedge clk) begin
    if(g_in == 1'b1)
    y <= temp1;
    else
    y = 8'b00001000;
end

endmodule






