module filo(x, filo_en, rst, clk, y);
input [7:0]x;
input clk, filo_en, rst;
output reg[7:0]y;

parameter s1 = 2'b00, s2 = 2'b01;
reg [1:0]ns, cs;
reg [7:0] stack[2:0];
reg [1:0]sp;
reg [7:0]temp1, temp;
reg g_in, i_in;
integer i;
//reg done;

//assign x[7:0] = temp1[7:0];

always@(posedge clk or posedge rst) begin
    if(rst == 1)begin
        cs <= s1;
        temp = 8'b0;
        for(i=0;i<3;i=i+1) begin
            stack[i] = 8'b0;
        end
        temp1 = 8'b0;
        g_in = 1'b0;
        i_in = 1'b0;
        sp = 2'b0;
        y = 8'b0;
        //done = 0;
    end
    else begin
        cs <= ns;
    end
end

always@(*)begin
    if(filo_en == 1) begin
        case(cs)
            s1: begin
                if(filo_en == 1 && sp < 3) begin
                    ns = s1;
                end
                else begin
                    ns = s2;
                end
                i_in = 1'b1;
                g_in = 1'b0;
            end
            s2: begin
                if(filo_en == 1 && sp > 0) begin
                    ns = s2;
                end
                else begin
                    ns = s1;
                end
                i_in = 1'b0;
                g_in = 1'b1;
            end
            default: begin
                ns = s1;
                i_in = 1'b0;
                g_in = 1'b0;
            end
        endcase
    end
end

always @(posedge clk) begin
    if(i_in == 1'b1 && filo_en == 1'b1) begin
        if(sp<3) begin
            stack[sp] <= x;
            sp = sp + 1;
        end
        //done = 1;
    end
    //done = 1;
end


always @(posedge clk) begin
    if(g_in == 1'b1 && filo_en == 1'b1)begin
        if(sp >= 0) begin
            sp = sp - 1;
            y <= stack[sp -1];
        end
        //done = 1;
    end
    //done = 0;
end

endmodule






