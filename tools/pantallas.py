#!/usr/bin/env python3
"""Las pantallas de Pachinko U.F.O.

  - el titulo: EJECUTANDO la ROM (tools/bios.py: el Z80 con la BIOS que usa) desde INIT (0x81B3) hasta la
    espera del boton (0x8162). INIT copia la fuente de la BIOS (la de la direccion 0x0004) a los tres tercios y
    encima pone sus propias cifras y letras; lo que queda de la BIOS (el espacio, el guion) sale aqui de la VRAM
    que grabo openMSX con C-BIOS. INITIO, SETGRP y ERAFNK no tocan nada que se vea y aqui no hacen nada;
  - logotipo.png, la cabecera de la web: CASIO y PACHINKO-U.F.O. del titulo;
  - las tres maquinas, de los cuadros que grabo openMSX (work/larga.bin): el tragaperras y las bolas son al azar.

El titulo se coteja con la VRAM grabada (work/atraccion.bin, cuadro 600): la imagen sin sprites punto a punto,
la tabla de nombres y los registros (el registro 7 solo cambia en el color del texto, que en SCREEN 2 no
se usa: C-BIOS deja el 15).

Uso: pantallas.py <dir> [cotejo]
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from bios import Msx        # noqa: E402

RAIZ = os.path.dirname(AQUI)
COTEJO = ("atraccion", 600)
MAQUINAS = {"maquina0.png": ("larga", 2000), "maquina1.png": ("larga", 12000), "maquina2.png": ("larga", 17300)}


def cuadro(grab, n):
    for i, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", grab + ".bin"))):
        if i == n:
            return c


class Pachinko(Msx):
    def _bios(self):
        if self.pc in (0x003B, 0x007E, 0x00CC):          # INITIO, SETGRP, ERAFNK
            self.pc = self._pop()
            return
        super()._bios()


def titulo():
    rom = open(os.path.join(RAIZ, "pachinkoufo.rom"), "rb").read()
    m = Pachinko(rom, 0x8000)
    fuente = bytes(cuadro(*COTEJO)["vram"][0:0x800])
    m.mem[0x1000:0x1800] = fuente                       # la fuente de C-BIOS, donde la "BIOS" la tiene
    m.mem[0x0004], m.mem[0x0005] = 0x00, 0x10
    m.hasta(0x81B3, 0x8162)
    return bytes(m.vdp.vram), bytes(m.vdp.regs)


def cotejo(v, regs):
    suya = cuadro(*COTEJO)
    nombres = [a - 0x1800 for a in range(0x1800, 0x1B00) if v[a] != suya["vram"][a]]
    t1, t2 = vdp.tela(v, regs, False), vdp.tela(suya["vram"], suya["regs"], False)
    puntos = [(x, y) for y in range(192) for x in range(256) if t1[y][x] != t2[y][x]]
    print("titulo contra %s/%d: puntos distintos %d de 49152; nombres distintos %d; registros %s"
          % (COTEJO[0], COTEJO[1], len(puntos), len(nombres),
             "iguales" if regs == bytes(suya["regs"]) else "%s / %s" % (regs.hex(), bytes(suya["regs"]).hex())))
    return len(puntos), len(nombres)


def main(argv):
    v, regs = titulo()
    vdp.imagen(v, regs, 2, con_sprites=False).save(os.path.join(argv[0], "titulo.png"))
    vdp.imagen(v, regs, 4, con_sprites=False).crop((80, 120, 944, 328)).save(os.path.join(argv[0], "logotipo.png"))
    for f, (g, n) in MAQUINAS.items():
        c = cuadro(g, n)
        vdp.imagen(c["vram"], c["regs"], 2).save(os.path.join(argv[0], f))
    if len(argv) > 1:
        cotejo(v, regs)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
