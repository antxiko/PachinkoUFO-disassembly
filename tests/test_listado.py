"""Lo que se afirma de la ROM, comprobado contra sus bytes.

Corre con la ROM delante y sin ella: cuando no esta, la imagen se rehace desde
las filas defb/defw del listado, que si viaja con el repositorio. Sin la ROM
solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "pachinkoufo.rom")
ASM = os.path.join(RAIZ, "src", "pachinkoufo.asm")
NOTAS = os.path.join(RAIZ, "src", "pachinkoufo.notes")
ORG = 0x8000
TAM = 16384

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def b(a):
    return lee()[a - ORG]


def w(a):
    rom = lee()
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def instruccion(dirr):
    """La instruccion del listado en esa direccion (sin el comentario)."""
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = re.match(r"^\t(\S.*?)\s*;([0-9a-f]{4})", ln)
            if m and int(m.group(2), 16) == dirr:
                return m.group(1).replace("\t", " ").strip()
    return None


class Cabecera(unittest.TestCase):
    def test_ab_e_init_en_0x81b3(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(w(0x8002), 0x81B3)
        self.assertEqual(rom[4:16], bytes(12))

    def test_son_16_kb(self):
        self.assertEqual(len(lee()), TAM)


class LaInterrupcion(unittest.TestCase):
    def test_va_por_h_keyi(self):
        self.assertEqual([instruccion(a) for a in (0x81B7, 0x81B9, 0x81BC, 0x81BF)],
                         ["ld a,0c3h", "ld (0fd9ah),a", "ld hl,08010h", "ld (0fd9bh),hl"])

    def test_vuelve_dos_bytes_mas_alla(self):
        self.assertEqual([instruccion(a) for a in (0x8016, 0x8017, 0x8018, 0x8019, 0x801A)],
                         ["pop hl", "inc hl", "inc hl", "xor a", "jp (hl)"])


class LosDatosEnLinea(unittest.TestCase):
    def test_cada_texto_acaba_en_0_y_cada_copia_en_1f(self):
        rom = lee()
        llamadas = [i + ORG for i in range(len(rom) - 3) if rom[i] == 0xCD and rom[i + 1] in (0x90, 0xA3) and rom[i + 2] == 0x80]
        self.assertEqual(len(llamadas), 20)
        for c in llamadas:
            fin = 0x00 if rom[c - ORG + 1] == 0x90 else 0x1F
            p = c + 5
            while rom[p - ORG] != fin:
                p += 1
            self.assertIsNotNone(instruccion(p + 1), hex(c))

    def test_los_textos(self):
        rom = lee()
        self.assertEqual(rom[0x8127 - ORG:0x8143 - ORG], b"PUSH TRIGGER 1 TO START GAME")
        self.assertEqual(rom[0x849A - ORG:0x84AD - ORG], b" YOU WIN THE GAME! ")
        self.assertEqual(rom[0x8555 - ORG:0x8560 - ORG], b" GAME OVER ")


class LaPartida(unittest.TestCase):
    def test_los_cuatro_objetivos(self):
        self.assertEqual([w(0x817D + 4 * k) for k in range(4)], [400, 600, 800, 1000])
        self.assertEqual([b(0x817F + 4 * k) for k in range(4)], [0x00, 0x00, 0x00, 0x00])
        self.assertEqual([b(0x8180 + 4 * k) for k in range(4)], [0x04, 0x06, 0x08, 0x10])

    def test_tres_maquinas_seguidas(self):
        self.assertEqual([instruccion(a) for a in (0x8255, 0x8256, 0x8257)], ["ld a,(hl)", "inc a", "cp 003h"])

    def test_el_tragaperras_cuenta_las_cifras_de_6_o_mas(self):
        self.assertEqual(instruccion(0x89EE), "ld b,081h")
        self.assertEqual(instruccion(0x895B), "add a,07bh")

    def test_el_record_se_para_en_99999(self):
        self.assertEqual([instruccion(a) for a in (0x8744, 0x874D, 0x8755)], ["cp 010h", "ld a,099h", "ld a,009h"])


class ElEspejo(unittest.TestCase):
    def test_las_casillas_y_el_mapa_se_dan_la_vuelta(self):
        self.assertEqual([instruccion(a) for a in (0x9DE5, 0x9DE6)], ["rlca", "rr c"])
        self.assertEqual([instruccion(a) for a in (0xAAA4, 0xAAA5)], ["rrca", "rl c"])


class Sonido(unittest.TestCase):
    def test_doce_ordenes(self):
        t = [w(0xBBFE + 2 * k) for k in range(12)]
        self.assertEqual(t[0], 0xBB34)
        self.assertEqual(t[11], 0xBB46)

    def test_el_giro_del_tragaperras_esta_entre_las_casillas(self):
        self.assertEqual(instruccion(0x8987), "ld de,09fc7h")
        self.assertTrue(0x9DF7 <= 0x9FC7 < 0xA027)
        self.assertEqual(b(0x9FC7), 0xFA)


class LoQueNadieUsa(unittest.TestCase):
    def test_la_rutina_de_0x9dbc_no_la_llama_nadie(self):
        rom = lee()
        for op in (0xCD, 0xC3, 0xC4, 0xCC, 0xD4, 0xDC, 0xC2, 0xCA, 0xD2, 0xDA):
            self.assertNotIn(bytes([op, 0xBC, 0x9D]), rom)


class ElListado(unittest.TestCase):
    def test_densidad_y_flojas(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertGreaterEqual(int(m.group(2)) * 100, 40 * int(m.group(1)))
        self.assertIn("---- 0 rutinas por debajo del 10 %", salida)

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_cada_comentario_en_su_instruccion(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "valida_c.py"), ASM, NOTAS],
            capture_output=True, text=True, check=True).stdout
        self.assertIn("0 fuera de sitio, 0 repetidos", salida)


if __name__ == "__main__":
    unittest.main()
