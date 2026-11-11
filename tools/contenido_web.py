#!/usr/bin/env python3
"""EL CONTENIDO de la web de esta ROM: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Todas las cifras de aqui estan medidas sobre esta ROM, con las herramientas
de tools/: CODIGO y DATOS los imprime tools/presupuesto.py (make sanity),
INSTRUCCIONES, COMENTARIOS y RUTINAS los da tools/densidad.py (make densidad:
"de N" rutinas, "N instrucciones, M comentarios").
"""

NOMBRE = "Pachinko U.F.O."
EDITOR = "Casio"
ANIO = 1984
REPOSITORIO = "https://github.com/antxiko/PachinkoUFO-disassembly"
SHA1 = "cad653766b597a4aa130a9a1956ece77ba4d52bc"

CODIGO = 5591
DATOS = 10793
RUTINAS = 372
INSTRUCCIONES = 2883
COMENTARIOS = 1210


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Pachinko U.F.O.</em> es un juego de Casio para MSX, de 1984, en un cartucho de 16 KB. "
          "Todos los derechos sobre el juego siguen siendo de sus titulares. Este trabajo es de "
          "preservaci&oacute;n, estudio y documentaci&oacute;n, y la imagen de la ROM no se distribuye.",
    "en": "<em>Pachinko U.F.O.</em> is a 1984 Casio game for the MSX, on a 16 KB cartridge. All rights in "
          "the game remain with their holders. This is preservation, study and documentation work, and the "
          "ROM image is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Pachinko U.F.O. - desensamblado comentado",
        claim="Una m&aacute;quina de pachinko, y luego otra y otra: la del centro que se abre, la del "
              "tragaperras y la de los OVNIs. La fuerza de cada bola, los clavos en un mapa de bits con su "
              "mitad en espejo, los agujeros, la V, las aperturas y el OVNI grande; el t&iacute;tulo desde los "
              "bytes de la ROM, cotejado con openMSX; las tres m&aacute;quinas en GIF y las cuatro m&uacute;sicas "
              "de su propio motor, id&eacute;nticas a openMSX cuadro a cuadro.",
        ficha=["Casio - <b>(c) 1984</b>",
               "Cartucho de <b>16 KB</b> en 0x8000",
               "<b>MSX</b>", "Volcado <b>cad65376...</b>"],
        aviso="<b>Aqu&iacute; no hay capturas del juego.</b> El logotipo y el t&iacute;tulo salen de "
              "ejecutar la ROM (cotejados con openMSX), y los GIF son la ROM <b>funcionando en "
              "openMSX</b>: en cada cuadro se apuntan la VRAM y los registros del VDP, y <b>c&oacute;digo "
              "nuestro los pinta</b>.",
    ),
    "en": dict(
        titulo="Pachinko U.F.O. - commented disassembly",
        claim="A pachinko machine, then another and another: the one whose centre opens, the one with the "
              "slot machine and the one with the UFOs. The strength of each ball, the pins in a bitmap whose "
              "half is a mirror, the pockets, the V, the openings and the big UFO; the title from the ROM's "
              "bytes, checked against openMSX; the three machines in GIF and the four tunes from its own "
              "engine, identical to openMSX frame by frame.",
        ficha=["Casio - <b>(c) 1984</b>",
               "<b>16 KB</b> cartridge at 0x8000",
               "<b>MSX</b>", "Dump <b>cad65376...</b>"],
        aviso="<b>There are no screenshots of the game here.</b> The logo and the title come from running "
              "the ROM (checked against openMSX), and the GIFs are the ROM <b>running in openMSX</b>: on every "
              "frame the VRAM and the VDP registers are logged, and <b>our own code paints them</b>.",
    ),
}

PAGINAS = [
    [("THE-GAME.html", "LA-PARTIDA.html", "The game", "La partida",
      "the controls, the balls, the objective, the levels and the endings, as the code has them",
      "los mandos, las bolas, el objetivo, los niveles y los finales, como los tiene el c&oacute;digo"),
     ("THE-MACHINES.html", "LAS-MAQUINAS.html", "The machines", "Las m&aacute;quinas",
      "the three machines, played in GIF: the centre that opens, the slot machine and the UFOs",
      "las tres m&aacute;quinas, jugadas en GIF: el centro que se abre, el tragaperras y los OVNIs"),
     ("THE-TEXTS.html", "LOS-TEXTOS.html", "The texts", "Los textos",
      "every text in the ROM, with its translation",
      "todos los textos de la ROM, con su traducci&oacute;n"),
     ("THE-MUSIC.html", "LA-MUSICA.html", "The music", "La m&uacute;sica",
      "the four tunes, from its own sound engine and checked against openMSX",
      "las cuatro m&uacute;sicas, de su propio motor de sonido y cotejadas con openMSX")],
    [("CURIOSITIES.html", "CURIOSIDADES.html", "Curiosities", "Curiosidades",
      "a machine drawn in half, a sound hidden among the tiles, ten that are sixteen and the code nobody calls",
      "una m&aacute;quina dibujada a medias, un sonido escondido entre las casillas, diez que son diecis&eacute;is "
      "y el c&oacute;digo que nadie llama")],
    [("UNDER-THE-HOOD.html", "POR-DENTRO.html", "Under the hood", "Por dentro",
      "rebuilding the ROM, the BIOS it uses, the interrupt, the texts behind the calls, the RAM and the tools",
      "rehacer la ROM, la BIOS que usa, la interrupci&oacute;n, los textos detr&aacute;s de las llamadas, la "
      "RAM y las herramientas")],
]

# Repositorio nuevo: no hay paginas viejas que redirigir.
VIEJAS = {}

LOGOTIPO = "logotipo.png"
