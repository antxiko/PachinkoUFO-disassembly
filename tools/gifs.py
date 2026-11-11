#!/usr/bin/env python3
"""Los GIF de la web: tramos de las grabaciones de openMSX (tools/guiones/*.tcl, grabados con
tools/lanza_graba.ps1 en C-BIOS_MSX1_JP, -ram "0xE000 0x1000"), pintados con tools/vdp.py.

Los tramos salen de la RAM grabada: 0xEC5A la maquina (0, 1, 2), 0xEC80/0xEC81 el premio y sus aperturas,
0xEC82 la V, 0xED2A/0xEFFF el final, 0xED2E las bolas.

  larga  una partida de 30000 cuadros (guion larga.tcl: la barra sostenida un tiempo distinto cada 40 cuadros
         y GRAPH cada 300): las tres maquinas, PATTERN CLEAR y LEVEL CLEAR

Uso: gifs.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402

# (fichero, grabacion, desde, hasta, cada)
TRAMOS = [
    ("lanzamiento.gif", "larga", 400, 760, 2),        # las primeras bolas, cada una con su fuerza
    ("apertura.gif", "larga", 1270, 1600, 2),         # una bola en la V (1366): el centro se abre y se cierra
    ("pattern_clear.gif", "larga", 10100, 10470, 2),  # las bolas pasan del objetivo: PATTERN CLEAR (10167)
    ("maquina1.gif", "larga", 12000, 12360, 2),       # la maquina 1, la del tragaperras
    ("ovnis.gif", "larga", 17212, 17930, 2),          # la maquina 2: los OVNIs, el grande tocado y LEVEL CLEAR
]


def main(salida):
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for fichero, grab, desde, hasta, cada in TRAMOS:
        n, s = vdp.gif(os.path.join(raiz, "work", grab + ".bin"),
                       os.path.join(salida, fichero), desde, hasta, cada=cada, tope_ms=4000)
        print("%-20s %4d imagenes, %5.1f s, %8d bytes" % (
            fichero, n, s, os.path.getsize(os.path.join(salida, fichero))))


if __name__ == "__main__":
    main(sys.argv[1])
