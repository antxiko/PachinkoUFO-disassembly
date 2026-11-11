# The texts

Every text in the ROM is in English. They are written with `texto_vram` (0x8090): the `call` is
followed by the screen address and the letters, up to a 0. The digits and the capital letters
are the game's own tiles (0xA881); the space and the dash come from the BIOS font.

| Where | Text | Meaning |
|---|---|---|
| the title (0x80C0, 0x80E4) | CASIO, PACHINKO-U.F.O. | in big letters of their own, two rows high |
| the title (0x8125) | PUSH TRIGGER 1 TO START GAME | press button 1 to start |
| the title (0x8147) | COPYRIGHT 1984 @ CASIO | the @ is drawn as © |
| the scoreboard (0x8404) | HIGH-SCORE | the record |
| the scoreboard (0x841A) | SCORE | the score |
| the scoreboard (0x8425) | CLEAR | the balls to reach |
| the scoreboard (0x8438) | LEVEL | the laps of the three machines |
| the centre (0x84FD) | PATTERN CLEAR | the machine is passed |
| the centre (0x8537) | LEVEL CLEAR | the three machines are passed |
| the centre (0x8553) | GAME OVER | no balls left |
| the centre (0x8498) | YOU WIN THE GAME! | the record has reached 100,000 |

Under CLEAR, the cup of the balls left is two tiles (0x78, 0x79).
