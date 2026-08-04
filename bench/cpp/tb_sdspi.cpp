////////////////////////////////////////////////////////////////////////////////
//
// Filename:	bench/cpp/tb_sdspi.cpp MODIFIED
// {{{
// Project:	SD-Card controller
//
// Purpose:	Exercise all of the functionality contained within the Verilog
//		core, from bring up through read to write and read-back.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2016-2025, Gisselquist Technology, LLC
// {{{
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
// }}}
// Include files
// {{{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <Vapb_spi_master.h>
#include "testb.h"
#include "apb_tb.h"
#include "sdspisim.h"
// }}}

// MACRO definitions
// {{{
// #define	OPT_LITTLE_ENDIAN

/*

#define	SDSPI_CMD_ADDR	0
#define	SDSPI_DATA_ADDR	1
#define	SDSPI_FIFO_A	0x1A102018 //TX
#define	SDSPI_FIFO_B	0x1A102020 //RX


#define	READAUX	0x80
#define	SETAUX	0xc0

#define	SDSPI_CMD			0x000040
#define	SDSPI_ACMD			(SDSPI_CMD + 55)
#define	SDread_responseREG	0x000200
#define	SDSPI_FIFO_OP		0x000800
#define	SDSPI_WRITEOP		0x000c00
#define	SDSPI_FIFO_ID		0x001000
#define	SDSPI_BUSY			0x004000
#define	SDSPI_ERROR			0x008000
#define	SDSPI_CLEARERR		0x008000
#define	SDSPI_REMOVED		0x040000
#define	SDSPI_PRESENTN		0x080000
#define	SDSPI_RESET			0x100000
#define	SDSPI_WATCHDOG		0x200000
#define	SDSPI_GO_IDLE		((SDSPI_REMOVED|SDSPI_CLEARERR|SDSPI_CMD)+0)
#define	SDread_response_SECTOR	((SDSPI_CMD|SDSPI_CLEARERR|SDSPI_FIFO_OP)+17)
#define	SDSPI_WRITE_SECTOR	((SDSPI_CMD|SDSPI_CLEARERR|SDSPI_WRITEOP)+24)

#define log2(VALUE) ((VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE) < ( 8 ) ? 3 : (VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11 : (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 : (VALUE) < ( 1048576 ) ? 20 : (VALUE) < ( 1048576 * 2 ) ? 21 : (VALUE) < ( 1048576 * 4 ) ? 22 : (VALUE) < ( 1048576 * 8 ) ? 23 : (VALUE) < ( 1048576 * 16 ) ? 24 : 25)


*/

typedef struct {
	uint32_t fifo0;
	uint32_t fifo1;
	int	 r_frame;
} SDCMD;


#define REG_STATUS 		0x1A102000
#define REG_CLKDIV 		0x1A102004
#define REG_SPICMD 		0x1A102008
#define REG_SPIADR 		0x1A10200c
#define REG_SPILEN 		0x1A102010
#define REG_SPIDUM 		0x1A102014
#define REG_TXFIFO 		0x1A102018
#define REG_RXFIFO 		0x1A102020
#define REG_INTCFG 		0x1A102024
#define REG_INTSTA 		0x1A102028

//Status register values
#define WRITE_OP		0x00000122
#define READ_OP			0x00000121

//Response frame sizes
#define R1				1
#define R3				5
#define R7				5

//Register values
#define CLK_DIV			0x7c
#define CMD_DATA_LEN	0x00300000
#define RX_DATA_LEN		0x00600000


//SD CMDs
#define CMD0			((SDCMD){0x40000000, 0x00950000, R1})
#define CMD8			((SDCMD){0x48000001, 0xAA870000, R7})
#define CMD55			((SDCMD){0x77000000, 0x00650000, R1})
#define ACMD41			((SDCMD){0x69400000, 0x00770000, R1})
#define CMD58			((SDCMD){0x7A000000, 0x00FD0000, R3})
#define CMD16			((SDCMD){0x50000002, 0x00150000, R1})
#define CMD17			((SDCMD){0x51000000, 0x00550000, R1})
#define CMD24			((SDCMD){0x58000000, 0x006F0000, R1})


