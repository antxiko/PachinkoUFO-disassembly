# Secretos y fallos

Lo que se ha buscado en el código y lo que se ha encontrado. Un fallo solo entra aquí si está comprobado:
ejecutando la propia rutina del juego (`tools/bios.py`) o contra las grabaciones de openMSX.

## Secretos

- **Ninguna tecla escondida.** El juego lee dos botones y nada más: el botón 1 (el A de los mandos 1 o 2, o la barra
  espaciadora; `boton1`, 0x8078) y el botón 2 (el B de los mandos, o GRAPH leída con SNSMAT en la fila 6; `boton2`,
  0x8058). Ni la palanca ni ninguna otra tecla.
- **La bola que salva la partida.** Cuando las bolas llegan a cero, el GAME OVER no llega enseguida: espera a que no
  quede ninguna bola rodando (como mucho 192 cuadros, `juego_final`, 0x87B0). Si en ese rato una de ellas entra en un
  agujero o en el centro y paga 10 bolas, **la partida sigue** (`juego_diez`, 0x8760). En la máquina 2 no pasa: con el
  GAME OVER pendiente, sus agujeros no pagan (`puntos`, 0x85DB).
- **Con 9.000 bolas, GAME OVER.** Si las bolas llegan a 9.000 se ponen a cero (`juego_9000`, 0x876F), y sin bolas la
  partida se acaba. Solo se llega en la máquina 2, que no tiene objetivo: en la 0 y la 1 el CLEAR llega mucho antes.

Ejecutando aquí el final de `juego` (0x8760) con 8.999 bolas en la máquina 2 no pasa nada; con 9.000, las bolas se
ponen a 0 y queda pendiente el GAME OVER.

## Fallo: la bola que salva tiene que dar 10 justas

El juego no mira si quedan bolas, sino si hay **exactamente 10**. Lee el marcador con `ld hl,(0xED2E)` y lo compara
con 0x1000: como el marcador está en BCD con el byte alto primero, 0x1000 son las cifras 00 10. Si en el mismo cuadro
entran dos bolas (20), el GAME OVER sigue adelante con 20 bolas en el marcador:

| bolas | final pendiente | después |
|---|---|---|
| 0 → 10 | GAME OVER | la partida sigue |
| 0 → 20 | GAME OVER | **GAME OVER** con 20 bolas |

## Fallo: después de salvarse, el final llega antes

La cuenta de la espera (0xED32) sube en cada cuadro con un final pendiente y solo vuelve a cero al empezar la máquina
siguiente: la bola que salva la partida no la pone a cero. Ejecutándolo aquí cuadro a cuadro, con una bola rodando todo
el rato:

| | el final llega a los |
|---|---|
| sin bolas, la primera vez | 192 cuadros |
| sin bolas otra vez, tras salvarse a los 100 cuadros | **92** cuadros |

Lo mismo le pasa al CLEAR que llegue después: espera menos a las bolas que aún ruedan.

## Comprobado: la bandeja va con la otra cuenta

Como se cuenta en [Curiosidades](CURIOSIDADES.html), un agujero suma 10 bolas al marcador y 16 a la cuenta en binario
(0xEC7D). La bandeja de abajo se dibuja con la binaria (`bandeja_pinta`, 0x87D5: una casilla cada 16 y una capa cada
256), así que va siempre más llena de lo que dice el marcador. En la partida grabada en openMSX, con **457** bolas en
el marcador, la cuenta binaria lleva **769** (0x0301) y la bandeja ya pinta la tercera capa.
