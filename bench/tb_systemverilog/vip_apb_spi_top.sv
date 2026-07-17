module vip_apb_spi #() (
    apb_interface.APB_Master apb_mst
    /* spi_interface.SPI_Master spi_mst,
    spi_interface.SPI_Slave spi_slv */
);
    
    
// TODO connect C++ sd card emulator from zipcpu or create your own (vhdl versions with reference available and maybe an sv version without sd card register configurations)

// vip_spi_slv #() i_SD_card (
//    .sclk (clk),
//    .cs (spi_csn0),
//    .mosi (spi_sdo0),
//    .miso (spi_sdi0)
// );

    localparam time clk_cycle = 10ns;
    localparam longint unsigned SimCycles = 'd1_000;
    logic clk, rst_n;

    clk_rst_gen # (
        .ClkPeriod (clk_cycle),
        .RstClkCycles (15)
    ) i_clk_rst (
        .clk_o (clk),
        .rst_no (apb_mst.PRESETn)
    );

    sim_timeout #(
      .Cycles(SimCycles)
  ) i_timeout (
      .clk_i (clk),
      .rst_ni(rst_n)
  );

// APB master that drives the spi controller
    vip_apb_driver #() i_apb (
        .clk(clk),
        .apb_mst(apb_mst)
    );

    task automatic test_APB_REG_write_read (logic [11:0] addr, logic [31:0] write_data, bit manual_data);
        automatic logic [31:0] read_data = 0;
        automatic logic [31:0] data = 0;
        if(manual_data == 1) begin
            data = write_data;
        end else begin
            data = $urandom();
        end
        $display("[VIP] Write-read test with APB interface on address 0x%8H", addr);
        i_apb.write(addr, data);
        i_apb.read(addr, read_data);
        $display("[VIP] Write-data: 0x%8H", data);
        $display("[VIP] read-data: 0x%8H", read_data);

    endtask

endmodule : vip_apb_spi