/*
 * cli.c - Command line interface
 *
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

#include <string.h>
#include <uart.h>
#include <util.h>
#include <mos6502.h>

int cli_buffer_char(void);
static int cli_key_from_input_buffer(void);
static void cli_reset_input_buffer(void);
static void cli_reset_buffers(void);
static void cli_show_line(void);
static void cli_process_line(void);
static void cli_help(void);

// These constants are used to mark special commands
#define VK_UP        0x100
#define VK_DOWN      0x101
#define VK_RIGHT     0x102
#define VK_LEFT      0x103
#define VK_HOME      0x104
#define VK_END       0x105
#define VK_INSERT    0x106
#define VK_DEL       0x107
#define VK_PAGEUP    0x108
#define VK_PAGEDOWN  0x109
#define VK_F1        0x10A

// VT100 Terminal Control Escape Sequence
#define VT_CLR_TO_EOL   "\x1b[K"

// This is the maximum length of a command line, incl. '\0'
#define MAX_COMMAND_LINE_SIZE 81

// This is the number of chars in input buffer, incl. `\0'
#define MAX_INPUT_BUFFER_SIZE 5

static char last_command_line[MAX_COMMAND_LINE_SIZE];
static char command_line[MAX_COMMAND_LINE_SIZE];
static char input_buffer[MAX_INPUT_BUFFER_SIZE];
static uint8_t cursor_pos;

/*******************************************************************************
 * Initialize the CLI.
 *
 ******************************************************************************/
void cli_init(void)
{
    uart_puts("= open1541 CLI =\r\n");
    cli_show_line();
}


/*******************************************************************************
 * Check if something is to do on the command line.
 * This must be called regulary from the main loop.
 *
 ******************************************************************************/
void cli_check(void)
{
    int c, len;

    c = cli_buffer_char();
    if (!c)
        return;

    c = cli_key_from_input_buffer();
    if (c)
    {
        len = strlen(command_line);
        if ((c == '\n') || (c == '\r'))
        {
            cli_process_line();
            cli_reset_buffers();
        }
        else if (c == 0x7f || c == 0x08)   // backspace
        {
            if (cursor_pos > 0)
            {
                // to remove char left of cursor: move left rest of line
                memmove(command_line + cursor_pos - 1,
                        command_line + cursor_pos,
                        len - cursor_pos + 1);
                cursor_pos--;
            }
        }
        else if (c == VK_LEFT)
        {
            if (cursor_pos > 0)
                cursor_pos--;
        }
        else if (c == VK_RIGHT)
        {
            if (cursor_pos < len)
                cursor_pos++;
        }
        else if (c == VK_HOME)
        {
            cursor_pos = 0;
        }
        else if (c == VK_END)
        {
            cursor_pos = len;
        }
        else if (c == VK_DEL)
        {
            if (cursor_pos < len)
            {
                // to remove char right of cursor: move left rest of line
                memmove(command_line + cursor_pos,
                        command_line + cursor_pos + 1,
                        len - cursor_pos);
            }
        }
        else if (c == VK_F1)
        {
            strcpy(command_line, last_command_line);
            cli_show_line();
            cli_process_line();
            cli_reset_buffers();
        }
        else if ((c >= ' ') &&
                 (len < MAX_COMMAND_LINE_SIZE - 1))
        {
            // move right everything behind cursor
            memmove(command_line + cursor_pos + 1,
                    command_line + cursor_pos,
                    len - cursor_pos + 1);
            command_line[cursor_pos++] = (char) c;
        }

        cli_show_line();
    }
}


/*******************************************************************************
 * Try to get a character from UART and put it into the input buffer.
 * Return the character, 0 if nothing was received.
 *
 ******************************************************************************/
int cli_buffer_char(void)
{
    int len;
    int c = uart_getc();
    if (c > 0)
    {
        len = strlen(input_buffer);
        // discard input buffer if full (unknown esc secuence?)
        if (len >= MAX_INPUT_BUFFER_SIZE - 1)
        {
            cli_reset_input_buffer();
        }
        input_buffer[len]     = c;
        input_buffer[len + 1] = '\0';
        return c;
    }

    return 0;
}


/*******************************************************************************
 * Get a character from the input buffer. If there is no (valid) character
 * available, return 0. Special control characters and VT100 escape sequeces 
 * are mapped to > 255, see VK_... macros.
 *
 * If the buffer contains an unknown escape sequence,0 is returned and the 
 * collected input bytes are discarded.
 *
 ******************************************************************************/
