
module tb_apb_spi #() ();


localparam time clk_cycle = 10ns;
logic clk, rst_n;


// APB & SPI Busses
apb_interface #(
    .ADDR_W(32),
    .DATA_W(32)
) apb_bus (clk);

spi_interface #(
    .ADDR_W(32)
    .DATA_W(32)
) spi_bus (clk);


// Unused out & in of DUT
logic                      unused_out, unused_in;
assign unused_in = 1'b0;

always clk_cycle/2 clk = ~clk;

initial begin
    $dumpfile("build/verilator_build/wave.vcd");
    $dumpvar(0, i_dut);
    $display("\n\t###TESTING###");

    clok <= 0;
    rst_n <= 0;

    apb_spi_master #() i_dut (
        .HCLK (apb_intf.PCLK),
        .HRESETn (apb_intf.PRESETn),
        .PADDR (apb_intf.PADDR),
        .PWDATA (apb_intf.PWDATA),
        .PWRITE (apb_intf.PWRITE),
        .PSEL (apb_intf.PSEL),
        .PENABLE (apb_intf.PENABLE),
        .PRDATA (apb_intf.PRDATA),
        .PREADY (apb_intf.PREADY),
        .PSLVERR (apb_intf.PSLVERR),

        .spi_clk(spi_clk), // connect to SPI SD-Card
        .spi_csn0(spi_csn0), // connect to SPI SD-Card
        .spi_csn1(unused_out),
        .spi_csn2(unused_out),
        .spi_csn3(unused_out),
        .spi_mode(unused_out),
        .spi_sdo0(), // connect to SPI SD-Card
        .spi_sdo1(unused_out),
        .spi_sdo2(unused_out),
        .spi_sdo3(unused_out),
        .spi_sdi0(), // connect to SPI SD-Card
        .spi_sdi1(unused_in),
        .spi_sdi2(unused_in),
        .spi_sdi3(unused_in)
    )
    
end