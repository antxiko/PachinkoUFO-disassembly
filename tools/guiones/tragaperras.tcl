# TRAGAPERRAS (FORZADA): el piloto de partida.tcl, pero un gancho en 0x829E (donde la partida lee la maquina,
# 0xEC5A) pone la maquina 1, la del tragaperras, y a los 700 cuadros se le da una tirada (0xEC84 = 1), como si una bola
# hubiera entrado en su agujero (en la partida grabada ninguna entro). Gira y el boton 2 (GRAPH, cada 300 cuadros en el
# piloto) lo para. 2200 cuadros.
debug set_bp 0x829E {} { debug write memory 0xEC5A 1 }
proc guion {n} {
    if {$n == 200} { keymatrixdown 8 0x01 }
    if {$n == 206} { keymatrixup 8 0x01 }
    if {$n == 700} { debug write memory 0xEC84 1 }
    if {$n > 400} {
        set f [expr {6 + (($n / 40) % 5) * 6}]
        if {$n % 40 == 0} { keymatrixdown 8 0x01 }
        if {$n % 40 == $f} { keymatrixup 8 0x01 }
        if {$n % 300 == 150} { keymatrixdown 6 0x04 }
        if {$n % 300 == 156} { keymatrixup 6 0x04 }
    }
    return [expr {$n >= 2200}]
}
