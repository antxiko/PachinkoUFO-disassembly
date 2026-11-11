# Under the hood

## Rebuilding the ROM

`make verify` assembles `src/pachinkoufo.asm` with pasmo and the 16 KB ROM comes out **byte for
byte**. `make sanity` checks what reassembling does not cover: that no byte declared as data is
read as code, that no entry point falls in data and that all 16,384 bytes are explained. `make
test` runs the tests. The ROM is not in the repository: it has to be placed in the root as
`pachinkoufo.rom` (the GoodMSX dump, `[!]`, sha1 `cad65376...`).

| | bytes |
|---|---|
| traced code | 5,591 |
| named data | 10,793 |
| unexplained | 0 |

The listing has 1,210 comments on 2,883 instructions (42.0%), 372 routines and labels, none
below 10% commented, and no called routine without a name.

## The cartridge

16 KB in **page 2** (0x8000-0xBFFF), with INIT at 0x81B3. Two thirds are data: the tiles of the
three machines and their colours (in runs of colour and length), the half bitmaps of the pins,
the screens of the machines, 30 sprites, its own letters and the music.

## The BIOS it uses

INITIO, SETGRP, CLRSPR, INIGRP, ERAFNK and CHGCLR at the start, and WRTVDP; it copies the BIOS
font through its address (0x0004) and puts its own digits and letters on top. Then FILVRM, LDIRVM,
WRTVRM and RDVDP, GTTRIG and SNSMAT for the buttons, DCOMPR, and WRTPSG and RDPSG for the sound.

## The texts behind the calls

Twenty `call`s carry their data behind them: `texto_vram` (0x8090) takes a screen address and
letters up to a 0, and `copia_ram` (0x80A3) a RAM address and bytes up to 0x1F; both return after
the data. The tracer would read those bytes as instructions: `comun/casio/en_linea.py` finds the
calls, declares the data in `src/pachinkoufo.nocode` and the return in
`src/pachinkoufo.entries`.

## The game loop

INIT goes to the title, and the main loop only waits: the interrupt does the game while 0xF000
is zero, and when something ends the machine it leaves a number in 0xEFFF (1 CLEAR, 2 GAME OVER,
3 YOU WIN THE GAME!) that the main loop reads (`partida_juega`, 0x847E). Each frame: the launcher,
the centre, the slot machine, the eight balls, the pinwheels or the UFOs, the sprites, the lights
and the tulips (`juego`, 0x86F2).

## How it was done

The trace follows the code from INIT, the interrupt, the two jump tables of the pockets (0x9002)
and the calls with data. The rest has been **measured in openMSX** (`tools/omsx_cobertura.tcl`:
a condition on every instruction logs every new ROM address), playing and waiting for the
demonstration on a Philips VG 8020.

## The RAM

| | |
|---|---|
| 0xE000-0xEBCF | the bitmap of the pins: 147 lines of 18 bytes |
| 0xEBD0 | the sprite table, sent to 0x1B00 every frame |
| 0xEC50 / 0xEC55 | the record and the score (BCD) |
| 0xEC59-0xEC5E | the rounds, the machine, LEVEL, the lap, the objective, the demonstration |
| 0xEC64 | the four pinwheels (6 bytes) |
| 0xEC7B / 0xEC7D | the strength of the shot, the balls in binary |
| 0xEC80-0xEC88 | the prize, its openings, the V and the slot machine |
| 0xEC89 | the tulips and the pockets (4 bytes) |
| 0xECC5 | the six UFOs of machine 2 (5 bytes) |
| 0xECE4 | the eight balls (8 bytes: state, Y, X, drawing, speeds) |
| 0xED25 / 0xED26 | the two buttons |
| 0xED2C / 0xED2E | the objective and the balls (BCD) |
| 0xEFFF | how the machine ends |
| 0xF000 | the interrupt: busy |
| 0xF100-0xF15F | the sound engine |
