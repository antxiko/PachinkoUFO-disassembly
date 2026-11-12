# Secrets and bugs

What was searched for in the code and what was found. A bug only goes here if it has been checked: by running the
game's own routine (`tools/bios.py`) or against the openMSX recordings.

## Secrets

- **No hidden keys.** The game reads two buttons and nothing else: button 1 (A on joystick 1 or 2, or the space bar;
  `boton1`, 0x8078) and button 2 (B on the joysticks, or GRAPH read with SNSMAT on row 6; `boton2`, 0x8058). Neither the
  stick nor any other key.
- **The ball that saves the game.** When the balls reach zero, GAME OVER does not come straight away: it waits until no
  ball is still rolling (192 frames at most, `juego_final`, 0x87B0). If in that time one of them drops into a pocket or
  into the centre and pays 10 balls, **the game goes on** (`juego_diez`, 0x8760). Not on machine 2: with GAME OVER
  pending, its pockets do not pay (`puntos`, 0x85DB).
- **At 9,000 balls, GAME OVER.** If the balls reach 9,000 they are set to zero (`juego_9000`, 0x876F), and with no balls
  the game ends. It can only happen on machine 2, which has no target: on 0 and 1 the CLEAR comes much earlier.

Running the end of `juego` (0x8760) here with 8,999 balls on machine 2 nothing happens; with 9,000, the balls are set to
0 and GAME OVER is left pending.

## Bug: the saving ball has to give exactly 10

The game does not check whether there are balls, but whether there are **exactly 10**. It reads the counter with
`ld hl,(0xED2E)` and compares it with 0x1000: as the counter is BCD with the high byte first, 0x1000 is the digits
00 10. If two balls drop in the same frame (20), GAME OVER goes ahead with 20 balls on the counter:

| balls | pending end | after |
|---|---|---|
| 0 → 10 | GAME OVER | the game goes on |
| 0 → 20 | GAME OVER | **GAME OVER** with 20 balls |

## Bug: after being saved, the end comes sooner

The wait count (0xED32) goes up every frame with an end pending and only goes back to zero when the next machine
starts: the ball that saves the game does not reset it. Running it here frame by frame, with one ball rolling all the
time:

| | the end comes after |
|---|---|
| no balls, the first time | 192 frames |
| no balls again, after being saved at 100 frames | **92** frames |

The same happens to a CLEAR that comes later: it waits less for the balls still rolling.

## Checked: the tray goes by the other count

As told in [Curiosities](CURIOSITIES.html), a pocket adds 10 balls to the counter and 16 to the binary count (0xEC7D).
The tray at the bottom is drawn from the binary one (`bandeja_pinta`, 0x87D5: one tile every 16 and one layer every
256), so it is always fuller than the counter says. In the game recorded in openMSX, with **457** balls on the counter,
the binary count holds **769** (0x0301) and the tray already draws the third layer.
