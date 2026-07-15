

# SPI controller input/config for SD-card communication

BASEADDR DEFAULT = 0x0000 0000

## CONFIG  


**For init set CLKDIV to SYSTEM_CLK/CLKDIV=400kHz**  

| Config CLKDIV reg                                              | PADDR            | PWDATA                                  |
| -------------------------------------------------------------- | ---------------- | --------------------------------------- |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x04 | 32'h??? "what ever value to get 400kHz" |

**Set SPILEN**
| Config SPILEN reg                                                                                      | PADDR            | PWDATA       |
| ------------------------------------------------------------------------------------------------------ | ---------------- | ------------ |
| SPICMD 8 bits for sd CMD, SPIADDR to 40 bits for CMD additional fields + CRC + stop bit, FIFO to 512kB | BASE ADDR + 0010 | 32'h10002808 |

**Send CMD0 using SPICMD & SPIADDR**

**CMD0**
| SPICMD                             | PADDR         | PWDATA |
| ---------------------------------- | ------------- | ------ |
| start bit + transaction bit + CMD0 | BASE + 0x0008 | 32'h40 |

| SPIADDR                            | PADDR         | PWDATA |
| ---------------------------------- | ------------- | ------ |
| Additional fileds + CRC + stop bit | BASE + 0x000C | 32'h95 |

| Config status reg                                              | PADDR            | PWDATA   |
| -------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x00 | 32'h0102 |

**CMD8**
| SPICMD | PADDR         | PWDATA |
| ------ | ------------- | ------ |
| CMD8   | BASE + 0x0008 | 32'h48 |

| SPIADDR                            | PADDR         | PWDATA     |
| ---------------------------------- | ------------- | ---------- |
| Additional fields + CRC + stop bit | BASE + 0x000C | 32'h01AA87 |

**CMD55**
| SPICMD | PADDR         | PWDATA |
| ------ | ------------- | ------ |
| CMD55  | BASE + 0x0008 | 32'h77 |

| SPIADDR | PADDR         | PWDATA |
| ------- | ------------- | ------ |
| CMD55   | BASE + 0x000C | 32'h01 |

**ACMD41**
| SPICMD | PADDR         | PWDATA |
| ------ | ------------- | ------ |
| ACMD41 | BASE + 0x0008 | 32'h69 |

| SPIADDR | PADDR         | PWDATA |
| ------- | ------------- | ------ |
| ACMD41  | BASE + 0x000C | 32'h01 |

**CMD58**
| SPICMD | PADDR         | PWDATA |
| ------ | ------------- | ------ |
| CMD58  | BASE + 0x0008 | 32'h7A |

| SPIADDR | PADDR         | PWDATA |
| ------- | ------------- | ------ |
| CMD58   | BASE + 0x000C | 32'h01 |

**INIT Ohi**

**CMD16** 
| SPICMD | PADDR         | PWDATA |
| ------ | ------------- | ------ |
| CMD16  | BASE + 0x0008 | 32'h50 |

| SPIADDR | PWADDR         | PWDATA       |
| ------- | ------------- | ------------ |
| CMD16   | BASE + 0x000C | 32'h02 00 01 |

