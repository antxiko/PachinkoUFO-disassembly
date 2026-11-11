# Una partida: la barra (boton 1) en el cuadro 200 empieza. Despues, cada 40 cuadros la barra sostenida un
# tiempo que va cambiando (de 6 a 30 cuadros: la fuerza de la bola) y GRAPH (boton 2, fila 6 0x04) cada 300.
# 9000 cuadros.
proc guion {n} {
    if {$n == 200} { keymatrixdown 8 0x01 }
    if {$n == 206} { keymatrixup 8 0x01 }
    if {$n > 400} {
        set f [expr {6 + (($n / 40) % 5) * 6}]
        if {$n % 40 == 0} { keymatrixdown 8 0x01 }
        if {$n % 40 == $f} { keymatrixup 8 0x01 }
        if {$n % 300 == 150} { keymatrixdown 6 0x04 }
        if {$n % 300 == 156} { keymatrixup 6 0x04 }
    }
    return [expr {$n >= 9000}]
}
