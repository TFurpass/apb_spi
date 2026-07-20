
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
    (* keep *)
    logic spi_clk, mosi, miso, csn;
    (* keep *)
    logic o1,o2,o3 /* verilator public */;
    (* keep *)
    logic i0, i1, i2, i3 /* verilator public */;
    // TODO correct bit widths
    logic [8:0] DUT_STATUS_REG; // shows STATUS_REG signals
    logic [7:0] REG_CLKDIV; 
    logic [31:0] REG_SPICMD; 
    logic [31:0] REG_SPIADR; 
    logic [27:0] REG_SPILEN; 
    logic [8:0] REG_SPIDUM; 
    logic [8:0] REG_TXFIFO; 
    logic [8:0] REG_RXFIFO; 
    logic [8:0] REG_INTCFG; 
    logic [8:0] REG_INTSTA; 
    logic [3:0] write_address;

    assign write_address = i_dut.u_axiregs.write_address;
    assign  unused_in = 1'b0;

    assign REG_CLKDIV = {
        i_dut.u_axiregs.spi_clk_div
    };

    assign REG_SPILEN = {
        i_dut.u_axiregs.spi_data_len,
        i_dut.u_axiregs.spi_addr_len,
        i_dut.u_axiregs.spi_cmd_len
    };

    assign REG_SPICMD = {
        i_dut.u_axiregs.spi_cmd
    };

    assign REG_SPIADR = {
        i_dut.u_axiregs.spi_addr
    };
    // TODO Other register assignments
    assign DUT_STATUS_REG = {
        i_dut.u_axiregs.spi_csreg,
        i_dut.u_axiregs.spi_swrst,
        i_dut.u_axiregs.spi_qwr,
        i_dut.u_axiregs.spi_qrd,
        i_dut.u_axiregs.spi_wr,
        i_dut.u_axiregs.spi_rd
        };

    initial begin
        $dumpfile("build/verilator_build/wave.vcd");
        $dumpvars(0, i_dut);
        $display("\n\t###TESTING###");
        #500ns;
        //i_vip.test_APB_REG_write_read(12'b0000, 32'b1000, 1);
        $display("\n\t###TESTING CMD0###");
        i_vip.CMD(0);
        
    end

    apb_spi_master #() i_dut (
        .HCLK (apb_bus.APB_Slave.PCLK),
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

        .spi_clk(spi_clk), // connect to SPI SD-Card
        .spi_csn0(csn), // connect to SPI SD-Card
        .spi_csn1(),
        .spi_csn2(),
        .spi_csn3(),
        .spi_mode(),
        .spi_sdo0(mosi), // connect to SPI SD-Card
        .spi_sdo1(o1),
        .spi_sdo2(o2),
        .spi_sdo3(o3),
        .spi_sdi0(i0), 
        .spi_sdi1(miso), // connect to SPI SD-Card
        .spi_sdi2(i2),
        .spi_sdi3(i3)
    );
    

    vip_apb_spi #() i_vip (
        .apb_mst (apb_bus.APB_Master)
        /* .spi_mst (unu),
        .spi_slv (spi_bus.SPI_Slave) */
    );

endmodule : tb_apb_spi