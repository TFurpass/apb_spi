

# SPI controller input/config for SD-card communication

BASEADDR DEFAULT = 0x0000 0000

| COMMAND | Purpose                                                      | Dataline (MOSI)   | Response                                        |
| ------- | ------------------------------------------------------------ | ----------------- | ----------------------------------------------- |
| CMD0    | Reset card and request SPI mode                              | 40 00 00 00 00 95 | R1 = 0x01 idle state entered                    |
| CMD8    | Check voltage range and card generation                      | 48 00 00 01 AA 87 | R7 echo ending in 0x01AA for SDv2+              |
| CMD55   | Prefix next command as application-specific                  | 77 00 00 00 00 01 | R1 = 0x01 while still idle                      |
| ACMD41  | init command: send same command & check response until ready | 69 40 00 00 00 01 | 0x01 busy, when 0x00 it is ready                |
| CMD58   | Read OCR and card capacity status                            | 7A 00 00 00 00 01 | R3; use CCS to distinguish SDSC from SDHC/SDXC  |
| CMD16   | Set block length for SDSC access                             | 50 00 00 02 00 01 | Use when you need 512-byte SDSC block transfers |
| CMD17   | Reads one block set by CMD16 (default 512kB)                 | 51 00 00 00 00 01 | TODO                                            |
| CMD24   | Writes one data block                                        | 58 00 00 00 00 01 | TODO                                            |

## CONFIG  

### CLKDIV
**For init set CLKDIV to SYSTEM_CLK/CLKDIV=400kHz**  

| Config CLKDIV reg                                              | PADDR            | PWDATA                                  |
| -------------------------------------------------------------- | ---------------- | --------------------------------------- |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x04 | 32'h??? "what ever value to get 400kHz" |

### **Set SPILEN**
| Config SPILEN reg                                                                                      | PADDR            | PWDATA       |
| ------------------------------------------------------------------------------------------------------ | ---------------- | ------------ |
| SPICMD 8 bits for sd CMD, SPIADDR to 40 bits for CMD additional fields + CRC + stop bit, FIFO to 512kB | BASE ADDR + 0010 | 32'h10002808 |

### **STATUS REG, start write to sd-card**
``Note: spicmd and spiaddr sent before sending from txfifo``

| Config status reg                                              | PADDR            | PWDATA   |
| -------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x00 | 32'h0102 |


### **STATUS REG, start read to sd-card**

``Note: spicmd and spiaddr sent before reading to rxfifo``

| Config status reg                                             | PADDR            | PWDATA   |
| ------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to read with normal SPI, chipselect to cs0 | BASE ADDR + 0x00 | 32'h0101 |

Configured so that SPIADDR holds sd-card cmd additional fields + CRC + stop bit. Total 40 bits.  
Configured so that SPICMD holds sd-card start bit + transaction bit + cmd(6 bits). Total 8 bits.  

### **CMD0**

| Register | PADDR         | PWDATA |
| -------- | ------------- | ------ |
| SPICMD   | BASE + 0x0008 | 32'h40 |
| SPIADDR  | BASE + 0x000C | 32'h95 |


### **CMD8**

| Register | PADDR         | PWDATA     |
| -------- | ------------- | ---------- |
| SPICMD   | BASE + 0x0008 | 32'h48     |
| SPIADDR  | BASE + 0x000C | 32'h01AA87 |


### **CMD55**

| Register | PADDR         | PWDATA |
| -------- | ------------- | ------ |
| SPICMD   | BASE + 0x0008 | 32'h77 |
| SPIADDR  | BASE + 0x000C | 32'h01 |


### **ACMD41**

| Register | PADDR         | PWDATA |
| -------- | ------------- | ------ |
| SPICMD   | BASE + 0x0008 | 32'h69 |
| SPIADDR  | BASE + 0x000C | 32'h01 |


### **CMD58** 

| Register | PADDR         | PWDATA |
| -------- | ------------- | ------ |
| SPICMD   | BASE + 0x0008 | 32'h7A |
| SPIADDR  | BASE + 0x000C | 32'h01 |

### **CMD16** 

| Register | PADDR         | PWDATA       |
| -------- | ------------- | ------------ |
| SPICMD   | BASE + 0x0008 | 32'h50       |
| SPIADDR  | BASE + 0x000C | 32'h02 00 01 |

**INIT Ohi**

## WRITE COMMANDS

### Single write **CMD24** 
| Register | PADDR         | PWDATA |
| -------- | ------------- | ------ |
| SPICMD   | BASE + 0x0008 | 32'h58 |
| SPIADDR  | BASE + 0x000C | 32'h01 |

## READ COMMANDS

### Single read **CMD17**
| Register | PADDR         | PWDATA |
| -------- | ------------- | ------ |
| SPICMD   | BASE + 0x0008 | 32'h51 |
| SPIADDR  | BASE + 0x000C | 32'h01 |

