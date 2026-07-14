

module vip_apb_driver #( 
    parameter int unsigned ADDR_W = 32'd32,
    parameter int unsigned DATA_W = 32'd32
);
// this task reads from an APB4 slave, acts as master
    task read(
      input  addr_t addr,
      output data_t data,
      output logic  err
    );
      
      paddr   <= #TA addr;
      pwrite  <= #TA 1'b0;
      psel    <= #TA 1'b1;
      apb.penable <= #TA 1'b1;

      while (!apb.pready) begin
        cycle_end();
        cycle_start();
      end
      data  = apb.prdata;
      err   = apb.pslverr;
      cycle_end();
      apb.paddr   <= #TA '0;
      apb.psel    <= #TA 1'b0;
      apb.penable <= #TA 1'b0;
      lock.put();
    endtask

     // this task writes to an APB4 slave, acts as master
    task write(
      input  addr_t addr,
      input  data_t data,
      input  strb_t strb,
      output logic  err
    );
      while (!lock.try_get()) begin
        cycle_end();
      end
      apb.paddr   <= #TA addr;
      apb.pwdata  <= #TA data;
      apb.pstrb   <= #TA strb;
      apb.pwrite  <= #TA 1'b1;
      apb.psel    <= #TA 1'b1;
      cycle_end();
      apb.penable <= #TA 1'b1;
      cycle_start();
      while (!apb.pready) begin
        cycle_end();
        cycle_start();
      end
      err = apb.pslverr;
      cycle_end();
      apb.paddr   <= #TA '0;
      apb.pwdata  <= #TA '0;
      apb.pstrb   <= #TA '0;
      apb.pwrite  <= #TA 1'b0;
      apb.psel    <= #TA 1'b0;
      apb.penable <= #TA 1'b0;
      lock.put();
    endtask