
This utility downloads code to Philip LPC 2000 series chips, using the
bootloader communication protocol documented in the LPC2106/2105/2104 User
Manual, Sept 2003 revision, pages 177 to 192.  This code has also been tested
with LPC2131 and LPC2138 chips (thanks to New Micros for providing eval boards).
It may work with other Philips ARM LPC parts.


Usage:
-----

This program has these settings:

Usage: ./lpcflash [options] hexfile

 --port | -p    Serial port (default /dev/ttyS0)
 --baud | -b    Baud rate (default 38400)
 --xtal | -x    Crystal frequency in kHz (default 10000)

Once you start the program, it writes your firmware to the LPC flash memory, and
automatically runs it.


Hardware Requirements:
---------------------

You must have a compatible Philips LPC chip with its UART0 interfaced to a
serial port on your PC.

You must be able to reset the chip and cause it to enter bootloader mode.
Normally, this is done by connecting the (TTL level translated) DTR signal to
the LPC reset, so that when DTR is high (the TTL version is low), the Philips
chip is in reset mode.  Alternately, a pushbutton may be used, but you will need
to manually press the button every time you want to get back into bootloader
mode (while this program attempts to sync baud rates), rather than letting DTR
do it automatically.  A few minutes spent wiring up your circuit so DTR can
reset the board will save you much trouble as you develop code.

P0.14 must be connected low shortly after reset. Normally, this pin is just
shorted to ground using a jumper. You may also build a simple circuit that
forces this pin to ground when RTS is high.


Software Requirements:
---------------------

You must have a Linux-based system.  This code has been tested with Linux kernel
2.4.20 and 2.6.8, and should work with almost any linux system.

Your serial port device file (usually /dev/ttyS0 or /dev/ttyS1) must allow
permission for you to use the serial port.


Building and Installation:
-------------------------

If you compile from the source code, the result should be a small binary that is
optimal for your system.

Simply type "make" to build the code.  The resulting "lpcflash" program can be
run from any location.  Simply copy to /usr/local/bin, or where ever you like.


Contact Info:
------------

Please do not bother the original author Paul Stoffregen concerning problems
with this tool, but you can check his LPC2K_PGM for newer versions. If you have
questions or patches you can send them to me, Thomas Giesel
<skoe@directbox.com>.
