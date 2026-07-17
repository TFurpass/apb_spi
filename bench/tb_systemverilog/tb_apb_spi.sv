
module tb_apb_spi #() ();

    logic clk, rst_n;

    // APB & SPI Busses
    apb_interface #(
        .ADDR_W(12),
        .DATA_W(32)
    ) apb_bus ();
/* 
    spi_interface #(
        .ADDR_W(32),
        .DATA_W(32)
    ) spi_bus (clk); */

    // Unused out & in of DUT
    logic   unused_out, unused_in;
    assign  unused_in = 1'b0;


    initial begin
        $dumpfile("build/verilator_build/wave.vcd");
        $dumpvars(0, i_dut);
        $display("\n\t###TESTING###");
        #500ns;
        i_vip.test_APB_REG_write_read(12'b0000, 32'b1000, 1);
        $finish();
    end

    apb_spi_master #() i_dut (
        .HCLK (apb_bus.PCLK),
        .HRESETn (apb_bus.PRESETn),
        .PADDR (apb_bus.PADDR),
        .PWDATA (apb_bus.PWDATA),
        .PWRITE (apb_bus.PWRITE),
        .PSEL (apb_bus.PSEL),
        .PENABLE (apb_bus.PENABLE),
        .PRDATA (apb_bus.PRDATA),
        .PREADY (apb_bus.PREADY),
        .PSLVERR (apb_bus.PSLVERR),

        .events_o(),

        .spi_clk(), // connect to SPI SD-Card
        .spi_csn0(), // connect to SPI SD-Card
        .spi_csn1(),
        .spi_csn2(),
        .spi_csn3(),
        .spi_mode(),
        .spi_sdo0(), // connect to SPI SD-Card
        .spi_sdo1(),
        .spi_sdo2(),
        .spi_sdo3(),
        .spi_sdi0(unused_in), 
        .spi_sdi1(), // connect to SPI SD-Card
        .spi_sdi2(unused_in),
        .spi_sdi3(unused_in)
    );
    
    vip_apb_spi #() i_vip (
        .apb_mst (apb_bus.APB_Master)
        /* .spi_mst (unu),
        .spi_slv (spi_bus.SPI_Slave) */
    );

endmodule : tb_apb_spi