class	SDSPI_TB : public apb_TB<Vapb_spi_master> {
	SDSPISIM	*m_sdspi;
public:

	unsigned	OCR(void) { return m_sdspi->OCR(); }

	SDSPI_TB(const char *sdcard_image) {
		// {{{
		if (0 != access(sdcard_image, R_OK)) {
			fprintf(stderr, "Cannot open %s for reading\n", sdcard_image);
			exit(EXIT_FAILURE);
		} if (0 != access(sdcard_image, W_OK)) {
			fprintf(stderr, "Cannot open %s for writing\n", sdcard_image);
			exit(EXIT_FAILURE);
		}

		m_sdspi = new SDSPISIM(true);
		m_sdspi->load(sdcard_image);
		// }}}
	}

	virtual	void	tick(void) {
		// {{{
		TESTB<Vapb_spi_master>::tick();

		core()->spi_sdi1 = (*m_sdspi)(core()->spi_csn0, core()->spi_clk, core()->spi_sdo0);
		// }}}
	}

	Vapb_spi_master *core(void) {
		return m_core;
	}


	void wait_for_idle(void){

		while ((apb_read(REG_STATUS)& 0x1) == 0)
			;

	}


	uint64_t sdcmd(SDCMD cmd, bool csn_toggle = true){

		apb_write(REG_SPILEN, CMD_DATA_LEN);
		apb_write(REG_TXFIFO, cmd.fifo0);
		apb_write(REG_TXFIFO, cmd.fifo1);
		apb_write(REG_STATUS, WRITE_OP); //Start write to the SD-card

		//Waiting for TX
		wait_for_idle();
		apb_write(REG_SPILEN, RX_DATA_LEN);
		apb_write(REG_STATUS, READ_OP); //Start read from the SD-card

		//Waiting for RX
		wait_for_idle();

		if (csn_toggle){
			apb_write(REG_STATUS, 0); //CSn toggle
		}

		return read_response(cmd.r_frame);

	}

	uint64_t read_response(int FRAME){

		//Fix static lenghts

		//Change to operate using single bytes?

		//Add timeout?

		uint8_t buffer[12];
		int idx = 0;

		//Read 12 bytes from 3 fifo buffer
		for (int i = 0; i < 3; i++) {

			uint32_t rx = apb_read(REG_RXFIFO);

			buffer[idx++] = (rx >> 24) & 0xFF;
			buffer[idx++] = (rx >> 16) & 0xFF;
			buffer[idx++] = (rx >>  8) & 0xFF;
			buffer[idx++] =  rx        & 0xFF;
		}

		//Find first non-0xFF byte
		int start_idx = -1;
		for (int i = 0; i < 12; i++) {
			if (buffer[i] != 0xFF) {
				start_idx = i;
				break;
			}
		}


		if (start_idx < 0 || start_idx + 5 > 12) {
			printf("No valid 5-byte response found\n");
			return 0;
		}


		// Collect 5-byte response
		uint8_t response[5];
		for (int i = 0; i < 5; i++) {
			response[i] = buffer[start_idx + i];
		}


		/* DEBUG PRINTS
		printf("RESPONSE BYTES: [ ");
		for (int i = 0; i < 5; i++) {
			printf("%02X ", response[i]);
		}
		printf("]   --->   [ RESPONSE FRAME(%d) ]\n",FRAME);

		*/
		uint64_t resp = 0;
		//pack the response bytes according to the frame
		for (int i = 0; i < FRAME; i++){
			resp = (resp << 8) | response[i];
		}

		//printf("RESP = 0x%02llX\n", (unsigned long long)resp);
		//printf("_________________________________________________________________\n\n");


		return resp;
}


uint64_t read(SDCMD cmd, int ln, unsigned *data) {

	unsigned	lglen;
	uint64_t 	r,token;

	/*
	for(lglen = 4; (1<<lglen) < ln; lglen++)
		;
	set_aux(lglen << 16);

	*/

	r = sdcmd(CMD17,false); //disable CSn toggle
	assert (r == 0);

	//Poll for token 0xFE
	do{
		apb_write(REG_SPILEN, 0x00080000); //1 byte reads
		apb_write(REG_STATUS, READ_OP);

		//Waiting for RX
		wait_for_idle();
		token = apb_read(REG_RXFIFO);

	}while((token & 0xFF) != 0xFE);


	//printf("GOT THE TOKEN: 0x%02lX\n",token & 0xFF);

	//read the block
	for (int i = 0; i<128; i++){ //Fix static length

		apb_write(REG_SPILEN, 0x00200000); //32-bit reads
		apb_write(REG_STATUS, READ_OP);

		//Waiting for RX
		wait_for_idle();
		data[i] = apb_read(REG_RXFIFO);

	}

	apb_write(REG_STATUS, 0); //Toggle CSn


	return	1;


}

uint64_t write(SDCMD cmd, unsigned arg, int ln, unsigned *data) {

	unsigned	lglen;
	uint64_t	r;

	/*

	for(lglen = 4; (1<<lglen) < ln; lglen++)
		;
	apb_write(REG_SPILEN, lglen << 16);
	assert((1<<lglen) == ln);

	*/

	r = sdcmd(cmd,false);
	assert(r == 0);

	//send start token
	apb_write(REG_SPILEN, 0x00200000);
	apb_write(REG_TXFIFO, 0x000000FE);
	apb_write(REG_STATUS, WRITE_OP); //Start write to the SD-card

	//Wait for TX
	wait_for_idle();


	//Start block write
	for (int i = 0; i < 128; i++){ //fix static length!
		apb_write(REG_SPILEN, 0x00200000);
		apb_write(REG_TXFIFO,data[i]);
		apb_write(REG_STATUS, WRITE_OP); //Start write to the SD-card

		//wait for tx
		wait_for_idle();
	}

	//Create function for CRC calculation!
	apb_write(REG_TXFIFO,0x399AFFFF);
	apb_write(REG_STATUS, WRITE_OP); //Start write to the SD-card

	//wait for tx
	wait_for_idle();


	apb_write(REG_STATUS, 0); //Toggle CSn

	return	1;

}
	////////////////////////////////////////////////////////////////////////


