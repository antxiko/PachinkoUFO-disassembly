# Pachinko U.F.O. - commented disassembly

*(También [en castellano](README.es.md).)*

The commented disassembly of **Pachinko U.F.O.** (Casio, 1984) for the MSX: a 16 KB cartridge at 0x8000.

- **100%** of the binary explained: 5,591 bytes of code and 10,793 of named data, not one byte unassigned.
- **42.0%** of the listing commented, 372 routines and labels, none below 10% of comments.
- The listing reassembles into the original ROM **byte for byte**.
- The title comes from running the ROM, checked against openMSX; the three machines, the shot, the centre that opens and the UFOs, played in GIF; the four tunes, from its own sound engine and identical to openMSX frame by frame.

The site: <https://antxiko.github.io/PachinkoUFO-disassembly/>
(in Spanish: <https://antxiko.github.io/PachinkoUFO-disassembly/es/>).

## Rebuilding it

The ROM image is not distributed. Put yours in the root as `pachinkoufo.rom` (sha256 `5a29b6cc...`) and run `make`. The details, in [UNDER THE HOOD](docs/UNDER-THE-HOOD.md).

## Legal

The game belongs to Casio and its rights holders. The `LICENSE` covers only the tools, comments, analysis and documentation here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