static int cli_key_from_input_buffer(void)
{
    typedef struct esc_s { const char* seq; int vkey; } esc_t;
    esc_t esccmds[] = {
        {"A",   VK_UP},       // cursor key Up
        {"B",   VK_DOWN},     // cursor key Down
        {"C",   VK_RIGHT},    // Cursor Key Right
        {"D",   VK_LEFT},     // cursor key Left
        {"OA",  VK_UP},       // cursor key Up
        {"OB",  VK_DOWN},     // cursor key Down
        {"OC",  VK_RIGHT},    // Cursor Key Right
        {"OD",  VK_LEFT},     // cursor key Left
        {"OH",  VK_HOME},     // Cursor Key Home
        {"OF",  VK_END},      // Cursor Key End
        {"OP",  VK_F1},       // F1 Key
        {"[A",  VK_UP},       // cursor key Up
        {"[B",  VK_DOWN},     // cursor key Down
        {"[C",  VK_RIGHT},    // Cursor Key Right
        {"[D",  VK_LEFT},     // cursor key Left
        {"[H",  VK_HOME},     // Cursor Key Home
        {"[F",  VK_END},      // Cursor Key End
        {"[1~", VK_HOME},     // Cursor Key Home
        {"[2~", VK_INSERT},   // Cursor Key Insert
        {"[3~", VK_DEL},      // Cursor Key Delete
        {"[4~", VK_END},      // Cursor Key End
        {"[5~", VK_PAGEUP},   // Cursor Key Page Up
        {"[6~", VK_PAGEDOWN}, // Cursor Key Page Down
        {NULL, 0}
    };
    int len, i, c_first;
    int ret = 0;

    len = strlen(input_buffer);
    if (len)
    {
        c_first = input_buffer[0];

        if (c_first == 0x1b) // Esc
        {
            // Esc sequence?
            for (i = 0; esccmds[i].seq != NULL; i++)
            {
                // known sequence?
                if (!strncmp(input_buffer + 1, esccmds[i].seq, 
                             strlen(esccmds[i].seq)))
                {
                    ret = esccmds[i].vkey;
                }
            }
            // could be an incomplete sequence, keep it
            // but not if it is an unknown sequence
            if (len >= MAX_INPUT_BUFFER_SIZE -1)
            {
                cli_reset_input_buffer();
            }
        }
        else if ((c_first == 8) || (c_first == 0x7f)) // Backspace
        {
            ret = 0x7f;
        }
        else
        {
            ret = c_first;
        }
    }

    if (ret)
    {
        cli_reset_input_buffer();
    }

    return ret;
}

/*******************************************************************************
 * Delete the input buffer.
 *
 ******************************************************************************/
static void cli_reset_input_buffer(void)
{
    input_buffer[0]     = '\0';
}

/*******************************************************************************
 * Delete the input buffer and the command line.
 *
 ******************************************************************************/
static void cli_reset_buffers(void)
{
    command_line[0]     = '\0';
    cursor_pos          = 0;
    cli_reset_input_buffer();
}

/*******************************************************************************
 * Show the prompt and the current line,
 * Removes the rest of the line and moves the cursor to cursor_x.
 *
 ******************************************************************************/
static void cli_show_line(void)
{
    int n;
    uart_puts("\r> ");
    uart_puts(command_line);

    // erase to eol
    uart_puts(VT_CLR_TO_EOL);

    // move cursor left to its current position
    n = strlen(command_line) - cursor_pos;
    if (n)
    {
        uart_puts("\x1b[");
        uart_putdec(n);
        uart_puts("D");
    }
}

/*******************************************************************************
 * Execute the command line entered.
 *
 ******************************************************************************/
static void cli_process_line(void)
{
    uint16_t pc;

    uart_putcrlf();
    if (!command_line[0])
        return;

    strcpy(last_command_line, command_line);

    if (strcmp(command_line, "stop") == 0)
    {
        mos6502_stop();
    }
    else if ((strcmp(command_line, "step") == 0) ||
        (strcmp(command_line, "z") == 0))
    {
        mos6502_step();
        mos6502_dump_regs();
        pc = mos6502_get_pc();
        mos6502_dis(pc, pc);
    }
    else if ((strcmp(command_line, "regs") == 0) ||
             (strcmp(command_line, "r") == 0))
    {
        mos6502_dump_regs();
    }
    else if (strcmp(command_line, "cont") == 0)
    {
        mos6502_continue();
    }
    else if (strcmp(command_line, "speed") == 0)
    {
        uart_putdec(util_benchmark());
        uart_putcrlf();
    }
    else if (strcmp(command_line, "help") == 0)
    {
        cli_help();
    }
    else
    {
        uart_puts("?SYNTAX  ERROR\r\n");
    }
}

/*******************************************************************************
 * Print the help text.
 *
 ******************************************************************************/
static void cli_help(void)
{
    uart_puts("stop\tStop 6502 emulation\r\n"
              "step|z\tExecute single instruction\r\n"
              "regs|r\tShow 6502 registers\r\n"
              "cont\tContinue 6502 emulation\r\n"
              "speed\tStart a benchmark\r\n"
              "help\tHelp\r\n"
              "<F1>\tRepeat last command\r\n");
}
