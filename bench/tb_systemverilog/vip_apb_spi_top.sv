`define STATUS_ADDR  8'h0 // BASEREG + 0x00
`define CLKDIV_ADDR  8'h0004 // BASEREG + 0x04
`define SPICMD_ADDR  8'h08 // BASEREG + 0x08
`define SPIADDR_ADDR 8'h0C // BASEREG + 0x0C
`define SPILEN_ADDR  8'h10 // BASEREG + 0x10
`define SPIDUM_ADDR  8'h14 // BASEREG + 0x14
`define TXFIFO_ADDR  8'h18 // BASEREG + 0x18
`define RXFIFO_ADDR  8'h20 // BASEREG + 0x20
`define INTCFG_ADDR  8'h24 // BASEREG + 0x24
`define INTSTA_ADDR  8'h28 // BASEREG + 0x28

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
    localparam longint unsigned SimCycles = 'd5_000;
    logic clk, rst_n;

    clk_rst_gen # (
        .ClkPeriod (clk_cycle),
        .RstClkCycles (5)
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

    // TODO display all register info, since some are write only.
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

    task automatic CMD (logic [7:0] CMD);
        
        automatic logic [31:0] read_data = 0;
        automatic logic [31:0] data = 0;
        logic [31:0] CMD0_data = 32'h40;
        logic [11:0] addr;

        $display("[VIP] Writing to STATUS_REG (addr: 0x%8H) the value: 0x%8H", addr, data);
        
        //TODO vector for address order depending on command
        case(CMD)
            0: begin
                addr = 12'(`STATUS_ADDR);
                data = 32'h0008;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data);
                #50ns
                addr = 12'(`SPILEN_ADDR);
                data = 32'h10002808;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data );
                addr = 12'(`CLKDIV_ADDR);
                data = 32'h00;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data);
                  addr = 12'(`STATUS_ADDR);
                data = 32'h0102;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data);
                addr = 12'(`SPICMD_ADDR);
                data = 32'h40;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data);
                addr = 12'(`SPIADDR_ADDR);
                data = 32'h95;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr,data);
                addr = 12'(`TXFIFO_ADDR);
                data = 32'h0102;
                i_apb.write(addr, data);
                 addr = 12'(`STATUS_ADDR);
                data = 32'h0102;
                $display("[VIP] Writing to (addr: 0x%8H) the value: 0x%8H", addr, data);
                

            end
            default: begin
                addr = 12'(`SPILEN_ADDR);
                data = 32'h10002808;
                i_apb.write(addr, data);
                addr = 12'(`CLKDIV_ADDR);
                data = 32'hFA;
                i_apb.write(addr, data);
                addr = 12'(`SPICMD_ADDR);
                data = 32'h40;
                i_apb.write(addr, data);
                addr = 12'( `SPIADDR_ADDR);
                data = 32'h95;
                i_apb.write(addr,data);
                addr = 12'(`STATUS_ADDR);
                data = 32'h0102;
                i_apb.write(addr, data);
            end
        endcase
/* 
        case(addr)

            0: begin
                $display("REG_STATUS");
                data = 32'h0102;
                $display("Writing 0x%8H", data);
            end

            4: begin 
                logic div_value;
                $display("CLKDIV_ADDR");
            end
            
            8: begin
                $display("SPICMD_ADDR");
            end

            12: $display("SPIADDR_ADDR");

            16: begin
                data = 32'h10002808;
                $display("SPILEN_ADDR");
                $display("Setting SPICMD length to 8 bits");
                $display("SPIADDR to 40 bits for additional fields and CRC");
                $display("FIFO to 512KB");
                $display("Writing 0x%8H", data);
            end

            20: $display("SPIDUM_ADDR");
            24: $display("TXFIFO_ADDR");
            28: $display("RXFIFO_ADDR");
            32: $display("INTCFG_ADDR");
            36: $display("INTSTA_ADDR");
            default: $display("No register mapped to given addr");
        endcase */
        //TODO add addr check.


    endtask

endmodule : vip_apb_spi