# Por dentro

## Rehacer la ROM

`make verify` ensambla `src/pachinkoufo.asm` con pasmo y sale la ROM de 16 KB **byte a byte**.
`make sanity` comprueba lo que el reensamblado no cubre: que ningún byte declarado como dato se lea
como código, que ninguna entrada caiga en datos y que estén explicados los 16.384 bytes. `make test`
pasa los tests. La ROM no está en el repositorio: hay que ponerla en la raíz como `pachinkoufo.rom`
(el volcado de GoodMSX, `[!]`, sha1 `cad65376...`).

| | bytes |
|---|---|
| código trazado | 5.591 |
| datos con nombre | 10.793 |
| sin explicar | 0 |

El listado tiene 1.210 comentarios en 2.883 instrucciones (42,0 %), 372 rutinas y etiquetas,
ninguna por debajo del 10 % comentado, y ninguna rutina llamada sin nombre.

## El cartucho

16 KB en la **página 2** (0x8000-0xBFFF), con INIT en 0x81B3. Dos tercios son datos: las casillas
de las tres máquinas y sus colores (en tramos de color y largo), los medios mapas de los clavos,
las pantallas de las máquinas, 30 sprites, sus letras y la música.

## La BIOS que usa

INITIO, SETGRP, CLRSPR, INIGRP, ERAFNK y CHGCLR al arrancar, y WRTVDP; copia la fuente de la BIOS
por su dirección (0x0004) y encima pone sus propias cifras y letras. Después FILVRM, LDIRVM, WRTVRM
y RDVDP, GTTRIG y SNSMAT para los botones, DCOMPR, y WRTPSG y RDPSG para el sonido.

## Los textos detrás de las llamadas

Veinte `call` llevan sus datos detrás: `texto_vram` (0x8090) toma una dirección de la pantalla y
letras hasta un 0, y `copia_ram` (0x80A3) una dirección de la RAM y bytes hasta 0x1F; las dos
vuelven detrás de los datos. El trazador leería esos bytes como instrucciones:
`comun/casio/en_linea.py` encuentra las llamadas, declara los datos en `src/pachinkoufo.nocode` y la
vuelta en `src/pachinkoufo.entries`.

## El bucle de la partida

INIT va al título, y el bucle principal solo espera: la interrupción hace el juego mientras 0xF000
está a cero, y cuando algo acaba la máquina deja un número en 0xEFFF (1 CLEAR, 2 GAME OVER, 3 YOU
WIN THE GAME!) que lee el bucle principal (`partida_juega`, 0x847E). En cada cuadro: el lanzador,
el centro, el tragaperras, las ocho bolas, los molinillos o los OVNIs, los sprites, las luces y los
tulipanes (`juego`, 0x86F2).

## Cómo se ha hecho

El trazado sigue el código desde INIT, la interrupción, las dos tablas de saltos de los agujeros
(0x9002) y las llamadas con datos. El resto se ha **medido en openMSX**
(`tools/omsx_cobertura.tcl`: una condición en cada instrucción apunta cada dirección nueva de la
ROM), jugando y esperando a la demostración en un Philips VG 8020.

## La RAM

| | |
|---|---|
| 0xE000-0xEBCF | el mapa de bits de los clavos: 147 líneas de 18 bytes |
| 0xEBD0 | la tabla de sprites, que va a 0x1B00 en cada cuadro |
| 0xEC50 / 0xEC55 | el récord y los puntos (BCD) |
| 0xEC59-0xEC5E | las rondas, la máquina, LEVEL, la vuelta, el objetivo, la demostración |
| 0xEC64 | los cuatro molinillos (6 bytes) |
| 0xEC7B / 0xEC7D | la fuerza del tiro, las bolas en binario |
| 0xEC80-0xEC88 | el premio, sus aperturas, la V y el tragaperras |
| 0xEC89 | los tulipanes y los agujeros (4 bytes) |
| 0xECC5 | los seis OVNIs de la máquina 2 (5 bytes) |
| 0xECE4 | las ocho bolas (8 bytes: estado, Y, X, dibujo, velocidades) |
| 0xED25 / 0xED26 | los dos botones |
| 0xED2C / 0xED2E | el objetivo y las bolas (BCD) |
| 0xEFFF | cómo acaba la máquina |
| 0xF000 | la interrupción: ocupada |
| 0xF100-0xF15F | el motor de sonido |
