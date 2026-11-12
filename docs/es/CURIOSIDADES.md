# Curiosidades

## Una máquina dibujada a medias

La máquina es simétrica, y la ROM guarda **solo la mitad**. De las casillas, muchas están una vez
y se escriben dos, tal cual y con los bits al revés, en espejo (`casillas_espejo`, 0x9DDA). Los
clavos también: el mapa de bits en el que rebotan las bolas son 147 líneas de 18 bytes en la RAM,
y la ROM tiene 9 bytes por línea; los otros 9 son los mismos del último al primero, con los bits al
revés (`clavos_monta`, 0xAA7F).

## Un sonido entre las casillas

El giro del tragaperras es una pieza de sonido en 0x9FC7: en medio de las casillas del primer
tercio de la pantalla. Esos bytes van a la VRAM como dibujo y el motor los toca como música.

## Diez que son dieciséis

Un agujero paga 0x10 bolas (`agujero_mete_bola`, 0x90FE). El juego lleva las bolas dos veces: en
binario (0xEC7D), donde 0x10 son 16, y en decimal para la pantalla (0xED2E), donde ese mismo 0x10
se suma como si ya fuera decimal: 10. La pantalla enseña 10 bolas más; la cuenta en binario, la que
sirve para pintar las bolas de la bandeja, se lleva 16.

## Código que también es dibujo

Las casillas del tercer tercio se cargan de una vez desde 0xA347, y el bloque llega más allá: la
tabla de las casillas de la bandeja (0xA4E7), dos rutinas cortas (0xA507 y 0xA517) y los bytes de
detrás también van a la VRAM como dibujo de casillas.

## Código y bytes que nadie usa

- En 0x9DBC hay una rutina de doce bytes que escribe cada casilla dos veces;
  nadie la llama y no se ejecuta en las medidas de openMSX.
- El mapa de los clavos de las máquinas 0 y 1 tiene una línea más de las que se leen (9 bytes en
  0xB07A), y detrás del de la máquina 2 hay 7 bytes que nadie lee (0xB5AE).
- Los trozos del mapa (los postes, los tulipanes, la ventana del tragaperras, el centro abierto y
  cerrado) van uno tras otro, y en seis de ellos el último byte o los dos últimos son los primeros
  del siguiente.

## Otra interrupción

El juego no usa el gancho H.TIMI sino H.KEYI (0xFD9A), al que la BIOS llama antes. Lee él mismo el
estado del VDP, hace su cuadro y, al volver, **salta dos bytes más allá** en la rutina de la BIOS
que lo ha llamado, con A a cero. En la BIOS del MSX esos dos bytes son la instrucción que lee el
estado del VDP: con A a cero la BIOS lo toma como que no hay interrupción del VDP y se salta el
resto de su rutina, el gancho H.TIMI y el teclado (`interrupcion`, 0x8010).
