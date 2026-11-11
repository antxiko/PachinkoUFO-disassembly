# Pachinko U.F.O. - desensamblado comentado

*(Also [in English](README.md).)*

El desensamblado comentado de **Pachinko U.F.O.** (Casio, 1984) para MSX: un cartucho de 16 KB en 0x8000.

- **100 %** del binario explicado: 5.591 bytes de código y 10.793 de datos con nombre, ni un byte sin asignar.
- **42,0 %** del listado comentado, 372 rutinas y etiquetas, ninguna por debajo del 10 % de comentarios.
- El listado se reensambla en la ROM original **byte a byte**.
- El título sale de ejecutar la ROM, cotejado con openMSX; las tres máquinas, el tiro, el centro que se abre y los OVNIs, jugados en GIF; las cuatro músicas, de su propio motor de sonido e idénticas a openMSX cuadro a cuadro.

La web: <https://antxiko.github.io/PachinkoUFO-disassembly/es/>
(en inglés: <https://antxiko.github.io/PachinkoUFO-disassembly/>).

## Reproducirlo

La imagen de la ROM no se distribuye. Pon la tuya en la raíz como `pachinkoufo.rom` (sha256 `5a29b6cc...`) y ejecuta `make`. El detalle, en [POR DENTRO](docs/es/POR-DENTRO.md).

## Legal

El juego es de Casio y de sus titulares. La licencia de `LICENSE` cubre solo las herramientas, los comentarios, el análisis y la documentación de aquí. Mira [AVISO-LEGAL.md](AVISO-LEGAL.md).
