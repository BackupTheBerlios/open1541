/*
** hexdump.c - Program to dump the contents of a file to hexadecimal
**
** File created:  8/8/2000
** Last revision: 8/10/2000
**
** Copyright (C) 2000	Sean R. Wells <swells@gmu.edu>
**                    Modified by Thomas Giesel
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
**
*/

/*
 * modifications by Thomas Giesel skoe@directbox.com:
 * 090414 Removed unneeded command line switches
 *        Removed old version output, because it's not the same program anymore
 *        Changed format to ".byte 0x12, 0x23"   
 */  
#include <stdio.h>

#define OUT_WIDTH 8

typedef struct arg_info {
  FILE *infile;
} arg_info;


int ProcessArgs ( int argc, char **argv, arg_info *arguments )
{
  register FILE *input_file;
  int i;

  if ( argc < 2 ) {
    fprintf ( stderr, "hexdump special edition\n");
    fprintf ( stderr, "Usage: hexdump <filename>\n" );
    return ( -1 );
  }

  input_file = fopen ( argv[1], "rb" );

  if ( !input_file ) {
    fprintf ( stderr, "ERROR - could not open input file\n" );
    return ( -1 );
  }

  ( *arguments ).infile = input_file;

  return ( 0 );

}


int DumpFile ( arg_info arguments )
{
  int i, i2;
  int ch;
  long int file_size = 0;

  ch = getc ( arguments.infile );
  while ( ch != EOF ) {
    printf(".byte ");
    for ( i = 0; ( i < OUT_WIDTH ) && ( ch != EOF ); i++ ) {
      printf ("0x%02x", ( unsigned char ) ch );
      if (i < OUT_WIDTH - 1)
        printf (", ");
      ch = getc ( arguments.infile );
      file_size++;
    }
    printf ( "\n" );
  }

  fclose ( arguments.infile );

  return ( 0 );
}

int main ( argc, argv )
           int argc;
           char **argv;
{
  long int file_size = 0;
  arg_info arguments;

  if ( ProcessArgs ( argc, argv, &arguments ) == -1 ) return ( 0 );
  file_size = DumpFile ( arguments );

  return ( 0 );
}

