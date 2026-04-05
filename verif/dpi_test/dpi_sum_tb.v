// DPI testbench
module dpi_sum_tb;
    import "DPI-C" function uint32_t dpi_sum(uint32_t a, uint32_t b);

    reg [31:0] a, b;
    wire [31:0] result;

    assign result = dpi_sum(a, b);

    initial begin
        a = 10;
        b = 20;
        #10;
        $display("Result: %0d + %0d = %0d", a, b, result);
        if (result == 30) begin
            $display("PASS: DPI works!");
        end else begin
            $display("FAIL: Expected 30, got %0d", result);
        end
        $finish;
    end
endmodule
