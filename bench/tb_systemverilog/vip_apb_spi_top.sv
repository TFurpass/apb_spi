`define STATUS_ADDR  8'h0 // BASEREG + 0x00
`define CLKDIV_ADDR  8'h04 // BASEREG + 0x04
`define SPICMD_ADDR  8'h08 // BASEREG + 0x08
`define SPIADDR_ADDR 8'h0C // BASEREG + 0x0C
`define SPILEN_ADDR  8'h10 // BASEREG + 0x10
`define SPIDUM_ADDR  8'h14 // BASEREG + 0x14
`define TXFIFO_ADDR  8'h18 // BASEREG + 0x18
`define RXFIFO_ADDR  8'h20 // BASEREG + 0x20
`define INTCFG_ADDR  8'h24 // BASEREG + 0x24
`define INTSTA_ADDR  8'h28 // BASEREG + 0x28

module vip_apb_spi #() (
    apb_interface.APB_Master apb_mst,
    input logic cs,
    input logic sclk
        /* spi_interface.SPI_Master spi_mst,
    spi_interface.SPI_Slave spi_slv */
);
    
    localparam time clk_cycle = 10ns;
    localparam longint unsigned SimCycles = 'd500_000;
    logic clk, rst_n;
    logic [7:0] counter = 0;

    integer i;
    bit rsp_found;
    logic [7:0] response;
    logic [31:0] read_data = 0;

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

    // An SD-card needs atleast 74 sclk cycles to powerup
    task automatic sd_powerup ();
        automatic logic [31:0] data = 0;
        automatic logic [11:0] addr = 0;

        counter = 0;
        while (counter < 'd75) begin

            @(negedge sclk);
            counter++;
            @(posedge sclk);
        end
        $display("[VIP] SCLK cycle: %d", counter);
    endtask

    task automatic init();
        
    endtask

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
        
        automatic logic [31:0] data = 0;
        logic [31:0] CMD0_data = 32'h40;
        logic [11:0] addr;
       
        logic [31:0] status;
        logic [31:0] bounds;
        rsp_found = 0;

        
        //TODO vector for address order depending on command
        case(CMD)

            0: begin

                addr = 12'(`CLKDIV_ADDR);
                data = 32'h1F4;
                $display("[VIP] Writing to CLKDIV (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data);
                
                addr = 12'(`SPILEN_ADDR);
                data = 32'h00300000;
                $display("[VIP] Writing to SPILEN (addr: 0x%8H) the value: 0x%8H", addr, data);
                i_apb.write(addr, data );

                addr = 12'(`TXFIFO_ADDR);
                data = 32'h40000000;
                i_apb.write(addr, data); 

                addr = 12'(`TXFIFO_ADDR);
                data = 32'h00950000;
                i_apb.write(addr, data); 

                addr = 12'(`STATUS_ADDR);
                data = 32'h0122;
                $display("[VIP] Writing to STATUS (addr: 0x%8H) the value: 0x%8H, APB WRITE", addr, data);
                i_apb.write(addr, data);

                // wait for idle state of the spi_master_controller
                addr = 12'(`STATUS_ADDR);
                i_apb.read(addr, read_data);
                while (read_data != 32'h01 ) begin
                    i_apb.read(addr, read_data);
                end

                addr = 12'(`SPILEN_ADDR);
                data = 32'h00400000;
                $display("[VIP] Writing to SPILEN (addr: 0x%8H) the value: 0x%8H, \n\tNote: Setting FIFO width larger for reading SD-card response", addr, data);
                i_apb.write(addr, data );

                #2.5us;

                addr = 12'(`STATUS_ADDR);
                data = 32'h0121;
                $display("[VIP] Writing to STATUS (addr: 0x%8H) the value: 0x%8H, APB READ", addr, data);
                i_apb.write(addr, data);

                // wait for idle state of the spi_master_controller
                addr = 12'(`STATUS_ADDR);
                while (read_data != 32'h01 ) begin
                    i_apb.read(addr, read_data);
                end

                addr = 12'(`RXFIFO_ADDR);
                do begin

                    counter = 0;

                    for(integer i = 0; i < 8; i++) begin
                        @(posedge sclk);
                    end
                    i_apb.read(addr, read_data);

                    do begin

                        @(negedge apb_mst.PCLK);
                        response = read_data[counter*8 +: 8];
                        counter++;
                        @(negedge apb_mst.PCLK);

                        if (response == 8'h01) begin
                            rsp_found = 1;
                            $display("RSP Found!");
                        end
                    end while (counter != 'd3 );

                end while (!rsp_found);
            end

            default: begin
                $display("No Command Detected!");
            end
        endcase

        //TODO add addr check.


    endtask

   
endmodule : vip_apb_spi