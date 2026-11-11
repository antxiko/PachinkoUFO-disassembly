#!/usr/bin/env python3
"""Los sprites de Pachinko U.F.O. MONTADOS DESDE LA ROM (ninguna imagen es una captura).

Los 30 dibujos de 16 x 16 (0x992F, 960 bytes) van tal cual a 0x3800 (`sprites_dibujos`, 0x8C07). Los sprites son de
16 x 16 (el registro 1 del VDP, 0xE2): el VDP no mira los dos bits de abajo del numero de dibujo, asi que la bola,
que cuenta de dos en dos (8, 10... 22), cambia de dibujo cada dos pasos, y el molinillo, que cuenta de 0 a 7, alterna
el 0 y el 4.

  sprites.png    el lanzador (0x24, negro), los dos dibujos del molinillo en sus colores (la RAM que pone 0x8389:
                 azul los de arriba, magenta los de abajo), los cuatro de la bola (blanca) y los OVNIs de la maquina 2
                 en sus cuatro pasos (`sprites_ovni`, 0x8C52): el pequeno (0x4C/0x58, tres sprites: dibujo + 4 negro,
                 el dibujo en magenta y dibujo + 8 en el color del paso), el mediano (0x34/0x40, en azul claro), el
                 grande (0x70/0x64 y su pareja, mas 0x6C) y estallando (0x28, 0x2C y 0x30)
  ovnis_cuadros.gif  los tres OVNIs cuadro a cuadro: el paso cada 8 cuadros (cada 4 el grande, que ademas sube y baja con
                 las 32 alturas de 0x8927) y el color del paso (+ 7; el 0 es el 6)

Uso: hojas.py docs/imagenes | hojas.py cotejo
"""
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
import vdp          # noqa: E402

ORG = 0x8000
ROM = open(os.path.join(RAIZ, "pachinkoufo.rom"), "rb").read()
FONDO = (40, 40, 48)


def b(a):
    return ROM[a - ORG]


def patrones():
    t = bytearray(0x800)
    t[0:0x3C0] = ROM[0x992F - ORG:0x992F - ORG + 0x3C0]
    return bytes(t)


def pinta(im, pat, n, x, y, color, escala=1):
    if color == 0:
        return
    n &= 0xFC                       # 16 x 16: los dos bits de abajo no cuentan
    d = pat[n * 8:n * 8 + 32]
    c = vdp.PALETA[color]
    for fila in range(16):
        for col in range(16):
            if (d[fila + (16 if col >= 8 else 0)] >> (7 - (col & 7))) & 1:
                for ey in range(escala):
                    for ex in range(escala):
                        px, py = (x + col) * escala + ex, (y + fila) * escala + ey
                        if 0 <= px < im.width and 0 <= py < im.height:
                            im.putpixel((px, py), c)


def color_paso(paso):
    """sprites_ovni_color (0x8CB3): el paso + 7, y el 0 es el 6."""
    c = (paso + 7) & 0xFF
    return 6 if c == 7 else c


def ovni(estado, forma, paso, y=0, x=0):
    """Los sprites (Y, X, dibujo, color) de un OVNI como los pone sprites_ovni (0x8C52)."""
    if estado == 3:                                  # estallando
        d = 0x28 + ((paso * 2) & 0x0F)
        return [(y, x, d if d < 0x34 else 0x28, color_paso(paso))]
    if forma >= 2:                                   # grande
        d = 0x64 if paso & 1 else 0x70
        return [(y, x, d, 5), (y, (x + 16) & 0xFF, d + 4, 5), (y, (x + 8) & 0xFF, 0x6C, color_paso(paso))]
    d, e = ((0x40 if paso & 1 else 0x34), 5) if forma == 1 else ((0x58 if paso & 1 else 0x4C), 13)
    return [(y, x, d + 4, 1), (y, x, d, e), (y, x, d + 8, color_paso(paso))]


def tabla_sprites(ram):
    """La copia de la tabla de sprites (0xEBD0) que monta `sprites` (0x8C14) con la RAM de un cuadro (ram[k] = 0xE000
    + k): el lanzador, los molinillos o los OVNIs y las bolas."""
    out = []
    a = 0x8193 + 2 * ram[0xC7B]
    out.append((b(a), b(a + 1), 0x24, 1))
    if ram[0xC5A] != 2:
        for k in range(4):
            out.append(tuple(ram[0xC65 + 6 * k:0xC69 + 6 * k]))
    else:
        for k in range(6):
            e = ram[0xCC5 + 5 * k:0xCCA + 5 * k]
            if e[0] == 0 or (e[0] >= 4):
                continue
            out += ovni(e[0], e[4], e[3], e[1], e[2])
    for k in range(8):
        e = ram[0xCE4 + 8 * k:0xCE4 + 8 * k + 4]
        if 0 < e[0] < 0x40:
            out.append(((e[1] + 4) & 0xFF, (e[2] + 0x24) & 0xFF, e[3], 15))
    return out


