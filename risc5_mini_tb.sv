module testbench;
    logic clk, reset;
    top dut(clk, reset);

    always #5 clk = ~clk;

    // Functional Coverage
    covergroup instr_cov @(posedge clk);
        coverpoint dut.c.opcode {
            bins load  = {7'b0000011};
            bins store = {7'b0100011};
            bins rtype = {7'b0110011};
        }
        coverpoint dut.c.funct3;
    endgroup

    instr_cov icov = new();

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, testbench);

        clk = 0;
        reset = 1;
        #20;
        reset = 0;
    end

    initial begin
        #200;
        $display("Finished simulation");
        $finish;
    end
endmodule
