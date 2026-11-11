# La música

Cuatro músicas, en los tres canales del PSG. No están grabadas a mano: `tools/musica.py`
**ejecuta el propio motor de sonido de la ROM** con `tools/z80run.py` -`pieza` (0xB9CF) con cada
pieza en su canal y, en cada cuadro, `sonido_cuadro` (0xBA30)- y apunta lo que escribe en el PSG
a través de la BIOS (WRTPSG y RDPSG).

**Cotejadas con openMSX**: los registros de tono y de volumen coinciden con los grabados, **0
distintos** en las cuatro, mientras suena cada pieza. Se grabaron en el título, que no suena,
llamando a las rutinas `sonido_calla` y `pieza` del propio juego (`tools/guiones/musicas.tcl`);
cada cuadro grabado se empareja con el cuadro del motor que tiene la misma RAM en los canales. En
LEVEL CLEAR el tercer canal solo toca ruido y deja su periodo de tono como lo dejó la música de
antes: el cotejo arranca el motor con el PSG como estaba.

Los sonidos del juego no están: los clavos, los agujeros, el centro que se abre, el giro del
tragaperras, el premio gordo, los OVNIs y el sonido sin fin de la máquina 2.

## El motor

Tres canales en 0xF102, 0xF122 y 0xF142, de 32 bytes, con piezas en grupos de **tres bytes**: una
nota (su número, la duración y lo que se espera a la siguiente) o una orden de la 0xF4 a la 0xFF
(la tabla 0xBBFE). Las notas salen de doce periodos de la octava más grave (0xBC26), a la mitad
por cada octava. El canal 0xF102 suena en el C del PSG, el 0xF122 en el B y el 0xF142 en el A.

| | Quién la pide | Dura |
|---|---|---:|
| la salida | la primera partida, antes de la primera bola (0x8332) | 9,6 s |
| PATTERN CLEAR | la máquina 0 o la 1 superadas (0x84E2) | 3,0 s |
| LEVEL CLEAR | la máquina 2 superada (0x851C) | 3,2 s |
| GAME OVER | sin bolas, o después de YOU WIN THE GAME! (0x84B1) | 5,1 s |

## La salida

<audio controls src="../audio/musica_salida.mp3"></audio>

## PATTERN CLEAR

<audio controls src="../audio/musica_pattern_clear.mp3"></audio>

## LEVEL CLEAR

<audio controls src="../audio/musica_level_clear.mp3"></audio>

## GAME OVER

<audio controls src="../audio/musica_game_over.mp3"></audio>
