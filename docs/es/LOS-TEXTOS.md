# Los textos

Todos los textos de la ROM, en inglés. Se escriben con `texto_vram` (0x8090): detrás del `call`
van la dirección de la pantalla y las letras, hasta un 0. Las cifras y las mayúsculas son
casillas propias del juego (0xA881); el espacio y el guion salen de la fuente de la BIOS.

| Dónde | Texto | Qué dice |
|---|---|---|
| el título (0x80C0, 0x80E4) | CASIO, PACHINKO-U.F.O. | en letras grandes propias, de dos filas |
| el título (0x8125) | PUSH TRIGGER 1 TO START GAME | pulsa el botón 1 para empezar |
| el título (0x8147) | COPYRIGHT 1984 @ CASIO | la @ se dibuja como © |
| el marcador (0x8404) | HIGH-SCORE | el récord |
| el marcador (0x841A) | SCORE | los puntos |
| el marcador (0x8425) | CLEAR | las bolas a las que hay que llegar |
| el marcador (0x8438) | LEVEL | las vueltas a las tres máquinas |
| el centro (0x84FD) | PATTERN CLEAR | máquina superada |
| el centro (0x8537) | LEVEL CLEAR | las tres máquinas superadas |
| el centro (0x8553) | GAME OVER | sin bolas: fin de la partida |
| el centro (0x8498) | YOU WIN THE GAME! | has ganado: el récord ha llegado a 100.000 |

Debajo de CLEAR, la taza de las bolas que quedan son dos casillas (0x78, 0x79).