def hoja(Image):
    pat, E = patrones(), 3
    im = Image.new("RGB", (12 * 24 * E, 5 * 28 * E), FONDO)
    pinta(im, pat, 0x24, 4, 4, 1, E)
    for k, (d, c) in enumerate(((0, 4), (4, 4), (0, 13), (4, 13))):
        pinta(im, pat, d, 28 + 24 * k, 4, c, E)
    for k, d in enumerate((8, 12, 16, 20)):
        pinta(im, pat, d, 28 + 24 * (4 + k), 4, 15, E)
    for fila, forma in ((1, 0), (2, 1), (3, 2)):
        for paso in range(4):
            for y, x, d, c in ovni(1, forma, paso, fila * 28 + 4, 4 + 36 * paso):
                pinta(im, pat, d, x, y, c, E)
    for k, paso in enumerate((0, 2, 4)):
        for y, x, d, c in ovni(3, 0, paso, 4 * 28 + 4, 4 + 24 * k):
            pinta(im, pat, d, x, y, c, E)
    return im


def anima(Image):
    pat, E, cuadros = patrones(), 3, []
    alturas = [b(0x8927 + k) for k in range(32)]
    paso_p = paso_g = alt = 0
    for n in range(256):
        if n % 8 == 0 and n:
            paso_p = (paso_p + 1) & 3
        if n % 4 == 0 and n:
            paso_g = (paso_g + 1) & 3
        alt = (alt + 1) & 31
        im = Image.new("RGB", (3 * 40 * E, 44 * E), FONDO)
        for k, (forma, paso) in enumerate(((0, paso_p), (1, paso_p), (2, paso_g))):
            y = 14 + (alturas[alt] - 0x88 if forma == 2 else 0)
            for yy, xx, d, c in ovni(1, forma, paso, y, 4 + 40 * k):
                pinta(im, pat, d, xx, yy, c, E)
        cuadros.append(im)
    return cuadros


def guarda_gif(cuadros, ruta, ms=1000 / 60):
    imgs, durs = [], []
    for im in cuadros:
        if imgs and list(im.getdata()) == list(imgs[-1].getdata()):
            durs[-1] += ms
        else:
            imgs.append(im)
            durs.append(ms)
    imgs[0].save(ruta, save_all=True, append_images=imgs[1:], duration=[max(20, int(round(d))) for d in durs],
                 loop=0, disposal=1)


def cotejo():
    """Contra las grabaciones de openMSX (work/*.bin, la RAM desde 0xE000):
    1) la tabla de dibujos de los sprites (VRAM 0x3800-0x3BBF) contra los 960 bytes de 0x992F;
    2) la copia de la tabla de sprites (0xEBD0) entera, sprite a sprite, contra `tabla_sprites()` con la RAM del
       cuadro (el lanzador, los molinillos u OVNIs y las bolas). Se cuentan aparte los cuadros que casan con la RAM
       del cuadro anterior (el juego monta la copia y despues mueve)."""
    pat = patrones()
    tot = dict(patrones=0, pat_mal=0, tabla=0, maquina2=0, tabla_antes=0, sin_montar=0, ram_borrada=0, tabla_mal=0)
    for grab, ram_n in (("atraccion", 0x1000), ("partida", 0x1000), ("larga", 0x1000), ("musicas", 0x1200)):
        ruta = os.path.join(RAIZ, "work", grab + ".bin")
        if not os.path.exists(ruta):
            continue
        antes = None
        for c in vdp.cuadros(ruta, ram_n):
            v, ram = c["vram"], c["ram"]
            t = v[0x3800:0x3BC0]
            if any(t):
                tot["patrones"] += t == pat[:0x3C0]
                tot["pat_mal"] += t != pat[:0x3C0]
            if ram[0xBD0] >= 0xC0 or ram[0xC5A] not in (1, 2):
                antes = ram
                continue
            quiero = tabla_sprites(ram)
            hay = [tuple(ram[0xBD0 + 4 * k:0xBD4 + 4 * k]) for k in range(len(quiero))]
            tot["tabla"] += 1
            tot["maquina2"] += ram[0xC5A] == 2
            if hay != quiero:
                if antes is not None and hay == tabla_sprites(antes)[:len(hay)]:
                    tot["tabla_antes"] += 1
                elif hay[0] == (0, 0, 0, 0):
                    tot["sin_montar"] += 1          # la copia todavia sin montar (al empezar)
                elif (ram[0xC5A] == 1 and not any(ram[0xC65:0xC7D])) or (ram[0xC7B] == 0 and hay[1:] == quiero[1:]):
                    tot["ram_borrada"] += 1         # la RAM ya borrada (molinillos o fuerza), la copia aun vieja
                else:
                    tot["tabla_mal"] += 1
            antes = ram
    return tot


def main(argv):
    if argv and argv[0] == "cotejo":
        print(cotejo())
        return 0
    from PIL import Image
    salida = argv[0]
    os.makedirs(salida, exist_ok=True)
    hoja(Image).save(os.path.join(salida, "sprites.png"))
    guarda_gif(anima(Image), os.path.join(salida, "ovnis_cuadros.gif"))
    for f in ("sprites.png", "ovnis_cuadros.gif"):
        print(f, os.path.getsize(os.path.join(salida, f)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
