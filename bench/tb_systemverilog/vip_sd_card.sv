//TODO
// -> FIX magic numbers
// -> Re-structure frames



module vip_sd_card #(
) (
    input logic mosi,
    input logic cs,
    input logic sclk,
    output logic miso
); 

    import sd_reg_pkg::ocr_t;
    ocr_t ocr = '{1'b0, 1'b0, 1'b0, 4'b0, 9'h1FF, 7'hFF, 1'b0, 7'hFF};
    /* TODO
    - add commands
    - test cs interrupt in the middle of transfer functionality
     */


    localparam time TA = 100ns; // after clk edge, when values are driven
    localparam time TT = 4.8us; // after clk edge, when values are read/sampled

    typedef struct packed{
        logic [7:0] cmd;
        logic [7:0] crc;
        logic [39:0] response;   // response bytes to send on MISO
        logic [2:0] resp_len;    // number of response bytes
    } sd_cmd_t;

    sd_cmd_t rx_cmd;

    localparam sd_cmd_t SD_CMDS[7] = '{
        '{8'h40, 8'h95, 40'h01,         1}, // CMD0 -> R1=0x01
        '{8'h48, 8'h87, 40'h01000001AA, 5}, // CMD8 -> R7
        '{8'h77, 8'h65, 40'h01,         1}, // CMD55
        '{8'h69, 8'h77, 40'h00,         1}, // ACMD41
        '{8'h7A, 8'hFD, 40'h0040000000, 5}, // CMD58 -> R3
        '{8'h51, 8'h55, 40'h00,         1}, // CMD17
        '{8'h58, 8'h6F, 40'h00,         1}  // CMD24
    };

    //CMD names
    typedef enum logic [7:0] {
        CMD0 = 8'h40, 
        CMD8 = 8'h48,
        CMD55 = 8'h77,
        ACMD41 = 8'h69,
        CMD58 = 8'h7A,
        CMD17 = 8'h51,
        CMD24 = 8'h58
        } cmd_num;
    cmd_num cmd;

    logic [7:0] counter;
    logic [47:0] data_packet;
    // when CRC is detected, rsp is asserted to enable response.
    bit rsp = 0;
    logic miso_line;
    logic [3:0] i;

    logic [39:0] tx;


    // does not take into account interruptions in sclk 
    task automatic powerup(logic mosi, logic cs, logic sclk);

        logic [7:0] cycle_cnt = 0;
        @(posedge sclk);
    
        for (cycle_cnt = 0; cycle_cnt < 74; cycle_cnt++) begin
            if(~cs | ~mosi) begin
                $display("\tpowerup of an sd card needs atleast 74 sclk cycles where cs & mosi are high");
            end
            @(posedge sclk);
        end
        $display("\tpowerup finished correctly, CMD0 can be sent.");
    endtask


    task miso_generate();
        do begin
            while(~rsp) begin 
                miso_line = 1;
                @(posedge sclk);
            end;

            // simulate delay, sd card is aligned with sclk in 8 bit counts for all data it sends and evaluates.
            for ( i = 0; i< 8; i++) begin
                @(negedge sclk);
                miso_line = 1;
            end

            //Aling response to the top
            tx = rx_cmd.response << (40-rx_cmd.resp_len*8);

            //Send response
            for ( i = 0; i< rx_cmd.resp_len * 8; i++) begin
                miso_line = tx[39];
                tx = tx << 1;
               @(negedge sclk);
            end
            i=0;
            rsp = 0;
        end while(rsp); // TODO TEST cs interrupt in the middle of transfer functionality
    endtask

    task automatic detect_CMD_and_CRC();
        data_packet = 0;
        // wait for sclk since the sd card operates only when sclk is provided
        //@(posedge sclk);

        // cs and mosi should be high for powerup, when cs goes low, we read mosi
        while (mosi) begin
            #2us;
        end


        //CMD and CRC reading -> CHECK!
        do begin @(posedge sclk);
            data_packet[0] =  mosi;
            counter++; 
            if (counter < 8'd48) begin
                data_packet =  data_packet << 1;
                
            end
            else begin
                counter = 0;
                data_packet[0] =  mosi;
                rx_cmd.crc = {data_packet[7:0]};
                rx_cmd.cmd = {data_packet[47:40]};

                //Search matching command from the structure
                foreach (SD_CMDS[i]) begin
                    if (SD_CMDS[i].cmd == rx_cmd.cmd &&
                        SD_CMDS[i].crc == rx_cmd.crc) begin

                        //Copy the matching command from the table
                        rx_cmd = SD_CMDS[i];
                        cmd = cmd_num'(rx_cmd.cmd);
                        $display("%s detected, CRC: %2h\n", cmd.name(),rx_cmd.crc);
                        rsp = 1;

                    end
                end
                @(posedge sclk);
                data_packet = 0;
                
            end
            
        end while (~cs & ~rsp);

    endtask

    assign miso = miso_line;

endmodule : vip_sd_card
