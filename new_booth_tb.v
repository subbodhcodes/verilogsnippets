module booth_tb_final;

    reg [3:0] X, Y; 
    wire[7:0] Z;    

   
    booth_new inst (
        .A(X),
        .B(Y),
        .Z(Z)
    );
    
    initial begin
        X = 4'b0011; Y = 4'b0111;   
        #10;
        X = 4'b0100; Y = 4'b0100;  
        #10;
    end

endmodule
