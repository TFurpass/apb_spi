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
    logic [31:0] counter = 0;

    integer i;
    logic rsp_found;
    logic read_rsp;
    logic [7:0] response;
    logic [31:0] read_data = 0;
    logic [31:0] fifodata = 0;
    logic acmd_no_rsp = 0;

    

    // TODO expand on response type logic
    typedef enum logic[2:0] {
        R1,
        R3,
        R7,
        ACMDR1,
        block_read 
    } rsp_type;

    rsp_type r_type;
    

    typedef struct packed {
        logic [11:0] addr;
        logic [31:0] data;
    } apb_addr_data;

    apb_addr_data init_apb [0:3]='{
        '{12'(`CLKDIV_ADDR), 32'h1F4},
        '{12'(`SPILEN_ADDR), 32'h00500000},
        '{12'(`TXFIFO_ADDR), 32'hFFFFFFFF},
        '{12'(`STATUS_ADDR), 32'h02}
    };
   
    apb_addr_data cmd_apb_write_config [0:3] = '{
        '{12'(`CLKDIV_ADDR), 32'h1F4},
        '{12'(`SPILEN_ADDR), 32'h00300000},
        '{12'(`STATUS_ADDR), 32'h0122},
        '{12'(`SPILEN_ADDR), 32'h00300000}
    };

    apb_addr_data cmd_apb_read_config [0:1] = '{
        '{12'(`SPILEN_ADDR), 32'h00080000},
        '{12'(`STATUS_ADDR), 32'h0121}
    };
    apb_addr_data cmd0 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h40000000},
        '{12'(`TXFIFO_ADDR), 32'h00950000}
    };

    apb_addr_data cmd8 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h48000001},
        '{12'(`TXFIFO_ADDR), 32'hAA870000}
    };

    apb_addr_data cmd55 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h77000000},
        '{12'(`TXFIFO_ADDR), 32'h00650000}
    };
    
    apb_addr_data acmd41 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h69400000},
        '{12'(`TXFIFO_ADDR), 32'h00770000}
    };

    apb_addr_data cmd58 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h7A000000},
        '{12'(`TXFIFO_ADDR), 32'h00FD0000}
    };

    apb_addr_data cmd17 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h51000000},
        '{12'(`TXFIFO_ADDR), 32'h00550000}
    };

    apb_addr_data cmd24 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h58000000},
        '{12'(`TXFIFO_ADDR), 32'h006F0000}
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

        logic no_rsp;
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

        while (counter < 80) begin
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
        
        logic [31:0] data = 0;
        logic [11:0] addr;
        rsp_type rsp_for_cmd;
        apb_addr_data cmd [0:1] = '{default:'0};

        logic loopcmd55 = 0;
        logic [7:0] which_cmd = CMD;
       
        logic [31:0] bounds;
        rsp_found = 0;
        response = 0;
        
        $display("\n\tStarting single command test");
        $display("\tCMD: %2d", CMD);
        
        case(CMD)

            0: begin 
                cmd =  cmd0;
                rsp_for_cmd = R1;
            end
            
            8: begin
                cmd = cmd8;
                rsp_for_cmd = R7;
            end
                
            55: begin
                cmd = cmd55;
                rsp_for_cmd = R1;
            end

            41: begin
                cmd= acmd41;
                rsp_for_cmd = ACMDR1;
            end

            58: begin
                cmd = cmd58;
                rsp_for_cmd = R3;
            end

            17: begin
                cmd = cmd17;
                rsp_for_cmd = block_read;
            end

            24: begin
                cmd = cmd24;
                rsp_for_cmd = R1;
            end

            default: begin
                $display("No Command Detected!");
            end
        endcase

        r_type = rsp_for_cmd;

        // config registers of dut for TX to sd-card and RX from sd-card
        write_and_read_with_sd(cmd, data, addr, rsp_for_cmd);
        
    endtask

    task automatic write_and_read_with_sd(apb_addr_data cmd [0:1], logic [31:0] data, logic [11:0] addr, rsp_type rsp_for_cmd);
        
            for(integer i= 0; i< 4; i++) begin

                // waiting for idle state at the start and everytime an spi write or read is issued through state_register
                if(i == 2 | i == 0 ) begin
                    wait_for_idle();
                end

                if(i == 2) begin 
                    // write fifos with data before issuing cmd transfer to the sd card
                    for(integer j = 0; j< 2; j++) begin
                        data = cmd[j].data;
                        addr = cmd[j].addr;
                        i_apb.write(addr, data);
                        @(posedge apb_mst.PCLK);
                    end
                end 

                data = cmd_apb_write_config[i].data;
                addr = cmd_apb_write_config[i].addr;
                i_apb.write(addr, data);

                @(posedge apb_mst.PCLK);
            end

            wait_for_idle();

            // read values from DUT RXFIFO
            read_rxfifo(rsp_for_cmd);

    endtask

    // TODO expand on response type logic
    task automatic read_rxfifo(rsp_type rsp_for_cmd);
        logic [11:0] addr = 0;
        logic [31:0] data;
        logic valid_data = 0;
        bit token_found = 0;
        
        read_rsp = 0;
        counter = 0;
        
        // read from dut's rxfifo until a response has arrived
        do begin
            wait_for_idle();
            // config spilen for fifo read to be 8 bits
            // write spiread to status register
            for(integer i = 0; i< 2; i++) begin
                data = cmd_apb_read_config[i].data;
                addr = cmd_apb_read_config[i].addr;
                i_apb.write(addr, data);

                @(posedge apb_mst.PCLK);
            end

            // wait for RX state of the spi_master_controller so we know read from sd has begun
            addr = 12'(`STATUS_ADDR);
            while (read_data[7:0] != 8'h40 ) begin
                i_apb.read(addr, read_data);
                #5us;
            end
            wait_for_idle();
            // TODO create a timeout with counter so the dut doesn't poll the response forever if card is not inserted
            addr = 12'(`RXFIFO_ADDR);
            i_apb.read(addr, fifodata);
            @(negedge apb_mst.PCLK);

            // first zero indicates start of response
            if(fifodata[7] == 0 && ~valid_data) begin
                valid_data = 1;
            end else begin
                counter++;
            end

            @(negedge apb_mst.PCLK);
            
            case(rsp_for_cmd)
                R1: begin

                    if (fifodata[7:0] == 8'h01) begin
                        read_rsp = 1;
                        $display("RSP Found! RSP: %2h in IDLE\n", fifodata[7:0]);
                    end else if ( fifodata[7:0] == 8'h00) begin
                        $display("RSP Found! Not in IDLE");
                        read_rsp = 1;
                    end
                end

                ACMDR1: begin

                    if(fifodata[7:0] == 00) begin
                        acmd_no_rsp = 1;
                        read_rsp = 1;
                        $display("acmd found");
                    end
                    if(fifodata[7:0] == 01) read_rsp = 1;
                end

                R3: begin
                    
                    // when fifo_data has OCR data, check the values
                    // it takes 40 bits to get data i.e. when counter is >5 (5*8=40) fifodata is valid
                    if(counter == 5) begin
                        
                        // index 31 busy bit not needed for spi because of R1 but could/should be implemented for sdio or sd bus

                        // CS bit, capacity status
                        if(fifodata[30] == 1) begin
                            $display("CCS = 1 High capacity cards in use SDHC or SDXC\n");
                        end else begin
                            $display("CCS = 0, SDSC, use cmd 16 to define 512 byte block addressing");
                        end

                        //UHS-II, not in use for SPI
                        if(fifodata[29] == 1) begin
                            $display("UHS-II status: asserted");
                        end
                        
                        // 1.8 V capability (not supported by SPI)
                        if(fifodata[28:25] == 4'hF) begin
                            $display("low_voltage_accept");
                        end

                        // voltage range
                        if(fifodata[24:16] == 9'h1FF) begin
                            $display("Voltage range: 2.7-3.6 V supported");
                        end

                        // rest bits in ocr are reserved, don't care at this point
                        read_rsp = 1;
                    end
                end

                R7: begin
                    if(counter == 5) begin
                        if (fifodata[31:0] == 32'h000001AA) begin
                            $display("\tVoltage accepted");
                            $display("\tValue: %3h echoed in response.", fifodata[8:0]);
                            read_rsp = 1;
                        end
                    end
                end

                block_read: begin
                    if (fifodata[7:0] == 8'h00) begin
                        $display("RSP Found! RSP: %2h\n", response);

                        // keep reading until token received from fifo
                        if(fifodata[7:0] == 8'hFE) token_found = 1;

                        // if token has not arrived, keep counter at 0
                        if(~token_found) counter = 0;

                        // when counter reaches 65, 512 bytes of data have been read (64*8=512) Note: needs extra count before the data is in fifo
                        if(counter == 513) begin
                            read_rsp = 1;
                        end
                        if(counter % 31 == 0) $display("%8h", fifodata);
                    end 
                end

            endcase

        end while (~read_rsp);
       
        @(posedge apb_mst.PCLK);
        read_rsp = 0;
        counter = 0;
        response = 0;
    endtask

    task automatic write_read_test();
        logic [31:0] data;

        for (integer i = 0; i< 64; i++)begin
            data = $urandom();
            //i_apb.write(`TXFIFO_ADDR, data);
            end
    endtask
    assign rsp_found = read_rsp;
   
endmodule : vip_apb_spi