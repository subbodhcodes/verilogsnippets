module booth_new(
    input signed [3:0] A,  
    input signed [3:0] B,    
    output reg signed [7:0] Z    
);

    reg signed [8:0] P;
    reg signed [4:0] M, M_neg;
    reg [4:0] Q; 
    integer i;

    always @* begin
        M = {A[3], A};
        M_neg = -M; 
        Q = {B, 1'b0}; 
        P = 9'b0;
        for (i = 0; i < 4; i = i + 1) begin
            case (Q[1:0])
                2'b10: P = P + {M_neg, 4'b0};
                2'b01: P = P + {M, 4'b0}; 
            endcase
            P = P >>> 1; 
            Q = Q >> 1;
        end

        Z = P[7:0]; 
    end

endmodule