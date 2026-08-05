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
    localparam longint unsigned SimCycles = 'd300_000;
    logic clk, rst_n;
    logic [7:0] counter = 0;

    integer i;
    bit rsp_found;
    logic [7:0] response;
    logic [31:0] read_data = 0;

    typedef struct packed {
        logic [11:0] addr;
        logic [31:0] data;
    } apb_addr_data;

    apb_addr_data init_apb [0:3]='{
        '{12'(`CLKDIV_ADDR),32'h1F4},
        '{12'(`SPILEN_ADDR),32'h00500000},
        '{12'(`TXFIFO_ADDR),32'hFFFFFFFF},
        '{12'(`STATUS_ADDR), 32'h02}
    };

    apb_addr_data cmd0_apb_writepairs [0:6] = '{
        '{12'(`CLKDIV_ADDR), 32'h1F4},
        '{12'(`SPILEN_ADDR), 32'h00300000},
        '{12'(`TXFIFO_ADDR),32'h40000000},
        '{12'(`TXFIFO_ADDR),32'h00950000},
        '{12'(`STATUS_ADDR),32'h0122},
        '{12'(`SPILEN_ADDR),32'h00300000},
        '{12'(`STATUS_ADDR), 32'h0121}
    };

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

    
    task automatic detect_card(output bit card_found);


        for(logic[3:0] i = 0; i < 3; i++) begin

            CMD(0);
            if(rsp_found) begin
                $display("\n\tCARD DETECTED\n");
                card_found = 1;
                return;
            end
        end

        $display("\n\tNO CARD INSERTED\n");
        card_found = 0;

    endtask

    // An SD-card needs atleast 74 sclk cycles to powerup, this task generates these cycles
    task automatic sd_powerup ();

        logic [31:0] read_data = 0;
        $display("\n\tpowerup start\n");
        counter = 0;

        while (counter < 'd80) begin
            @(posedge sclk);
            counter++;
            
        end

        $display("[powerup] SCLK cycle: %d", counter);
        $display("\tpowerup end\n");
        
        counter = 0;
    endtask

    // writes clkdiv for producing 400khz sclk, sets spilen for sending enough clk cycles to the sd-card, writes ones to txfifo
    task automatic init();
        
        logic [31:0] data = 0;
        logic [11:0] addr = 0;

        $display("\n\tinit start");
        for(integer i = 0; i< 4; i++) begin
            addr = init_apb[i].addr;
            data = init_apb[i].data;
            if(i != 2) begin 
                i_apb.write(addr, data);
                $display("[init] APB write addr : %2h, data : %8h", addr, data);
            end else begin
                for(integer j = 0; j< 3; j++) begin
                    i_apb.write(addr, data); 
                    $display("[init] APB write addr : %2h, data : %8h", addr, data);
                end            
            end
        end
        $display("\tinit end\n");
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

    task automatic wait_for_idle();
            logic [11:0] addr;

        @(posedge apb_mst.PCLK);
        // wait for idle state
        addr = 12'(`STATUS_ADDR);
        while (read_data[0] != 1'h1 ) begin
            i_apb.read(addr, read_data);
            @(posedge apb_mst.PCLK);
        end
        read_data = 0;
    endtask

    task automatic CMD (logic [7:0] CMD);
        
        automatic logic [31:0] data = 0;
        logic [31:0] CMD0_data = 32'h40;
        logic [11:0] addr;
       
        logic [31:0] status;
        logic [31:0] bounds;
        rsp_found = 0;
        response = 0;

        $display("\n\tStarting single command test");
        $display("\tCMD: %2d", CMD);
        
        //TODO vector for address order depending on command
        case(CMD)

            0: begin

 
                for(integer i= 0; i< 7; i++) begin
                    // waiting for idle state at the start and everytime an spi write or read is issued through state_register
                    if(i == 4 | i == 0 | i == 5) begin
                        wait_for_idle();
                    end
                    data = cmd0_apb_writepairs[i].data;
                    addr = cmd0_apb_writepairs[i].addr;
                    i_apb.write(addr, data);
                    @(posedge apb_mst.PCLK);
                end

                // wait for RX state of the spi_master_controller so we know read from sd has begun
                addr = 12'(`STATUS_ADDR);
                while (read_data[7:0] != 8'h40 ) begin
                    i_apb.read(addr, read_data);
                    #5us;
                end

                // wait for read from sd-card to finish
                wait_for_idle();

                // read values from DUT RXFIFO
                addr = 12'(`RXFIFO_ADDR);
                counter = 0;
                read_data = 0;
                i_apb.read(addr, read_data);
                do begin

                    @(negedge apb_mst.PCLK);
                    response = read_data[counter*8 +: 8];
                    counter++;
                    @(negedge apb_mst.PCLK);

                    if (response == 8'h01) begin
                        rsp_found = 1;
                        $display("RSP Found!\n");
                    end
                end while (counter != 'd3 );
            end

            default: begin
                $display("No Command Detected!");
            end
        endcase

        //TODO add addr check.


    endtask

   
endmodule : vip_apb_spi