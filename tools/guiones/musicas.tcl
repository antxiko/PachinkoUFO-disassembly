# Para cotejar las cuatro musicas: en el titulo (que no suena), cada vuelta de su espera (0x8162) deja DE en
# 0x8000 para que no llegue la demostracion, y en los cuadros que se dicen llama a `sonido_calla` (0xB9F8) y a
# `pieza` (0xB9CF), las rutinas del juego, con las piezas de cada musica: la salida (250), PATTERN CLEAR (900),
# LEVEL CLEAR (1150) y GAME OVER (1400). 1800 cuadros. Solo vale para el sonido.
set ::cola {}
proc llama {dir b de} {
    set sp [expr {[reg sp] - 2}]
    debug write memory $sp 0x62
    debug write memory [expr {$sp + 1}] 0x81
    reg sp $sp
    reg b $b
    reg de $de
    reg pc $dir
}
debug set_bp 0x8162 {} {
    reg de 0x8000
    if {[llength $::cola]} {
        set p [lindex $::cola 0]
        set ::cola [lrange $::cola 1 end]
        llama [lindex $p 0] [lindex $p 1] [lindex $p 2]
    }
}
proc musica {a b c} { set ::cola [list {0xB9F8 0 0} [list 0xB9CF 0 $a] [list 0xB9CF 1 $b] [list 0xB9CF 2 $c]] }
proc guion {n} {
    if {$n == 250} { musica 0xBC7E 0xBCFA 0xBD61 }
    if {$n == 900} { musica 0xBF03 0xBF22 0xBF41 }
    if {$n == 1150} { musica 0xBF60 0xBF79 0xBF92 }
    if {$n == 1400} { musica 0xBE76 0xBEA7 0xBED8 }
    return [expr {$n >= 1800}]
}
