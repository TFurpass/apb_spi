////////////////////////////////////////////////////////////////////////////////
//
// Filename:	bench/cpp/apb_tb.h MODIFIED VERSION
// {{{
// Project:	SD-Card controller
//
// Purpose:	
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
#include <stdio.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "testb.h"

const int	BOMBCOUNT = 32,
		LGMEMSIZE = 15;

template <class VA>	class	apb_TB : public TESTB<VA> {
public:
	bool	m_bomb;

	apb_TB(void) {
		m_bomb = false;

		//
		// Release the bus
		//
		TESTB<VA>::m_core->PSEL    = 0;
		TESTB<VA>::m_core->PENABLE = 0;
	}

#define	TICK	this->tick
	/*
	virtual	void	tick(void) {
		printf("apb-TICK\n");
		TESTB<VA>::tick();
	}
	*/

	unsigned apb_read(unsigned a){
		//Read-operation from given address

		int errcount = 0;
		unsigned result;

		printf("APB-READ(%08x)\n", a);

		// Setup phase
		TESTB<VA>::m_core->PADDR   = a;
		TESTB<VA>::m_core->PWRITE  = 0;
		TESTB<VA>::m_core->PSEL    = 1;
		TESTB<VA>::m_core->PENABLE = 0;
		
		TICK();
		// Access phase
		TESTB<VA>::m_core->PENABLE = 1;

		while ((errcount++ < BOMBCOUNT) && (!TESTB<VA>::m_core->PREADY))
		{
			TICK();
		}

		if (errcount >= BOMBCOUNT) {
			printf("APB-READ BOMB: NO RESPONSE AFTER %d CLOCKS\n", errcount);
			m_bomb = true;
		}

		result = TESTB<VA>::m_core->PRDATA;
		TICK();
		//
		// Release the bus
		//
		TESTB<VA>::m_core->PSEL    = 0;
		TESTB<VA>::m_core->PENABLE = 0;

		TICK();

		//assert(!TESTB<VA>::m_core->PSEL);
		//assert(!TESTB<VA>::m_core->PENABLE);

		return result;
}
	
	// }}}

	void apb_read(unsigned a, int len, unsigned *buf, const int inc=1)
	{
		int errcount = 0;
		int THISBOMBCOUNT = BOMBCOUNT * len;
		int rdidx = 0;

		printf("APB-READM(%08x, %d)\n", a, len);

		//
		// Ensure bus is idle
		//
		TESTB<VA>::m_core->PSEL    = 0;
		TESTB<VA>::m_core->PENABLE = 0;

		TICK();

		while ((rdidx < len) && (errcount++ < THISBOMBCOUNT))
		{
			//
			// Setup phase
			//
			TESTB<VA>::m_core->PADDR   = a;
			TESTB<VA>::m_core->PWRITE  = 0;
			TESTB<VA>::m_core->PSEL    = 1;
			TESTB<VA>::m_core->PENABLE = 0;

			TICK();

			//
			// Access phase
			//
			TESTB<VA>::m_core->PENABLE = 1;

			int waitcount = 0;

			while ((waitcount++ < BOMBCOUNT)
					&& (!TESTB<VA>::m_core->PREADY))
			{
				TICK();
			}

			if (waitcount >= BOMBCOUNT)
			{
				printf("APB-READ BOMB: timeout waiting for PREADY\n");
				m_bomb = true;
				break;
			}

			//
			// Capture returned data
			//
			buf[rdidx++] = TESTB<VA>::m_core->PRDATA;

			//
			// Optional APB error check
			//
			if (TESTB<VA>::m_core->PSLVERR)
			{
				printf("APB-READ ERROR: PSLVERR asserted\n");
				m_bomb = true;
				break;
			}

			//
			// End transaction
			//
			TESTB<VA>::m_core->PSEL    = 0;
			TESTB<VA>::m_core->PENABLE = 0;

			TICK();

			//
			// Next address
			//
			a += inc;
		}

		if (rdidx != len)
		{
			printf("APB/PR-BOMB: expected %d words, got %d\n",
					len, rdidx);
			m_bomb = true;
		}

		//
		// Return bus to idle
		//
		TESTB<VA>::m_core->PSEL    = 0;
		TESTB<VA>::m_core->PENABLE = 0;

		TICK();
}
	// }}}

	void apb_write(unsigned a, unsigned v)
	{	

		int errcount = 0;

		printf("APB-WRITE(%08x) <= %08x\n", a, v);
		
		// Setup phase
		
		TESTB<VA>::m_core->PSEL    = 1;
		TESTB<VA>::m_core->PADDR   = a;
		TESTB<VA>::m_core->PWDATA  = v;
		TESTB<VA>::m_core->PWRITE  = 1;
		TESTB<VA>::m_core->PENABLE = 0;
		
		
		TICK();
		
		// Access phase		
		TESTB<VA>::m_core->PENABLE = 1;

		while ((errcount++ < BOMBCOUNT)
				&& (!TESTB<VA>::m_core->PREADY))
		{
			TICK();
		}

		if (errcount >= BOMBCOUNT)
		{
			printf("APB/SW-BOMB: NO RESPONSE AFTER %d CLOCKS\n",
					errcount);
			m_bomb = true;
		}

		if (TESTB<VA>::m_core->PSLVERR)
		{
			printf("APB/SW-BOMB: PSLVERR asserted\n");
			m_bomb = true;
		}

		TICK();

		//
		// Release the bus
		//
		TESTB<VA>::m_core->PSEL    = 0;
		TESTB<VA>::m_core->PENABLE = 0;

		TICK();
}
	// }}}

	void apb_write(unsigned a, unsigned int ln, unsigned *buf, const int inc = 1)
	{
		unsigned errcount = 0;

		printf("APB-WRITEM(%08x, %d, ...)\n", a, ln);

		for (unsigned i = 0; i < ln; i++)
		{
			//
			// Setup phase
			//
			TESTB<VA>::m_core->PADDR   = a;
			TESTB<VA>::m_core->PWDATA  = buf[i];
			TESTB<VA>::m_core->PWRITE  = 1;
			TESTB<VA>::m_core->PSEL    = 1;
			TESTB<VA>::m_core->PENABLE = 0;

			TICK();

			//
			// Access phase
			//
			TESTB<VA>::m_core->PENABLE = 1;

			errcount = 0;

			while ((errcount++ < BOMBCOUNT)
					&& (!TESTB<VA>::m_core->PREADY))
			{
				TICK();
			}

			if (errcount >= BOMBCOUNT)
			{
				printf("APB/PW-BOMB: NO RESPONSE AFTER %u CLOCKS\n",
						errcount);
				m_bomb = true;
				break;
			}

			if (TESTB<VA>::m_core->PSLVERR)
			{
				printf("APB/PW-BOMB: PSLVERR asserted\n");
				m_bomb = true;
				break;
			}

			//
			// Return to idle
			//
			TESTB<VA>::m_core->PSEL    = 0;
			TESTB<VA>::m_core->PENABLE = 0;

			TICK();

			//
			// Next address
			//
			a += inc;
		}

		TESTB<VA>::m_core->PWRITE  = 0;
		TESTB<VA>::m_core->PSEL    = 0;
		TESTB<VA>::m_core->PENABLE = 0;

		TICK();
	}
	// }}}

	bool	bombed(void) const { return m_bomb; }

	// bool	debug(void) const	{ return m_debug; }
	// bool	debug(bool nxtv)	{ return m_debug = nxtv; }
};

