module vip_apb_spi #() (
    output  logic                      HCLK,
    output  logic                      HRESETn,
    output  logic [APB_ADDR_WIDTH-1:0] PADDR,
    output  logic               [31:0] PWDATA,
    output  logic                      PWRITE,
    output  logic                      PSEL,
    output  logic                      PENABLE,
    input logic               [31:0]   PRDATA,
    input logic                        PREADY,
    input logic                        PSLVERR,

    input logic                [1:0] events_o,

    input logic                      spi_clk,
    input logic                      spi_csn0,
    input logic                      spi_csn1,
    input logic                      spi_csn2,
    input logic                      spi_csn3,
    input logic                [1:0] spi_mode,
    input logic                      spi_sdo0,
    input logic                      spi_sdo1,
    input logic                      spi_sdo2,
    input logic                      spi_sdo3,
    output  logic                      spi_sdi0,
    output  logic                      spi_sdi1,
    output  logic                      spi_sdi2,
    output  logic                      spi_sdi3
);

// TODO connect C++ sd card emulator from zipcpu or create your own (vhdl versions with reference available and maybe an sv version without sd card register configurations)

// vip_spi_slv #() i_SD_card (
//    .sclk (clk),
//    .cs (spi_csn0),
//    .mosi (spi_sdo0),
//    .miso (spi_sdi0)
// );

// APB master that drives the spi controller
vip_apb_drv #() (
    .HCLK(),
    .HRESETn(),
    .PADDR(),
    .PWDATA(),
    .PWRITE(),
    .PSEL(),
    .PENABLE(),
    .PRDATA(),
    .PREADY(),
    .PSLVERR(),
)


