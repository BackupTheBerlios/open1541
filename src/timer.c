/*
 * (c) 2008 Thomas Giesel <skoe@directbox.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <lpc213x.h>
#include <timer.h>

/*******************************************************************************
 * Initialize the timers.
 *
 * Timer 0 runs at 1 MHz, overflow about every 71 minutes.
 *
 ******************************************************************************/
void timer_init()
{
    T0PR = PCLK / 1000000;
    T0TCR = TTCR_CTRENA;
}
