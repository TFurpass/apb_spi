

# SPI controller input/config for SD-card communication

BASEADDR DEFAULT = 0x0000 0000  

**Needs testing how the spi_master sends the txfifo data and how it receives rxfifo data to determine if spicmd and spiaddr should be used to transmit the whole sd card cmd and its additional fields or whether they should act as the start bit & transaction bit. Fifo could be configured to 8 bit data packets for init and commands and then to 512kB for data reads. Yet to be determined how to approach this.** 

**Current approach is to use spicmd and spiaddr for commands + additional fields and fifo for dummy cycles during init phase to receive responses (needed since spidummy sends zeros not ones and sd-card emulator needs ones), FIFO should be configured with SPILEN differently after init**

| COMMAND | Purpose                                                      | Dataline (MOSI)   | Response + info                                     |
| ------- | ------------------------------------------------------------ | ----------------- | --------------------------------------------------- |
| CMD0    | Reset card and request SPI mode                              | 40 00 00 00 00 95 | R1 = 0x01 idle state entered                        |
| CMD8    | Check voltage range and card generation                      | 48 00 00 01 AA 87 | R7 echo ending in 0x01AA for SDv2+                  |
| CMD55   | Prefix next command as application-specific                  | 77 00 00 00 00 01 | R1 = 0x01 while still idle                          |
| ACMD41  | init command: send same command & check response until ready | 69 40 00 00 00 01 | 0x01 busy, when 0x00 it is ready                    |
| CMD58   | Read OCR and card capacity status                            | 7A 00 00 00 00 01 | R3; use CCS to distinguish SDSC from SDHC/SDXC      |
| CMD16   | Set block length for SDSC access                             | 50 00 00 02 00 01 | R1; Use when you need 512-byte SDSC block transfers |
| CMD17   | Reads one block set by CMD16 (default 512kB)                 | 51 00 00 00 00 01 | R1                                                  |
| CMD24   | Writes one data block                                        | 58 00 00 00 00 01 | R1                                                  |

| SD-card Command width |
| :-------------------: |
|        48 bits        |

## CONFIG  

### CLKDIV
**For init set CLKDIV to SYSTEM_CLK/CLKDIV=400kHz**  

PWDATA value configured for the sdspi tb of zipcpu.

| Config CLKDIV reg                                              | PADDR            | PWDATA |
| -------------------------------------------------------------- | ---------------- | ------ |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x04 | 32'h7c |

### **SPILEN**

|                                      32 : 0                                       |
| :-------------------------------------------------------------------------------: |
|             31:16 FIFO width - 15:8 SPIADDR width - 7:0 SPICMD width              |
| Max length for FIFO : 65535 (16'hFFFF), SPIADDR : 63 (8'h3F), SPICMD : 63 (8'h3F) |

PWDATA 32'h00802020 sets fifo length as 128 bits  SPIADDR length to 32 bits and SPICMD length to 32 bits.  

To send a cmd to sd card, these could be configured to 32'h00602808, where FIFO is 96 bits (should be enough for the sd card to give a response), SPIADDR is 32 bits for cmd additional fields + CRC and stop bit, and SPICMD 16 bits for Start bit + transaction bit, CMD, and one additiona  field byte.  
`Note: when setting the length to lower than 32 bits, the missing bits from the length are cut from LSB side. if we want to write 16 bit length to CMD: 16'h4000, it needs to be written to input (PWDATA) as 32'h40000000. Not 32'h4000`

| Config SPILEN reg                                                                                                               | PADDR            | PWDATA       |
| ------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------------ |
| SPICMD 16 bits for sd CMD and additional field, SPIADDR to 32 bits for CMD additional fields + CRC + stop bit, FIFO to 128 bits | BASE ADDR + 0010 | 32'h00802010 |

`When sending just commands in the init phase, we use the fifo to send dummy bits/cycles, these are needed to receive a response from the sd-card`

### **STATUS REG, start write to sd-card**
``Note: spicmd and spiaddr sent before sending from txfifo``

PWDATA 32'h0102 starts a standard SPI write transaction, using chip select cs0. SPILEN, CLKDIV, SPICMD, SPIADDR and TXFIFO should be written before STATUS is written.  
STATUS can not be written to while cs is low i.e. during a transaction. 

| Config status reg                                              | PADDR            | PWDATA   |
| -------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x00 | 32'h0102 |


### **STATUS REG, start read from sd-card**

``Note: spicmd and spiaddr sent before reading to rxfifo``  

**TESTING NEEDED**

| Config status reg                                             | PADDR            | PWDATA   |
| ------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to read with normal SPI, chipselect to cs0 | BASE ADDR + 0x00 | 32'h0101 |

| FIFO length| PWDATA to SPILEN|
| 512kB for data reads|h02002010

Configured so that SPIADDR holds sd-card cmd additional fields + CRC + stop bit. Total 40 bits.  
Configured so that SPICMD holds sd-card start bit + transaction bit + cmd(6 bits). Total 8 bits.  

### **CMD0**

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h40000000 |
| SPIADDR  | BASE + 0x000C | 32'h00000095 |


### **CMD8**

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h48000000 |
| SPIADDR  | BASE + 0x000C | 32'h0001AA87 |


### **CMD55**

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h77000000 |
| SPIADDR  | BASE + 0x000C | 32'h00000001 |


### **ACMD41**

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h69000000 |
| SPIADDR  | BASE + 0x000C | 32'h00000001 |


### **CMD58** 

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h7A000000 |
| SPIADDR  | BASE + 0x000C | 32'h00000001 |

### **CMD16** 

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h50000000 |
| SPIADDR  | BASE + 0x000C | 32'h00020001 |

**INIT Ohi**

## WRITE COMMANDS

### Single write **CMD24** 
| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h58000000 |
| SPIADDR  | BASE + 0x000C | 32'h00000001 |

## READ COMMANDS

### Single read **CMD17**
| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h51000000 |
| SPIADDR  | BASE + 0x000C | 32'h00000001 |

