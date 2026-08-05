
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

    typedef enum logic [7:0] {
        CMD0_CRC = 8'h95, 
        CMD8_CRC = 8'h87,
        CMD55_CRC = 8'h65,
        ACMD41_CRC = 8'h77,
        CMD58_CRC = 8'hFD,
        CMD17_CRC = 8'h55,
        CMD24_CRC = 8'h6F
    } crc_val;
    crc_val crc;

    logic [3:0] counter;
    logic [7:0] data_packet;
    // when CRC is detected, rsp is asserted to enable response.
    bit rsp = 0;
    logic miso_line;
    logic [3:0] i = 0;
    logic [7:0] R1_data = 8'h01;

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
        miso_line = 1;          
        while (cs) begin
            #2.5us;
        end
        @(posedge sclk);
        do begin

            do begin 

                miso_line = 1;
                @(posedge sclk);
            end while(~rsp);
           
            
            // simulate delay, sd card is aligned with sclk in 8 bit counts for all data it sends and evaluates.
            for ( i = 0; i< 8; i++) begin

                miso_line = @(negedge sclk) 1;
                @(posedge sclk);
            end 
            
            // send response
            for ( i = 0; i< 8; i++) begin

                miso_line = #TA R1_data[7-i];
                @(posedge sclk);

            end
            rsp = #TA 0;
            
        end while(!cs); // TODO TEST cs interrupt in the middle of transfer functionality
    endtask

    task automatic detect_CMD_and_CRC();

        // wait for sclk since the sd card operates only when sclk is provided
        //@(posedge sclk);

        // cs and mosi should be high for powerup, when cs goes low, we read mosi
        while (cs) begin
            #2us;
        end

        do  begin
            @(posedge sclk);
            data_packet[0] =  mosi;
            counter++; 
            if (counter < 4'd8) begin
                data_packet =  data_packet << 1;
                
            end else begin
                counter = 0;
                crc = crc_val'(data_packet);
                cmd = cmd_num'(data_packet);

                if (cmd.name() != "") begin
                    $display("\n%s detected", cmd.name());

                end else if (crc.name() != "") begin
                    $display("CRC %2h for %s detected\n", crc, crc.name);
                    
                    rsp = 1;
                end 
                data_packet = 0;
                
            end
            
        end while (~cs);                                                                                                                                      
    endtask

    assign miso = miso_line;

endmodule : vip_sd_card