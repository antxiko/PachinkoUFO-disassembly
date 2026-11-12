# Curiosities

## A machine drawn in half

The machine is symmetrical, and the ROM keeps **only half**. Of the tiles, many are stored once
and written twice, as they are and with their bits reversed, a mirror image (`casillas_espejo`,
0x9DDA). The pins too: the bitmap the balls bounce on is 147 lines of 18 bytes in RAM, and the
ROM has 9 bytes per line; the other 9 are the same ones from last to first, with their bits
reversed (`clavos_monta`, 0xAA7F).

## A sound among the tiles

The spin of the slot machine is a sound piece at 0x9FC7: in the middle of the tiles of the first
third of the screen. Those bytes are loaded into the VRAM as drawings and played by the engine as
a tune.

## Ten that are sixteen

A pocket pays 0x10 balls (`agujero_mete_bola`, 0x90FE). The game keeps the balls twice: in
binary (0xEC7D), where 0x10 is 16, and in decimal for the screen (0xED2E), where the same 0x10 is
added as if it were already decimal: 10. The screen shows 10 more balls; the binary count, the one
used to draw the balls in the tray, gets 16.

## Code that is also drawing

The tiles of the third third are loaded in one go from 0xA347, and the block reaches beyond
them: the table of the tray tiles (0xA4E7), two short routines (0xA507 and 0xA517) and
the bytes after them are copied into the VRAM as tile drawings too.

## Code and bytes nobody uses

- At 0x9DBC there is a twelve-byte routine that writes each tile twice; nobody calls it and it
  does not run in the openMSX measurements.
- The pin bitmap of machines 0 and 1 has one line more than is read (9 bytes at 0xB07A), and
  after that of machine 2 there are 7 bytes nobody reads (0xB5AE).
- The pieces of the bitmap (the posts, the tulips, the window of the slot machine, the centre
  open and closed) are stored one after the other, and in six of them the last one or two bytes
  are the first of the next.

## A different interrupt

The game does not use the H.TIMI hook but H.KEYI (0xFD9A), which the BIOS calls first. It reads
the VDP status itself, does its frame and, on the way back, **jumps two bytes further** in the
BIOS routine that called it, with A at zero. In the MSX BIOS those two bytes are the instruction
that reads the VDP status: with A at zero the BIOS takes it as no VDP interrupt and skips the rest
of its routine, the H.TIMI hook and the keyboard (`interrupcion`, 0x8010).
