
.ifndef EMUDATA_S
EMUDATA_S = 1

#include <autoconf.h>

/*******************************************************************************
 * Define a macro to create offset constants
 * if MACH_DATA_DECLARE is defined
 *
 ******************************************************************************/
.ifdef MACH_DATA_DECLARE

offset_counter = 0
.macro data size symbol offset
    \offset = offset_counter
    offset_counter = offset_counter + \size
.endm

.endif

/*******************************************************************************
 * Reserve space in the BSS segment and define symbols
 * if MACH_DATA_DECLARE is undefined
 *
 ******************************************************************************/
.ifndef MACH_DATA_DECLARE

        .bss
        .align 2        @ 4 bytes align

        .global mach_data
mach_data:

.macro data size symbol offset
        .global \symbol
\symbol:
        .space \size, 0
.endm

.endif

/*******************************************************************************
 * The table for declaring and defining machine data values follows below.
 *
 * Each line has following format:
 *
 * data <size> <data_symbol> <offset_symbol>
 *
 * size             is the number of bytes to be reserved in BSS
 * data_symbol      is the global symbol (label) pointing to the data
 * offset_symbol    is an assembler symbol containing the offset in
 *                  mach_data
 *
 ******************************************************************************/

#include <mos6502_data.S>
#include <via_data.S>

.endif