	uint64_t read_ocr(void) {
		// {{{
		unsigned	r;
		r = sdcmd(CMD58);
		TBASSERT((*this),(r & 0) == 0);
		//fprintf(stderr, "R:   0x%08x\nOCR: 0x%08x\n", r, m_sdspi->OCR());
		TBASSERT((*this), (r == m_sdspi->OCR()));
		return r;
		// }}}
	}
/*
	unsigned read_csd(unsigned *data) {
		// {{{
		unsigned	r;
		r = read(SDSPI_CLEARERR|SDSPI_FIFO_OP|SDSPI_CMD+9, 0,
				16, data);

		for(int k=0; k<4; k++)
			printf("CSD[%d] = 0x%08x\n", k, data[k]);

		for(int k=0; k<4; k++) {
			unsigned v;
			v = 0;
#ifdef	OPT_LITTLE_ENDIAN
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CSD(k*4+3-i);
#else
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CSD(k*4+i);
#endif

			TBASSERT((*this), v == data[k]);
		}
		return r;
		// }}}
	}

	unsigned read_cid(unsigned *data) {
		// {{{
		unsigned	r;
		r = read(SDSPI_CLEARERR|SDSPI_FIFO_OP|SDSPI_CMD+10, 0,
				16, data);
		for(int k=0; k<4; k++) {
			unsigned v;
			v = 0;
#ifdef	OPT_LITTLE_ENDIAN
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CID(k*4+3-i);
#else
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CID(k*4+i);
#endif

			TBASSERT((*this), v == data[k]);
		} return r;
		// }}}
	}
	
*/
};

