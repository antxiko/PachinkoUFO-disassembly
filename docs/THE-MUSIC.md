# The music

Four tunes, on the three channels of the PSG. They are not recorded by hand: `tools/musica.py`
**runs the ROM's own sound engine** with `tools/z80run.py` -`pieza` (0xB9CF) with each piece on
its channel and, every frame, `sonido_cuadro` (0xBA30)- and logs what it writes to the PSG
through the BIOS (WRTPSG and RDPSG).

**Checked against openMSX**: the tone and volume registers match the recorded ones, **0
different** in all four, for as long as each piece plays. They were recorded on the title
screen, which is silent, calling the game's own `sonido_calla` and `pieza` routines
(`tools/guiones/musicas.tcl`); each recorded frame is paired with the engine frame that has the
same RAM in the channels. In LEVEL CLEAR the third channel only plays noise and leaves its tone
period as the previous tune left it: the comparison starts the engine with the PSG as it was.

The sounds of the game are not here: the pins, the pockets, the centre that opens, the spin of
the slot machine, the jackpot, the UFOs and the endless sound of machine 2.

## The engine

Three channels at 0xF102, 0xF122 and 0xF142, 32 bytes each, with pieces in **three-byte**
groups: a note (its number, the duration and how long to wait for the next one) or an order from
0xF4 to 0xFF (the table 0xBBFE). The notes come from twelve periods of the lowest octave
(0xBC26), halved for every octave. Channel 0xF102 plays on the PSG's C, 0xF122 on B and 0xF142
on A.

| | Who asks for it | Length |
|---|---|---:|
| the start | the first game, before the first ball (0x8332) | 9.6 s |
| PATTERN CLEAR | machine 0 or 1 passed (0x84E2) | 3.0 s |
| LEVEL CLEAR | machine 2 passed (0x851C) | 3.2 s |
| GAME OVER | no balls left, or after YOU WIN THE GAME! (0x84B1) | 5.1 s |

## The start

<audio controls src="audio/musica_salida.mp3"></audio>

## PATTERN CLEAR

<audio controls src="audio/musica_pattern_clear.mp3"></audio>

## LEVEL CLEAR

<audio controls src="audio/musica_level_clear.mp3"></audio>

## GAME OVER

<audio controls src="audio/musica_game_over.mp3"></audio>
