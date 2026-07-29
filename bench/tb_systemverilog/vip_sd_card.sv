
module vip_sd_card #(
) (
    input logic mosi,
    input logic cs,
    input logic sclk,
    output logic miso
); 


    localparam time TA = 100ns; // after clk edge, when values are driven
    localparam time TT = 4.8us; // after clk edge, when values are read/sampled

    logic [3:0] counter;
    logic [8:0] data_packet;
    // when CRC is detected, rsp is asserted to enable response.
    bit rsp = 0;
    logic miso_line;
    logic [3:0] i = 0;
    logic [7:0] R1_data = 8'h01;

    task miso_generate();

        while (cs) begin
            #2.5us;
        end
        @(posedge sclk);
        do begin

            do begin 

                miso_line = #TA 1;
                @(posedge sclk);
            end while(~rsp);
           
            
            // simulate delay, sd card is aligned with sclk in 8 bit counts for all data it sends and evaluates.
            for ( i = 0; i< 7; i++) begin

                miso_line = #TA 1;
                @(posedge sclk);
            end 
            @(negedge sclk);
            // send response
            for (integer i = 0; i< 8; i++) begin
                
                miso_line = #TA R1_data[7-i];
                @(posedge sclk);
            end
            rsp = #TA 0;
            
        end while(!cs); // TODO TEST cs interrupt in the middle of transfer functionality
    endtask

    task automatic basic();
        
        while (cs) begin
            #2us;
        end
        @(posedge sclk);
        while (~cs & ~rsp) begin
            #TA 
            counter++; 
            data_packet[0] =  mosi;
          
            if (counter < 4'd8) begin
                data_packet =  data_packet << 1;

            end else begin

                counter = 0;
                if (data_packet == 9'h40) begin
                    $display("CMD0 detected");
                end else if (data_packet == 9'h95) begin
                    $display("CRC 0x95 for CMD0 detected");
                    rsp = 1;
                end
            end
            
            @(posedge sclk);
           
        end

        
    endtask
    assign miso = miso_line;

endmodule : vip_sd_card