int	main(int argc, char **argv) {

	const char	SDIMAGE_FILENAME[] = "sdcard.img";
	const char	VCD_FILENAME[] = "trace.vcd";
	SDSPI_TB	tb(SDIMAGE_FILENAME);
	unsigned	resp;

	unsigned	boot_sector[128], test_sector[128], buf[128];

	tb.opentrace(VCD_FILENAME);
	tb.core()->HRESETn = 0;
	tb.tick();
	tb.core()->HRESETn = 1;
	tb.tick();


	//Initializes apb_spi_master
	tb.apb_write(REG_CLKDIV,CLK_DIV);

	//ADD START MOSI ACTION

	/*
	
	if (tb.apb_read(REG_STATUS)) {
		printf("Waiting for the card assertion to be registered\n");
		while(tb.apb_read(REG_STATUS)){;
		}
	}
	
	*/

	// GO_IDLE
	printf("_________________________________________________________________\n\n");
	printf("[SEND_GO_IDLE]\n\n");
	assert(0x01 == tb.sdcmd(CMD0));

	//SEND_IF_COND
	printf("_________________________________________________________________\n\n");
	printf("[SEND_IF_COND]\n\n");
	assert(0x01AA == tb.sdcmd(CMD8));

	// Wait for the card to start up
	printf("_________________________________________________________________\n\n");
	printf("[CARD_START_UP]\n\n");
	do {
		assert (0x00 == tb.sdcmd(CMD55));
		resp = tb.sdcmd(ACMD41);
		assert (resp == 0 || resp == 0x01);
	} while(resp == 0x01);


	// Read the OCR register
	printf("_________________________________________________________________\n\n");
	printf("[READ_OCR_REGISTER]\n\n");
	printf("[OCR: 0x%08X]\n", resp = tb.read_ocr());
	assert(resp == tb.OCR());

	// Speed up our interface
	//tb.set_aux(1);

    /* OPTIONAL
	// Read the CSD register
	printf("[READ_CSD_REGISTER]\n\n");
	tb.read_csd(test_sector);
	fprintf(stderr, "Read\n");
	printf("CSD: ");
	for(int k=0; k<4; k++)
		printf("%08x%c", test_sector[k], (k < 3) ? ':':'\n');


	/*
	// OPTIONAL
	// Read the CID register
	tb.read_cid(test_sector);
	printf("CID: ");
	for(int k=0; k<4; k++)
		printf("%08x%c", test_sector[k], (k < 3) ? ':':'\n');

	*/

	// Read the original boot sector
	printf("_________________________________________________________________\n\n");
	printf("[READ_THE_ORIGINAL_BOOT_SECTOR]\n\n");
	tb.read(CMD17, 512, boot_sector);


	// Write random data to the boot sector
	printf("_________________________________________________________________\n\n");
	printf("[WRITE_RANDOM_DATA_TO_BOOT_SECTOR]\n\n");
	for(unsigned k=0; k<128; k++)
		test_sector[k] = rand();
	tb.write(CMD24, 0, 512, test_sector);


	// Read the random data back
	printf("_________________________________________________________________\n\n");
	printf("[READ_RANDOM_DATA_BACK]\n\n");
	tb.read(CMD17, 512, buf);


	// Check that it was correctly written
	printf("_________________________________________________________________\n\n");
	printf("[CHECK_WRITTEN_DATA]\n\n");
	for(unsigned k=0; k<128; k++) {
	fprintf(stderr, "BUF[%3d] = 0x%08x, TST[%3d] = 0x%08x\n", k, buf[k], k, test_sector[k]);
	}
	for(unsigned k=0; k<128; k++) {
	fprintf(stderr, "BUF[%d] = 0x%08x\n", k, buf[k]);
	fprintf(stderr, "TST[%d] = 0x%08x\n", k, test_sector[k]);
		assert(buf[k] == test_sector[k]);
	}

	// Restore the boot sector
	printf("_________________________________________________________________\n\n");
	printf("[RESTORE_BOOT_SECTOR]\n\n");
	tb.write(CMD24, 0, 512, boot_sector);

	// Read it back again
	printf("_________________________________________________________________\n\n");
	printf("[READ_DATA]\n\n");
	tb.read(CMD17, 512, buf);

	// Check that it was properly stored
	printf("_________________________________________________________________\n\n");
	printf("[CHECK_DATA_STORAGE]\n");
	for(unsigned k=0; k<128; k++)
		assert(buf[k] == boot_sector[k]);

	printf("_________________________________________________________________\n\n");
	printf("SUCCESS!\n");

};
