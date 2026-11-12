; ==========================================================================
; PACHINKO U.F.O. - ROM de 16 KB en 0x8000
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x08000


; ----------------------------------------------------------------------
; DATOS cabecera: "AB", INIT (0x81B3) y el resto de la cabecera a cero
;   0x8000..0x8010  (16 bytes)
DATA_cabecera:
	defb 041h,042h	; 8000
	defw 081b3h,00000h,00000h,00000h,00000h,00000h,00000h	; 8002

; ======================================================================
; CODIGO 0x8010..0x80c0  (176 bytes)
; ======================================================================


interrupcion:		; La interrupcion (H.KEYI): el estado del VDP, el cuadro y la vuelta a la BIOS dos bytes mas alla
	call 0013eh		;8010   ; RDVDP: lee el estado (y el VDP deja de pedir la interrupcion)
	call cuadro		;8013   ; el cuadro
	pop hl			;8016   ; la vuelta a la BIOS...
	inc hl			;8017   ; ...dos bytes mas alla...
	inc hl			;8018
	xor a			;8019   ; ...con A = 0...
	jp (hl)			;801a   ; ...salta alli
cuadro:		; Un cuadro: el sonido (si no es la demostracion) y, si el anterior ha acabado, el juego
	ld a,(0ec5eh)		;801b   ; la demostracion?
	or a			;801e
	call z,sonido_cuadro		;801f   ; no: el sonido
	ld a,(0f000h)		;8022   ; el cuadro anterior aun corre?
	or a			;8025
	ret nz			;8026
	ei			;8027   ; con las interrupciones abiertas
	inc a			;8028   ; ocupado
	ld (0f000h),a		;8029
	call juego		;802c   ; el juego
	ld a,(0efffh)		;802f   ; la partida se acaba?
	or a			;8032
	di			;8033   ; cerradas
	ret nz			;8034
	ld (0f000h),a		;8035   ; libre
	ret			;8038
espera:		; Una espera de unos 200.000 pasos (tres vueltas de 65.536), salvo en la demostracion
	ld a,(0ec5eh)		;8039   ; la demostracion?
	or a			;803c
	ret nz			;803d
	ld b,003h		;803e   ; tres vueltas
	push de			;8040
espera_vuelta:		; ...DE desde 0...
	ld d,a			;8041
	ld e,a			;8042
espera_paso:		; ...hasta 0 otra vez
	dec de			;8043   ; un paso...
	ld a,d			;8044   ; ...hasta que DE sea 0
	or e			;8045
	jr nz,espera_paso		;8046
	djnz espera_vuelta		;8048
	pop de			;804a
	ret			;804b
ocupado:		; 0xF000 a 0xFF: la interrupcion no hace el juego
	push af			;804c
	ld a,0ffh		;804d
	jr ocupado_pon		;804f
libre:		; 0xF000 a 0: la interrupcion hace el juego
	push af			;8051
	xor a			;8052
ocupado_pon:
	ld (0f000h),a		;8053
	pop af			;8056
	ret			;8057
boton2:		; El boton 2: B del mando 1 o 2 (GTTRIG 3 y 4) o GRAPH (fila 6, bit 2), 0xFF en 0xED26
	ld a,003h		;8058   ; el mando 1...
	call 000d8h		;805a
	or a			;805d
	jr nz,boton2_pon		;805e
	ld a,004h		;8060   ; ...el 2...
	call 000d8h		;8062
	or a			;8065
	jr nz,boton2_pon		;8066
	ld a,006h		;8068   ; ...o el teclado: la fila 6 (SNSMAT)
	call 00141h		;806a
	bit 2,a		;806d   ; GRAPH a 0 = pulsada
	ld a,0ffh		;806f
	jr z,boton2_pon		;8071
	xor a			;8073
boton2_pon:
	ld (0ed26h),a		;8074
	ret			;8077
boton1:		; El boton 1: A del mando 1 o 2 o la barra (GTTRIG 1, 2 y 0), en 0xED25
	ld a,001h		;8078   ; el mando 1...
	call 000d8h		;807a
	or a			;807d
	jr nz,boton1_pon		;807e
	ld a,002h		;8080   ; ...el 2...
	call 000d8h		;8082
	or a			;8085
	jr nz,boton1_pon		;8086
	xor a			;8088   ; ...o la barra
	call 000d8h		;8089
boton1_pon:
	ld (0ed25h),a		;808c
	ret			;808f
texto_vram:		; Escribe en la VRAM el texto que va detras del "call": la direccion y las letras hasta 0x00; vuelve detras
	pop hl			;8090   ; la vuelta: los datos
	ld e,(hl)			;8091   ; la direccion de la VRAM...
	inc hl			;8092
	ld d,(hl)			;8093
	inc hl			;8094
	ex de,hl			;8095   ; ...en HL
texto_vram_letra:		; Una letra (WRTVRM)
	ld a,(de)			;8096
	inc de			;8097
	or a			;8098   ; 0: se acaba
	jr z,texto_vram_fin		;8099
	call 0004dh		;809b
	inc hl			;809e
	jr texto_vram_letra		;809f
texto_vram_fin:		; La vuelta, detras del 0
	push de			;80a1
	ret			;80a2
copia_ram:		; Copia a la RAM los bytes que van detras del "call": la direccion y los bytes hasta 0x1F; vuelve detras
	pop hl			;80a3   ; la vuelta: los datos
	ld e,(hl)			;80a4   ; la direccion de la RAM...
	inc hl			;80a5
	ld d,(hl)			;80a6
	inc hl			;80a7
	ex de,hl			;80a8
copia_ram_byte:		; Un byte
	ld a,(de)			;80a9
	inc de			;80aa
	cp 01fh		;80ab   ; 0x1F: se acaba
	jr z,copia_ram_fin		;80ad
	ld (hl),a			;80af
	inc hl			;80b0
	jr copia_ram_byte		;80b1
copia_ram_fin:		; La vuelta, detras del 0x1F
	push de			;80b3
	ret			;80b4
titulo:		; El titulo: la pantalla en blanco, los sprites fuera, CASIO, PACHINKO-U.F.O., PUSH TRIGGER 1 TO START GAME y el copyright
	ld a,020h		;80b5   ; el espacio...
	call pantalla_borra		;80b7   ; ...en toda la pantalla
	call sprites_fuera		;80ba   ; los sprites fuera
	call texto_vram		;80bd

; ----------------------------------------------------------------------
; DATOS texto_80c0: CASIO en letras grandes, la fila de arriba (fila 4,
;   columna 10; casillas propias) y el 0 final
;   0x80c0..0x80cf  (15 bytes)
DATA_texto_80c0:
	defw 0188ah	; 80c0
	defb 001h,003h,020h,005h,007h,020h,001h,003h,00bh,020h,001h,00dh	; 80c2  .. .. ... ..
	defb 000h	; 80ce

; ======================================================================
; CODIGO 0x80cf..0x80d2  (3 bytes)
; ======================================================================


L_80CF:
	call texto_vram		;80cf

; ----------------------------------------------------------------------
; DATOS texto_80d2: CASIO en letras grandes, la fila de abajo (fila 5) y el 0
;   final
;   0x80d2..0x80e1  (15 bytes)
DATA_texto_80d2:
	defw 018aah	; 80d2
	defb 002h,004h,020h,006h,008h,020h,009h,00ah,00ch,020h,002h,00eh	; 80d4  .. .. ... ..
	defb 000h	; 80e0

; ======================================================================
; CODIGO 0x80e1..0x80e4  (3 bytes)
; ======================================================================


L_80E1:
	call texto_vram		;80e1

; ----------------------------------------------------------------------
; DATOS texto_80e4: PACHINKO-U.F.O. en letras grandes, la fila de arriba (fila
;   8, columna 3) y el 0 final
;   0x80e4..0x8101  (29 bytes)
DATA_texto_80e4:
	defw 01903h	; 80e4
	defb 00fh,00dh,005h,007h,001h,003h,011h,012h,00bh,020h,013h,012h,011h,016h,001h,00dh,020h,020h,011h,012h,020h,00fh,003h,020h,001h,00dh	; 80e6  ......... ......  .. .. ..
	defb 000h	; 8100

; ======================================================================
; CODIGO 0x8101..0x8104  (3 bytes)
; ======================================================================


L_8101:
	call texto_vram		;8101

; ----------------------------------------------------------------------
; DATOS texto_8104: PACHINKO-U.F.O., la fila de abajo (fila 9) y el 0 final
;   0x8104..0x8122  (30 bytes)
DATA_texto_8104:
	defw 01923h	; 8104
	defb 006h,010h,006h,008h,002h,004h,006h,008h,00ch,020h,014h,015h,006h,017h,002h,00eh,019h,010h,002h,00eh,018h,006h,010h,018h,002h,00eh,018h	; 8106  ......... .................
	defb 000h	; 8121

; ======================================================================
; CODIGO 0x8122..0x8125  (3 bytes)
; ======================================================================


L_8122:
	call texto_vram		;8122

; ----------------------------------------------------------------------
; DATOS texto_8125: El texto de "call 0x8090": fila 14, columna 2 de la
;   pantalla, "PUSH TRIGGER 1 TO START GAME" y el 0 final
;   0x8125..0x8144  (31 bytes)
DATA_texto_8125:
	defw 019c2h	; 8125
	defb 050h,055h,053h,048h,020h,054h,052h,049h,047h,047h,045h,052h,020h,031h,020h,054h,04fh,020h,053h,054h,041h,052h,054h,020h,047h,041h,04dh,045h	; 8127  PUSH TRIGGER 1 TO START GAME
	defb 000h	; 8143

; ======================================================================
; CODIGO 0x8144..0x8147  (3 bytes)
; ======================================================================


L_8144:
	call texto_vram		;8144

; ----------------------------------------------------------------------
; DATOS texto_8147: El texto de "call 0x8090": fila 22, columna 5 de la
;   pantalla, "COPYRIGHT 1984 @ CASIO" y el 0 final
;   0x8147..0x8160  (25 bytes)
DATA_texto_8147:
	defw 01ac5h	; 8147
	defb 043h,04fh,050h,059h,052h,049h,047h,048h,054h,020h,031h,039h,038h,034h,020h,040h,020h,043h,041h,053h,049h,04fh	; 8149  COPYRIGHT 1984 @ CASIO
	defb 000h	; 815f

; ======================================================================
; CODIGO 0x8160..0x817d  (29 bytes)
; ======================================================================


L_8160:
	ld d,a			;8160
	ld e,a			;8161
titulo_espera:		; Espera DE vueltas al boton 1; si llega a 0, la demostracion (0xEC5E = 1)
	call boton1		;8162   ; el boton 1
	ld a,(0ed25h)		;8165
	or a			;8168   ; pulsado?
	jr nz,titulo_boton		;8169
	dec de			;816b   ; una vuelta menos
	ld a,d			;816c
	or e			;816d
	jr nz,titulo_espera		;816e
	inc a			;8170   ; nadie: la demostracion
	ld (0ec5eh),a		;8171
	ret			;8174
titulo_boton:		; El boton: la partida, con el sonido callado
	xor a			;8175
	ld (0ec5eh),a		;8176
	call sonido_calla		;8179
	ret			;817c

; ----------------------------------------------------------------------
; DATOS niveles: Los cuatro objetivos: las bolas que hay que hacer (binario:
;   400, 600, 800 y 1000) y el CLEAR en BCD
;   0x817d..0x818d  (16 bytes)
DATA_niveles:
	defb 090h,001h,000h,004h	; 817d
	defb 058h,002h,000h,006h	; 8181
	defb 020h,003h,000h,008h	; 8185
	defb 0e8h,003h,000h,010h	; 8189

; ----------------------------------------------------------------------
; DATOS tabla_818d: Los dos bytes de cada vuelta de la maquina 2 (0xED30,
;   0xED31: lo que quita el OVNI malo y lo que da el bueno), y desde 0x8193 la
;   Y y la X del lanzador por la fuerza (16 parejas)
;   0x818d..0x81b3  (38 bytes)
DATA_tabla_818d:
	defb 00ah,010h	; 818d
	defb 01eh,030h	; 818f
	defb 032h,050h	; 8191
	defb 09dh,0b6h	; 8193
	defb 09dh,0b8h	; 8195
	defb 09eh,0bah	; 8197
	defb 09fh,0bch	; 8199
	defb 0a1h,0bdh	; 819b
	defb 0a3h,0beh	; 819d
	defb 0a5h,0beh	; 819f
	defb 0a7h,0beh	; 81a1
	defb 0a9h,0bdh	; 81a3
	defb 0abh,0bch	; 81a5
	defb 0ach,0bah	; 81a7
	defb 0adh,0b8h	; 81a9
	defb 0adh,0b5h	; 81ab
	defb 0ach,0b2h	; 81ad
	defb 0aah,0afh	; 81af
	defb 0a7h,0aeh	; 81b1

; ======================================================================
; CODIGO 0x81b3..0x822a  (119 bytes)
; ======================================================================


init:		; El arranque: la pila, la interrupcion en H.KEYI, SCREEN 2, la fuente de la BIOS en los tres tercios y la partida
	di			;81b3
	ld sp,0f2f0h		;81b4   ; la pila
	ld a,0c3h		;81b7   ; el "jp"...
	ld (0fd9ah),a		;81b9
	ld hl,08010h		;81bc   ; ...a 0x8010...
	ld (0fd9bh),hl		;81bf   ; ...en H.KEYI
	call ocupado		;81c2   ; la interrupcion no hace el juego
	call 0003bh		;81c5   ; INITIO
	call 0007eh		;81c8   ; SETGRP
	call sonido_calla		;81cb   ; el sonido callado
	call 00069h		;81ce   ; CLRSPR
	call 00072h		;81d1   ; INIGRP: SCREEN 2
	call 000cch		;81d4   ; ERAFNK
	ld a,020h		;81d7   ; la pantalla en blanco
	call pantalla_borra		;81d9
	ld a,001h		;81dc   ; el color del borde: 1
	ld (0f3ebh),a		;81de
	call 00062h		;81e1   ; CHGCLR
	ld bc,0e201h		;81e4   ; el registro 1 a 0xE2: sprites de 16 x 16
	call 00047h		;81e7
	ld bc,00200h		;81ea   ; el registro 2...
	call 00047h		;81ed
	ld hl,(00004h)		;81f0   ; la fuente de la BIOS (la direccion de 0x0004)...
	ld bc,00800h		;81f3   ; ...2 KB...
	ld d,c			;81f6   ; ...desde 0
	ld e,c			;81f7
init_fuente:		; ...en los tres tercios de la tabla de patrones (LDIRVM)
	push hl			;81f8
	push de			;81f9
	push bc			;81fa
	call 0005ch		;81fb
	pop bc			;81fe
	pop de			;81ff
	pop hl			;8200
	ex de,hl			;8201
	add hl,bc			;8202
	ex de,hl			;8203
	ld a,d			;8204   ; hasta 0x1800
	cp 018h		;8205
	jr nz,init_fuente		;8207
	call casillas		;8209   ; los dibujos del juego
	call sprites_dibujos		;820c   ; la pantalla de la maquina
	ld hl,0e000h		;820f   ; la RAM 0xE000-0xEFFF a cero
	ld de,0e001h		;8212
	ld bc,00fffh		;8215
	ld (hl),000h		;8218
	ldir		;821a
	ld a,001h		;821c   ; el record: 10000 (0x01, BCD)
	ld (0ec50h),a		;821e
	call letras		;8221   ; los dibujos de los sprites
partida_nueva:		; El titulo, la espera y una partida nueva
	call titulo		;8224   ; el titulo
	call copia_ram		;8227   ; el record a 0, los puntos a 0 y el resto (0xEC55)

; ----------------------------------------------------------------------
; DATOS copia_822a: Los bytes de "call 0x80A3": 9 bytes a 0xEC55 y el 0x1F
;   final
;   0x822a..0x8236  (12 bytes)
DATA_copia_822a:
	defw 0ec55h	; 822a
	defb 000h,000h,050h,000h,000h,002h,000h,002h,003h	; 822c  ..P......
	defb 01fh	; 8235

; ======================================================================
; CODIGO 0x8236..0x82b7  (129 bytes)
; ======================================================================


L_8236:
	ld a,(0ec5eh)		;8236   ; la demostracion?
	or a			;8239   ; no: la maquina que haya
	jr z,partida_ronda		;823a
	ld a,r		;823c   ; una maquina al azar (0-3; la ronda pasa a la siguiente)
	and 003h		;823e   ; de 0 a 3
	ld (0ec5ah),a		;8240
partida_ronda:		; Una ronda: la RAM de la ronda a cero y la maquina siguiente; tras las tres, otra vuelta y LEVEL + 1; tras tres vueltas, el objetivo siguiente
	ld b,000h		;8243   ; 256 bytes
	ld hl,0ec61h		;8245   ; 256 bytes desde 0xEC61
partida_borra:
	ld (hl),000h		;8248   ; a cero
	inc hl			;824a
	djnz partida_borra		;824b   ; todos
	call casillas_colores		;824d   ; la maquina
	ld hl,0ec59h		;8250   ; una partida mas
	inc (hl)			;8253   ; una mas
	inc hl			;8254
	ld a,(hl)			;8255   ; la maquina siguiente...
	inc a			;8256   ; la maquina + 1...
	cp 003h		;8257   ; ...pasa de 2?
	jr c,partida_nivel		;8259   ; ...0, 1 o 2: sigue
	ld a,(0ec5ch)		;825b   ; la vuelta siguiente...
	inc a			;825e   ; la vuelta + 1...
	cp 003h		;825f   ; ...pasa de 2?
	jr c,partida_vuelta		;8261
	ld a,(0ec5dh)		;8263   ; el objetivo siguiente (de 0 a 3)
	inc a			;8266   ; el siguiente...
	and 003h		;8267   ; ...de 0 a 3
	ld (0ec5dh),a		;8269
	xor a			;826c   ; la vuelta 0
partida_vuelta:
	ld (0ec5ch),a		;826d
	inc hl			;8270   ; LEVEL, uno mas (BCD)
	ld a,(hl)			;8271   ; LEVEL...
	inc a			;8272   ; ...+ 1...
	or a			;8273
	daa			;8274   ; ...en BCD
	ld (hl),a			;8275
	dec hl			;8276
	xor a			;8277   ; la maquina 0
partida_nivel:		; Las bolas del objetivo (0x817D)
	ld (hl),a			;8278
	ld a,(0ec5dh)		;8279   ; el objetivo x 4
	add a,a			;827c   ; x 4
	add a,a			;827d
	ld c,a			;827e
	ld b,000h		;827f
	ld hl,0817dh		;8281   ; la tabla de objetivos
	add hl,bc			;8284
	ld e,(hl)			;8285   ; las bolas que hay que hacer (binario)...
	inc hl			;8286
	ld d,(hl)			;8287   ; (los bytes en orden)
	inc hl			;8288
	ld (0ec61h),de		;8289   ; en 0xEC61
	ld d,(hl)			;828d   ; ...y en BCD, para el CLEAR
	inc hl			;828e
	ld e,(hl)			;828f
	ld (0ed2ch),de		;8290   ; en 0xED2C
	ld a,050h		;8294   ; 50 bolas en BCD
	ld (0ed2fh),a		;8296   ; en 0xED2F (las bolas, BCD)
	ld a,032h		;8299   ; 50 en binario
	ld (0ec7dh),a		;829b   ; en 0xEC7D (las bolas)
	ld a,(0ec5ah)		;829e   ; la maquina
	or a			;82a1   ; la maquina 0?
	jp z,partida_maq0		;82a2
	cp 001h		;82a5   ; la maquina 1?
	jp z,partida_maq1		;82a7
	call maquina_maq2		;82aa   ; la maquina 2: su maquina
	xor a			;82ad   ; sin objetivo
	ld (0ec61h),a		;82ae
	ld (0ed2ch),a		;82b1
	call copia_ram		;82b4   ; los seis OVNIs (0xECC5)

; ----------------------------------------------------------------------
; DATOS copia_82b7: Los bytes de "call 0x80A3": 31 bytes a 0xECC5 y el 0x1F
;   final
;   0x82b7..0x82d9  (34 bytes)
DATA_copia_82b7:
	defw 0ecc5h	; 82b7
	defb 001h,030h,078h,000h,000h,002h,040h,060h,001h,001h,002h,050h,078h,002h,000h,001h,060h,0a0h,003h,001h,001h,070h,078h,000h,000h,000h,080h,070h,001h,002h,000h	; 82b9  .0x...@`...Px...`....px....p...
	defb 01fh	; 82d8

; ======================================================================
; CODIGO 0x82d9..0x8389  (176 bytes)
; ======================================================================


L_82D9:
	ld a,(0ec5ch)		;82d9   ; la vuelta x 2...
	add a,a			;82dc
	ld hl,0818dh		;82dd   ; ...en la tabla 0x818D
	ld c,a			;82e0
	ld b,000h		;82e1
	add hl,bc			;82e3
	ld a,(hl)			;82e4
	inc hl			;82e5
	ld (0ed30h),a		;82e6   ; lo que quita el OVNI malo
	ld a,(hl)			;82e9
	ld (0ed31h),a		;82ea   ; los puntos del OVNI bueno
	ld a,(0ec5dh)		;82ed   ; objetivo + 2 OVNIs: los demas fuera
	add a,002h		;82f0
	ld b,a			;82f2
	add a,a			;82f3   ; x 5 bytes
	add a,a			;82f4
	add a,b			;82f5
	ld c,a			;82f6
	ld b,000h		;82f7
	ld hl,0ecc5h		;82f9   ; desde el primero que sobra...
	add hl,bc			;82fc
	ld de,0ecddh		;82fd   ; ...hasta el OVNI grande
partida_limpia:
	ld (hl),000h		;8300   ; a cero
	inc hl			;8302
	call 00020h		;8303   ; DCOMPR: HL < DE?
	jr c,partida_limpia		;8306
	ld a,(0ec5dh)		;8308   ; el objetivo
	ld bc,00201h		;830b   ; 1 golpe al OVNI grande, en los objetivos 0 y 1
	cp 002h		;830e
	jr c,partida_marcas		;8310
	ld bc,00002h		;8312   ; 2 en los objetivos 2 y 3
partida_marcas:
	ld a,c			;8315
	ld (0ed2bh),a		;8316   ; los golpes que hacen falta
	ld a,b			;8319
	ld (0ecdeh),a		;831a   ; y el OVNI grande se mueve o no
	jp partida_marcador		;831d
partida_maq1:		; La maquina 1
	call maquina_maq1		;8320   ; la maquina de la maquina 1
	call marcas		;8323   ; sus tres marcas
	jr partida_pantalla		;8326
partida_maq0:		; La maquina 0: en la primera partida, la musica de la salida (0xBC7E, 0xBCFA, 0xBD61)
	call maquina_maq0		;8328   ; la maquina de la maquina 0
	ld a,(0ec59h)		;832b   ; la primera partida?
	cp 001h		;832e
	jr nz,partida_pantalla		;8330
	call sonido_calla		;8332   ; su musica: el canal 0...
	ld b,000h		;8335
	ld de,0bc7eh		;8337
	call pieza		;833a
	ld b,001h		;833d   ; ...el 1...
	ld de,0bcfah		;833f
	call pieza		;8342
	ld b,002h		;8345   ; ...y el 2
	ld de,0bd61h		;8347
	call pieza		;834a
partida_pantalla:
	ld a,(0ec5ch)		;834d   ; la vuelta 1 o 2...
	cp 002h		;8350
	jr c,partida_textos		;8352
	ld c,01ch		;8354   ; ...mas clavos en el mapa: cuatro lineas...
	ld hl,0e2eah		;8356
	ld de,00012h		;8359
	ld b,004h		;835c
L_835E:
	ld a,(hl)			;835e   ; ...con un bit mas cada una
	or c			;835f
	ld (hl),a			;8360
	add hl,de			;8361
	rrc c		;8362
	djnz L_835E		;8364
	ld c,038h		;8366   ; y cuatro mas al otro lado
	ld hl,0e2ebh		;8368
	ld b,004h		;836b
L_836D:
	ld a,(hl)			;836d
	or c			;836e
	ld (hl),a			;836f
	add hl,de			;8370
	rlc c		;8371
	djnz L_836D		;8373
	ld a,(0ec5ch)		;8375   ; la vuelta 1...
	dec a			;8378
	jr z,partida_textos		;8379
	ld a,0c0h		;837b   ; ...no: tres bytes mas del mapa
	ld (0e16fh),a		;837d
	ld (0e181h),a		;8380
	ld (0e193h),a		;8383
partida_textos:
	call copia_ram		;8386   ; los molinillos (0xEC63)

; ----------------------------------------------------------------------
; DATOS copia_8389: Los bytes de "call 0x80A3": 24 bytes a 0xEC63 y el 0x1F
;   final
;   0x8389..0x83a4  (27 bytes)
DATA_copia_8389:
	defw 0ec63h	; 8389
	defb 001h,000h,03bh,034h,000h,004h,001h,000h,03bh,094h,000h,004h,001h,000h,061h,046h,004h,00dh,001h,000h,061h,082h,004h,00dh	; 838b  ..;4....;.....aF....a...
	defb 01fh	; 83a3

; ======================================================================
; CODIGO 0x83a4..0x83a7  (3 bytes)
; ======================================================================


L_83A4:
	call copia_ram		;83a4   ; los tulipanes y agujeros (0xEC89)

; ----------------------------------------------------------------------
; DATOS copia_83a7: Los bytes de "call 0x80A3": 60 bytes a 0xEC89 y el 0x1F
;   final
;   0x83a7..0x83e6  (63 bytes)
DATA_copia_83a7:
	defw 0ec89h	; 83a7
	defb 001h,000h,05ch,00dh,001h,000h,05ch,001h,001h,000h,084h,00bh,001h,000h,084h,003h,001h,000h,08ch,007h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h,001h,000h,000h,000h	; 83a9  ..\...\.....................................................
	defb 01fh	; 83e5

; ======================================================================
; CODIGO 0x83e6..0x8404  (30 bytes)
; ======================================================================


partida_maq1_borra:
	ld a,(0ec5ah)		;83e6   ; la maquina 1?
	cp 001h		;83e9
	jr nz,partida_marcador		;83eb
	ld hl,0ecb1h		;83ed   ; 20 bytes de 0xECB1...
	ld b,014h		;83f0
L_83F2:
	ld (hl),000h		;83f2   ; ...a cero
	inc hl			;83f4
	djnz L_83F2		;83f5
partida_marcador:		; El marcador: HIGH-SCORE, SCORE, CLEAR, las bolas y LEVEL
	ld hl,0ece4h		;83f7   ; las ocho bolas...
	ld b,040h		;83fa   ; ...64 bytes...
	xor a			;83fc
L_83FD:
	ld (hl),a			;83fd   ; ...a cero
	inc hl			;83fe
	djnz L_83FD		;83ff
	call texto_vram		;8401   ; HIGH-

; ----------------------------------------------------------------------
; DATOS texto_8404: El texto de "call 0x8090": fila 1, columna 26 de la
;   pantalla, "HIGH-" y el 0 final
;   0x8404..0x840c  (8 bytes)
DATA_texto_8404:
	defw 0183ah	; 8404
	defb 048h,049h,047h,048h,02dh	; 8406
	defb 000h	; 840b

; ======================================================================
; CODIGO 0x840c..0x840f  (3 bytes)
; ======================================================================


L_840C:
	call texto_vram		;840c   ; SCORE

; ----------------------------------------------------------------------
; DATOS texto_840f: El texto de "call 0x8090": fila 2, columna 26 de la
;   pantalla, "SCORE" y el 0 final
;   0x840f..0x8417  (8 bytes)
DATA_texto_840f:
	defw 0185ah	; 840f
	defb 053h,043h,04fh,052h,045h	; 8411
	defb 000h	; 8416

; ======================================================================
; CODIGO 0x8417..0x841a  (3 bytes)
; ======================================================================


L_8417:
	call texto_vram		;8417   ; SCORE

; ----------------------------------------------------------------------
; DATOS texto_841a: El texto de "call 0x8090": fila 6, columna 26 de la
;   pantalla, "SCORE" y el 0 final
;   0x841a..0x8422  (8 bytes)
DATA_texto_841a:
	defw 018dah	; 841a
	defb 053h,043h,04fh,052h,045h	; 841c
	defb 000h	; 8421

; ======================================================================
; CODIGO 0x8422..0x8425  (3 bytes)
; ======================================================================


L_8422:
	call texto_vram		;8422   ; CLEAR

; ----------------------------------------------------------------------
; DATOS texto_8425: El texto de "call 0x8090": fila 12, columna 26 de la
;   pantalla, "CLEAR" y el 0 final
;   0x8425..0x842d  (8 bytes)
DATA_texto_8425:
	defw 0199ah	; 8425
	defb 043h,04ch,045h,041h,052h	; 8427
	defb 000h	; 842c

; ======================================================================
; CODIGO 0x842d..0x8430  (3 bytes)
; ======================================================================


L_842D:
	call texto_vram		;842d   ; la caja de las bolas

; ----------------------------------------------------------------------
; DATOS texto_8430: La caja de las bolas: las casillas 0x78 y 0x79 en la fila
;   16, columna 28, y el 0 final
;   0x8430..0x8435  (5 bytes)
DATA_texto_8430:
	defw 01a1ch	; 8430
	defb 078h,079h	; 8432
	defb 000h	; 8434

; ======================================================================
; CODIGO 0x8435..0x8438  (3 bytes)
; ======================================================================


L_8435:
	call texto_vram		;8435   ; LEVEL

; ----------------------------------------------------------------------
; DATOS texto_8438: El texto de "call 0x8090": fila 20, columna 26 de la
;   pantalla, "LEVEL" y el 0 final
;   0x8438..0x8440  (8 bytes)
DATA_texto_8438:
	defw 01a9ah	; 8438
	defb 04ch,045h,056h,045h,04ch	; 843a
	defb 000h	; 843f

; ======================================================================
; CODIGO 0x8440..0x8498  (88 bytes)
; ======================================================================


L_8440:
	call pinta_record		;8440   ; las cifras
	call pinta_puntos		;8443
	call pinta_clear		;8446
	call pinta_bolas		;8449
	call pinta_nivel		;844c
	call sprites		;844f   ; los sprites
	xor a			;8452   ; sin final
	ld (0efffh),a		;8453
	ld (0ec7fh),a		;8456   ; el centro cerrado
	ld a,(0ec5ah)		;8459   ; la maquina 2?
	cp 002h		;845c
	jr z,partida_maq2		;845e
	ld a,(0ec5eh)		;8460   ; la demostracion?
	or a			;8463
	jr nz,partida_calla		;8464
partida_espera:		; Espera al boton 1 para empezar
	call boton1		;8466   ; el boton 1
	ld a,(0ed25h)		;8469
	or a			;846c   ; pulsado?
	jr z,partida_espera		;846d
	jr partida_calla		;846f
partida_maq2:		; La maquina 2: su musica (0xBE2A)
	ld b,000h		;8471   ; el canal 0...
	ld de,0be2ah		;8473   ; ...la musica de la maquina 2
	call pieza		;8476
	jr partida_juega		;8479
partida_calla:		; El sonido callado
	call sonido_calla		;847b   ; el sonido callado
partida_juega:		; La interrupcion hace el juego hasta que deja algo en 0xEFFF
	call libre		;847e   ; la interrupcion hace el juego
partida_juega_espera:
	ld a,(0efffh)		;8481   ; hasta que hay un final
	or a			;8484
	jr z,partida_juega_espera		;8485
	call ocupado		;8487   ; la interrupcion deja de hacer el juego
	push af			;848a   ; el final
	call espera		;848b   ; la espera
	pop af			;848e   ; 1: CLEAR (0x84D5)
	dec a			;848f   ; 1?
	jr z,$+69		;8490   ; ...a 0x84D5
	dec a			;8492   ; 2?
	jr z,$+27		;8493   ; 2: GAME OVER (0x84AE); 3: YOU WIN THE GAME! y despues GAME OVER
	call texto_vram		;8495   ; YOU WIN THE GAME!

; ----------------------------------------------------------------------
; DATOS texto_8498: El texto de "call 0x8090": fila 9, columna 4 de la
;   pantalla, "YOU WIN THE GAME!" y el 0 final
;   0x8498..0x84ae  (22 bytes)
DATA_texto_8498:
	defw 01924h	; 8498
	defb 020h,059h,04fh,055h,020h,057h,049h,04eh,020h,054h,048h,045h,020h,047h,041h,04dh,045h,021h,020h	; 849a   YOU WIN THE GAME! 
	defb 000h	; 84ad

; ======================================================================
; CODIGO 0x84ae..0x84fd  (79 bytes)
; ======================================================================


game_over:		; GAME OVER y su musica (0xBE76, 0xBEA7, 0xBED8); despues, el titulo
	call sonido_calla		;84ae   ; el sonido callado
	ld b,000h		;84b1   ; su musica: el canal 0...
	ld de,0be76h		;84b3
	call pieza		;84b6
	ld b,001h		;84b9   ; ...el 1...
	ld de,0bea7h		;84bb
	call pieza		;84be
	ld b,002h		;84c1   ; ...y el 2
	ld de,0bed8h		;84c3
	call pieza		;84c6
	call cartel_game_over		;84c9   ; el cartel del centro
	call espera_musica		;84cc   ; espera a que acabe
	call espera		;84cf   ; y un rato mas
	jp partida_nueva		;84d2   ; al titulo
pattern_clear:		; PATTERN CLEAR y su musica (0xBF03, 0xBF22, 0xBF41); la maquina 2, LEVEL CLEAR
	call sonido_calla		;84d5   ; el sonido callado
	call sprites_fuera		;84d8   ; los sprites fuera
	ld a,(0ec5ah)		;84db   ; la maquina 2?
	cp 002h		;84de
	jr z,$+53		;84e0   ; si: LEVEL CLEAR (0x8515)
	ld b,000h		;84e2   ; la musica: el canal 0...
	ld de,0bf03h		;84e4
	call pieza		;84e7
	ld b,001h		;84ea   ; ...el 1...
	ld de,0bf22h		;84ec
	call pieza		;84ef
	ld b,002h		;84f2   ; ...y el 2
	ld de,0bf41h		;84f4
	call pieza		;84f7
	call texto_vram		;84fa   ; PATTERN CLEAR

; ----------------------------------------------------------------------
; DATOS texto_84fd: El texto de "call 0x8090": fila 10, columna 6 de la
;   pantalla, "PATTERN CLEAR" y el 0 final
;   0x84fd..0x850f  (18 bytes)
DATA_texto_84fd:
	defw 01946h	; 84fd
	defb 020h,050h,041h,054h,054h,045h,052h,04eh,020h,043h,04ch,045h,041h,052h,020h	; 84ff   PATTERN CLEAR 
	defb 000h	; 850e

; ======================================================================
; CODIGO 0x850f..0x8537  (40 bytes)
; ======================================================================


L_850F:
	call espera_musica		;850f   ; espera a que acabe
	jp partida_ronda		;8512   ; la ronda siguiente
level_clear:		; La maquina 2: LEVEL CLEAR y su musica (0xBF60, 0xBF79, 0xBF92); en la demostracion, al titulo
	ld a,(0ec5eh)		;8515   ; la demostracion?
	or a			;8518
	jp nz,partida_nueva		;8519   ; si: al titulo
	ld b,000h		;851c   ; la musica: el canal 0...
	ld de,0bf60h		;851e
	call pieza		;8521
	ld b,001h		;8524   ; ...el 1...
	ld de,0bf79h		;8526
	call pieza		;8529
	ld b,002h		;852c   ; ...y el 2
	ld de,0bf92h		;852e
	call pieza		;8531
	call texto_vram		;8534   ; LEVEL CLEAR

; ----------------------------------------------------------------------
; DATOS texto_8537: El texto de "call 0x8090": fila 10, columna 7 de la
;   pantalla, "LEVEL CLEAR" y el 0 final
;   0x8537..0x8547  (16 bytes)
DATA_texto_8537:
	defw 01947h	; 8537
	defb 020h,04ch,045h,056h,045h,04ch,020h,043h,04ch,045h,041h,052h,020h	; 8539   LEVEL CLEAR 
	defb 000h	; 8546

; ======================================================================
; CODIGO 0x8547..0x8553  (12 bytes)
; ======================================================================


L_8547:
	call espera_musica		;8547   ; espera a que acabe
	jp partida_ronda		;854a   ; la ronda siguiente
cartel_game_over:		; Los sprites fuera y GAME OVER
	call sprites_fuera		;854d   ; los sprites fuera
	call texto_vram		;8550   ; GAME OVER

; ----------------------------------------------------------------------
; DATOS texto_8553: El texto de "call 0x8090": fila 10, columna 8 de la
;   pantalla, "GAME OVER" y el 0 final
;   0x8553..0x8561  (14 bytes)
DATA_texto_8553:
	defw 01948h	; 8553
	defb 020h,047h,041h,04dh,045h,020h,04fh,056h,045h,052h,020h	; 8555   GAME OVER 
	defb 000h	; 8560

; ======================================================================
; CODIGO 0x8561..0x8927  (966 bytes)
; ======================================================================


L_8561:
	ret			;8561
espera_musica:		; Espera a que acabe la musica, salvo en la demostracion
	ld a,(0ec5eh)		;8562   ; la demostracion no espera
	or a			;8565
	ret nz			;8566
espera_musica_va:		; ...los tres canales callados?
	ld a,(0f104h)		;8567   ; el canal 0 suena?...
	ld b,a			;856a
	ld a,(0f124h)		;856b   ; ...el 1...
	or b			;856e
	ld b,a			;856f
	ld a,(0f144h)		;8570   ; ...el 2
	or b			;8573
	jr nz,espera_musica_va		;8574   ; espera
	ret			;8576
puntos_suena:		; Puntos (DE) y el sonido (0xBE5C, canal 1)
	push ix		;8577   ; lo de quien llama
	push iy		;8579
	push de			;857b
	call puntos		;857c   ; las bolas y los puntos
	ld b,001h		;857f   ; el canal 1...
	ld de,0be5ch		;8581   ; ...el sonido
	call pieza		;8584
	pop de			;8587   ; lo de quien llama
	pop iy		;8588
	pop ix		;858a
	ret			;858c
bola_menos:		; Una bola menos: en las bolas (0xEC7D y 0xED2E) y en los puntos
	push ix		;858d   ; lo de quien llama
	push iy		;858f
	call bola_menos_va		;8591   ; una bola menos
	pop iy		;8594
	pop ix		;8596
	ret			;8598
bola_menos_va:
	ld hl,(0ec7dh)		;8599   ; una menos en binario
	dec hl			;859c   ; una menos...
	ld (0ec7dh),hl		;859d   ; ...en 0xEC7D
	ld ix,0ed2eh		;85a0   ; una menos en BCD
	ld a,(ix+001h)		;85a4   ; el byte bajo...
	sub 001h		;85a7   ; ...menos 1...
	daa			;85a9   ; ...en BCD
	ld (ix+001h),a		;85aa
	ld a,(ix+000h)		;85ad   ; el alto, con el acarreo
	sbc a,000h		;85b0
	daa			;85b2
	ld (ix+000h),a		;85b3
	call pinta_bolas		;85b6   ; en la pantalla
	ld ix,0ec55h		;85b9   ; y un punto menos (BCD, tres bytes)
	ld a,(ix+002h)		;85bd   ; el byte bajo
	sub 001h		;85c0
	daa			;85c2
	ld (ix+002h),a		;85c3
	ld a,(ix+001h)		;85c6   ; el de en medio
	sbc a,000h		;85c9
	daa			;85cb
	ld (ix+001h),a		;85cc
	ld a,(ix+000h)		;85cf   ; el alto
	sbc a,000h		;85d2
	daa			;85d4
	ld (ix+000h),a		;85d5
	jp pinta_puntos		;85d8   ; en la pantalla
puntos:		; DE bolas mas y DE puntos mas (salvo en un caso), y el record si se pasa
	ld a,(0ed2ah)		;85db   ; el final pendiente...
	ld b,a			;85de
	ld a,(0ec5ah)		;85df   ; ...mas la maquina...
	add a,b			;85e2
	cp 004h		;85e3   ; ...4: nada
	ret z			;85e5
	ex de,hl			;85e6   ; en binario
	ld hl,(0ec7dh)		;85e7   ; las bolas en binario...
	add hl,de			;85ea   ; ...+ DE
	ld (0ec7dh),hl		;85eb
	ex de,hl			;85ee
	push hl			;85ef   ; y en BCD: DE se suma tal cual como BCD (0x10 son 16 en binario y 10 en el marcador)
	ld ix,0ed2eh		;85f0   ; en BCD
	ld a,(ix+001h)		;85f4   ; el byte bajo...
	add a,l			;85f7   ; ...+ L...
	daa			;85f8   ; ...BCD
	ld (ix+001h),a		;85f9
	ld a,(ix+000h)		;85fc   ; el alto, + H con el acarreo
	adc a,h			;85ff
	daa			;8600
	ld (ix+000h),a		;8601
	call pinta_bolas		;8604   ; en la pantalla
	pop hl			;8607   ; lo mismo en los puntos
	ld ix,0ec55h		;8608   ; los puntos (BCD, tres bytes)
	ld a,(ix+002h)		;860c   ; el byte bajo
	add a,l			;860f
	daa			;8610
	ld (ix+002h),a		;8611
	ld a,(ix+001h)		;8614   ; el de en medio
	adc a,h			;8617
	daa			;8618
	ld (ix+001h),a		;8619
	ld a,(ix+000h)		;861c   ; el alto
	adc a,000h		;861f
	daa			;8621
	ld (ix+000h),a		;8622
	call pinta_puntos		;8625   ; en la pantalla
	ld ix,0ec55h		;8628   ; pasa del record?
	ld iy,0ec50h		;862c   ; contra el record
	ld a,(ix+000h)		;8630   ; el byte alto: menor?
	cp (iy+000h)		;8633
	ret c			;8636
	jr nz,record		;8637   ; mayor: record
	ld a,(ix+001h)		;8639   ; el de en medio
	cp (iy+001h)		;863c
	ret c			;863f
	jr nz,record		;8640
	ld a,(ix+002h)		;8642   ; el bajo
	cp (iy+002h)		;8645
	ret c			;8648
record:		; El record nuevo, salvo en la demostracion
	ld a,(0ec5eh)		;8649   ; en la demostracion no
	or a			;864c
	ret nz			;864d
	ld a,(ix+000h)		;864e   ; los puntos...
	ld (iy+000h),a		;8651
	ld a,(ix+001h)		;8654   ; ...son el record...
	ld (iy+001h),a		;8657
	ld a,(ix+002h)		;865a
	ld (iy+002h),a		;865d   ; ...nuevo
	jr pinta_record		;8660   ; en la pantalla
pinta_clear:		; El CLEAR (0xED2C) en la pantalla
	ld hl,019dbh		;8662   ; en la fila 14, columna 27
	ld iy,0ed2ch		;8665   ; el CLEAR
	jr pinta_dos		;8669
pinta_bolas:		; Las bolas (0xED2E)
	ld hl,01a5bh		;866b   ; en la fila 18, columna 27
	ld iy,0ed2eh		;866e   ; las bolas
pinta_dos:		; Dos bytes BCD: cuatro cifras
	ld c,000h		;8672   ; aun sin cifras
	ld a,(iy+000h)		;8674   ; el byte alto...
	ld d,000h		;8677   ; ...no es el ultimo
	call pinta_byte		;8679
	ld a,(iy+001h)		;867c   ; el bajo...
	ld d,001h		;867f   ; ...el ultimo
	jr pinta_byte		;8681
pinta_record:		; El record (0xEC50)
	ld hl,0189ah		;8683   ; en la fila 4, columna 26
	ld iy,0ec50h		;8686   ; el record
	jr pinta_tres		;868a
pinta_puntos:		; Los puntos (0xEC55)
	ld hl,0191ah		;868c   ; en la fila 8, columna 26
	ld iy,0ec55h		;868f   ; los puntos
pinta_tres:		; Tres bytes BCD: seis cifras
	ld c,000h		;8693   ; aun sin cifras
	ld a,(iy+000h)		;8695   ; el byte alto: solo su cifra baja
	ld d,000h		;8698
	call pinta_baja		;869a
	ld a,(iy+001h)		;869d   ; el de en medio
	ld d,000h		;86a0
	call pinta_byte		;86a2
	ld a,(iy+002h)		;86a5   ; el bajo, el ultimo
	ld d,001h		;86a8
	jr pinta_byte		;86aa
pinta_nivel:		; LEVEL (0xEC5B)
	ld hl,01adch		;86ac   ; en la fila 22, columna 28
	ld a,(0ec5bh)		;86af   ; LEVEL
	ld c,000h		;86b2
	ld d,001h		;86b4   ; el ultimo
	jr pinta_byte		;86b6
pinta_byte:		; Las dos cifras de un byte BCD; los ceros de la izquierda en blanco
	inc d			;86b8   ; una cifra mas
	ld b,a			;86b9
	rrca			;86ba   ; la cifra alta
	rrca			;86bb
	rrca			;86bc
	rrca			;86bd
	and 00fh		;86be
	jr nz,pinta_alta		;86c0   ; no es 0
	call cero_blanco		;86c2   ; un 0: en blanco?
	jr pinta_cifra		;86c5
pinta_alta:
	inc c			;86c7   ; ya hay cifras
pinta_cifra:		; La cifra (0x30 + n, WRTVRM)
	add a,030h		;86c8   ; la casilla de la cifra
	call 0004dh		;86ca   ; WRTVRM
	inc hl			;86cd
	ld a,b			;86ce   ; la cifra baja
pinta_baja:		; La cifra baja
	inc d			;86cf
	and 00fh		;86d0
	or a			;86d2
	jr nz,pinta_baja_va		;86d3   ; no es 0
	call cero_blanco		;86d5   ; un 0: en blanco?
	jr pinta_baja_cifra		;86d8
pinta_baja_va:
	inc c			;86da   ; ya hay cifras
pinta_baja_cifra:
	add a,030h		;86db
	call 0004dh		;86dd   ; WRTVRM
	inc hl			;86e0
	ret			;86e1
cero_blanco:		; Un 0 a la izquierda: en blanco (0xF0 - 0x30 = espacio), salvo la ultima cifra
	ld a,d			;86e2   ; la ultima cifra...
	cp 003h		;86e3
	ld a,000h		;86e5   ; ...siempre se ve
	jr z,cero_fin		;86e7
	ld a,c			;86e9   ; ya hay cifras?
	or a			;86ea
	ld a,000h		;86eb
	jr nz,cero_fin		;86ed
	ld a,0f0h		;86ef   ; no: 0xF0 + 0x30 = espacio
cero_fin:
	ret			;86f1
juego:		; Un cuadro del juego (desde la interrupcion): la demostracion, el lanzador, el centro, las bolas, el marcador y el final
	ld a,(0ec5eh)		;86f2   ; la demostracion
	ld b,a			;86f5   ; B = la demostracion
	ld a,(0ed28h)		;86f6   ; un cuadro mas
	inc a			;86f9
	ld (0ed28h),a		;86fa   ; en 0xED28
	jr nz,juego_demo		;86fd   ; cada 256 cuadros...
	ld a,b			;86ff   ; ...en la demostracion...
	or a			;8700
	jr z,juego_demo		;8701
	inc a			;8703   ; ...una cuenta mas...
	ld (0ec5eh),a		;8704   ; en 0xEC5E
	cp 00ah		;8707   ; ...a la 10...
	jr c,juego_demo		;8709
	ld a,002h		;870b   ; ...se acaba (2)
	ld (0efffh),a		;870d   ; en 0xEFFF
juego_demo:		; En la demostracion, el boton 1 la acaba
	ld a,b			;8710
	or a			;8711
	jr z,juego_cuadro		;8712
	call boton1		;8714   ; el boton 1
	ld a,(0ed25h)		;8717
	or a			;871a
	jr z,juego_cuadro		;871b
	ld a,002h		;871d   ; se acaba (2)
	ld (0efffh),a		;871f
	ret			;8722
juego_cuadro:		; Las partes del cuadro
	call lanzador		;8723   ; el lanzador y la bola nueva
	call centro		;8726   ; el centro abierto o cerrado
	call tragaperras		;8729   ; el tragaperras
	call bolas		;872c   ; las bolas
	call molinillos		;872f   ; los molinillos
	call ovnis		;8732   ; los OVNIs de la maquina 2
	call sprites		;8735   ; los sprites
	call luces		;8738   ; las luces
	call tulipanes		;873b   ; los tulipanes
	call bandeja_pinta		;873e   ; la bandeja en la pantalla
	ld a,(0ec50h)		;8741   ; el record llega a 100.000?...
	cp 010h		;8744   ; 0x10 en el byte alto (BCD): 100.000
	jr c,juego_diez		;8746
	ld a,003h		;8748   ; ...se acaba la partida (3)...
	ld (0efffh),a		;874a   ; en 0xEFFF
	ld a,099h		;874d   ; ...con 99.999 (se ven cinco cifras)...
	ld (0ec52h),a		;874f   ; las otras dos...
	ld (0ec51h),a		;8752
	ld a,009h		;8755
	ld (0ec50h),a		;8757   ; ...99.999
	call pinta_record		;875a   ; ...en la pantalla
	call pinta_puntos		;875d   ; los puntos
juego_diez:		; Con 10 bolas justas (LD HL lee el BCD al reves: 0x1000 son 0x00 0x10), nada de final: la bola que entra sin bolas salva la partida
	ld hl,(0ed2eh)		;8760   ; las bolas...
	ld de,01000h		;8763   ; ...10? (0x00 0x10 leido al reves)
	or a			;8766
	sbc hl,de		;8767   ; la resta
	jr nz,juego_9000		;8769
	xor a			;876b
	ld (0ed2ah),a		;876c   ; sin final
juego_9000:		; 9000 o mas: vuelven a 0 (y sin bolas, GAME OVER)
	ld a,(0ed2eh)		;876f   ; el byte alto
	cp 090h		;8772   ; 9000?
	jr c,juego_sin_bolas		;8774
	ld hl,00000h		;8776   ; a 0
	ld (0ed2eh),hl		;8779
	call pinta_bolas		;877c   ; en la pantalla
juego_sin_bolas:		; Sin bolas: el final 2 (GAME OVER)
	ld hl,(0ed2eh)		;877f   ; las bolas...
	ld a,h			;8782   ; ...son 0?
	or l			;8783
	jr nz,juego_objetivo		;8784
	ld a,002h		;8786   ; el final 2
	ld (0ed2ah),a		;8788
	jr juego_final		;878b
juego_objetivo:		; Mas bolas que el objetivo y sin premio en marcha: el final 1 (CLEAR); la maquina 2 no tiene objetivo
	ld a,(0ec5ah)		;878d   ; la maquina 2?
	cp 002h		;8790
	jr z,juego_final		;8792
	ld de,(0ed2eh)		;8794   ; las bolas, con los bytes al reves (BCD)
	ld a,d			;8798   ; los bytes cambiados
	ld d,e			;8799
	ld e,a			;879a
	ld hl,(0ed2ch)		;879b   ; el objetivo
	ld a,h			;879e   ; los del objetivo, cambiados
	ld h,l			;879f
	ld l,a			;87a0
	or a			;87a1   ; el objetivo menos las bolas
	sbc hl,de		;87a2   ; objetivo - bolas
	jr nc,juego_final		;87a4   ; aun no
	ld a,(0ec80h)		;87a6   ; hay premio en marcha?
	or a			;87a9   ; en marcha: espera
	jr nz,juego_final		;87aa
	inc a			;87ac   ; el final 1
	ld (0ed2ah),a		;87ad
juego_final:		; Con un final pendiente: cuando no queda ninguna bola en juego (o pasan 192 cuadros), a 0xEFFF
	ld a,(0ed2ah)		;87b0   ; hay final pendiente?
	or a			;87b3
	ret z			;87b4
	ld a,(0ed32h)		;87b5   ; la cuenta del final (0xED32): no vuelve a 0 hasta la maquina siguiente, ni despues de la bola que salva
	inc a			;87b8   ; un cuadro mas...
	ld (0ed32h),a		;87b9
	cp 0c0h		;87bc   ; ...192?
	jr nc,juego_final_va		;87be
	ld hl,0ece4h		;87c0   ; las ocho bolas...
	ld de,00008h		;87c3   ; de 8 en 8 bytes
	ld b,008h		;87c6   ; ocho bolas
	xor a			;87c8
juego_final_bola:		; ...alguna en juego?
	or (hl)			;87c9   ; el estado
	add hl,de			;87ca
	djnz juego_final_bola		;87cb
	ret nz			;87cd   ; alguna: espera
juego_final_va:		; El final
	ld a,(0ed2ah)		;87ce   ; el final...
	ld (0efffh),a		;87d1   ; ...a 0xEFFF
	ret			;87d4
bandeja_pinta:		; Cada 16 cuadros, una casilla de la bandeja de abajo: el sitio, las bolas en binario entre 16 (0-10); la capa, entre 256 (0-4)
	ld a,(0ed28h)		;87d5   ; cada 16 cuadros
	and 00fh		;87d8   ; cada 16 cuadros
	ret nz			;87da
	ld a,(0ec5ah)		;87db   ; la maquina 2 no
	cp 002h		;87de   ; la maquina 2?
	ret z			;87e0
	ld a,(0ec7eh)		;87e1   ; el byte alto de las bolas en binario (0xEC7E): las capas...
	cp 005h		;87e4   ; ...no mas de 4
	jr c,bandeja_casilla		;87e6
	ld a,004h		;87e8   ; 4
bandeja_casilla:		; La casilla de la tabla 0xA4E7...
	ld c,a			;87ea
	ld b,000h		;87eb
	ld hl,0a4e7h		;87ed   ; la tabla
	add hl,bc			;87f0
	ld a,(hl)			;87f1
	ld d,a			;87f2   ; en D
	ld a,(0ec7dh)		;87f3   ; ...y las bolas entre 16...
	rrca			;87f6   ; las bolas entre 16...
	rrca			;87f7
	rrca			;87f8
	rrca			;87f9
	and 00fh		;87fa
	cp 00bh		;87fc   ; ...no mas de 10...
	jr c,bandeja_sitio		;87fe
	ld a,00ah		;8800   ; 10
bandeja_sitio:		; ...el sitio en la pantalla
	ld c,a			;8802
	ld b,000h		;8803
	ld hl,01ac8h		;8805   ; la columna del lanzador, fila 22
	add hl,bc			;8808
	ld a,l			;8809   ; par o impar...
	and 001h		;880a
	add a,d			;880c   ; ...se suma a la casilla
	cp 021h		;880d   ; 0x21?
	jr nz,bandeja_pon		;880f
	dec a			;8811   ; 0x20
bandeja_pon:		; WRTVRM
	jp 0004dh		;8812
molinillos:		; Los cuatro molinillos (0xEC64, 6 bytes): mientras les queda cuenta, giran mas deprisa al principio
	ld a,(0ec5ah)		;8815   ; la maquina 2 no tiene
	cp 002h		;8818   ; la maquina 2?
	ret z			;881a
	ld b,004h		;881b   ; cuatro
	ld hl,0ec64h		;881d   ; la cuenta del primero
molinillo:		; Uno: le queda cuenta?
	push hl			;8820
	ld a,(hl)			;8821
	or a			;8822
	jr z,molinillo_sig		;8823
	dec a			;8825   ; una menos
	ld (hl),a			;8826   ; una menos
	rlca			;8827   ; los dos bits altos: lo que gira
	rlca			;8828   ; los dos bits altos de la cuenta...
	rlca			;8829
	and 003h		;882a
	ld d,a			;882c   ; ...en D: lo que avanza
	inc hl			;882d   ; el dibujo
	inc hl			;882e
	inc hl			;882f
	ld a,(hl)			;8830   ; el dibujo...
	add a,d			;8831   ; ...gira (de 0 a 7)
	and 007h		;8832   ; de 0 a 7
	ld (hl),a			;8834
molinillo_sig:		; El siguiente
	pop hl			;8835
	ld de,00006h		;8836   ; el siguiente, 6 bytes mas alla
	add hl,de			;8839
	djnz molinillo		;883a   ; los cuatro
	ret			;883c
cuenta_ix:		; Una cuenta menos en IX+3; a 0, IX+0 = 4 y otra vez 40
	ld a,(ix+003h)		;883d
	dec a			;8840   ; una menos
	ld (ix+003h),a		;8841
	ret nz			;8844   ; aun no
	ld (ix+000h),004h		;8845   ; estado 4...
	ld (ix+003h),028h		;8849   ; ...y otra vez 40
	ret			;884d
ovnis:		; La maquina 2: cada cuatro cuadros, los cinco OVNIs (0xECC5, 5 bytes) se mueven segun su estado
	ld a,(0ec5ah)		;884e   ; solo la maquina 2
	cp 002h		;8851   ; la maquina 2?
	ret nz			;8853
	ld a,(0ed28h)		;8854   ; cada 4 cuadros
	and 003h		;8857   ; cada 4 cuadros
	ret nz			;8859
	ld ix,0ecc5h		;885a   ; los cinco OVNIs
	ld a,005h		;885e   ; cinco
ovni:		; Uno: su estado
	push af			;8860
	ld a,(ix+000h)		;8861   ; el estado
	or a			;8864
	jr z,ovni_sig		;8865   ; 0: quieto
	dec a			;8867
	jr z,ovni_derecha		;8868   ; 1: a la derecha
	dec a			;886a
	jr z,ovni_izquierda		;886b   ; 2: a la izquierda
	dec a			;886d
	jr z,ovni_espera		;886e   ; 3: espera
	ld a,(ix+003h)		;8870   ; 4 o mas: una cuenta...
	dec a			;8873
	ld (ix+003h),a		;8874   ; la cuenta
	jr nz,ovni_sig		;8877
	ld a,r		;8879   ; ...y al azar a 1 o a 2
	and 001h		;887b   ; 1 o 2
	inc a			;887d
	ld (ix+000h),a		;887e
	ld (ix+003h),a		;8881   ; la cuenta
	jr ovni_sig		;8884
ovni_espera:		; Estado 3: la cuenta
	call cuenta_ix		;8886   ; la cuenta
	jr ovni_sig		;8889
ovni_izquierda:		; Estado 2: a la izquierda; en X 0x30, a la derecha
	ld a,(ix+002h)		;888b   ; la X...
	sub (ix+004h)		;888e   ; ...menos la velocidad...
	dec a			;8891
	ld (ix+002h),a		;8892
	cp 030h		;8895   ; ...0x30?
	jr nc,ovni_dibujo		;8897
	ld (ix+000h),001h		;8899   ; a la derecha
	jr ovni_dibujo		;889d
ovni_derecha:		; Estado 1: a la derecha; en X 0x90, a la izquierda
	ld a,(ix+002h)		;889f   ; la X...
	add a,(ix+004h)		;88a2   ; ...mas la velocidad...
	inc a			;88a5
	ld (ix+002h),a		;88a6
	cp 090h		;88a9   ; ...0x90?
	jr c,ovni_dibujo		;88ab
	ld (ix+000h),002h		;88ad   ; a la izquierda
ovni_dibujo:		; Cada 8 cuadros, el dibujo siguiente (0-3)
	ld a,(0ed28h)		;88b1   ; cada 8 cuadros
	and 007h		;88b4
	jr nz,ovni_sig		;88b6
	ld a,(ix+003h)		;88b8   ; el dibujo...
	inc a			;88bb   ; ...siguiente, de 0 a 3
	and 003h		;88bc
	ld (ix+003h),a		;88be
ovni_sig:		; El siguiente
	ld bc,00005h		;88c1   ; el siguiente, 5 bytes mas alla
	add ix,bc		;88c4
	pop af			;88c6
	dec a			;88c7   ; los cinco
	jr nz,ovni		;88c8
	ld a,(ix+000h)		;88ca   ; el sexto: el OVNI grande
	or a			;88cd   ; el OVNI grande: su estado
	ret z			;88ce
	dec a			;88cf   ; 1: a la derecha
	jr z,ovni_grande_der		;88d0
	dec a			;88d2   ; 2: a la izquierda
	jr z,ovni_grande_izq		;88d3
	call cuenta_ix		;88d5   ; 3: estallando, la cuenta
	ld a,(ix+003h)		;88d8
	cp 028h		;88db   ; al final de la cuenta...
	ret nc			;88dd
	ld a,001h		;88de   ; ...el final 1: CLEAR
	ld (0efffh),a		;88e0
	ret			;88e3
ovni_grande_izq:		; A la izquierda hasta 0x44
	dec (ix+002h)		;88e4   ; la X, uno menos
	ld a,(ix+002h)		;88e7
	cp 044h		;88ea   ; 0x44?
	jr nc,ovni_grande_dibujo		;88ec
	ld (ix+000h),001h		;88ee   ; a la derecha
	jr ovni_grande_dibujo		;88f2
ovni_grande_der:		; A la derecha hasta 0x74
	inc (ix+002h)		;88f4   ; la X, uno mas
	ld a,(ix+002h)		;88f7
	cp 074h		;88fa   ; 0x74?
	jr c,ovni_grande_dibujo		;88fc
	ld (ix+000h),002h		;88fe   ; a la izquierda
ovni_grande_dibujo:		; Su dibujo cada 4 cuadros
	ld a,(0ed28h)		;8902   ; cada 4 cuadros
	and 003h		;8905
	jr nz,ovni_grande_altura		;8907
	ld a,(ix+003h)		;8909   ; el dibujo...
	inc a			;890c   ; ...siguiente, de 0 a 3
	and 003h		;890d
	ld (ix+003h),a		;890f
ovni_grande_altura:		; Su altura, de la tabla 0x8927 (32 pasos)
	ld a,(ix+005h)		;8912   ; el paso de la altura...
	inc a			;8915   ; ...de 0 a 31
	and 01fh		;8916
	ld (ix+005h),a		;8918
	ld c,a			;891b
	ld b,000h		;891c
	ld hl,08927h		;891e   ; la tabla
	add hl,bc			;8921
	ld a,(hl)			;8922
	ld (ix+001h),a		;8923   ; la Y
	ret			;8926

; ----------------------------------------------------------------------
; DATOS ovni_alturas: Las 32 alturas del OVNI grande: sube y baja
;   0x8927..0x8947  (32 bytes)
DATA_ovni_alturas:
	defb 088h,086h,084h,083h,082h,081h,080h,080h,080h,081h,082h,083h,084h,086h,088h,089h	; 8927  ................
	defb 08ah,08ah,08bh,08ch,08dh,08fh,08fh,08fh,08eh,08eh,08dh,08ch,08bh,08ah,089h,088h	; 8937  ................

; ======================================================================
; CODIGO 0x8947..0x8bb3  (620 bytes)
; ======================================================================


cifra_azar:		; Una cifra al azar para el tragaperras: la casilla 0x7B-0x84 (0-9)
	ld a,r		;8947   ; el registro R...
	ld b,a			;8949   ; en B
	ld a,(0ec54h)		;894a   ; ...mas la semilla...
	add a,b			;894d   ; sumados
	ld b,a			;894e
	add a,a			;894f   ; ...x 5 + 13
	add a,a			;8950   ; x 4...
	add a,b			;8951   ; ...+ 1: x 5
	add a,00dh		;8952
	ld (0ec54h),a		;8954   ; la semilla nueva
	or a			;8957
	daa			;8958   ; en BCD, las unidades
	and 00fh		;8959   ; de 0 a 9...
	add a,07bh		;895b   ; ...la casilla de la cifra
	ret			;895d
tragaperras:		; La maquina 1: el tragaperras del centro; gira mientras tiene tiradas y el boton 2 lo para
	ld a,(0ec5ah)		;895e   ; solo la maquina 1
	cp 001h		;8961   ; la maquina 1?
	ret nz			;8963
	ld a,(0ec81h)		;8964   ; sin premio en marcha
	or a			;8967   ; premio en marcha?
	ret nz			;8968
	ld a,(0ed28h)		;8969   ; cada 4 cuadros
	and 003h		;896c   ; cada 4 cuadros
	ret nz			;896e
	ld a,(0ec84h)		;896f   ; tiradas?
	or a			;8972   ; ninguna tirada
	ret z			;8973
	ld a,(0ec85h)		;8974   ; la cuenta del giro
	dec a			;8977   ; la cuenta, una menos (de 0 a 0x7F)
	and 07fh		;8978
	ld (0ec85h),a		;897a
	cp 070h		;897d   ; 0x70 o mas: aun no gira
	ret nc			;897f
	cp 06fh		;8980   ; al empezar, el sonido del giro (0x9FC7)
	jr nz,tragaperras_fin		;8982   ; 0x6F: empieza
	push af			;8984
	ld b,000h		;8985   ; el canal 0...
	ld de,09fc7h		;8987
	call pieza		;898a   ; ...el giro
	pop af			;898d
tragaperras_fin:		; A 0: una tirada menos y el sonido de parar
	or a			;898e   ; 0: se para
	jr nz,tragaperras_cifras		;898f
	ld a,(0ec84h)		;8991   ; una tirada menos
	dec a			;8994
	ld (0ec84h),a		;8995
	ld b,000h		;8998   ; el canal 0...
	ld de,0be5bh		;899a   ; ...callado
	call pieza		;899d
tragaperras_cifras:		; Las tres cifras: la primera gira hasta la cuenta 16, la segunda hasta la 8, la tercera hasta 0
	ld hl,0198ch		;89a0   ; la fila 12, columna 12
	ld a,(0ec85h)		;89a3
	cp 010h		;89a6   ; la primera gira hasta la cuenta 16
	jr c,tragaperras_2		;89a8
	call cifra_azar		;89aa
	ld (0ec86h),a		;89ad   ; la primera cifra...
	call 0004dh		;89b0   ; ...en la pantalla
tragaperras_2:		; La segunda
	inc hl			;89b3
	ld a,(0ec85h)		;89b4
	cp 008h		;89b7   ; la segunda hasta la 8
	jr c,tragaperras_3		;89b9
	call cifra_azar		;89bb
	ld (0ec87h),a		;89be   ; la segunda
	call 0004dh		;89c1
tragaperras_3:		; La tercera
	inc hl			;89c4
	call cifra_azar		;89c5   ; la tercera hasta el final
	ld (0ec88h),a		;89c8   ; la tercera
	call 0004dh		;89cb
	ld a,(0ec85h)		;89ce   ; parada?
	cp 011h		;89d1   ; la cuenta pasa de 17?
	jr c,tragaperras_premio		;89d3
	call boton2		;89d5   ; el boton 2...
	ld a,(0ed26h)		;89d8   ; el boton 2?
	or a			;89db
	jr z,tragaperras_premio		;89dc
	ld a,011h		;89de   ; ...para las tres: la cuenta a 17
	ld (0ec85h),a		;89e0   ; la cuenta a 17: se paran en orden
	ret			;89e3
tragaperras_premio:		; Paradas: cuantas cifras son 6 o mas; una da 1 apertura, dos dan 6 y tres el premio gordo (0x80)
	ld a,(0ec85h)		;89e4   ; parado del todo?
	or a			;89e7
	ret nz			;89e8
	ld hl,0ec86h		;89e9   ; las tres cifras
	ld d,000h		;89ec   ; ninguna aun
	ld b,081h		;89ee   ; 0x81: la casilla del 6
	ld a,(hl)			;89f0   ; la primera...
	inc hl			;89f1
	cp b			;89f2   ; ...6 o mas?
	jr c,tragaperras_premio2		;89f3
	inc d			;89f5   ; una
tragaperras_premio2:
	ld a,(hl)			;89f6   ; la segunda
	inc hl			;89f7
	cp b			;89f8
	jr c,tragaperras_premio3		;89f9
	inc d			;89fb   ; una mas
tragaperras_premio3:
	ld a,(hl)			;89fc   ; la tercera
	inc hl			;89fd
	cp b			;89fe
	jr c,tragaperras_cuenta		;89ff
	inc d			;8a01   ; una mas
tragaperras_cuenta:		; Ninguna: nada
	xor a			;8a02
	or d			;8a03   ; ninguna?
	ret z			;8a04
	ld a,d			;8a05
	cp 001h		;8a06   ; una: 1 apertura
	jr z,tragaperras_abre		;8a08
	cp 002h		;8a0a   ; dos: 6 aperturas
	jr nz,tragaperras_gordo		;8a0c
	ld a,006h		;8a0e
	jr tragaperras_abre		;8a10
tragaperras_gordo:		; Las tres: el sonido (0xBE49) y 0x80 aperturas
	ld b,000h		;8a12
	ld de,0be49h		;8a14   ; el canal 0: el sonido del premio gordo
	call pieza		;8a17
	ld a,080h		;8a1a   ; 0x80 aperturas
tragaperras_abre:		; Las aperturas, el premio en marcha y 8 cuadros
	ld b,a			;8a1c
	ld a,(0ec81h)		;8a1d   ; las aperturas...
	add a,b			;8a20   ; ...mas B
	ld (0ec81h),a		;8a21
	ld a,001h		;8a24   ; el premio en marcha
	ld (0ec80h),a		;8a26
	ld (0ed33h),a		;8a29   ; y su cuenta
	ld a,008h		;8a2c   ; 8 cuadros
	ld (0ec83h),a		;8a2e
	ret			;8a31
centro:		; El centro: abierto o cerrado cada 48 cuadros mientras queden aperturas
	ld a,(0ec7fh)		;8a32   ; abierto?
	or a			;8a35
	jr nz,centro_cuenta		;8a36
	ld a,(0ec80h)		;8a38   ; premio en marcha?
	or a			;8a3b
	jr nz,centro_cuenta		;8a3c
	ld a,008h		;8a3e   ; nada: 8 cuadros
	ld (0ec83h),a		;8a40
	ret			;8a43
centro_cuenta:		; Un cuadro menos
	ld a,(0ec83h)		;8a44
	dec a			;8a47   ; un cuadro menos
	ld (0ec83h),a		;8a48
	or a			;8a4b
	ret nz			;8a4c
	call centro_cambia		;8a4d   ; abre o cierra
	ld a,(0ec7fh)		;8a50   ; ahora abierto?
	or a			;8a53
	jr z,centro_suena		;8a54
	ld a,(0ec81h)		;8a56   ; cerrado: una apertura menos
	dec a			;8a59
	ld (0ec81h),a		;8a5a
	jr centro_fin		;8a5d
centro_suena:		; Al abrir, el sonido (0xBDF2, canal 2)
	ld b,002h		;8a5f   ; abierto: el canal 2...
	ld de,0bdf2h		;8a61   ; ...el sonido
	call pieza		;8a64
centro_fin:		; Sin aperturas: el premio acaba (0xBE5B) y el centro se cierra
	ld a,(0ec81h)		;8a67   ; quedan?
	or a			;8a6a
	ret nz			;8a6b
	ld (0ec82h),a		;8a6c   ; no: sin premio
	ld (0ec80h),a		;8a6f
	ld b,a			;8a72   ; el canal 0...
	ld de,0be5bh		;8a73   ; ...callado
	call pieza		;8a76
	jp lamparas_apaga		;8a79   ; y las lamparas apagadas
centro_cambia:		; Abre o cierra: el dibujo del centro segun la maquina
	ld a,(0ec7fh)		;8a7c   ; abierto o cerrado...
	inc a			;8a7f
	and 001h		;8a80   ; ...al reves
	ld (0ec7fh),a		;8a82
	ld b,a			;8a85
	ld a,030h		;8a86   ; 48 cuadros
	ld (0ec83h),a		;8a88
	ld a,080h		;8a8b   ; las luces 128 cuadros
	ld (0ed29h),a		;8a8d
	ld a,(0ec5ah)		;8a90   ; la maquina
	or a			;8a93
	jr z,centro_maq0		;8a94
	cp 002h		;8a96   ; el 2 no tiene centro
	ret z			;8a98
	ld a,b			;8a99   ; abierto?
	or a			;8a9a
	jr z,centro_maq1		;8a9b
	ld a,003h		;8a9d   ; tres filas...
	ld hl,098f9h		;8a9f   ; ...del centro abierto
	call centro_pinta		;8aa2
	jp clavos_centro_abierto1		;8aa5   ; y en el mapa
centro_maq1:		; La maquina 1: a las 30 aperturas se acaba
	ld a,(0ed33h)		;8aa8   ; una vez mas cerrado...
	inc a			;8aab
	ld (0ed33h),a		;8aac
	cp 01eh		;8aaf   ; ...30?
	jr c,centro_maq1_va		;8ab1
	xor a			;8ab3   ; se acaba el premio
	ld (0ec81h),a		;8ab4
centro_maq1_va:
	ld a,(0ec81h)		;8ab7   ; 6 aperturas o mas: sigue abierto
	cp 006h		;8aba
	jr c,centro_maq1_dibujo		;8abc
	ret			;8abe
centro_maq1_dibujo:
	ld a,003h		;8abf   ; tres filas...
	ld hl,09914h		;8ac1   ; ...del centro cerrado
	call centro_pinta		;8ac4
	jp clavos_centro_cerrado1		;8ac7   ; y en el mapa
centro_maq0:		; La maquina 0
	ld a,b			;8aca   ; abierto?
	or a			;8acb
	jr z,centro_maq0_cerrado		;8acc
	ld a,004h		;8ace   ; cuatro filas del abierto
	ld hl,098b1h		;8ad0
	call centro_pinta		;8ad3
	jp clavos_centro_abierto0		;8ad6   ; y en el mapa
centro_maq0_cerrado:
	ld a,004h		;8ad9   ; cuatro filas del cerrado
	ld hl,098d5h		;8adb
	call centro_pinta		;8ade
	call clavos_centro_cerrado0		;8ae1   ; y en el mapa
	ld ix,0ece4h		;8ae4   ; las ocho bolas
	ld a,008h		;8ae8
centro_bolas:		; Las bolas que estan en el centro al cerrarse salen a un lado o al otro
	push af			;8aea
	ld a,(ix+001h)		;8aeb   ; la Y...
	cp 044h		;8aee   ; ...entre 0x44...
	jr c,centro_bola_sig		;8af0
	cp 04ch		;8af2   ; ...y 0x4B
	jr nc,centro_bola_sig		;8af4
	ld a,(ix+002h)		;8af6   ; la X...
	cp 024h		;8af9   ; ...entre 0x24...
	jr c,centro_bola_sig		;8afb
	cp 06ch		;8afd   ; ...y 0x6B
	jr nc,centro_bola_sig		;8aff
	cp 048h		;8b01   ; la mitad izquierda?
	jr c,centro_bola_izq		;8b03
	ld (ix+002h),050h		;8b05   ; a la derecha (X 0x50)
	jr centro_bola_sig		;8b09
centro_bola_izq:
	ld (ix+002h),03bh		;8b0b   ; a la izquierda (X 0x3B)
centro_bola_sig:		; La siguiente
	ld bc,00008h		;8b0f   ; la siguiente
	add ix,bc		;8b12
	pop af			;8b14
	dec a			;8b15
	jr nz,centro_bolas		;8b16
	ret			;8b18
lanzador:		; El lanzador: el boton 1 sostenido carga la fuerza (hasta 15); al soltarlo, sale una bola
	ld a,(0ec7ch)		;8b19   ; hay una bola saliendo?
	cp 001h		;8b1c   ; saliendo: baja la fuerza
	jr z,lanzador_baja		;8b1e
	ld a,(0ec5eh)		;8b20   ; la demostracion...
	or a			;8b23   ; la demostracion?
	jr z,L_8B2C		;8b24
	ld a,r		;8b26   ; ...pulsa al azar
	and 078h		;8b28   ; una fuerza al azar
	jr lanzador_boton		;8b2a
L_8B2C:
	call boton1		;8b2c   ; el boton 1
	ld a,(0ed25h)		;8b2f
lanzador_boton:		; Pulsado: la fuerza, uno mas
	or a			;8b32
	jr z,lanzador_suelta		;8b33
	ld a,(0ec7bh)		;8b35   ; la fuerza...
	inc a			;8b38   ; ...uno mas...
	cp 010h		;8b39   ; ...16?
	jr nz,lanzador_fuerza		;8b3b
	dec a			;8b3d   ; 15
lanzador_fuerza:
	ld (0ec7bh),a		;8b3e
	ret			;8b41
lanzador_suelta:		; Suelto: con fuerza y sin final, una bola nueva en un hueco libre
	ld a,(0ed2ah)		;8b42   ; hay final pendiente?
	or a			;8b45
	ret nz			;8b46
	ld a,(0ec7bh)		;8b47   ; sin fuerza?
	or a			;8b4a
	ret z			;8b4b
	ld a,001h		;8b4c   ; sale una bola
	ld (0ec7ch),a		;8b4e
	ld b,008h		;8b51   ; ocho huecos
	ld hl,0ece4h		;8b53   ; los huecos
	ld de,00008h		;8b56
lanzador_hueco:		; Un hueco libre?
	ld a,(hl)			;8b59
	or a			;8b5a   ; ocupado?
	jr nz,lanzador_sig		;8b5b
	ld (hl),0ech		;8b5d   ; el estado
	inc hl			;8b5f
	ld (hl),01dh		;8b60   ; la Y
	inc hl			;8b62
	ld (hl),00eh		;8b63   ; la X
	inc hl			;8b65
	ld (hl),008h		;8b66   ; el dibujo
	inc hl			;8b68
	ld a,(0ec7bh)		;8b69   ; la velocidad: hacia arriba con la fuerza...
	ld b,a			;8b6c
	neg		;8b6d   ; hacia arriba: -fuerza
	ld (hl),a			;8b6f
	inc hl			;8b70
	inc b			;8b71   ; ...y hacia el lado
	inc b			;8b72   ; hacia el lado: fuerza + 2
	ld (hl),b			;8b73
	call bola_menos		;8b74   ; una bola menos
	jr lanzador_baja		;8b77
lanzador_sig:		; La maquina 2 solo tiene una bola
	ld a,(0ec5ah)		;8b79   ; la maquina 2: una bola cada vez
	cp 002h		;8b7c
	jr z,lanzador_baja		;8b7e
	add hl,de			;8b80   ; el hueco siguiente
	djnz lanzador_hueco		;8b81
lanzador_baja:		; La fuerza baja de 4 en 4 hasta 0
	ld a,(0ec7bh)		;8b83
	sub 004h		;8b86   ; 4 menos...
	cp 080h		;8b88   ; ...menos de 0?
	jr c,lanzador_fuerza_pon		;8b8a
	xor a			;8b8c   ; 0: ya no sale
	ld (0ec7ch),a		;8b8d
lanzador_fuerza_pon:
	ld (0ec7bh),a		;8b90
	ret			;8b93
marcas:		; Tres marcas de 3 x 2 casillas en la pantalla (0x8BB3) y sus sprites
	ld de,0e904h		;8b94   ; la marca 1: en el mapa...
	exx			;8b97
	ld de,01a28h		;8b98   ; ...y en la pantalla (fila 17, columna 8)
	call marca		;8b9b
	ld de,0e90ch		;8b9e   ; la 2
	exx			;8ba1
	ld de,01a30h		;8ba2
	call marca		;8ba5
	ld de,0e998h		;8ba8   ; la 3
	exx			;8bab
	ld de,01a4ch		;8bac
	call marca		;8baf
	ret			;8bb2

; ----------------------------------------------------------------------
; DATOS marca_casillas: Las seis casillas de la marca
;   0x8bb3..0x8bb9  (6 bytes)
DATA_marca_casillas:
	defb 08ah,06eh,08bh	; 8bb3
	defb 088h,06fh,089h	; 8bb6

; ======================================================================
; CODIGO 0x8bb9..0x8be4  (43 bytes)
; ======================================================================


marca:		; Una: dos filas de tres casillas
	ld hl,08bb3h		;8bb9   ; las casillas
	ld bc,00003h		;8bbc
	push hl			;8bbf
	push de			;8bc0
	call 0005ch		;8bc1   ; la fila de arriba
	pop de			;8bc4
	pop hl			;8bc5
	ld bc,00020h		;8bc6   ; la de abajo
	ex de,hl			;8bc9
	add hl,bc			;8bca
	ex de,hl			;8bcb
	ld bc,00003h		;8bcc
	add hl,bc			;8bcf
	call 0005ch		;8bd0   ; ...LDIRVM
	exx			;8bd3   ; y el poste en el mapa
	jp clavos_poste		;8bd4
marca1:
	ld hl,08be4h		;8bd7   ; tres casillas
	ld bc,00003h		;8bda
	call 0005ch		;8bdd
	exx			;8be0
	jp clavos_tulipan1		;8be1   ; y el tulipan en el mapa

; ----------------------------------------------------------------------
; DATOS marca1_casillas: Las casillas de la marca
;   0x8be4..0x8be7  (3 bytes)
DATA_marca1_casillas:
	defb 08ah,06eh,08bh	; 8be4

; ======================================================================
; CODIGO 0x8be7..0x8bf4  (13 bytes)
; ======================================================================


marca2:
	ld hl,08bf4h		;8be7   ; tres casillas
	ld bc,00003h		;8bea
	call 0005ch		;8bed
	exx			;8bf0
	jp clavos_tulipan2		;8bf1

; ----------------------------------------------------------------------
; DATOS marca2_casillas: Las casillas de la marca
;   0x8bf4..0x8bf7  (3 bytes)
DATA_marca2_casillas:
	defb 08ch,070h,08dh	; 8bf4

; ======================================================================
; CODIGO 0x8bf7..0x8c04  (13 bytes)
; ======================================================================


marca3:
	ld hl,08c04h		;8bf7   ; tres casillas
	ld bc,00003h		;8bfa
	call 0005ch		;8bfd
	exx			;8c00
	jp clavos_tulipan3		;8c01

; ----------------------------------------------------------------------
; DATOS marca3_casillas: Las casillas de la marca
;   0x8c04..0x8c07  (3 bytes)
DATA_marca3_casillas:
	defb 08eh,070h,08fh	; 8c04

; ======================================================================
; CODIGO 0x8c07..0x9004  (1021 bytes)
; ======================================================================


sprites_dibujos:		; Los dibujos de los sprites (0x992F, 960 bytes) a 0x3800
	ld hl,0992fh		;8c07   ; 960 bytes...
	ld de,03800h		;8c0a   ; ...a 0x3800
	ld bc,003c0h		;8c0d
	call 0005ch		;8c10
	ret			;8c13
sprites:		; La tabla de sprites en la RAM (0xEBD0) y a la VRAM: el lanzador segun la fuerza, los molinillos o los OVNIs, y las bolas
	ld a,(0ec7bh)		;8c14   ; la fuerza x 2...
	add a,a			;8c17   ; x 2
	ld c,a			;8c18
	ld b,000h		;8c19
	ld hl,08193h		;8c1b   ; ...en la tabla 0x8193: la Y y la X del lanzador
	add hl,bc			;8c1e
	ld de,0ebd0h		;8c1f   ; el lanzador, el primer sprite
	ex de,hl			;8c22
	ld a,(de)			;8c23   ; la Y...
	ld (hl),a			;8c24
	inc hl			;8c25
	inc de			;8c26
	ld a,(de)			;8c27   ; ...la X
	ld (hl),a			;8c28
	inc hl			;8c29
	ld (hl),024h		;8c2a   ; el dibujo 0x24...
	inc hl			;8c2c
	ld (hl),001h		;8c2d   ; ...negro
	inc hl			;8c2f
	ld a,(0ec5ah)		;8c30   ; la maquina 2?
	cp 002h		;8c33   ; la maquina 2?
	jr z,sprites_ovnis		;8c35
	ld de,0ec63h		;8c37   ; los cuatro molinillos: Y, X, dibujo y color de cada uno (0xEC66)
	ld c,004h		;8c3a   ; cuatro molinillos
sprites_molinillo:		; Uno
	inc de			;8c3c
	inc de			;8c3d
	ld b,004h		;8c3e   ; Y, X, dibujo y color
sprites_molinillo_byte:		; Sus cuatro bytes
	ld a,(de)			;8c40
	ld (hl),a			;8c41
	inc hl			;8c42
	inc de			;8c43
	djnz sprites_molinillo_byte		;8c44
	dec c			;8c46   ; el siguiente
	jr nz,sprites_molinillo		;8c47
	jp sprites_bolas		;8c49   ; las bolas
sprites_ovnis:		; La maquina 2: los seis OVNIs (0xECC5, 5 bytes)
	ld iy,0ecc5h		;8c4c   ; seis OVNIs
	ld a,006h		;8c50
sprites_ovni:		; Uno: segun su estado
	push af			;8c52
	ld a,(iy+000h)		;8c53   ; su estado
	or a			;8c56   ; 0: no esta
	jp z,sprites_ovni_sig		;8c57
	cp 003h		;8c5a   ; 3: estallando
	jr z,sprites_ovni_estalla		;8c5c
	cp 004h		;8c5e   ; 4 o mas: no se ve
	jp nc,sprites_ovni_sig		;8c60
	ld a,(iy+004h)		;8c63   ; su forma: 0 pequeno, 1 mediano, 2 o mas grande
	or a			;8c66   ; 0: pequeno
	jp z,sprites_ovni_pequeno		;8c67
	dec a			;8c6a   ; 1: mediano
	jp z,sprites_ovni_mediano		;8c6b
	ld a,(iy+001h)		;8c6e   ; grande: tres sprites (dibujos 0x64/0x70 segun el paso)
	ld (hl),a			;8c71   ; la Y
	inc hl			;8c72
	ld a,(iy+002h)		;8c73   ; la X
	ld (hl),a			;8c76
	inc hl			;8c77
	ld a,(iy+003h)		;8c78   ; el paso
	and 001h		;8c7b
	ld a,064h		;8c7d   ; el dibujo 0x64...
	jr nz,sprites_ovni_grande		;8c7f
	ld a,070h		;8c81   ; ...o 0x70
sprites_ovni_grande:
	ld (hl),a			;8c83
	inc hl			;8c84
	ld b,a			;8c85
	ld (hl),005h		;8c86   ; el color 5
	inc hl			;8c88
	ld a,(iy+001h)		;8c89   ; el segundo, 16 pixeles a la derecha
	ld (hl),a			;8c8c
	inc hl			;8c8d
	ld a,(iy+002h)		;8c8e
	add a,010h		;8c91
	ld (hl),a			;8c93
	inc hl			;8c94
	ld a,b			;8c95   ; el dibujo + 4
	add a,004h		;8c96
	ld (hl),a			;8c98
	inc hl			;8c99
	ld (hl),005h		;8c9a
	inc hl			;8c9c
	ld a,(iy+001h)		;8c9d   ; el tercero, 8 a la derecha
	ld (hl),a			;8ca0
	inc hl			;8ca1
	ld a,(iy+002h)		;8ca2
	add a,008h		;8ca5
	ld (hl),a			;8ca7
	inc hl			;8ca8
	ld (hl),06ch		;8ca9   ; el dibujo 0x6C
	inc hl			;8cab
	call sprites_ovni_color		;8cac   ; su color
	ld (hl),a			;8caf
	inc hl			;8cb0
	jr sprites_ovni_sig		;8cb1
sprites_ovni_color:		; El color: el paso + 7, o 6
	ld a,(iy+003h)		;8cb3   ; el paso...
	add a,007h		;8cb6   ; ...+ 7...
	cp 007h		;8cb8   ; ...0 es 6
	ret nz			;8cba
	ld a,006h		;8cbb
	ret			;8cbd
sprites_ovni_estalla:		; Estallando: un sprite, dibujos 0x28-0x33 segun la cuenta
	ld a,(iy+001h)		;8cbe   ; la Y
	ld (hl),a			;8cc1
	inc hl			;8cc2
	ld a,(iy+002h)		;8cc3   ; la X
	ld (hl),a			;8cc6
	inc hl			;8cc7
	ld a,(iy+003h)		;8cc8   ; la cuenta x 2...
	add a,a			;8ccb
	and 00fh		;8ccc
	add a,028h		;8cce   ; ...el dibujo de 0x28 a 0x33
	cp 034h		;8cd0
	jr c,sprites_ovni_estalla_pon		;8cd2
	ld a,028h		;8cd4
sprites_ovni_estalla_pon:
	ld (hl),a			;8cd6   ; el dibujo
	inc hl			;8cd7
	call sprites_ovni_color		;8cd8
	ld (hl),a			;8cdb
	inc hl			;8cdc
	jr sprites_ovni_sig		;8cdd
sprites_ovni_mediano:		; Forma 1: tres sprites desde el dibujo 0x34 o 0x40, color 5
	ld e,005h		;8cdf   ; el color 5
	ld a,(iy+003h)		;8ce1   ; el paso: el dibujo 0x34...
	and 001h		;8ce4
	ld d,034h		;8ce6
	jr z,sprites_ovni_tres		;8ce8
	ld d,040h		;8cea   ; ...o 0x40
	jr sprites_ovni_tres		;8cec
sprites_ovni_pequeno:		; Forma 0: tres sprites desde el dibujo 0x4C o 0x58, color 13
	ld e,00dh		;8cee   ; el color 13
	ld a,(iy+003h)		;8cf0   ; el paso: el dibujo 0x4C...
	and 001h		;8cf3
	ld d,04ch		;8cf5
	jr z,sprites_ovni_tres		;8cf7
	ld d,058h		;8cf9   ; ...o 0x58
sprites_ovni_tres:		; Los tres sprites del OVNI: dibujo +4, dibujo y dibujo +8
	ld b,(iy+001h)		;8cfb   ; la Y y la X
	ld c,(iy+002h)		;8cfe
	ld (hl),b			;8d01
	inc hl			;8d02
	ld (hl),c			;8d03
	inc hl			;8d04
	ld a,d			;8d05   ; el primero: dibujo + 4, negro
	add a,004h		;8d06
	ld (hl),a			;8d08
	inc hl			;8d09
	ld (hl),001h		;8d0a
	inc hl			;8d0c
	ld (hl),b			;8d0d   ; el segundo: el dibujo, color E
	inc hl			;8d0e
	ld (hl),c			;8d0f
	inc hl			;8d10
	ld a,d			;8d11
	ld (hl),a			;8d12
	inc hl			;8d13
	ld (hl),e			;8d14
	inc hl			;8d15
	ld (hl),b			;8d16   ; el tercero: dibujo + 8
	inc hl			;8d17
	ld (hl),c			;8d18
	inc hl			;8d19
	ld a,d			;8d1a
	add a,008h		;8d1b
	ld (hl),a			;8d1d
	inc hl			;8d1e
	call sprites_ovni_color		;8d1f   ; con el color del paso
	ld (hl),a			;8d22
	inc hl			;8d23
sprites_ovni_sig:		; El siguiente
	ld bc,00005h		;8d24   ; el siguiente
	add iy,bc		;8d27
	pop af			;8d29
	dec a			;8d2a
	jp nz,sprites_ovni		;8d2b
sprites_bolas:		; Las bolas en juego (estado 1 a 0x3F): un sprite blanco cada una, desplazado a la pantalla (Y + 4, X + 0x24)
	ld c,008h		;8d2e   ; ocho bolas
	ld de,0ece4h		;8d30
sprites_bola:		; Una
	push de			;8d33
	ld a,(de)			;8d34   ; el estado
	inc de			;8d35
	or a			;8d36
	jr z,sprites_bola_sig		;8d37
	cp 040h		;8d39   ; 0x40 o mas: saliendo, no se ve
	jr nc,sprites_bola_sig		;8d3b
	ld a,(de)			;8d3d   ; la Y + 4
	add a,004h		;8d3e
	ld (hl),a			;8d40
	inc hl			;8d41
	inc de			;8d42
	ld a,(de)			;8d43   ; la X + 0x24
	add a,024h		;8d44
	ld (hl),a			;8d46
	inc hl			;8d47
	inc de			;8d48
	ld a,(de)			;8d49   ; el dibujo
	ld (hl),a			;8d4a
	inc hl			;8d4b
	inc de			;8d4c
	ld (hl),00fh		;8d4d   ; blanco
	inc hl			;8d4f
sprites_bola_sig:
	pop de			;8d50
	ld a,c			;8d51   ; la siguiente
	ld bc,00008h		;8d52
	ex de,hl			;8d55
	add hl,bc			;8d56
	ex de,hl			;8d57
	ld c,a			;8d58
	dec c			;8d59
	jr nz,sprites_bola		;8d5a
	ld (hl),0d0h		;8d5c   ; la marca de fin (0xD0)
	ld hl,0ebd0h		;8d5e   ; la tabla (0xEBD0)...
	ld de,01b00h		;8d61   ; ...a 0x1B00, 32 sprites
	ld bc,00080h		;8d64   ; 32 sprites
	call 0005ch		;8d67
	ret			;8d6a
bolas:		; Las ocho bolas (0xECE4, 8 bytes: estado, Y, X, dibujo, velocidad Y, velocidad X): 1 rueda, 2 dentro del centro, 3 cae en un agujero, 0x80 o mas sale del lanzador
	ld ix,0ece4h		;8d6b   ; las ocho bolas
	ld a,008h		;8d6f
bola:		; Una: su estado
	push af			;8d71
	ld a,(ix+000h)		;8d72   ; el estado
	ld b,a			;8d75
	or a			;8d76
	jp z,bola_sig		;8d77   ; 0: libre
	cp 001h		;8d7a
	jr z,bola_rueda		;8d7c   ; 1: rueda
	cp 002h		;8d7e
	jp z,bola_centro		;8d80   ; 2: en el centro
	cp 003h		;8d83
	jp z,bola_agujero_fin		;8d85   ; 3: en un agujero
	ld a,b			;8d88   ; 0x80 o mas: saliendo, una cuenta hasta 0 (y a 1)
	inc a			;8d89   ; la cuenta, uno mas...
	jr nz,bola_sale		;8d8a
	inc a			;8d8c   ; ...pasa de 0xFF: a 1, rueda
bola_sale:
	ld (ix+000h),a		;8d8d
	jp nz,bola_sig		;8d90
bola_rueda:		; Rueda: los clavos de alrededor (0x914A) la desvian; el sonido del clavo
	call clavos		;8d93   ; los clavos
	ld a,e			;8d96   ; ha tocado alguno?
	or d			;8d97   ; alguno?
	jr z,bola_choque_y		;8d98
	push de			;8d9a
	ld a,(0f124h)		;8d9b   ; el canal 1 libre?...
	and a			;8d9e   ; el canal 1 suena?
	jr nz,bola_choque		;8d9f
	ld b,001h		;8da1   ; ...el sonido (0xBE6F)
	ld de,0be6fh		;8da3   ; el clavo
	call pieza		;8da6
bola_choque:		; La desviacion a la mitad (al menos 1)
	pop de			;8da9
bola_choque_y:		; ...en Y
	ld a,e			;8daa   ; en Y...
	and a			;8dab
	jr z,bola_choque_x		;8dac
	sra e		;8dae   ; ...a la mitad
	jr nz,bola_choque_x		;8db0
	inc e			;8db2   ; al menos 1
bola_choque_x:		; ...en X
	ld a,d			;8db3   ; en X...
	and a			;8db4
	jr z,bola_y		;8db5
	sra d		;8db7   ; ...a la mitad
	jr nz,bola_y		;8db9
	inc d			;8dbb   ; al menos 1
bola_y:		; La velocidad Y: con la desviacion, rebota; y la gravedad (1, 2 por debajo de Y 0x18)
	ld a,e			;8dbc   ; choca en Y?
	and a			;8dbd
	ld a,(ix+004h)		;8dbe   ; la velocidad Y
	jr z,bola_y_gravedad		;8dc1
	and 083h		;8dc3   ; hacia abajo y grande?...
	jp p,bola_y_suma		;8dc5
	and 003h		;8dc8   ; ...a lo mas 3, hacia arriba: rebota
	neg		;8dca
bola_y_suma:
	add a,e			;8dcc   ; mas el choque
bola_y_gravedad:
	ld b,a			;8dcd
	ld a,(ix+001h)		;8dce   ; la Y...
	cp 018h		;8dd1   ; ...arriba de 0x18?
	ld a,001h		;8dd3   ; la gravedad: 1...
	jr c,bola_y_pon		;8dd5
	add a,a			;8dd7   ; ...o 2
bola_y_pon:		; La velocidad y la Y nueva (velocidad / 4)
	add a,b			;8dd8
	ld (ix+004h),a		;8dd9   ; la velocidad Y
	sra a		;8ddc   ; entre 4...
	sra a		;8dde
	add a,(ix+001h)		;8de0   ; ...mas la Y
	ld (ix+001h),a		;8de3
	ld a,d			;8de6   ; choca en X?
	and a			;8de7
	ld a,(ix+005h)		;8de8   ; la velocidad X
	jr z,bola_x		;8deb
	and 083h		;8ded   ; hacia la izquierda?...
	jp p,bola_x		;8def
	and 003h		;8df2   ; ...a lo mas 3, rebota
	neg		;8df4
bola_x:		; La velocidad X: rebote y un poco de azar en ciertas alturas
	add a,d			;8df6   ; mas el choque
	ld b,a			;8df7
	inc d			;8df8   ; choque en X?
	dec d			;8df9
	jr nz,bola_x_azar		;8dfa
	ld a,(ix+001h)		;8dfc   ; sin choque: la Y...
	cp 020h		;8dff   ; ...arriba de 0x20?
	jr c,bola_x_arriba		;8e01
bola_x_quieta:
	xor a			;8e03   ; abajo: nada
	jr bola_x_suma		;8e04
bola_x_arriba:
	ld a,(ix+002h)		;8e06   ; la X...
	cp 049h		;8e09   ; ...a la derecha de 0x49?
	jr nc,bola_x_quieta		;8e0b
	ld a,(0ed28h)		;8e0d   ; arriba a la izquierda: un poco a la derecha cada dos cuadros
	and 001h		;8e10
bola_x_suma:
	add a,b			;8e12
	ld b,a			;8e13
	jr bola_x_limite		;8e14
bola_x_azar:
	ld a,(ix+001h)		;8e16   ; con choque: la Y
	cp 018h		;8e19   ; arriba de 0x18: nada
	jr c,bola_x_limite		;8e1b
	cp 030h		;8e1d   ; entre 0x18 y 0x30: azar
	jr c,bola_x_azar_va		;8e1f
	cp 040h		;8e21   ; entre 0x30 y 0x40: nada
	jr c,bola_x_limite		;8e23
bola_x_azar_va:		; +2 o -2 al azar (el registro R)
	ld a,r		;8e25   ; el registro R...
	rrca			;8e27
	rrca			;8e28
	rrca			;8e29
	and 002h		;8e2a   ; ...+2 o -2
	dec a			;8e2c
	add a,a			;8e2d
	add a,b			;8e2e
	ld b,a			;8e2f
bola_x_limite:		; No mas de 11 a cada lado
	ld a,(ix+001h)		;8e30   ; la Y
	cp 018h		;8e33   ; arriba de 0x18: sin limite
	ld a,b			;8e35
	jr c,bola_x_pon		;8e36
	cp 00bh		;8e38   ; hasta 11...
	jr c,bola_x_pon		;8e3a
	cp 0f6h		;8e3c   ; ...o hasta -10
	jr nc,bola_x_pon		;8e3e
	and a			;8e40   ; que lado?
	jp m,bola_x_limite_izq		;8e41
	ld a,00bh		;8e44   ; 11
	jr bola_x_pon		;8e46
bola_x_limite_izq:
	ld a,0f6h		;8e48   ; -10
bola_x_pon:		; La X nueva (velocidad / 4), dentro de 0 a 0x87
	ld b,a			;8e4a
	ld (ix+005h),a		;8e4b   ; la velocidad X
	sra a		;8e4e   ; entre 4...
	sra a		;8e50
	add a,(ix+002h)		;8e52   ; ...mas la X
bola_x_borde:
	ld (ix+002h),a		;8e55
	cp 088h		;8e58   ; fuera por la derecha?
	jr c,bola_fondo		;8e5a
	bit 7,b		;8e5c   ; hacia donde iba
	ld a,087h		;8e5e   ; 0x87
	jr z,bola_x_borde		;8e60
	xor a			;8e62   ; o 0
	jr bola_x_borde		;8e63
bola_fondo:		; El fondo de la maquina: la bola no baja de su curva (mas honda en el centro) y rueda hacia el centro
	sub 048h		;8e65   ; lo que se separa del centro (X 0x48)
	jp p,bola_fondo_centro		;8e67
	neg		;8e6a
bola_fondo_centro:
	cp 00ah		;8e6c   ; menos de 10: la curva en 0xA1
	jr nc,bola_fondo_lado		;8e6e
	ld b,0a1h		;8e70
	xor a			;8e72
	jr bola_fondo_y		;8e73
bola_fondo_lado:
	cp 050h		;8e75   ; mas de 0x50: nada
	jr nc,bola_maquina		;8e77
	ld b,0beh		;8e79   ; de 0x20 a 0x50: 0xBE menos eso
	cp 020h		;8e7b
	jr nc,bola_fondo_y		;8e7d
	ld b,0a8h		;8e7f   ; de 10 a 0x20: 0xA8 menos la mitad
	srl a		;8e81
bola_fondo_y:
	neg		;8e83   ; la curva...
	add a,b			;8e85
	cp (ix+001h)		;8e86   ; ...por encima de la bola?
	jr nc,bola_maquina		;8e89
	ld (ix+001h),a		;8e8b   ; la bola sobre la curva
	ld a,(ix+002h)		;8e8e   ; de que lado?
	cp 045h		;8e91
	ld a,00ah		;8e93   ; hacia la derecha...
	jr c,bola_fondo_rueda		;8e95
	neg		;8e97   ; ...o hacia la izquierda
bola_fondo_rueda:		; Hacia el centro: 10 o -10
	ld (ix+005h),a		;8e99
bola_maquina:		; Lo que hay segun la maquina: la 1 el centro abierto, la 0 los agujeros, la 2 los OVNIs
	ld a,(0ec5ah)		;8e9c   ; la maquina
	cp 001h		;8e9f
	jp z,bola_centro_abierto		;8ea1   ; el 1
	or a			;8ea4
	jp z,bola_agujeros		;8ea5   ; el 0
	ld iy,0ecc5h		;8ea8   ; la maquina 2: los cinco OVNIs
	ld a,005h		;8eac
bola_ovni:		; La maquina 2: un OVNI pequeno o mediano tocado: puntos o bolas menos, y el OVNI estalla
	push af			;8eae
	ld a,(iy+000h)		;8eaf   ; el estado del OVNI
	or a			;8eb2
	jr z,bola_ovni_sig		;8eb3   ; no esta
	sub 003h		;8eb5   ; 3: estallando
	jr z,bola_ovni_sig		;8eb7
	dec a			;8eb9   ; 4 o mas: nada
	jr nc,bola_ovni_sig		;8eba
	ld e,(ix+001h)		;8ebc   ; la Y de la bola...
	ld a,(iy+001h)		;8ebf   ; ...contra la del OVNI...
	sub e			;8ec2
	add a,004h		;8ec3
	cp 00ch		;8ec5   ; ...a menos de 12?
	jr nc,bola_ovni_sig		;8ec7
	ld d,(ix+002h)		;8ec9   ; la X de la bola...
	ld a,(iy+002h)		;8ecc   ; ...contra la del OVNI...
	sub 016h		;8ecf
	sub d			;8ed1
	cp 01ch		;8ed2   ; ...a menos de 28?
	jr nc,bola_ovni_sig		;8ed4
	ld a,(iy+004h)		;8ed6   ; su forma
	cp 001h		;8ed9
	jr c,bola_ovni_malo		;8edb   ; 0: el malo
	ld b,002h		;8edd   ; el canal 2...
	ld de,0bdb6h		;8edf   ; ...el sonido
	call pieza		;8ee2
	ld a,(0ed31h)		;8ee5   ; los puntos del OVNI bueno
	ld l,a			;8ee8
	ld h,000h		;8ee9
	call puntos_suena		;8eeb
	ld a,(0ed2bh)		;8eee   ; un golpe menos para el grande
	dec a			;8ef1
	ld (0ed2bh),a		;8ef2
	or a			;8ef5
	jr nz,bola_ovni_estalla		;8ef6   ; aun no
	inc a			;8ef8   ; ya: el OVNI grande se mueve
	ld (0ecdeh),a		;8ef9
	jr bola_ovni_estalla		;8efc
bola_ovni_malo:		; Tocado el de forma 0: el sonido (0xBDC6) y bolas menos
	ld b,002h		;8efe   ; el canal 2...
	ld de,0bdc6h		;8f00   ; ...el sonido
	call pieza		;8f03
	ld a,(0ed30h)		;8f06   ; las bolas que quita
	ld b,a			;8f09
bola_ovni_resta:
	push bc			;8f0a
	call bola_menos		;8f0b   ; una menos
	pop bc			;8f0e
	djnz bola_ovni_resta		;8f0f
bola_ovni_estalla:		; El OVNI estalla (3) y la bola se va
	ld (iy+000h),003h		;8f11   ; el OVNI estalla...
	ld (iy+003h),028h		;8f15   ; ...40 cuadros
	ld (ix+003h),008h		;8f19   ; la bola...
	ld (ix+000h),000h		;8f1d   ; ...se va
bola_ovni_sig:		; El siguiente
	ld bc,00005h		;8f21
	add iy,bc		;8f24
	pop af			;8f26
	dec a			;8f27
	jp nz,bola_ovni		;8f28
	ld a,(iy+000h)		;8f2b   ; el sexto: el OVNI grande
	or a			;8f2e   ; el estado del grande
	jp z,bola_fuera		;8f2f
	sub 003h		;8f32
	jp z,bola_fuera		;8f34
	dec a			;8f37
	jp z,bola_fuera		;8f38
	ld e,(ix+001h)		;8f3b   ; la Y de la bola contra la suya...
	ld a,(iy+001h)		;8f3e
	sub e			;8f41
	add a,003h		;8f42
	cp 00eh		;8f44   ; ...a menos de 14?
	jp nc,bola_fuera		;8f46
	ld d,(ix+002h)		;8f49   ; la X...
	ld a,(iy+002h)		;8f4c
	sub 009h		;8f4f
	sub d			;8f51
	cp 01ch		;8f52   ; ...a menos de 28?
	jp nc,bola_fuera		;8f54
	ld b,002h		;8f57   ; tocado: el sonido (0xBDD6), los puntos del OVNI bueno x 16, y el final 1
	ld de,0bdd6h		;8f59
	call pieza		;8f5c
	ld a,(0ed31h)		;8f5f   ; los puntos...
	ld l,a			;8f62
	ld h,000h		;8f63
	add hl,hl			;8f65   ; ...x 16
	add hl,hl			;8f66
	add hl,hl			;8f67
	add hl,hl			;8f68
	call puntos_suena		;8f69
	ld (iy+000h),003h		;8f6c   ; estalla...
	ld (iy+003h),032h		;8f70   ; ...50 cuadros
	ld (ix+000h),000h		;8f74   ; la bola se va
	ld (ix+003h),008h		;8f78
	ld a,001h		;8f7c   ; el final 1
	ld (0ed2ah),a		;8f7e
	jp bola_fuera		;8f81
bola_centro_abierto:		; La maquina 1 con el centro abierto: la bola que llega a su altura entra
	ld a,(0ec7fh)		;8f84   ; abierto?
	or a			;8f87
	jr z,bola_agujeros		;8f88
	ld a,(ix+001h)		;8f8a   ; la Y, por 16...
	add a,004h		;8f8d
	and 0f0h		;8f8f
	cp 050h		;8f91   ; ...0x50?
	jr nz,bola_agujeros		;8f93
	ld a,(ix+002h)		;8f95   ; la X...
	cp 06ch		;8f98   ; ...entre 0x20...
	jr nc,bola_agujeros		;8f9a
	cp 020h		;8f9c   ; ...y 0x6B
	jr c,bola_agujeros		;8f9e
	jp agujero_mete_bola		;8fa0   ; entra
bola_agujeros:		; Los agujeros: la bola en uno de los cuatro sitios de 0x9268 (por 16 pixeles) o en uno de los 15 de 0x9270 (por 4) salta a lo suyo
	ld hl,09268h		;8fa3   ; los cuatro sitios por 16 pixeles
	ld a,(ix+002h)		;8fa6   ; la X redondeada
	and 0f0h		;8fa9
	ld e,a			;8fab
	ld a,(ix+001h)		;8fac   ; la Y redondeada
	sub 008h		;8faf
	and 0f0h		;8fb1
	add a,008h		;8fb3
	ld d,a			;8fb5
	ld b,004h		;8fb6   ; cuatro
bola_agujero4:
	ld a,(hl)			;8fb8   ; la X...
	inc hl			;8fb9
	cp e			;8fba
	jr nz,bola_agujero4_sig		;8fbb
	ld a,(hl)			;8fbd   ; ...y la Y
	cp d			;8fbe
	jr nz,bola_agujero4_sig		;8fbf
	ld a,b			;8fc1   ; el sitio x 2...
	add a,a			;8fc2
	push bc			;8fc3
	ld c,a			;8fc4
	ld b,000h		;8fc5
	ld hl,09020h		;8fc7   ; ...en la tabla de saltos
	add hl,bc			;8fca
	pop bc			;8fcb
	ld e,(hl)			;8fcc   ; la rutina...
	inc hl			;8fcd
	ld d,(hl)			;8fce
	ex de,hl			;8fcf
	jp (hl)			;8fd0   ; ...a ella
bola_agujero4_sig:
	inc hl			;8fd1   ; el siguiente
	djnz bola_agujero4		;8fd2
bola_agujeros15:
	ld hl,09270h		;8fd4   ; los quince por 4 pixeles
	ld a,(ix+001h)		;8fd7   ; la Y redondeada
	and 0fch		;8fda
	ld d,a			;8fdc
	ld a,(ix+002h)		;8fdd   ; la X redondeada
	and 0fch		;8fe0
	ld e,a			;8fe2
	ld b,00fh		;8fe3   ; quince
bola_agujero15:
	ld a,(hl)			;8fe5   ; la X...
	inc hl			;8fe6
	cp e			;8fe7
	jr nz,bola_agujero15_sig		;8fe8
	ld a,(hl)			;8fea   ; ...y la Y
	cp d			;8feb
	jr nz,bola_agujero15_sig		;8fec
	ld a,b			;8fee   ; el sitio x 2...
	add a,a			;8fef
	push bc			;8ff0
	ld c,a			;8ff1
	ld b,000h		;8ff2
	ld hl,09002h		;8ff4   ; ...en la tabla
	add hl,bc			;8ff7
	pop bc			;8ff8
	ld e,(hl)			;8ff9   ; la rutina...
	inc hl			;8ffa
	ld d,(hl)			;8ffb
	ex de,hl			;8ffc
	jp (hl)			;8ffd   ; ...a ella
bola_agujero15_sig:
	inc hl			;8ffe   ; el siguiente
	djnz bola_agujero15		;8fff
	jp bola_fuera		;9001   ; ninguno

; ----------------------------------------------------------------------
; DATOS tablas_agujeros (tramo): Los saltos de los 15 agujeros (0x9004) y de
;   los 4 molinillos (0x9022), del ultimo al primero
;   0x9004..0x902a  (38 bytes)  de 0x9002..0x902a (40 bytes)
DATA_tablas_agujeros_9004:
	defw 090afh,090cdh	; 9004  -> agujero_centro agujero_centro2
	defw 090d2h,090dbh	; 9008  -> agujero_90d2 agujero_90db
	defw 090e0h,09078h	; 900c  -> agujero_v agujero_apertura3
	defw 09053h,09073h	; 9010  -> agujero_apertura1 agujero_apertura2
	defw 09042h,0904eh	; 9014  -> agujero_tulipan1 agujero_tulipan2
	defw 090a5h,090aah	; 9018  -> agujero_90a5 agujero_90aa
	defw 09094h,090a0h	; 901c  -> agujero_9094 agujero_90a0
	defw 09085h,0903dh	; 9020  -> agujero_tiradas molinillo_4
	defw 09038h,09033h	; 9024  -> molinillo_3 molinillo_2
	defw 0902ah	; 9028  -> molinillo_1

; ======================================================================
; CODIGO 0x902a..0x9268  (574 bytes)
; ======================================================================


molinillo_1:		; Un molinillo tocado gira (0x80)
	ld hl,0ec64h		;902a   ; el molinillo 1...
molinillo_gira:
	ld a,080h		;902d   ; ...gira
	ld (hl),a			;902f
	jp bola_agujeros15		;9030   ; y sigue con los agujeros
molinillo_2:
	ld hl,0ec6ah		;9033
	jr molinillo_gira		;9036
molinillo_3:
	ld hl,0ec70h		;9038
	jr molinillo_gira		;903b
molinillo_4:
	ld hl,0ec76h		;903d
	jr molinillo_gira		;9040
agujero_tulipan1:		; Un tulipan: su dibujo siguiente; mete la bola
	ld hl,0ec89h		;9042   ; el tulipan 1
agujero_tulipan:
	inc hl			;9045
	ld a,(hl)			;9046   ; su dibujo...
	inc a			;9047   ; ...el siguiente, de 0 a 3
	and 003h		;9048
	ld (hl),a			;904a
	jp agujero_mete_bola		;904b   ; la bola entra
agujero_tulipan2:
	ld hl,0ec8dh		;904e
	jr agujero_tulipan		;9051
agujero_apertura1:		; La maquina 0: una apertura del centro; si no, un tulipan
	ld hl,0ec91h		;9053
agujero_apertura:
	ld a,(0ec5ah)		;9056   ; la maquina 0?
	or a			;9059
	jr nz,agujero_tulipan		;905a
	ld b,001h		;905c   ; una apertura
agujero_apertura_pon:
	ld a,(0ec82h)		;905e   ; la V ya cuenta?
	or a			;9061
	jr nz,agujero_mete		;9062
	ld a,(0ec81h)		;9064   ; las aperturas...
	add a,b			;9067   ; ...mas B
agujero_aperturas:		; Las aperturas y el premio en marcha
	ld (0ec81h),a		;9068
	ld a,001h		;906b   ; premio en marcha
	ld (0ec80h),a		;906d
agujero_mete:
	jp agujero_mete_bola		;9070
agujero_apertura2:
	ld hl,0ec95h		;9073
	jr agujero_apertura		;9076
agujero_apertura3:		; La maquina 0: dos aperturas
	ld hl,0ec99h		;9078
	ld a,(0ec5ah)		;907b
	or a			;907e
	jr nz,agujero_tulipan		;907f
	ld b,002h		;9081   ; dos aperturas
	jr agujero_apertura_pon		;9083
agujero_tiradas:		; La maquina 1: una tirada del tragaperras
	ld hl,0ec9dh		;9085
	ld a,(0ec5ah)		;9088   ; la maquina 1?
	cp 001h		;908b
	jr nz,agujero_9099		;908d
	ld (0ec84h),a		;908f   ; una tirada
	jr agujero_mete_bola		;9092
agujero_9094:
	ld hl,0eca1h		;9094
	jr agujero_mete_bola		;9097
agujero_9099:
	ld a,001h		;9099   ; los otros: el tulipan 1 se abre
	ld (0ec8ah),a		;909b
	jr agujero_mete_bola		;909e
agujero_90a0:
	ld hl,0eca5h		;90a0
	jr agujero_mete_bola		;90a3
agujero_90a5:
	ld hl,0eca9h		;90a5
	jr agujero_mete_bola		;90a8
agujero_90aa:
	ld hl,0ecadh		;90aa
	jr agujero_mete_bola		;90ad
agujero_centro:		; El centro: con el centro abierto, la bola entra (estado 2) y 0x10 bolas y puntos
	ld hl,0ecb1h		;90af
agujero_centro_va:
	ld a,(0ec7fh)		;90b2   ; abierto?
	or a			;90b5
	jr z,bola_fuera		;90b6   ; no: sigue
	ld (ix+003h),018h		;90b8   ; 24 cuadros...
	ld (ix+000h),002h		;90bc   ; ...dentro del centro
	ld hl,00010h		;90c0   ; 0x10 bolas y puntos
	call puntos_suena		;90c3
	ld a,020h		;90c6   ; las luces
	ld (0ed29h),a		;90c8
	jr bola_sig		;90cb
agujero_centro2:
	ld hl,0ecb5h		;90cd
	jr agujero_centro_va		;90d0
agujero_90d2:
	ld hl,0ecb9h		;90d2
agujero_90d5:
	ld a,(hl)			;90d5   ; abierto?
	or a			;90d6
	jr z,bola_fuera		;90d7
	jr agujero_mete_bola		;90d9
agujero_90db:
	ld hl,0ecbdh		;90db
	jr agujero_90d5		;90de
agujero_v:		; La V: hasta ocho, el sonido (0xBE1D) y 18 aperturas
	ld a,(0ec82h)		;90e0   ; la V: una mas...
	inc a			;90e3
	ld (0ec82h),a		;90e4
	cp 008h		;90e7   ; ...8 o mas: como un agujero
	jr nc,agujero_mete_bola		;90e9
	ld b,000h		;90eb   ; el canal 0...
	ld de,0be1dh		;90ed   ; ...el sonido
	call pieza		;90f0
	ld hl,0ecc1h		;90f3
	call lampara_enciende		;90f6   ; su lampara
	ld a,012h		;90f9   ; 18 aperturas
	jp agujero_aperturas		;90fb
agujero_mete_bola:		; La bola entra: 0x10 bolas y puntos (16 en binario, 10 en el marcador), el sonido, y 120 cuadros cayendo (estado 3)
	ld hl,00010h		;90fe   ; 0x10 bolas y puntos
	call puntos_suena		;9101
	ld a,020h		;9104   ; las luces, 32 cuadros
	ld (0ed29h),a		;9106
	ld (ix+003h),078h		;9109   ; 120 cuadros...
	ld (ix+000h),003h		;910d   ; ...cayendo
	jr bola_sig		;9111
bola_fuera:		; El agujero de abajo (Y 0xA0, X 0x40-0x4F): la bola se pierde
	ld a,(ix+001h)		;9113   ; la Y...
	and 0fch		;9116
	cp 0a0h		;9118   ; ...0xA0?
	jp nz,bola_dibujo		;911a
	ld a,(ix+002h)		;911d   ; la X...
	and 0f0h		;9120
	cp 040h		;9122   ; ...0x40-0x4F?
	jp nz,bola_dibujo		;9124
	ld (ix+003h),078h		;9127   ; 120 cuadros...
	ld (ix+000h),003h		;912b   ; ...cayendo
	jr bola_sig		;912f
bola_dibujo:		; El dibujo de la bola: de 8 a 0x16, de 2 en 2
	ld a,(ix+003h)		;9131   ; el dibujo...
	add a,002h		;9134   ; ...siguiente...
	cp 018h		;9136   ; ...pasa de 0x16?
	jr nz,bola_dibujo_pon		;9138
	ld a,008h		;913a   ; 8
bola_dibujo_pon:
	ld (ix+003h),a		;913c
bola_sig:		; La bola siguiente
	ld bc,00008h		;913f   ; la bola siguiente
	add ix,bc		;9142
	pop af			;9144
	dec a			;9145
	jp nz,bola		;9146
	ret			;9149
clavos:		; Los clavos de alrededor de la bola en el mapa de bits de 0xE000 (18 bytes por linea): DE = la desviacion en Y y en X
	ld l,(ix+001h)		;914a
	ld h,000h		;914d   ; la Y...
	ld d,h			;914f
	ld e,l			;9150
	add hl,hl			;9151   ; ...x 18...
	add hl,hl			;9152
	add hl,hl			;9153
	add hl,de			;9154
	add hl,hl			;9155
	ld a,(ix+002h)		;9156   ; ...mas la X / 8...
	rrca			;9159
	rrca			;915a
	rrca			;915b
	and 01fh		;915c
	ld c,a			;915e
	ld b,0e0h		;915f   ; ...mas 0xE000: el byte del mapa
	add hl,bc			;9161
	ld a,(ix+002h)		;9162   ; los bits de la X dentro del byte, + 1
	and 007h		;9165
	inc a			;9167
	ld c,a			;9168
	push hl			;9169   ; IY = el byte
	pop iy		;916a
	ld hl,00000h		;916c   ; sin desviacion
	ld d,(iy+000h)		;916f   ; la primera linea: 16 bits
	ld e,(iy+001h)		;9172
	ex de,hl			;9175
	ld a,h			;9176   ; nada?
	or l			;9177
	jr z,clavos_5		;9178
	ld b,c			;917a   ; corridos hasta la bola
clavos_corre:		; ...
	add hl,hl			;917b
	djnz clavos_corre		;917c
	bit 7,h		;917e   ; bit 7: hacia abajo y a la derecha
	jr z,clavos_6		;9180
	inc d			;9182
	inc e			;9183
	inc e			;9184
clavos_6:
	bit 6,h		;9185   ; bit 6: a la derecha
	jr z,clavos_5		;9187
	inc e			;9189
	inc e			;918a
clavos_5:
	bit 5,h		;918b   ; bit 5: hacia arriba y a la derecha
	jr z,clavos_l2		;918d
	dec d			;918f
	inc e			;9190
	inc e			;9191
clavos_l2:		; La linea siguiente
	ex de,hl			;9192   ; la linea siguiente (18 bytes)
	ld a,c			;9193
	ld bc,00012h		;9194
	add iy,bc		;9197
	ld c,a			;9199
	ld d,(iy+000h)		;919a   ; sus 16 bits
	ld e,(iy+001h)		;919d
	ex de,hl			;91a0
	ld a,h			;91a1   ; nada?
	or l			;91a2
	jr z,clavos_l3		;91a3
	ld b,c			;91a5
clavos_l2_corre:
	add hl,hl			;91a6
	djnz clavos_l2_corre		;91a7
	jr nc,clavos_l2_b4		;91a9   ; el bit que sale: hacia abajo
	inc d			;91ab
	inc d			;91ac
	inc e			;91ad
	inc e			;91ae
clavos_l2_b4:
	bit 4,h		;91af   ; bit 4: hacia arriba
	jr z,clavos_l3		;91b1
	inc e			;91b3
	inc e			;91b4
	dec d			;91b5
	dec d			;91b6
clavos_l3:
	ex de,hl			;91b7   ; la tercera linea
	ld a,c			;91b8
	ld c,012h		;91b9
	add iy,bc		;91bb
	ld c,a			;91bd
	ld d,(iy+000h)		;91be   ; sus 16 bits
	ld e,(iy+001h)		;91c1
	ex de,hl			;91c4
	ld a,h			;91c5
	or l			;91c6
	jr z,clavos_l4		;91c7
	ld b,c			;91c9
clavos_l3_corre:
	add hl,hl			;91ca
	djnz clavos_l3_corre		;91cb
	jr nc,clavos_l3_b4		;91cd   ; el bit que sale
	inc e			;91cf
	inc d			;91d0
	inc d			;91d1
clavos_l3_b4:
	bit 4,h		;91d2   ; bit 4
	jr z,clavos_l4		;91d4
	inc e			;91d6
	dec d			;91d7
	dec d			;91d8
clavos_l4:
	ex de,hl			;91d9   ; la cuarta
	ld a,c			;91da
	ld c,012h		;91db
	add iy,bc		;91dd
	ld c,a			;91df
	ld d,(iy+000h)		;91e0   ; sus 16 bits
	ld e,(iy+001h)		;91e3
	ex de,hl			;91e6
	ld a,h			;91e7
	or l			;91e8
	jr z,clavos_l5		;91e9
	ld b,c			;91eb
clavos_l4_corre:
	add hl,hl			;91ec
	djnz clavos_l4_corre		;91ed
	jr nc,clavos_l4_b4		;91ef   ; el bit que sale: a la izquierda
	dec e			;91f1
	inc d			;91f2
	inc d			;91f3
clavos_l4_b4:
	bit 4,h		;91f4   ; bit 4
	jr z,clavos_l5		;91f6
	dec e			;91f8
	dec d			;91f9
	dec d			;91fa
clavos_l5:
	ex de,hl			;91fb   ; la quinta
	ld a,c			;91fc
	ld c,012h		;91fd
	add iy,bc		;91ff
	ld c,a			;9201
	ld d,(iy+000h)		;9202   ; sus 16 bits
	ld e,(iy+001h)		;9205
	ex de,hl			;9208
	ld a,h			;9209
	or l			;920a
	jr z,clavos_l6		;920b
	ld b,c			;920d
clavos_l5_corre:
	add hl,hl			;920e
	djnz clavos_l5_corre		;920f
	jr nc,clavos_l5_b4		;9211   ; el bit que sale
	inc d			;9213
	inc d			;9214
	dec e			;9215
	dec e			;9216
clavos_l5_b4:
	bit 4,h		;9217   ; bit 4
	jr z,clavos_l6		;9219
	dec e			;921b
	dec e			;921c
	dec d			;921d
	dec d			;921e
clavos_l6:
	ex de,hl			;921f   ; la sexta
	ld a,c			;9220
	ld c,012h		;9221
	add iy,bc		;9223
	ld c,a			;9225
	ld d,(iy+000h)		;9226   ; sus 16 bits
	ld e,(iy+001h)		;9229
	ex de,hl			;922c
	ld a,h			;922d
	or l			;922e
	jr z,clavos_fin		;922f
	ld b,c			;9231
clavos_l6_corre:
	add hl,hl			;9232
	djnz clavos_l6_corre		;9233
	bit 7,h		;9235   ; bit 7
	jr z,clavos_l6_b6		;9237
	inc d			;9239
	dec e			;923a
	dec e			;923b
clavos_l6_b6:
	bit 6,h		;923c   ; bit 6
	jr z,clavos_l6_b5		;923e
	dec e			;9240
	dec e			;9241
clavos_l6_b5:
	bit 5,h		;9242   ; bit 5
	jr z,clavos_fin		;9244
	dec d			;9246
	dec e			;9247
	dec e			;9248
clavos_fin:
	ret			;9249
bola_centro:		; Dentro del centro: 36 cuadros y 0x0A bolas y puntos (10)
	ld a,(ix+003h)		;924a   ; la cuenta...
	inc a			;924d   ; ...uno mas
	ld (ix+003h),a		;924e
	cp 024h		;9251   ; 36?
	jp c,bola_sig		;9253
	ld (ix+000h),000h		;9256   ; libre
	ld hl,0000ah		;925a   ; 0x0A bolas y puntos
	call puntos_suena		;925d
	ld a,020h		;9260   ; las luces
	ld (0ed29h),a		;9262
	jp bola_sig		;9265

; ----------------------------------------------------------------------
; DATOS sitios: Los cuatro sitios de los molinillos y los quince de los
;   agujeros (X, Y)
;   0x9268..0x928e  (38 bytes)
DATA_sitios:
	defb 010h,038h	; 9268
	defb 070h,038h	; 926a
	defb 020h,058h	; 926c
	defb 060h,058h	; 926e
	defb 044h,024h	; 9270
	defb 040h,028h	; 9272
	defb 048h,028h	; 9274
	defb 024h,034h	; 9276
	defb 064h,034h	; 9278
	defb 014h,060h	; 927a
	defb 074h,060h	; 927c
	defb 024h,084h	; 927e
	defb 064h,084h	; 9280
	defb 044h,08ch	; 9282
	defb 044h,05ch	; 9284
	defb 038h,060h	; 9286
	defb 050h,060h	; 9288
	defb 03ch,04ch	; 928a
	defb 050h,04ch	; 928c

; ======================================================================
; CODIGO 0x928e..0x93a4  (278 bytes)
; ======================================================================


bola_agujero_fin:		; En un agujero: libre
	ld (ix+000h),000h		;928e   ; libre
	jp bola_sig		;9292
tulipanes:		; Los tulipanes (0xEC89, 4 bytes): se abren y se cierran
	ld a,(0ec5ah)		;9295   ; la maquina 2 no tiene tulipanes
	cp 002h		;9298
	ret z			;929a
	or a			;929b   ; la maquina 0...
	ld hl,0ec89h		;929c   ; ...los tulipanes (0xEC89)
	ld a,002h		;929f   ; dos en la maquina 0...
	jr z,tulipan		;92a1
	ld a,005h		;92a3   ; ...cinco en los otros
tulipan:
	push af			;92a5
	push hl			;92a6
	ld a,(hl)			;92a7   ; activo?
	or a			;92a8
	jr z,tulipan_sig		;92a9
	inc hl			;92ab
	ld a,(hl)			;92ac   ; su dibujo
	inc hl			;92ad
	cp 010h		;92ae   ; 0x10 o mas: ya puesto
	jr nc,tulipan_sig		;92b0
	or a			;92b2   ; 0: se abre
	jr z,tulipan_abre		;92b3
	cp 002h		;92b5   ; 2: se cierra
	jr z,tulipan_cierra		;92b7
	push hl			;92b9
	inc a			;92ba   ; 1 o 3: a 2...
	and 002h		;92bb
	dec hl			;92bd
	ld (hl),a			;92be   ; ...guardado
	inc hl			;92bf
	call tulipan_ram		;92c0   ; su sitio en el mapa
	exx			;92c3
	pop hl			;92c4
	call tulipan_vram		;92c5   ; y en la pantalla
	call marca2		;92c8   ; la forma 2
	jr tulipan_sig		;92cb
tulipan_abre:
	push hl			;92cd
	or 080h		;92ce   ; con el bit 7: puesto
	dec hl			;92d0
	ld (hl),a			;92d1
	inc hl			;92d2
	call tulipan_ram		;92d3   ; su sitio en el mapa
	exx			;92d6
	pop hl			;92d7
	call tulipan_vram		;92d8   ; y en la pantalla
	call marca1		;92db   ; la forma 1
	jr tulipan_sig		;92de
tulipan_cierra:
	push hl			;92e0
	or 080h		;92e1   ; con el bit 7: puesto
	dec hl			;92e3
	ld (hl),a			;92e4
	inc hl			;92e5
	call tulipan_ram		;92e6   ; su sitio en el mapa
	exx			;92e9
	pop hl			;92ea
	call tulipan_vram		;92eb   ; y en la pantalla
	call marca3		;92ee   ; la forma 3
tulipan_sig:
	pop hl			;92f1
	ld bc,00004h		;92f2   ; el siguiente, 4 bytes mas alla
	add hl,bc			;92f5
	pop af			;92f6
	dec a			;92f7   ; todos
	jr nz,tulipan		;92f8
	ret			;92fa
tulipan_ram:
	ld e,(hl)			;92fb   ; la Y...
	inc hl			;92fc
	ld a,(hl)			;92fd   ; ...y la X
	ld d,000h		;92fe
	ld l,e			;9300   ; la Y x 18...
	ld h,d			;9301
	add hl,hl			;9302
	add hl,hl			;9303
	add hl,hl			;9304
	add hl,de			;9305
	add hl,hl			;9306
	ld e,a			;9307   ; ...+ la X...
	ld d,0e0h		;9308   ; ...+ 0xE000
	add hl,de			;930a
	ex de,hl			;930b   ; en DE
	ret			;930c
tulipan_vram:
	ld a,(hl)			;930d   ; la Y + 4...
	add a,004h		;930e
	ld e,a			;9310
	inc hl			;9311
	ld a,(hl)			;9312   ; ...la X + 5
	add a,005h		;9313
	ld d,000h		;9315
	ex de,hl			;9317
	add hl,hl			;9318   ; la Y x 4...
	add hl,hl			;9319
	ld e,a			;931a
	ld a,l			;931b   ; ...redondeada a la fila (x 32 / 8)...
	and 0e0h		;931c
	ld l,a			;931e
	ld a,e			;931f
	ld e,a			;9320   ; ...+ la X / 8...
	ld d,018h		;9321   ; ...+ 0x1800
	add hl,de			;9323
	ex de,hl			;9324   ; en DE
	ret			;9325
maquina_maq2:		; La pantalla de la maquina 2 (0x9614)
	call clavos_maq2		;9326   ; el mapa de los clavos
	ld de,09614h		;9329   ; la maquina 0x9614
	jr maquina_pinta		;932c
maquina_maq0:		; La pantalla de la maquina 0 (0x93A4)
	call clavos_maq01		;932e   ; el mapa
	jr maquina		;9331
maquina_maq1:		; La de la maquina 1: la de 0x93A4 y la ventana del tragaperras (9 filas de 5 casillas de 0x9884, en 0x18AB)
	call clavos_maq1		;9333   ; el mapa
	call maquina		;9336   ; la maquina
	ld de,018abh		;9339   ; en la fila 5, columna 11
	ld hl,09884h		;933c   ; la ventana
	ld a,009h		;933f   ; 9 filas
maquina_ventana:		; Una fila de la ventana
	ld bc,00005h		;9341   ; 5 casillas
	push hl			;9344
	push de			;9345
	push af			;9346
	call 0005ch		;9347   ; LDIRVM
	pop af			;934a
	pop de			;934b
	pop hl			;934c
	ld bc,00005h		;934d   ; la fila siguiente del dibujo...
	add hl,bc			;9350
	ld c,020h		;9351   ; ...y de la pantalla
	ex de,hl			;9353
	add hl,bc			;9354
	ex de,hl			;9355
	dec a			;9356   ; las nueve
	jr nz,maquina_ventana		;9357
	ret			;9359
maquina:		; La maquina: la pantalla en blanco y 24 filas de 26 casillas (0x93A4)
	ld de,093a4h		;935a   ; la maquina 0x93A4
maquina_pinta:		; La pantalla en blanco (FILVRM) y la maquina de DE
	ld hl,01800h		;935d   ; la pantalla...
	ld a,020h		;9360   ; ...en blanco...
	ld bc,00300h		;9362   ; ...768 casillas
	push de			;9365
	call 00056h		;9366
	pop hl			;9369
	ld de,01800h		;936a   ; desde la fila 0
	ld a,018h		;936d   ; 24 filas
maquina_fila:		; Una fila de 26 casillas
	ld bc,0001ah		;936f   ; 26 casillas
	push af			;9372
	push hl			;9373
	push de			;9374
	call 0005ch		;9375   ; LDIRVM
	pop de			;9378
	pop hl			;9379
	pop af			;937a
	ld bc,0001ah		;937b   ; la fila siguiente del dibujo...
	add hl,bc			;937e
	ld c,020h		;937f   ; ...y de la pantalla
	ex de,hl			;9381
	add hl,bc			;9382
	ex de,hl			;9383
	dec a			;9384   ; las 24
	jr nz,maquina_fila		;9385
	ret			;9387
centro_pinta:		; El dibujo del centro: A filas de 9 casillas de HL, desde la fila 9, columna 9
	ld de,01929h		;9388   ; en la fila 9, columna 9
centro_fila:		; Una fila
	ld bc,00009h		;938b   ; 9 casillas
	push hl			;938e
	push de			;938f
	push af			;9390
	call 0005ch		;9391   ; LDIRVM
	pop af			;9394
	pop de			;9395
	pop hl			;9396
	ld bc,00020h		;9397
	ex de,hl			;939a
	add hl,bc			;939b
	ex de,hl			;939c
	ld c,009h		;939d
	add hl,bc			;939f
	dec a			;93a0
	jr nz,centro_fila		;93a1
	ret			;93a3

; ----------------------------------------------------------------------
; DATOS maquina_maq01: La pantalla de las maquinas 0 y 1: 24 filas de 26
;   casillas
;   0x93a4..0x9614  (624 bytes)
DATA_maquina_maq01:
	defb 020h,07fh,06fh,06fh,06fh,06fh,06fh,06fh,06fh,083h,085h,087h,064h,064h,064h,088h,086h,084h,06fh,06fh,06fh,06fh,06fh,06fh,06fh,080h	; 93a4   .ooooooo...ddd...ooooooo.
	defb 020h,070h,073h,071h,071h,075h,081h,089h,08bh,08dh,08fh,060h,060h,060h,060h,060h,090h,08eh,08ch,08ah,082h,076h,071h,071h,074h,070h	; 93be   psqqu.....`````.....vqqtp
	defb 020h,070h,077h,072h,079h,07bh,091h,093h,095h,060h,060h,097h,099h,060h,09ah,098h,060h,060h,096h,094h,092h,07ch,07ah,072h,078h,070h	; 93d8   pwry{...``..`..``...|zrxp
	defb 020h,070h,077h,079h,07bh,09bh,09dh,09fh,060h,060h,099h,060h,099h,060h,09ah,060h,09ah,060h,060h,0a0h,09eh,09ch,07ch,07ah,078h,070h	; 93f2   pwy{...``.`.`.`.``...|zxp
	defb 020h,070h,07dh,07bh,081h,0a1h,0a3h,0a5h,062h,0a6h,0a7h,060h,0a7h,060h,0a8h,060h,0a8h,0a5h,062h,0a6h,0a4h,0a2h,082h,07ch,07eh,070h	; 940c   p}{....b..`.`.`..b....|~p
	defb 020h,070h,081h,081h,0abh,0adh,0afh,061h,099h,0b1h,0b3h,0b1h,0b3h,065h,0b4h,0b2h,0b4h,0b2h,09ah,061h,0b0h,0aeh,0ach,082h,082h,070h	; 9426   p.....a.....e.....a.....p
	defb 020h,070h,081h,081h,0b7h,0b9h,0bbh,060h,0a7h,0bdh,060h,0bfh,0d1h,066h,0d2h,0c0h,060h,0beh,0a8h,060h,0bch,0bah,0b8h,081h,081h,070h	; 9440   p.....`..`..f..`..`.....p
	defb 020h,070h,081h,0c5h,0c7h,0c9h,0cbh,062h,0cdh,063h,0cfh,067h,068h,069h,06ah,06bh,0d0h,063h,0ceh,062h,0cch,0cah,0c8h,0c6h,081h,070h	; 945a   p.....b.c.ghijk.c.b.....p
	defb 020h,060h,061h,098h,09ah,09ch,062h,063h,062h,066h,062h,068h,0ceh,086h,0cfh,069h,062h,066h,062h,063h,062h,09dh,09bh,099h,061h,060h	; 9474   `a...bcbfbh...ibfbcb...a`
	defb 020h,060h,061h,0a0h,0a2h,090h,064h,064h,064h,091h,062h,0e2h,087h,06bh,087h,0e3h,062h,090h,064h,064h,064h,091h,0a3h,0a1h,061h,060h	; 948e   `a...ddd.b..k..b.ddd...a`
	defb 020h,060h,061h,0a6h,0a8h,0aah,0aah,063h,0abh,062h,062h,0e4h,0eah,06ch,0ebh,0e5h,062h,062h,0aah,063h,0abh,0abh,0a9h,0a7h,061h,060h	; 94a8   `a....c.bb..l..bb.c....a`
	defb 020h,060h,061h,0a6h,0a8h,062h,0b0h,065h,0b1h,062h,062h,0e6h,06ah,06dh,06ah,0e7h,062h,062h,0b0h,065h,0b1h,062h,0a9h,0a7h,061h,060h	; 94c2   `a..b.e.bb.jmj.bb.e.b..a`
	defb 020h,060h,061h,0a0h,0a2h,062h,08ah,06eh,08bh,062h,062h,0e8h,0deh,06ah,0dfh,0e9h,062h,062h,08ah,06eh,08bh,062h,0a3h,0a1h,061h,060h	; 94dc   `a..b.n.bb..j..bb.n.b..a`
	defb 020h,060h,061h,098h,0b2h,0b4h,088h,06fh,089h,0b6h,062h,0dch,0e0h,085h,0e1h,0ddh,062h,0b7h,088h,06fh,089h,0b5h,0b3h,099h,061h,060h	; 94f6   `a....o..b.....b..o....a`
	defb 020h,060h,061h,0b8h,0bah,0bch,062h,062h,0beh,062h,0bfh,0c0h,0c2h,062h,0c3h,0c1h,0beh,062h,0bfh,062h,062h,0bdh,0bbh,0b9h,061h,060h	; 9510   `a...bb.b...b...b.bb...a`
	defb 020h,060h,061h,061h,0c4h,0c6h,062h,062h,0c8h,062h,0c9h,0cah,0cch,067h,0cdh,0cbh,0c8h,062h,0c9h,062h,062h,0c7h,0c5h,061h,061h,060h	; 952a   `aa..bb.b...g...b.bb..aa`
	defb 020h,060h,061h,061h,096h,098h,09ah,063h,09ch,062h,09dh,09eh,066h,066h,066h,09fh,09ch,062h,09dh,062h,09bh,099h,097h,061h,061h,060h	; 9544   `aa...c.b..fff..b.b...aa`
	defb 020h,094h,075h,075h,075h,0a2h,0a4h,062h,0c0h,071h,0c1h,062h,0a6h,065h,0a7h,062h,0c0h,071h,0c1h,062h,0a5h,0a3h,075h,075h,075h,095h	; 955e   .uuu..b.q.b.e.b.q.b..uuu.
	defb 020h,07bh,07bh,07bh,07bh,067h,068h,0aah,0c2h,072h,0c3h,062h,0c0h,071h,0c1h,062h,0c2h,072h,0c3h,0abh,076h,074h,07bh,07bh,07bh,07bh	; 9578   {{{{gh..r.b.q.b.r..vt{{{{
	defb 020h,07bh,07bh,07bh,07bh,07bh,069h,06ah,0aeh,062h,062h,062h,0c2h,073h,0c3h,062h,062h,062h,0afh,080h,077h,0c4h,0c6h,0c7h,0c5h,07bh	; 9592   {{{{{ij.bbb.s.bbb..w....{
	defb 020h,06bh,06bh,06bh,06bh,06bh,091h,06ch,0b0h,0b2h,0b4h,062h,0b6h,082h,0b7h,062h,0b5h,0b3h,0b1h,081h,090h,0c8h,06bh,06bh,0c9h,06bh	; 95ac   kkkkk.l...b...b......kk.k
	defb 020h,06bh,06bh,06bh,06bh,06bh,06bh,091h,092h,0b8h,0bah,0bch,0beh,087h,0bfh,0bdh,0bbh,0b9h,093h,090h,06bh,0cah,06bh,06bh,0cbh,06bh	; 95c6   kkkkkk.............k.kk.k
	defb 020h,07ah,07ah,07ah,07ah,07ah,07ah,06bh,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,06bh,06bh,0cch,0ceh,0cfh,0cdh,06bh	; 95e0   zzzzzzk           kk....k
	defb 020h,07ah,07ah,07ah,07ah,07ah,07ah,06bh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06bh,06bh,06bh,06bh,06bh,06bh,06bh	; 95fa   zzzzzzkmmmmmmmmmmmkkkkkkk

; ----------------------------------------------------------------------
; DATOS maquina_maq2: La pantalla de la maquina 2: 24 filas de 26 casillas
;   0x9614..0x9884  (624 bytes)
DATA_maquina_maq2:
	defb 020h,07fh,06fh,06fh,06fh,06fh,06fh,06fh,06fh,083h,085h,087h,064h,064h,064h,088h,086h,084h,06fh,06fh,06fh,06fh,06fh,06fh,06fh,080h	; 9614   .ooooooo...ddd...ooooooo.
	defb 020h,070h,073h,071h,071h,075h,081h,089h,08bh,08dh,08fh,060h,060h,060h,060h,060h,090h,08eh,08ch,08ah,082h,076h,071h,071h,074h,070h	; 962e   psqqu.....`````.....vqqtp
	defb 020h,070h,077h,072h,079h,07bh,091h,093h,095h,060h,060h,060h,060h,060h,060h,060h,060h,060h,096h,094h,092h,07ch,07ah,072h,078h,070h	; 9648   pwry{...`````````...|zrxp
	defb 020h,070h,077h,079h,07bh,09bh,09dh,09fh,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,0a0h,09eh,09ch,07ch,07ah,078h,070h	; 9662   pwy{...```````````...|zxp
	defb 020h,070h,07dh,07bh,081h,0a1h,0a3h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,0a4h,0a2h,082h,07ch,07eh,070h	; 967c   p}{...`````````````...|~p
	defb 020h,070h,081h,081h,0abh,0adh,0afh,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,0b0h,0aeh,0ach,082h,082h,070h	; 9696   p.....`````````````.....p
	defb 020h,070h,081h,081h,0b7h,0b9h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,0bah,0b8h,081h,081h,070h	; 96b0   p....```````````````....p
	defb 020h,070h,081h,0c5h,0c7h,0c9h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,060h,0cah,0c8h,0c6h,081h,070h	; 96ca   p....```````````````....p
	defb 020h,060h,061h,098h,09ah,09ch,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,09dh,09bh,099h,061h,060h	; 96e4   `a...bbbbbbbbbbbbbbb...a`
	defb 020h,060h,061h,0a0h,0a2h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0a3h,0a1h,061h,060h	; 96fe   `a..bbbbbbbbbbbbbbbbb..a`
	defb 020h,060h,061h,0a6h,0a8h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0a9h,0a7h,061h,060h	; 9718   `a..bbbbbbbbbbbbbbbbb..a`
	defb 020h,060h,061h,0a6h,0a8h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0a9h,0a7h,061h,060h	; 9732   `a..bbbbbbbbbbbbbbbbb..a`
	defb 020h,060h,061h,0a0h,0a2h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0a3h,0a1h,061h,060h	; 974c   `a..bbbbbbbbbbbbbbbbb..a`
	defb 020h,060h,061h,098h,0b2h,0b4h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0b5h,0b3h,099h,061h,060h	; 9766   `a...bbbbbbbbbbbbbbb...a`
	defb 020h,060h,061h,0b8h,0bah,0bch,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0bdh,0bbh,0b9h,061h,060h	; 9780   `a...bbbbbbbbbbbbbbb...a`
	defb 020h,060h,061h,061h,0c4h,0c6h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0c7h,0c5h,061h,061h,060h	; 979a   `aa..bbbbbbbbbbbbbbb..aa`
	defb 020h,060h,061h,061h,096h,098h,09ah,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,09bh,099h,097h,061h,061h,060h	; 97b4   `aa...bbbbbbbbbbbbb...aa`
	defb 020h,094h,075h,075h,075h,0a2h,0a4h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0a5h,0a3h,075h,075h,075h,095h	; 97ce   .uuu..bbbbbbbbbbbbb..uuu.
	defb 020h,07bh,07bh,07bh,07bh,067h,068h,0aah,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,062h,0abh,076h,074h,07bh,07bh,07bh,07bh	; 97e8   {{{{gh.bbbbbbbbbbb.vt{{{{
	defb 020h,07bh,07bh,07bh,07bh,07bh,069h,06ah,0aeh,062h,062h,062h,062h,062h,062h,062h,062h,062h,0afh,080h,077h,0c4h,0c6h,0c7h,0c5h,07bh	; 9802   {{{{{ij.bbbbbbbbb..w....{
	defb 020h,06bh,06bh,06bh,06bh,06bh,091h,06ch,0b0h,0b2h,0b4h,062h,0b6h,082h,0b7h,062h,0b5h,0b3h,0b1h,081h,090h,0c8h,06bh,06bh,0c9h,06bh	; 981c   kkkkk.l...b...b......kk.k
	defb 020h,06bh,06bh,06bh,06bh,06bh,06bh,091h,092h,0b8h,0bah,0bch,0beh,087h,0bfh,0bdh,0bbh,0b9h,093h,090h,06bh,0cah,06bh,06bh,0cbh,06bh	; 9836   kkkkkk.............k.kk.k
	defb 020h,07ah,07ah,07ah,07ah,07ah,07ah,06bh,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,020h,06bh,06bh,0cch,0ceh,0cfh,0cdh,06bh	; 9850   zzzzzzk           kk....k
	defb 020h,07ah,07ah,07ah,07ah,07ah,07ah,06bh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06dh,06bh,06bh,06bh,06bh,06bh,06bh,06bh	; 986a   zzzzzzkmmmmmmmmmmmkkkkkkk

; ----------------------------------------------------------------------
; DATOS ventana_tragaperras: La ventana del tragaperras de la maquina 1: 9
;   filas de 5 casillas
;   0x9884..0x98b1  (45 bytes)
DATA_ventana_tragaperras:
	defb 0b1h,0b3h,06ch,0b4h,0b2h	; 9884
	defb 0bfh,0d3h,06dh,0d4h,0c0h	; 9889
	defb 0d7h,0d5h,06eh,0d6h,0d8h	; 988e
	defb 0eeh,0ech,072h,0edh,0efh	; 9893
	defb 0f0h,0f2h,073h,0f3h,0f1h	; 9898
	defb 0f6h,0f4h,074h,0f5h,0f7h	; 989d
	defb 0f8h,075h,076h,077h,0f9h	; 98a2
	defb 0fah,07bh,07bh,07bh,0fbh	; 98a7
	defb 0fch,078h,079h,07ah,0fdh	; 98ac

; ----------------------------------------------------------------------
; DATOS centro_maq0_abierto: El centro de la maquina 0 abierto: 4 filas de 9
;   casillas
;   0x98b1..0x98d5  (36 bytes)
DATA_centro_maq0_abierto:
	defb 091h,062h,05bh,087h,06bh,087h,05bh,062h,090h	; 98b1  .b[.k.[b.
	defb 0d0h,0d2h,0d4h,0d6h,06ch,0d7h,0d5h,0d3h,0d1h	; 98ba  ....l....
	defb 062h,062h,0d8h,0dah,06dh,0dbh,0d9h,062h,062h	; 98c3  bb..m..bb
	defb 062h,062h,06ah,0deh,06ah,0dfh,06ah,062h,062h	; 98cc  bbj.j.jbb

; ----------------------------------------------------------------------
; DATOS centro_maq0_cerrado: El centro de la maquina 0 cerrado: 4 filas de 9
;   casillas
;   0x98d5..0x98f9  (36 bytes)
DATA_centro_maq0_cerrado:
	defb 091h,062h,0e2h,087h,06bh,087h,0e3h,062h,090h	; 98d5  .b..k..b.
	defb 062h,062h,0e4h,0eah,06ch,0ebh,0e5h,062h,062h	; 98de  bb..l..bb
	defb 062h,062h,0e6h,06ah,06dh,06ah,0e7h,062h,062h	; 98e7  bb.jmj.bb
	defb 062h,062h,0e8h,0deh,06ah,0dfh,0e9h,062h,062h	; 98f0  bb..j..bb

; ----------------------------------------------------------------------
; DATOS centro_maq1_abierto: El centro de la maquina 1 abierto: 3 filas de 9
;   casillas
;   0x98f9..0x9914  (27 bytes)
DATA_centro_maq1_abierto:
	defb 091h,062h,0f0h,0ffh,073h,0feh,0f1h,062h,090h	; 98f9  .b..s..b.
	defb 0adh,0a5h,095h,071h,074h,071h,094h,0a4h,0ach	; 9902  ...qtq...
	defb 0afh,09fh,097h,075h,076h,077h,096h,09eh,0aeh	; 990b  ...uvw...

; ----------------------------------------------------------------------
; DATOS centro_maq1_cerrado: El centro de la maquina 1 cerrado: 3 filas de 9
;   casillas
;   0x9914..0x992f  (27 bytes)
DATA_centro_maq1_cerrado:
	defb 091h,062h,0f0h,0f2h,073h,0f3h,0f1h,062h,090h	; 9914  .b..s..b.
	defb 062h,062h,0f6h,0f4h,074h,0f5h,0f7h,062h,062h	; 991d  bb..t..bb
	defb 062h,062h,0f8h,075h,076h,077h,0f9h,062h,062h	; 9926  bb.uvw.bb

; ----------------------------------------------------------------------
; DATOS sprites_dibujos_datos: Los dibujos de los sprites: 30 de 16 x 16 (960
;   bytes)
;   0x992f..0x9cef  (960 bytes)
DATA_sprites_dibujos_datos:
	defb 000h,000h,003h,00dh,01dh,01dh,03dh,03dh,03fh,021h,01fh,01fh,00fh,003h,000h,000h	; 992f  ......==?!......
	defb 000h,000h,0c0h,0f0h,0f8h,0f8h,084h,0fch,0fch,0bch,0b8h,0b8h,0b0h,0c0h,000h,000h	; 993f  ................
	defb 000h,000h,003h,00fh,01fh,01eh,02dh,037h,03bh,03dh,01fh,01eh,00dh,003h,000h,000h	; 994f  ......-7;=......
	defb 000h,000h,0c0h,0b0h,078h,0f8h,0bch,0dch,0ech,0b4h,078h,0f8h,0f0h,0c0h,000h,000h	; 995f  ....x.....x.....
	defb 070h,0f8h,0f8h,0f8h,0f8h,070h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 996f  p....p..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 997f  ................
	defb 070h,0d8h,0f8h,0f8h,0f8h,070h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 998f  p....p..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 999f  ................
	defb 070h,0d8h,0e8h,0f8h,0f8h,070h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99af  p....p..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99bf  ................
	defb 070h,0d8h,0e8h,0e8h,0f8h,070h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99cf  p....p..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99df  ................
	defb 020h,070h,0f8h,0f8h,070h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99ef   p..p ..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 99ff  ................
	defb 060h,0d0h,0f0h,0f0h,060h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a0f  `...`...........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a1f  ................
	defb 000h,000h,060h,0d0h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a2f  ..`.............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a3f  ................
	defb 060h,0f0h,0f0h,060h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a4f  `..`............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9a5f  ................
	defb 000h,016h,006h,026h,08bh,05fh,09ah,0bdh,0f9h,078h,022h,030h,010h,018h,00ch,00eh	; 9a6f  ...&._...x"0....
	defb 080h,088h,0a4h,0e4h,090h,078h,0fah,06ch,026h,046h,024h,00dh,008h,01ah,030h,07ch	; 9a7f  .....x.l&F$...0|
	defb 000h,000h,000h,000h,004h,000h,005h,002h,006h,007h,01dh,00fh,02fh,027h,013h,011h	; 9a8f  ............/'..
	defb 000h,000h,000h,000h,060h,084h,004h,092h,0d8h,0b8h,0dah,0f2h,0f4h,0e4h,0cch,080h	; 9a9f  ....`...........
	defb 000h,000h,000h,000h,000h,00ah,001h,025h,003h,00bh,02bh,01fh,00fh,02fh,007h,00bh	; 9aaf  .......%..+../..
	defb 000h,000h,000h,000h,080h,020h,048h,020h,054h,050h,0ech,0d8h,0f8h,0f0h,0f0h,0e8h	; 9abf  ..... H TP......
	defb 000h,000h,000h,00ch,01eh,01fh,03fh,03fh,07fh,077h,0e3h,0c1h,081h,081h,000h,000h	; 9acf  ......??.w......
	defb 000h,000h,000h,030h,078h,0f8h,0fch,0fch,0feh,0eeh,0c7h,083h,081h,081h,000h,000h	; 9adf  ...0x...........
	defb 000h,000h,000h,000h,000h,000h,002h,003h,007h,007h,003h,001h,001h,001h,000h,000h	; 9aef  ................
	defb 000h,000h,000h,000h,000h,000h,000h,010h,030h,028h,000h,000h,000h,000h,000h,000h	; 9aff  ........0(......
	defb 001h,003h,007h,003h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9b0f  ................
	defb 080h,0c0h,0e0h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9b1f  ................
	defb 000h,000h,000h,006h,007h,00fh,00fh,01fh,01fh,03ch,038h,070h,060h,040h,040h,000h	; 9b2f  .........<8p`@@.
	defb 000h,000h,000h,060h,0e0h,0f0h,0f0h,0f8h,0f8h,03ch,01ch,02eh,036h,012h,012h,000h	; 9b3f  ...`.....<..6...
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,004h,00ch,008h,008h,000h	; 9b4f  ................
	defb 000h,000h,000h,000h,000h,000h,040h,0e0h,0e0h,030h,018h,008h,004h,000h,000h,000h	; 9b5f  ......@..0......
	defb 001h,003h,003h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9b6f  ................
	defb 080h,0c0h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9b7f  ................
	defb 000h,000h,000h,00eh,00fh,039h,05fh,01bh,01bh,009h,000h,000h,000h,000h,000h,000h	; 9b8f  .....9_.........
	defb 000h,000h,000h,038h,03ch,0ceh,0edh,075h,077h,0f0h,060h,000h,000h,000h,000h,000h	; 9b9f  ...8<..uw.`.....
	defb 000h,000h,000h,000h,010h,004h,000h,044h,064h,036h,003h,001h,000h,000h,000h,000h	; 9baf  .......Dd6......
	defb 000h,000h,000h,000h,040h,010h,010h,008h,008h,00eh,080h,0c0h,000h,000h,000h,000h	; 9bbf  ....@...........
	defb 000h,000h,000h,000h,000h,002h,020h,020h,000h,000h,000h,000h,000h,000h,000h,000h	; 9bcf  ......  ........
	defb 000h,000h,000h,000h,000h,020h,002h,082h,080h,000h,000h,000h,000h,000h,000h,000h	; 9bdf  ..... ..........
	defb 000h,000h,000h,001h,001h,038h,030h,03eh,027h,027h,007h,000h,000h,000h,000h,000h	; 9bef  .....80>''......
	defb 000h,000h,000h,0c0h,0e0h,02eh,006h,03ah,035h,034h,01ch,000h,000h,000h,000h,000h	; 9bff  .......:54......
	defb 000h,000h,000h,000h,002h,002h,00ch,000h,050h,010h,018h,00eh,000h,000h,000h,000h	; 9c0f  ........P.......
	defb 000h,000h,000h,000h,000h,000h,018h,004h,042h,042h,060h,038h,000h,000h,000h,000h	; 9c1f  ........BB`8....
	defb 000h,000h,000h,000h,000h,001h,043h,041h,008h,008h,000h,000h,000h,000h,000h,000h	; 9c2f  ......CA........
	defb 000h,000h,000h,000h,000h,0c0h,0e1h,0c1h,088h,088h,000h,000h,000h,000h,000h,000h	; 9c3f  ................
	defb 000h,001h,007h,01dh,03ah,03bh,03bh,03bh,01bh,007h,008h,019h,011h,013h,003h,001h	; 9c4f  ....:;;;........
	defb 078h,0e3h,08fh,0fch,0fbh,077h,0ach,0c0h,080h,080h,0c0h,000h,080h,080h,000h,000h	; 9c5f  x....w..........
	defb 01eh,0c7h,0f1h,03fh,0dfh,077h,035h,003h,001h,001h,003h,000h,001h,001h,000h,000h	; 9c6f  ...?.w5.........
	defb 000h,080h,0e0h,0b8h,05ch,0dch,0dch,0dch,0d8h,070h,010h,098h,088h,0c8h,0c0h,040h	; 9c7f  ....\....p.....@
	defb 000h,000h,000h,003h,004h,008h,013h,03fh,07fh,07fh,03fh,00fh,000h,000h,000h,000h	; 9c8f  .......?..?.....
	defb 000h,000h,000h,0c0h,020h,010h,0c8h,0fch,0f7h,0f7h,0fch,0f0h,000h,000h,000h,000h	; 9c9f  .... ...........
	defb 000h,001h,007h,01dh,03ah,03bh,03bh,03bh,01bh,007h,018h,071h,003h,003h,006h,01ch	; 9caf  ....:;;;...q....
	defb 078h,0e3h,08fh,0fch,0fbh,077h,0ach,0c0h,080h,080h,0c0h,000h,0c0h,080h,000h,000h	; 9cbf  x....w..........
	defb 01eh,0c7h,0f1h,03fh,0dfh,077h,035h,003h,001h,001h,003h,000h,003h,001h,000h,000h	; 9ccf  ...?.w5.........
	defb 000h,080h,0e0h,0b8h,05ch,0dch,0dch,0dch,0d8h,070h,018h,08eh,0c0h,0c0h,060h,038h	; 9cdf  ....\....p....`8

; ======================================================================
; CODIGO 0x9cef..0x9d18  (41 bytes)
; ======================================================================


lamparas_apaga:		; Las siete lamparas de la maquina (0x9D18), apagadas: la casilla 0xC3
	ld hl,09d18h		;9cef   ; las direcciones
	ld a,007h		;9cf2   ; siete
L_9CF4:
	ld b,0c3h		;9cf4   ; la casilla 0xC3
	push af			;9cf6
	call lampara_pon		;9cf7   ; dos casillas en la direccion
	ex de,hl			;9cfa
	inc hl			;9cfb   ; la siguiente
	pop af			;9cfc
	dec a			;9cfd
	jr nz,L_9CF4		;9cfe
	ret			;9d00
lampara_enciende:		; La lampara A encendida: la casilla 0xC9
	add a,a			;9d01   ; A x 2
	ld c,a			;9d02
	ld b,000h		;9d03
	ld hl,09d16h		;9d05   ; la tabla (0x9D16)
	add hl,bc			;9d08
	ld b,0c9h		;9d09
lampara_pon:		; Las dos casillas de la lampara (WRTVRM)
	ld e,(hl)			;9d0b   ; la direccion
	inc hl			;9d0c
	ld d,(hl)			;9d0d
	ex de,hl			;9d0e
	ld a,b			;9d0f
	call 0004dh		;9d10   ; WRTVRM
	inc hl			;9d13
	call 0004dh		;9d14
	ret			;9d17

; ----------------------------------------------------------------------
; DATOS lamparas (tramo): Las direcciones de la pantalla de las lamparas
;   0x9d18..0x9d26  (14 bytes)  de 0x9d16..0x9d26 (16 bytes)
DATA_lamparas_9D18:
	defw 0233ah,02340h,0268eh,02336h,02696h,02350h,0235ah	; 9d18

; ======================================================================
; CODIGO 0x9d26..0x9df7  (209 bytes)
; ======================================================================


luces:		; Mientras dura la cuenta 0xED29, las luces de la maquina cambian de color cada 16 cuadros (0xA7FF o 0xA7EB)
	ld a,(0ed29h)		;9d26   ; las luces encendidas?
	or a			;9d29   ; encendidas?
	ret z			;9d2a
	dec a			;9d2b   ; un cuadro menos
	ld (0ed29h),a		;9d2c   ; un cuadro menos
	and 010h		;9d2f   ; cada 16 cuadros...
	ld hl,0a7ffh		;9d31   ; ...unas...
	jr z,L_9D39		;9d34
	ld hl,0a7ebh		;9d36   ; ...u otras
L_9D39:
	ld de,02388h		;9d39   ; en los colores de 0x2388...
	ld a,00ah		;9d3c   ; ...diez tramos
luces_tramo:		; Un tramo: el color y cuantos bytes (FILVRM)
	push af			;9d3e
	ld a,(hl)			;9d3f   ; el color
	inc hl			;9d40
	ld c,(hl)			;9d41   ; cuantos bytes
	inc hl			;9d42
	ld b,000h		;9d43
	ex de,hl			;9d45
	push bc			;9d46
	push hl			;9d47
	call 00056h		;9d48   ; FILVRM
	pop hl			;9d4b
	pop bc			;9d4c
	add hl,bc			;9d4d   ; el tramo siguiente
	ex de,hl			;9d4e
	pop af			;9d4f
	dec a			;9d50   ; los diez
	jr nz,luces_tramo		;9d51
	ret			;9d53
casillas:		; Las casillas de la maquina en los tres tercios: unas tal cual y otras dos veces, tal cual y en espejo
	ld hl,00300h		;9d54   ; el primer tercio, desde la casilla 0x60...
	ld de,09df7h		;9d57   ; ...de 0x9DF7...
	ld c,013h		;9d5a   ; ...19 casillas tal cual...
	call casillas_tal_cual		;9d5c   ; (19)
	ld c,033h		;9d5f   ; ...y 51 con su espejo
	call casillas_espejo		;9d61   ; (51)
	ld hl,00b00h		;9d64   ; el segundo tercio: 40 y 60
	ld de,0a027h		;9d67   ; de 0xA027
	ld c,028h		;9d6a
	call casillas_tal_cual		;9d6c
	ld c,03ch		;9d6f
	call casillas_espejo		;9d71
	ld hl,01300h		;9d74   ; el tercero: 40 y 36
	ld de,0a347h		;9d77   ; de 0xA347
	ld c,028h		;9d7a
	call casillas_tal_cual		;9d7c
	ld c,024h		;9d7f
	call casillas_espejo		;9d81
casillas_colores:		; Sus colores, en tramos (color, cuantos bytes): 71, 134 y 92 tramos
	ld hl,0a5a7h		;9d84   ; los colores del primer tercio...
	ld de,02300h		;9d87   ; ...desde la casilla 0x60
	ld a,047h		;9d8a   ; 71 tramos
	call colores_tramos		;9d8c
	ld hl,0a635h		;9d8f   ; el segundo
	ld de,02b00h		;9d92
	ld a,086h		;9d95   ; 134 tramos
	call colores_tramos		;9d97
	ld hl,0a741h		;9d9a   ; el tercero
	ld de,03300h		;9d9d
	ld a,05ch		;9da0   ; 92 tramos
	call colores_tramos		;9da2
	ret			;9da5
colores_tramos:		; A tramos (color, cuantos bytes; FILVRM cada uno)
	push af			;9da6
	ld a,(hl)			;9da7   ; el color
	inc hl			;9da8
	ld c,(hl)			;9da9   ; cuantos bytes
	inc hl			;9daa
	ld b,000h		;9dab
	ex de,hl			;9dad
	push bc			;9dae
	push hl			;9daf
	call 00056h		;9db0   ; FILVRM
	pop hl			;9db3
	pop bc			;9db4
	add hl,bc			;9db5   ; la direccion siguiente
	ex de,hl			;9db6
	pop af			;9db7
	dec a			;9db8   ; todos
	jr nz,colores_tramos		;9db9
	ret			;9dbb
casillas_dobles:		; Cada casilla de DE dos veces seguidas, C veces. Nadie la llama
	push de			;9dbc   ; la misma casilla...
	call casilla		;9dbd   ; ...en HL...
	pop de			;9dc0
	call casilla		;9dc1   ; ...y otra vez
	dec c			;9dc4   ; una menos
	jr nz,casillas_dobles		;9dc5
	ret			;9dc7
casillas_tal_cual:		; C casillas de DE en HL (WRTVRM)
	call casilla		;9dc8
	dec c			;9dcb   ; una menos
	jr nz,casillas_tal_cual		;9dcc
	ret			;9dce
casilla:		; Una casilla: 8 bytes
	ld b,008h		;9dcf   ; 8 bytes
L_9DD1:
	ld a,(de)			;9dd1
	call 0004dh		;9dd2   ; WRTVRM
	inc hl			;9dd5
	inc de			;9dd6
	djnz L_9DD1		;9dd7
	ret			;9dd9
casillas_espejo:		; C casillas de DE, cada una tal cual y su espejo (los bits al reves) detras
	push de			;9dda
	call casilla		;9ddb   ; tal cual
	pop de			;9dde   ; otra vez la misma...
	ld b,008h		;9ddf   ; 8 bytes
espejo_byte:		; ...un byte...
	ld a,(de)			;9de1
	push bc			;9de2
	ld b,008h		;9de3   ; los 8 bits...
espejo_bit:		; ...con los bits al reves
	rlca			;9de5
	rr c		;9de6   ; ...al reves en C
	djnz espejo_bit		;9de8
	ld a,c			;9dea
	pop bc			;9deb
	call 0004dh		;9dec   ; WRTVRM
	inc hl			;9def
	inc de			;9df0
	djnz espejo_byte		;9df1
	dec c			;9df3   ; una menos
	jr nz,casillas_espejo		;9df4
	ret			;9df6

; ----------------------------------------------------------------------
; DATOS casillas_tercio1: Las casillas del primer tercio; en 0x9FC7, dentro,
;   el sonido del giro del tragaperras: los mismos bytes son casillas y pieza
;   de musica
;   0x9df7..0xa027  (560 bytes)
DATA_casillas_tercio1:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 9df7  ........
	defb 000h,000h,000h,018h,018h,000h,000h,000h	; 9dff  ........
	defb 000h,000h,081h,081h,000h,000h,000h,000h	; 9e07  ........
	defb 000h,000h,000h,000h,000h,081h,081h,000h	; 9e0f  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h	; 9e17  ........
	defb 000h,000h,000h,000h,081h,0e7h,0ffh,07eh	; 9e1f  .......~
	defb 07eh,07eh,07eh,07eh,0ffh,0ffh,0c7h,0c7h	; 9e27  ~~~~....
	defb 00fh,03fh,0e3h,0e3h,0ffh,0f7h,0e7h,0f7h	; 9e2f  .?......
	defb 01fh,01fh,0f8h,01eh,0ddh,09eh,078h,01fh	; 9e37  ......x.
	defb 0ffh,0f7h,0e7h,0d7h,0c3h,0f7h,0ffh,0ffh	; 9e3f  ........
	defb 0f8h,0f8h,01fh,07ch,03bh,0d8h,03ah,0f8h	; 9e47  ...|;.:.
	defb 0f0h,0fch,0c7h,0c7h,0ffh,0c7h,0f7h,0efh	; 9e4f  ........
	defb 000h,000h,000h,000h,000h,081h,0e7h,0ffh	; 9e57  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e5f  ........
	defb 0ffh,0ffh,0ffh,0ffh,0c3h,081h,000h,000h	; 9e67  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e6f  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e77  ........
	defb 000h,000h,000h,000h,000h,000h,0ffh,0ffh	; 9e7f  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 9e87  ........
	defb 000h,000h,000h,000h,000h,000h,003h,003h	; 9e8f  ........
	defb 000h,000h,000h,000h,000h,000h,0ffh,0feh	; 9e97  ........
	defb 003h,003h,003h,003h,003h,003h,003h,003h	; 9e9f  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh	; 9ea7  ........
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h	; 9eaf  ........
	defb 003h,003h,003h,003h,003h,003h,003h,002h	; 9eb7  ........
	defb 0ffh,07fh,03fh,01fh,00fh,007h,003h,001h	; 9ebf  ..?.....
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9ec7  ........
	defb 000h,000h,000h,000h,003h,01fh,03fh,0ffh	; 9ecf  ......?.
	defb 000h,001h,01fh,07fh,0ffh,0ffh,0ffh,0feh	; 9ed7  ........
	defb 03fh,0ffh,0ffh,0ffh,0ffh,0ffh,0e0h,000h	; 9edf  ?.......
	defb 0ffh,0ffh,0ffh,0ffh,0feh,0fch,0f8h,0f0h	; 9ee7  ........
	defb 007h,00fh,01fh,07fh,0ffh,0ffh,0feh,0f8h	; 9eef  ........
	defb 0ffh,0ffh,0ffh,0f0h,0e0h,080h,000h,000h	; 9ef7  ........
	defb 0f0h,080h,000h,000h,000h,000h,000h,000h	; 9eff  ........
	defb 000h,000h,000h,001h,003h,007h,00fh,01fh	; 9f07  ........
	defb 01fh,07fh,0ffh,0ffh,0feh,0fch,0f0h,0e0h	; 9f0f  ........
	defb 0f0h,0c0h,080h,000h,000h,000h,000h,000h	; 9f17  ........
	defb 000h,000h,000h,000h,000h,000h,00ch,00ch	; 9f1f  ........
	defb 000h,000h,000h,000h,000h,000h,003h,003h	; 9f27  ........
	defb 000h,000h,000h,000h,001h,003h,007h,007h	; 9f2f  ........
	defb 03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h	; 9f37  ?.......
	defb 0c0h,080h,000h,000h,000h,000h,000h,000h	; 9f3f  ........
	defb 00fh,01fh,03fh,03fh,07fh,0feh,0feh,0fch	; 9f47  ..??....
	defb 0c0h,0c0h,080h,080h,000h,000h,000h,000h	; 9f4f  ........
	defb 000h,000h,001h,001h,000h,000h,000h,000h	; 9f57  ........
	defb 018h,018h,000h,060h,060h,000h,0c0h,0c0h	; 9f5f  ...``...
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 9f67  ........
	defb 001h,003h,003h,007h,007h,00fh,00fh,01fh	; 9f6f  ........
	defb 007h,00fh,00fh,01fh,01fh,01fh,03fh,03fh	; 9f77  ......??
	defb 0feh,0fch,0fch,0f8h,0f0h,0e0h,0c0h,080h	; 9f7f  ........
	defb 000h,001h,001h,000h,000h,000h,000h,000h	; 9f87  ........
	defb 000h,080h,080h,000h,000h,000h,000h,000h	; 9f8f  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 9f97  ........
	defb 0e0h,0c0h,080h,080h,001h,001h,003h,003h	; 9f9f  ........
	defb 07fh,07fh,0ffh,0ffh,0feh,0fch,0fch,0f8h	; 9fa7  ........
	defb 000h,000h,080h,006h,006h,000h,003h,003h	; 9faf  ........
	defb 000h,000h,000h,000h,006h,006h,000h,000h	; 9fb7  ........
	defb 000h,000h,00ch,00ch,000h,060h,060h,000h	; 9fbf  .....``.
	defb 0fah,000h,00ah,030h,001h,002h,034h,001h	; 9fc7  ...0..4.
	defb 002h,0fdh,000h,000h,0ffh,000h,000h,000h	; 9fcf  ........
	defb 001h,001h,001h,001h,003h,003h,003h,003h	; 9fd7  ........
	defb 0f8h,0f8h,0f8h,0f0h,0f0h,0f0h,0f0h,0f0h	; 9fdf  ........
	defb 0f8h,0f0h,0f0h,0f0h,0e0h,0e0h,0e0h,0e0h	; 9fe7  ........
	defb 000h,001h,001h,000h,000h,000h,000h,000h	; 9fef  ........
	defb 000h,000h,080h,080h,000h,001h,001h,000h	; 9ff7  ........
	defb 000h,000h,000h,000h,000h,080h,080h,000h	; 9fff  ........
	defb 000h,000h,0c0h,0f0h,0fch,0ffh,0f8h,0f8h	; a007  ........
	defb 001h,001h,081h,0c1h,0e1h,0f1h,0f9h,07dh	; a00f  .......}
	defb 07fh,07fh,03fh,03fh,01fh,01fh,00fh,00fh	; a017  ..??....
	defb 001h,007h,00fh,01fh,03fh,07fh,07fh,0ffh	; a01f  ....?...

; ----------------------------------------------------------------------
; DATOS casillas_tercio2: Las casillas del segundo tercio
;   0xa027..0xa347  (800 bytes)
DATA_casillas_tercio2:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a027  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a02f  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a037  ........
	defb 000h,000h,000h,018h,018h,000h,000h,000h	; a03f  ........
	defb 000h,000h,081h,081h,000h,000h,000h,000h	; a047  ........
	defb 000h,000h,000h,000h,000h,081h,081h,000h	; a04f  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07eh,03ch	; a057  ......~<
	defb 018h,018h,000h,000h,000h,000h,000h,000h	; a05f  ........
	defb 0f7h,0e3h,0ffh,0fch,000h,000h,000h,000h	; a067  ........
	defb 0efh,0efh,0ffh,03fh,000h,000h,000h,000h	; a06f  ...?....
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a077  ........
	defb 018h,03ch,07eh,0dbh,0dbh,0dbh,0c3h,0ffh	; a07f  .<~.....
	defb 0ffh,0ffh,0e7h,0c3h,0c3h,0e7h,0ffh,0ffh	; a087  ........
	defb 0c3h,0e7h,03ch,000h,000h,000h,000h,000h	; a08f  ..<.....
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; a097  ........
	defb 018h,0bdh,0ffh,0ffh,0ffh,0ffh,0ffh,03ch	; a09f  .......<
	defb 000h,000h,000h,000h,000h,000h,000h,081h	; a0a7  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a0af  ........
	defb 000h,000h,018h,03ch,07eh,0e7h,0e7h,0c3h	; a0b7  ...<~...
	defb 0c3h,081h,081h,018h,018h,03ch,03ch,07eh	; a0bf  .....<<~
	defb 07eh,0ffh,0e7h,0e7h,0c3h,0c3h,081h,000h	; a0c7  ~.......
	defb 0fch,0f0h,0f0h,0f0h,0f3h,0ffh,000h,001h	; a0cf  ........
	defb 000h,018h,03ch,0ffh,0ffh,0ffh,000h,001h	; a0d7  ..<.....
	defb 03fh,00fh,00fh,00fh,0cfh,0ffh,000h,001h	; a0df  ?.......
	defb 000h,0ffh,0fch,0fch,000h,000h,000h,000h	; a0e7  ........
	defb 000h,0ffh,0feh,0efh,000h,000h,000h,000h	; a0ef  ........
	defb 000h,0ffh,07fh,07fh,000h,000h,000h,000h	; a0f7  ........
	defb 07dh,045h,045h,07dh,005h,005h,07dh,001h	; a0ff  }EE}..}.
	defb 011h,011h,011h,011h,011h,011h,011h,001h	; a107  ........
	defb 07dh,005h,005h,07dh,005h,005h,07dh,001h	; a10f  }..}..}.
	defb 07dh,041h,041h,07dh,005h,005h,07dh,001h	; a117  }AA}..}.
	defb 07dh,041h,041h,07dh,045h,045h,07dh,001h	; a11f  }AA}EE}.
	defb 07dh,045h,045h,07dh,045h,045h,07dh,001h	; a127  }EE}EE}.
	defb 07dh,005h,005h,005h,005h,005h,005h,001h	; a12f  }.......
	defb 07dh,005h,005h,005h,005h,005h,005h,001h	; a137  }.......
	defb 07dh,005h,005h,005h,005h,005h,005h,001h	; a13f  }.......
	defb 07dh,005h,005h,005h,005h,005h,005h,001h	; a147  }.......
	defb 0c3h,0ffh,0bdh,0bdh,0dbh,0dbh,0e7h,0ffh	; a14f  ........
	defb 000h,000h,000h,000h,018h,018h,018h,018h	; a157  ........
	defb 000h,000h,000h,000h,000h,0ffh,000h,000h	; a15f  ........
	defb 003h,003h,003h,003h,003h,001h,000h,000h	; a167  ........
	defb 000h,000h,001h,001h,003h,003h,003h,002h	; a16f  ........
	defb 000h,000h,010h,018h,01ch,00eh,00fh,007h	; a177  ........
	defb 000h,000h,000h,000h,060h,038h,03eh,00fh	; a17f  ....`8>.
	defb 000h,000h,001h,001h,000h,000h,000h,000h	; a187  ........
	defb 000h,000h,080h,080h,000h,001h,001h,000h	; a18f  ........
	defb 080h,0c0h,0e0h,0f8h,0feh,0ffh,0ffh,0ffh	; a197  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,0f8h	; a19f  ........
	defb 007h,007h,007h,007h,007h,007h,007h,007h	; a1a7  ........
	defb 00fh,01fh,01fh,01fh,03fh,03fh,03fh,07fh	; a1af  ....???.
	defb 0e0h,0e0h,0c0h,0c0h,0c0h,080h,080h,080h	; a1b7  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h	; a1bf  ........
	defb 00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh	; a1c7  ........
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; a1cf  ........
	defb 000h,000h,000h,000h,000h,080h,0f0h,0ffh	; a1d7  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; a1df  ........
	defb 0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh	; a1e7  ........
	defb 000h,000h,000h,030h,030h,000h,000h,000h	; a1ef  ...00...
	defb 000h,000h,000h,000h,000h,000h,007h,007h	; a1f7  ........
	defb 0f8h,0f8h,0f8h,0f8h,0f8h,0f8h,000h,000h	; a1ff  ........
	defb 000h,000h,000h,000h,001h,001h,000h,000h	; a207  ........
	defb 03fh,03fh,03fh,03fh,01fh,01fh,01fh,00fh	; a20f  ????....
	defb 080h,080h,080h,080h,080h,0c0h,0c0h,0c0h	; a217  ........
	defb 000h,006h,006h,000h,000h,000h,000h,000h	; a21f  ........
	defb 003h,003h,003h,003h,001h,001h,001h,001h	; a227  ........
	defb 00fh,00fh,00fh,00fh,00fh,007h,007h,007h	; a22f  ........
	defb 0e0h,0e0h,0e0h,0f0h,0f0h,0f0h,0f8h,0f8h	; a237  ........
	defb 000h,000h,000h,000h,003h,003h,000h,003h	; a23f  ........
	defb 000h,000h,000h,000h,000h,060h,06ch,00dh	; a247  .....`l.
	defb 000h,000h,000h,000h,000h,000h,000h,080h	; a24f  ........
	defb 003h,003h,001h,001h,080h,080h,0c0h,0c0h	; a257  ........
	defb 0f8h,0fch,0fch,0fch,0feh,0feh,07fh,07fh	; a25f  ........
	defb 003h,000h,006h,006h,000h,00ch,00ch,000h	; a267  ........
	defb 001h,000h,000h,000h,000h,000h,000h,000h	; a26f  ........
	defb 0b0h,030h,000h,000h,000h,000h,000h,000h	; a277  .0......
	defb 0ffh,0f8h,080h,000h,000h,000h,000h,000h	; a27f  ........
	defb 000h,000h,0fch,01fh,001h,000h,000h,000h	; a287  ........
	defb 000h,000h,000h,0f0h,0ffh,01fh,001h,000h	; a28f  ........
	defb 000h,000h,000h,000h,0c0h,0ffh,0ffh,01fh	; a297  ........
	defb 001h,001h,003h,003h,003h,003h,0feh,0feh	; a29f  ........
	defb 061h,061h,061h,001h,001h,001h,000h,000h	; a2a7  aaa.....
	defb 0ffh,09fh,080h,080h,0c0h,0c0h,0c0h,0c0h	; a2af  ........
	defb 0f0h,0f8h,0fch,07fh,03fh,00fh,000h,000h	; a2b7  ....?...
	defb 000h,000h,000h,000h,000h,001h,003h,003h	; a2bf  ........
	defb 007h,00fh,01fh,0ffh,0ffh,0ffh,0ffh,007h	; a2c7  ........
	defb 004h,004h,004h,004h,004h,004h,004h,004h	; a2cf  ........
	defb 00ch,00ch,00ch,00ch,00ch,00ch,00ch,00ch	; a2d7  ........
	defb 01ch,07ch,07ch,01ch,01ch,01ch,01ch,01ch	; a2df  .||.....
	defb 03ch,03ch,03ch,03ch,03ch,030h,020h,020h	; a2e7  <<<<<0  
	defb 001h,001h,003h,003h,003h,003h,001h,001h	; a2ef  ........
	defb 007h,007h,007h,007h,007h,007h,007h,007h	; a2f7  ........
	defb 000h,000h,000h,001h,001h,001h,001h,001h	; a2ff  ........
	defb 001h,001h,001h,001h,001h,001h,001h,001h	; a307  ........
	defb 00fh,00fh,00fh,01fh,01fh,01fh,03fh,03fh	; a30f  ......??
	defb 07fh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a317  ........
	defb 001h,001h,001h,001h,003h,007h,01fh,01fh	; a31f  ........
	defb 01fh,01fh,01fh,01fh,01fh,01fh,01eh,01eh	; a327  ........
	defb 01eh,01eh,00eh,00eh,006h,006h,002h,002h	; a32f  ........
	defb 001h,001h,001h,001h,000h,000h,000h,000h	; a337  ........
	defb 0f0h,0f0h,0f8h,0f8h,0fch,0fch,0feh,0ffh	; a33f  ........

; ----------------------------------------------------------------------
; DATOS casillas_tercio3: Las casillas del tercer tercio (la lectura sigue por
;   la tabla de la bandeja y el codigo de 0xA507)
;   0xa347..0xa4e7  (416 bytes)
DATA_casillas_tercio3:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a347  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a34f  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a357  ........
	defb 000h,000h,001h,001h,000h,000h,000h,000h	; a35f  ........
	defb 000h,000h,000h,018h,018h,000h,000h,000h	; a367  ........
	defb 018h,018h,000h,000h,000h,000h,000h,000h	; a36f  ........
	defb 081h,081h,000h,000h,000h,000h,000h,000h	; a377  ........
	defb 007h,007h,003h,001h,000h,000h,000h,000h	; a37f  ........
	defb 0e0h,0f0h,0f8h,0fch,0feh,0ffh,07fh,03fh	; a387  .......?
	defb 01fh,00fh,007h,003h,001h,000h,000h,000h	; a38f  ........
	defb 0e0h,0f0h,0f8h,0fch,0feh,0ffh,07fh,03fh	; a397  .......?
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a39f  ........
	defb 00fh,007h,003h,001h,000h,000h,000h,000h	; a3a7  ........
	defb 000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh	; a3af  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; a3b7  ........
	defb 018h,0bdh,0ffh,0ffh,0ffh,0ffh,0ffh,03ch	; a3bf  .......<
	defb 000h,000h,000h,000h,000h,000h,000h,081h	; a3c7  ........
	defb 000h,081h,081h,000h,000h,018h,03ch,07eh	; a3cf  ......<~
	defb 0ffh,0e7h,0c7h,0e7h,0e7h,0e7h,0c3h,0ffh	; a3d7  ........
	defb 0ffh,0e7h,0dbh,0fbh,0e7h,0dfh,0c3h,0ffh	; a3df  ........
	defb 0e0h,0e0h,0c0h,080h,000h,000h,000h,000h	; a3e7  ........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a3ef  ........
	defb 007h,00fh,01fh,03fh,07fh,0ffh,0feh,0fch	; a3f7  ...?....
	defb 0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h	; a3ff  ........
	defb 00dh,02bh,055h,0eah,0ffh,07fh,07fh,03fh	; a407  .+U....?
	defb 048h,0ach,056h,0abh,0ffh,0feh,0feh,0fch	; a40f  H.V.....
	defb 01ch,01ch,01ch,01ch,01ch,01ch,01ch,01ch	; a417  ........
	defb 000h,001h,003h,007h,00fh,01fh,03fh,07fh	; a41f  ......?.
	defb 000h,000h,000h,000h,000h,000h,070h,0f9h	; a427  ......p.
	defb 000h,000h,000h,000h,000h,000h,000h,08eh	; a42f  ........
	defb 000h,000h,000h,000h,0c3h,0e7h,0ddh,0f7h	; a437  ........
	defb 000h,000h,000h,000h,081h,0dbh,0f3h,09dh	; a43f  ........
	defb 007h,00fh,03fh,07fh,0ffh,0ffh,0feh,0f8h	; a447  ..?.....
	defb 0f0h,0e0h,0c0h,080h,000h,000h,000h,000h	; a44f  ........
	defb 000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh	; a457  ........
	defb 000h,000h,070h,0f0h,0eeh,0d7h,0bbh,07dh	; a45f  ..p....}
	defb 000h,000h,000h,038h,07ch,00dh,077h,0fbh	; a467  ...8|.w.
	defb 070h,0f9h,0fbh,03ah,0d7h,0efh,0efh,0eeh	; a46f  p..:....
	defb 00eh,0d3h,0edh,0feh,05dh,08bh,073h,0fbh	; a477  ....].s.
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a47f  ........
	defb 003h,003h,003h,003h,003h,001h,000h,000h	; a487  ........
	defb 000h,000h,001h,001h,003h,003h,003h,002h	; a48f  ........
	defb 000h,000h,010h,018h,01ch,00eh,00fh,007h	; a497  ........
	defb 000h,000h,000h,000h,060h,038h,03eh,00fh	; a49f  ....`8>.
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,0ffh	; a4a7  .....?..
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,0ffh	; a4af  .....?..
	defb 000h,001h,003h,007h,00fh,01fh,03fh,07fh	; a4b7  ......?.
	defb 0e0h,0e0h,0f0h,0f0h,0f8h,0f8h,0fch,0feh	; a4bf  ........
	defb 03fh,03fh,01fh,01fh,01fh,00fh,00fh,007h	; a4c7  ??......
	defb 000h,000h,000h,000h,000h,080h,080h,080h	; a4cf  ........
	defb 030h,030h,080h,080h,000h,000h,000h,000h	; a4d7  00......
	defb 001h,001h,080h,080h,000h,000h,000h,000h	; a4df  ........

; ----------------------------------------------------------------------
; DATOS bandeja_tabla: Las casillas de la bandeja, una por capa (5), y 27
;   bytes mas que lee la carga de casillas
;   0xa4e7..0xa507  (32 bytes)
DATA_bandeja_tabla:
	defb 020h,07ch,07eh,083h,085h	; a4e7
	defb 000h,000h,000h,003h,001h,001h,080h,080h,0c0h	; a4ec  .........
	defb 0e0h,0e0h,080h,080h,0c0h,0c0h,0c0h,0c0h,0c0h	; a4f5  .........
	defb 0c0h,030h,030h,000h,000h,000h,000h,000h,000h	; a4fe  .00......

; ======================================================================
; CODIGO 0xa507..0xa510  (9 bytes)
; ======================================================================


pantalla_borra:		; La tabla de nombres llena de A
	ld hl,01800h		;a507
	ld bc,00300h		;a50a
	jp 00056h		;a50d

; ----------------------------------------------------------------------
; DATOS bytes_a510: Siete bytes entre dos rutinas: la carga de casillas del
;   tercer tercio los lee como dibujo
;   0xa510..0xa517  (7 bytes)
DATA_bytes_a510:
	defb 000h,000h,000h,000h,000h,080h,0c0h	; a510

; ======================================================================
; CODIGO 0xa517..0xa51f  (8 bytes)
; ======================================================================


sprites_fuera:		; El primer sprite con Y = 0xD0: ninguno se ve
	ld a,0d0h		;a517
	ld hl,01b00h		;a519
	jp 0004dh		;a51c

; ----------------------------------------------------------------------
; DATOS bytes_a51f: Lo que lee la carga de casillas del tercer tercio despues
;   del codigo
;   0xa51f..0xa5a7  (136 bytes)
DATA_bytes_a51f:
	defb 000h,000h,000h,000h,000h,080h,0c0h,0f0h	; a51f  ........
	defb 0f8h,0feh,0ffh,0ffh,07fh,01fh,00fh,007h	; a527  ........
	defb 000h,000h,080h,0e0h,0f0h,0feh,0ffh,0ffh	; a52f  ........
	defb 000h,000h,000h,000h,000h,000h,080h,0f0h	; a537  ........
	defb 000h,000h,000h,000h,00fh,01fh,03fh,03fh	; a53f  ......??
	defb 0ffh,03fh,00fh,003h,000h,000h,000h,000h	; a547  .?......
	defb 0feh,0ffh,0ffh,0ffh,07fh,01fh,001h,000h	; a54f  ........
	defb 000h,0e0h,0ffh,0ffh,0ffh,0ffh,0ffh,03fh	; a557  .......?
	defb 03fh,03fh,03fh,0ffh,0ffh,0ffh,0ffh,0ffh	; a55f  ???.....
	defb 000h,001h,001h,000h,006h,006h,007h,007h	; a567  ........
	defb 007h,007h,003h,003h,003h,001h,001h,000h	; a56f  ........
	defb 000h,000h,001h,003h,007h,00fh,01fh,03fh	; a577  .......?
	defb 00fh,07fh,0ffh,0ffh,0f8h,0e0h,080h,000h	; a57f  ........
	defb 03eh,07ch,07ch,078h,0f8h,0f0h,0f0h,0f0h	; a587  >||x....
	defb 0f0h,0f0h,0f0h,0f8h,078h,07ch,07ch,03eh	; a58f  ....x||>
	defb 03fh,01fh,00fh,007h,003h,001h,000h,000h	; a597  ?.......
	defb 000h,080h,0e0h,0f8h,0ffh,0ffh,07fh,00fh	; a59f  ........

; ----------------------------------------------------------------------
; DATOS colores_tercio1: Los colores del primer tercio: 71 tramos (color,
;   cuantos)
;   0xa5a7..0xa635  (142 bytes)
DATA_colores_tercio1:
	defb 033h,008h	; a5a7
	defb 0f3h,020h	; a5a9
	defb 0c3h,015h	; a5ab
	defb 0c1h,003h	; a5ad
	defb 0c3h,002h	; a5af
	defb 0c1h,00eh	; a5b1
	defb 0c3h,002h	; a5b3
	defb 0c1h,006h	; a5b5
	defb 0c3h,005h	; a5b7
	defb 0c1h,003h	; a5b9
	defb 0b3h,010h	; a5bb
	defb 0b7h,008h	; a5bd
	defb 077h,008h	; a5bf
	defb 055h,008h	; a5c1
	defb 09ch,008h	; a5c3
	defb 066h,008h	; a5c5
	defb 09ch,007h	; a5c7
	defb 08ch,001h	; a5c9
	defb 09ch,007h	; a5cb
	defb 08ch,001h	; a5cd
	defb 09ch,010h	; a5cf
	defb 08ch,010h	; a5d1
	defb 06ch,020h	; a5d3
	defb 08ch,010h	; a5d5
	defb 075h,010h	; a5d7
	defb 0cch,010h	; a5d9
	defb 0f7h,026h	; a5db
	defb 0f3h,001h	; a5dd
	defb 093h,001h	; a5df
	defb 0f7h,006h	; a5e1
	defb 0f3h,001h	; a5e3
	defb 093h,001h	; a5e5
	defb 0cfh,010h	; a5e7
	defb 0fch,006h	; a5e9
	defb 0f3h,002h	; a5eb
	defb 0fch,006h	; a5ed
	defb 0f3h,022h	; a5ef
	defb 0fch,014h	; a5f1
	defb 0f3h,004h	; a5f3
	defb 0fch,004h	; a5f5
	defb 0f3h,034h	; a5f7
	defb 0fch,010h	; a5f9
	defb 0fch,003h	; a5fb
	defb 0f3h,005h	; a5fd
	defb 0fch,003h	; a5ff
	defb 0f3h,015h	; a601
	defb 0fch,005h	; a603
	defb 0f3h,003h	; a605
	defb 0fch,005h	; a607
	defb 0f3h,033h	; a609
	defb 000h,010h	; a60b
	defb 0fch,010h	; a60d
	defb 05fh,010h	; a60f
	defb 053h,010h	; a611
	defb 0f3h,020h	; a613
	defb 000h,010h	; a615
	defb 0cfh,005h	; a617
	defb 05fh,003h	; a619
	defb 0cfh,005h	; a61b
	defb 05fh,003h	; a61d
	defb 053h,010h	; a61f
	defb 0f3h,030h	; a621
	defb 000h,020h	; a623
	defb 0fch,010h	; a625
	defb 0f5h,010h	; a627
	defb 053h,010h	; a629
	defb 0f3h,030h	; a62b
	defb 0c3h,010h	; a62d
	defb 0b3h,010h	; a62f
	defb 0b6h,010h	; a631
	defb 063h,010h	; a633

; ----------------------------------------------------------------------
; DATOS colores_tercio2: Los colores del segundo tercio: 134 tramos
;   0xa635..0xa741  (268 bytes)
DATA_colores_tercio2:
	defb 055h,008h	; a635
	defb 0cch,008h	; a637
	defb 033h,008h	; a639
	defb 0f3h,018h	; a63b
	defb 0d3h,008h	; a63d
	defb 0f3h,008h	; a63f
	defb 0c1h,002h	; a641
	defb 0c5h,006h	; a643
	defb 0c1h,002h	; a645
	defb 0c5h,006h	; a647
	defb 044h,008h	; a649
	defb 0c5h,001h	; a64b
	defb 075h,001h	; a64d
	defb 0c5h,001h	; a64f
	defb 07ch,004h	; a651
	defb 0cch,001h	; a653
	defb 0cah,008h	; a655
	defb 0c1h,002h	; a657
	defb 0c4h,006h	; a659
	defb 083h,008h	; a65b
	defb 0a3h,008h	; a65d
	defb 083h,008h	; a65f
	defb 0bbh,008h	; a661
	defb 0b7h,008h	; a663
	defb 0b5h,008h	; a665
	defb 0b4h,00eh	; a667
	defb 0bfh,001h	; a669
	defb 0f1h,001h	; a66b
	defb 0b4h,006h	; a66d
	defb 0bfh,001h	; a66f
	defb 0f1h,001h	; a671
	defb 0b4h,006h	; a673
	defb 0bfh,001h	; a675
	defb 0f1h,001h	; a677
	defb 0ffh,001h	; a679
	defb 0b3h,001h	; a67b
	defb 083h,006h	; a67d
	defb 0ffh,001h	; a67f
	defb 0b3h,001h	; a681
	defb 083h,006h	; a683
	defb 0ffh,001h	; a685
	defb 0b3h,001h	; a687
	defb 083h,006h	; a689
	defb 0f1h,050h	; a68b
	defb 0c4h,001h	; a68d
	defb 0cfh,007h	; a68f
	defb 055h,004h	; a691
	defb 0c5h,004h	; a693
	defb 0c5h,008h	; a695
	defb 0a3h,010h	; a697
	defb 083h,030h	; a699
	defb 0f3h,020h	; a69b
	defb 0b6h,010h	; a69d
	defb 0b3h,006h	; a69f
	defb 0b6h,002h	; a6a1
	defb 0b3h,006h	; a6a3
	defb 0b6h,002h	; a6a5
	defb 0fch,010h	; a6a7
	defb 05fh,010h	; a6a9
	defb 053h,010h	; a6ab
	defb 0b3h,010h	; a6ad
	defb 0fch,010h	; a6af
	defb 05fh,010h	; a6b1
	defb 0b3h,010h	; a6b3
	defb 0fch,010h	; a6b5
	defb 053h,010h	; a6b7
	defb 0f3h,010h	; a6b9
	defb 0f3h,010h	; a6bb
	defb 0bfh,006h	; a6bd
	defb 0b3h,002h	; a6bf
	defb 0bfh,006h	; a6c1
	defb 0b3h,002h	; a6c3
	defb 0f3h,010h	; a6c5
	defb 05fh,010h	; a6c7
	defb 053h,010h	; a6c9
	defb 0f3h,010h	; a6cb
	defb 0fch,010h	; a6cd
	defb 05fh,010h	; a6cf
	defb 053h,010h	; a6d1
	defb 0f3h,030h	; a6d3
	defb 05fh,004h	; a6d5
	defb 0cfh,004h	; a6d7
	defb 05fh,004h	; a6d9
	defb 0cfh,004h	; a6db
	defb 053h,006h	; a6dd
	defb 05fh,002h	; a6df
	defb 053h,006h	; a6e1
	defb 05fh,002h	; a6e3
	defb 0f3h,030h	; a6e5
	defb 0c5h,010h	; a6e7
	defb 0c3h,020h	; a6e9
	defb 0c5h,020h	; a6eb
	defb 0c4h,010h	; a6ed
	defb 0c4h,002h	; a6ef
	defb 0f4h,002h	; a6f1
	defb 014h,004h	; a6f3
	defb 0c4h,002h	; a6f5
	defb 0f4h,002h	; a6f7
	defb 014h,004h	; a6f9
	defb 0c4h,003h	; a6fb
	defb 0c3h,005h	; a6fd
	defb 0c4h,003h	; a6ff
	defb 0c3h,005h	; a701
	defb 0c4h,017h	; a703
	defb 0c3h,001h	; a705
	defb 0c4h,007h	; a707
	defb 0c3h,001h	; a709
	defb 0c5h,020h	; a70b
	defb 0c4h,020h	; a70d
	defb 0c5h,010h	; a70f
	defb 0b6h,002h	; a711
	defb 0b9h,006h	; a713
	defb 0b6h,002h	; a715
	defb 0b9h,006h	; a717
	defb 096h,020h	; a719
	defb 0b9h,020h	; a71b
	defb 096h,003h	; a71d
	defb 0b6h,003h	; a71f
	defb 0bfh,002h	; a721
	defb 096h,003h	; a723
	defb 0b6h,003h	; a725
	defb 0bfh,002h	; a727
	defb 0bfh,006h	; a729
	defb 0b6h,002h	; a72b
	defb 0bfh,006h	; a72d
	defb 0b6h,002h	; a72f
	defb 0b6h,010h	; a731
	defb 063h,001h	; a733
	defb 0b3h,001h	; a735
	defb 093h,006h	; a737
	defb 063h,001h	; a739
	defb 0b3h,001h	; a73b
	defb 093h,006h	; a73d
	defb 0b9h,010h	; a73f

; ----------------------------------------------------------------------
; DATOS colores_tercio3: Los colores del tercer tercio: 92 tramos; los ultimos
;   7 son a la vez los primeros de las luces encendidas
;   0xa741..0xa7eb  (170 bytes)
DATA_colores_tercio3:
	defb 055h,008h	; a741
	defb 0cch,008h	; a743
	defb 033h,008h	; a745
	defb 0f3h,020h	; a747
	defb 0feh,008h	; a749
	defb 0f3h,006h	; a74b
	defb 0feh,00ah	; a74d
	defb 0f3h,004h	; a74f
	defb 0feh,004h	; a751
	defb 022h,008h	; a753
	defb 0feh,008h	; a755
	defb 0dbh,008h	; a757
	defb 083h,008h	; a759
	defb 0a3h,008h	; a75b
	defb 083h,008h	; a75d
	defb 0f3h,004h	; a75f
	defb 0a3h,004h	; a761
	defb 0a1h,010h	; a763
	defb 0feh,008h	; a765
	defb 044h,008h	; a767
	defb 0f3h,006h	; a769
	defb 0feh,00ah	; a76b
	defb 0e1h,004h	; a76d
	defb 091h,004h	; a76f
	defb 0e1h,004h	; a771
	defb 091h,004h	; a773
	defb 0f2h,008h	; a775
	defb 0eeh,008h	; a777
	defb 0e1h,020h	; a779
	defb 0f3h,006h	; a77b
	defb 0feh,002h	; a77d
	defb 0feh,008h	; a77f
	defb 013h,008h	; a781
	defb 0e1h,020h	; a783
	defb 011h,003h	; a785
	defb 0ffh,005h	; a787
	defb 0a3h,010h	; a789
	defb 083h,030h	; a78b
	defb 02eh,010h	; a78d
	defb 01eh,010h	; a78f
	defb 045h,010h	; a791
	defb 0cfh,010h	; a793
	defb 05fh,010h	; a795
	defb 033h,010h	; a797
	defb 0f3h,020h	; a799
	defb 000h,010h	; a79b
	defb 05fh,003h	; a79d
	defb 04fh,005h	; a79f
	defb 05fh,003h	; a7a1
	defb 04fh,005h	; a7a3
	defb 053h,006h	; a7a5
	defb 0f3h,002h	; a7a7
	defb 053h,006h	; a7a9
	defb 0f3h,012h	; a7ab
	defb 000h,010h	; a7ad
	defb 0f3h,010h	; a7af
	defb 000h,010h	; a7b1
	defb 0f3h,010h	; a7b3
	defb 0f3h,004h	; a7b5
	defb 0feh,004h	; a7b7
	defb 0f3h,004h	; a7b9
	defb 0feh,004h	; a7bb
	defb 0f3h,020h	; a7bd
	defb 013h,010h	; a7bf
	defb 0f1h,010h	; a7c1
	defb 0f3h,001h	; a7c3
	defb 0f1h,007h	; a7c5
	defb 0f3h,001h	; a7c7
	defb 0f1h,007h	; a7c9
	defb 0f3h,003h	; a7cb
	defb 0f1h,005h	; a7cd
	defb 0f3h,003h	; a7cf
	defb 0f1h,005h	; a7d1
	defb 013h,003h	; a7d3
	defb 0f1h,005h	; a7d5
	defb 013h,003h	; a7d7
	defb 0f1h,005h	; a7d9
	defb 0f3h,004h	; a7db
	defb 0a3h,004h	; a7dd
	defb 0f3h,004h	; a7df
	defb 0a3h,014h	; a7e1
	defb 01eh,014h	; a7e3
	defb 012h,004h	; a7e5
	defb 01eh,004h	; a7e7
	defb 012h,044h	; a7e9

; ----------------------------------------------------------------------
; DATOS luces_a: Las luces de la maquina, una de las dos formas: 10 tramos
;   0xa7eb..0xa7ff  (20 bytes)
DATA_luces_a:
	defb 08ch,008h	; a7eb
	defb 099h,008h	; a7ed
	defb 08ch,007h	; a7ef
	defb 06ch,001h	; a7f1
	defb 08ch,007h	; a7f3
	defb 06ch,001h	; a7f5
	defb 08ch,010h	; a7f7
	defb 06ch,010h	; a7f9
	defb 09ch,020h	; a7fb
	defb 06ch,010h	; a7fd

; ----------------------------------------------------------------------
; DATOS luces_b: La otra forma: 10 tramos
;   0xa7ff..0xa813  (20 bytes)
DATA_luces_b:
	defb 09ch,008h	; a7ff
	defb 066h,008h	; a801
	defb 09ch,007h	; a803
	defb 08ch,001h	; a805
	defb 09ch,007h	; a807
	defb 08ch,001h	; a809
	defb 09ch,010h	; a80b
	defb 08ch,010h	; a80d
	defb 06ch,020h	; a80f
	defb 08ch,010h	; a811

; ======================================================================
; CODIGO 0xa813..0xa881  (110 bytes)
; ======================================================================


letras_grandes:		; 25 casillas de 0xA9AF a la VRAM DE y su color A en 256 bytes
	push de			;a813
	push af			;a814
	ld hl,0a9afh		;a815   ; las letras grandes
	ld bc,000c8h		;a818   ; 25 casillas
	call 0005ch		;a81b   ; LDIRVM
	pop af			;a81e
	pop de			;a81f
	ld hl,02000h		;a820   ; sus colores: 0x2000 + DE
	add hl,de			;a823
	ld bc,00100h		;a824   ; 256 bytes (FILVRM)
	jp 00056h		;a827
letras:		; Las letras propias: las grandes del titulo (dos colores) y las cifras y las mayusculas en los tres tercios
	ld de,00008h		;a82a   ; las grandes, a la casilla 1...
	ld a,071h		;a82d   ; ...cian sobre negro (0x71)
	call letras_grandes		;a82f
	ld de,00808h		;a832   ; en el segundo tercio...
	ld a,041h		;a835   ; ...azul sobre negro (0x41)
	call letras_grandes		;a837
	ld de,00180h		;a83a   ; las cifras y las letras, en los tres tercios
	call letras_tercio		;a83d   ; en el primer tercio
	ld de,00980h		;a840   ; en el segundo
	call letras_tercio		;a843
	ld de,01180h		;a846   ; y en el tercero
letras_tercio:		; Las diez cifras (casilla 0x30) y 28 letras (0x40) de 0xA881, y su color blanco sobre negro (0xF1)
	push de			;a849
	ld hl,0a881h		;a84a   ; las cifras...
	ld bc,00050h		;a84d   ; ...10 casillas
	push hl			;a850
	push de			;a851
	push bc			;a852
	call 0005ch		;a853   ; LDIRVM a la casilla 0x30
	pop bc			;a856
	pop de			;a857
	pop hl			;a858
	add hl,bc			;a859   ; las letras...
	ld bc,00080h		;a85a   ; ...en la casilla 0x40...
	ex de,hl			;a85d
	add hl,bc			;a85e
	ex de,hl			;a85f
	ld bc,000e0h		;a860   ; ...28
	call 0005ch		;a863
	pop de			;a866
	ld hl,01f80h		;a867   ; los colores de las casillas 0x20-0x5A...
	add hl,de			;a86a
	ld bc,001d8h		;a86b
	ld a,0f1h		;a86e   ; ...blanco sobre negro (0xF1)
	push hl			;a870
	call 00056h		;a871
	pop hl			;a874
	ld bc,001d8h		;a875   ; la casilla 0x5B...
	add hl,bc			;a878
	ld bc,00008h		;a879
	ld a,055h		;a87c   ; ...azul sobre azul (0x55)
	jp 00056h		;a87e

; ----------------------------------------------------------------------
; DATOS letras_datos: Las cifras 0-9 y las letras de la 0x40 a la 0x5B (8
;   bytes cada una)
;   0xa881..0xa9af  (302 bytes)
DATA_letras_datos:
	defb 03eh,041h,041h,041h,041h,041h,03eh,000h	; a881  >AAAAA>.
	defb 008h,008h,008h,008h,008h,008h,008h,000h	; a889  ........
	defb 07eh,001h,001h,03eh,040h,040h,07fh,000h	; a891  ~..>@@..
	defb 07eh,001h,001h,03eh,001h,001h,07eh,000h	; a899  ~..>..~.
	defb 044h,044h,044h,044h,07fh,004h,004h,000h	; a8a1  DDDD....
	defb 07fh,040h,040h,07eh,001h,001h,07eh,000h	; a8a9  .@@~..~.
	defb 03fh,040h,040h,03eh,041h,041h,03eh,000h	; a8b1  ?@@>AA>.
	defb 07fh,001h,001h,001h,001h,001h,001h,000h	; a8b9  ........
	defb 03eh,041h,041h,03eh,041h,041h,03eh,000h	; a8c1  >AA>AA>.
	defb 03eh,041h,041h,03eh,001h,001h,07eh,000h	; a8c9  >AA>..~.
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; a8d1  <B....B<
	defb 01ch,022h,041h,041h,07fh,041h,041h,000h	; a8d9  ."AA.AA.
	defb 07eh,041h,041h,07eh,041h,041h,07eh,000h	; a8e1  ~AA~AA~.
	defb 03eh,041h,040h,040h,040h,041h,03eh,000h	; a8e9  >A@@@A>.
	defb 07ch,042h,041h,041h,041h,042h,07ch,000h	; a8f1  |BAAAB|.
	defb 07fh,040h,040h,07fh,040h,040h,07fh,000h	; a8f9  .@@.@@..
	defb 07fh,040h,040h,07eh,040h,040h,040h,000h	; a901  .@@~@@@.
	defb 03eh,041h,040h,04fh,041h,041h,03eh,000h	; a909  >A@OAA>.
	defb 041h,041h,041h,07fh,041h,041h,041h,000h	; a911  AAA.AAA.
	defb 01ch,008h,008h,008h,008h,008h,01ch,000h	; a919  ........
	defb 007h,002h,002h,002h,042h,042h,03ch,000h	; a921  ....BB<.
	defb 041h,042h,044h,078h,044h,042h,041h,000h	; a929  ABDxDBA.
	defb 040h,040h,040h,040h,040h,040h,07fh,000h	; a931  @@@@@@..
	defb 041h,063h,055h,049h,041h,041h,041h,000h	; a939  AcUIAAA.
	defb 041h,061h,051h,049h,045h,043h,041h,000h	; a941  AaQIECA.
	defb 03eh,041h,041h,041h,041h,041h,03eh,000h	; a949  >AAAAA>.
	defb 07eh,041h,041h,07eh,040h,040h,040h,000h	; a951  ~AA~@@@.
	defb 03eh,041h,041h,041h,049h,045h,03eh,001h	; a959  >AAAIE>.
	defb 07eh,041h,041h,07eh,041h,041h,041h,000h	; a961  ~AA~AAA.
	defb 03eh,041h,040h,03eh,001h,041h,03eh,000h	; a969  >A@>.A>.
	defb 07fh,008h,008h,008h,008h,008h,008h,000h	; a971  ........
	defb 041h,041h,041h,041h,041h,041h,03eh,000h	; a979  AAAAAA>.
	defb 041h,041h,022h,022h,014h,014h,008h,000h	; a981  AA""....
	defb 049h,049h,049h,049h,049h,049h,036h,000h	; a989  IIIIII6.
	defb 041h,022h,014h,008h,014h,022h,041h,000h	; a991  A"..."A.
	defb 041h,041h,041h,07fh,008h,008h,008h,000h	; a999  AAA.....
	defb 07fh,002h,004h,008h,010h,020h,07fh,000h	; a9a1  ..... ..
	defb 000h,000h,000h,000h,000h,000h	; a9a9

; ----------------------------------------------------------------------
; DATOS letras_grandes_datos: Las 25 casillas de las letras grandes de CASIO y
;   PACHINKO-U.F.O. (la tabla de antes acaba en sus dos primeros bytes)
;   0xa9af..0xaa77  (200 bytes)
DATA_letras_grandes_datos:
	defb 000h,000h,03fh,03fh,0c0h,0c0h,0c0h,0c0h	; a9af  ..??....
	defb 0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,03fh,03fh	; a9b7  ......??
	defb 000h,000h,0fch,0fch,000h,000h,000h,000h	; a9bf  ........
	defb 000h,000h,000h,000h,000h,000h,0fch,0fch	; a9c7  ........
	defb 000h,00fh,03fh,030h,0c0h,0c0h,0c0h,0c0h	; a9cf  ..?0....
	defb 0ffh,0ffh,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h	; a9d7  ........
	defb 000h,0c0h,0f0h,030h,00ch,00ch,00ch,00ch	; a9df  ...0....
	defb 0fch,0fch,00ch,00ch,00ch,00ch,00ch,00ch	; a9e7  ........
	defb 03fh,03fh,000h,000h,000h,000h,0ffh,0ffh	; a9ef  ??......
	defb 0f0h,0f0h,00ch,00ch,00ch,00ch,0f0h,0f0h	; a9f7  ........
	defb 000h,000h,003h,003h,003h,003h,003h,003h	; a9ff  ........
	defb 003h,003h,003h,003h,003h,003h,003h,003h	; aa07  ........
	defb 000h,000h,0f0h,0f0h,00ch,00ch,00ch,00ch	; aa0f  ........
	defb 00ch,00ch,00ch,00ch,00ch,00ch,0f0h,0f0h	; aa17  ........
	defb 000h,000h,0ffh,0ffh,0c0h,0c0h,0c0h,0c0h	; aa1f  ........
	defb 0f0h,0f0h,000h,000h,000h,000h,000h,000h	; aa27  ........
	defb 000h,000h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h	; aa2f  ........
	defb 000h,000h,00ch,00ch,00ch,00ch,00ch,00ch	; aa37  ........
	defb 000h,000h,0c0h,0c0h,0f0h,0f0h,0cch,0cch	; aa3f  ........
	defb 0c3h,0c3h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h	; aa47  ........
	defb 00ch,00ch,0cch,0cch,03ch,03ch,00ch,00ch	; aa4f  ....<<..
	defb 000h,000h,00ch,00ch,030h,030h,0c0h,0c0h	; aa57  ....00..
	defb 000h,000h,0c0h,0c0h,030h,030h,00ch,00ch	; aa5f  ....00..
	defb 000h,000h,000h,000h,000h,000h,060h,060h	; aa67  ......``
	defb 03fh,03fh,000h,000h,000h,000h,000h,000h	; aa6f  ??......

; ======================================================================
; CODIGO 0xaa77..0xab4f  (216 bytes)
; ======================================================================


clavos_maq2:		; El mapa de los clavos de la maquina 2 (0xB083)
	ld hl,0b083h		;aa77   ; el mapa 0xB083
	jr clavos_monta		;aa7a
clavos_maq01:		; El de las maquinas 0 y 1 (0xAB4F)
	ld hl,0ab4fh		;aa7c   ; el mapa 0xAB4F
clavos_monta:		; El mapa de bits de los clavos en 0xE000: 147 lineas de 18 bytes, la mitad izquierda de la ROM y la derecha en espejo
	push hl			;aa7f
	ld bc,00bd0h		;aa80   ; 0xBD0 bytes...
	ld hl,0e000h		;aa83   ; desde 0xE000
clavos_borra:		; ...a cero
	ld (hl),000h		;aa86   ; un byte a 0
	inc hl			;aa88
	dec bc			;aa89   ; uno menos
	ld a,b			;aa8a
	or c			;aa8b
	jr nz,clavos_borra		;aa8c
	pop hl			;aa8e
	ld de,0e024h		;aa8f   ; desde la linea 2
	ld c,093h		;aa92   ; 147 lineas
clavos_linea:		; Una: 9 bytes tal cual...
	ld b,009h		;aa94   ; 9 bytes
clavos_byte:
	ld a,(hl)			;aa96   ; tal cual
	ld (de),a			;aa97
	inc hl			;aa98
	inc de			;aa99
	djnz clavos_byte		;aa9a
	push hl			;aa9c   ; los mismos...
	ld b,009h		;aa9d   ; ...y los mismos 9 al reves, con los bits al reves
clavos_espejo:
	dec hl			;aa9f   ; ...del ultimo al primero
	ld a,(hl)			;aaa0
	push bc			;aaa1
	ld b,008h		;aaa2
clavos_espejo_bit:
	rrca			;aaa4   ; los bits al reves
	rl c		;aaa5
	djnz clavos_espejo_bit		;aaa7
	ld a,c			;aaa9
	pop bc			;aaaa
	ld (de),a			;aaab   ; en la mitad derecha
	inc de			;aaac
	djnz clavos_espejo		;aaad
	pop hl			;aaaf
	dec c			;aab0   ; una linea menos
	jr nz,clavos_linea		;aab1
	ret			;aab3
clavos_maq1:		; La maquina 1: el de las maquinas 0 y 1, la ventana del tragaperras (0xB639) y tres postes (0xB5B5)
	call clavos_maq01		;aab4   ; el mapa de las maquinas 0 y 1
	ld de,0b639h		;aab7   ; la ventana del tragaperras...
	ld hl,0e2d6h		;aaba   ; ...en el mapa, linea 40
	ld c,040h		;aabd   ; 64 lineas
clavos_ventana:
	ld b,006h		;aabf   ; 6 bytes
clavos_ventana_byte:
	ld a,(de)			;aac1   ; un byte
	ld (hl),a			;aac2
	inc hl			;aac3
	inc de			;aac4
	djnz clavos_ventana_byte		;aac5
	ld a,c			;aac7
	ld c,00ch		;aac8   ; la linea siguiente (18 - 6)
	add hl,bc			;aaca
	ld c,a			;aacb
	dec c			;aacc   ; una menos
	jr nz,clavos_ventana		;aacd
	ld de,0e94ch		;aacf   ; los tres postes
	call clavos_poste		;aad2
	ld de,0e954h		;aad5
	call clavos_poste		;aad8
	ld de,0e9e0h		;aadb
	jp clavos_poste		;aade
clavos_centro_cerrado1:		; El centro de la maquina 1 cerrado en el mapa (0xB81B)
	ld hl,0b81bh		;aae1   ; cerrado
	jr clavos_centro1		;aae4
clavos_centro_abierto1:		; Abierto (0xB7B7)
	ld hl,0b7b7h		;aae6   ; abierto
clavos_centro1:		; 10 lineas de 10 bytes en 0xE5A4
	ld de,0e5a4h		;aae9   ; en el mapa
	ld a,00ah		;aaec   ; 10 lineas
clavos_copia10:
	ldi		;aaee   ; 10 bytes por linea
	ldi		;aaf0
	ldi		;aaf2
	ldi		;aaf4
	ldi		;aaf6
	ldi		;aaf8
	ldi		;aafa
	ldi		;aafc
	ldi		;aafe
	ldi		;ab00
	ld bc,00008h		;ab02   ; la linea siguiente (18 - 10)
	ex de,hl			;ab05
	add hl,bc			;ab06
	ex de,hl			;ab07
	dec a			;ab08   ; una menos
	jr nz,clavos_copia10		;ab09
	ret			;ab0b
clavos_centro_cerrado0:		; El centro de la maquina 0 cerrado (0xB925)
	ld hl,0b925h		;ab0c   ; cerrado
	jr clavos_centro0		;ab0f
clavos_centro_abierto0:		; Abierto (0xB87D)
	ld hl,0b87dh		;ab11   ; abierto
clavos_centro0:		; 17 lineas de 10 bytes en 0xE4CC
	ld de,0e4cch		;ab14   ; en el mapa
	ld a,011h		;ab17   ; 17 lineas
	jr clavos_copia10		;ab19
clavos_tulipan1:		; Un tulipan en el mapa (0xB5DC, 8 lineas de 4)
	ld hl,0b5dch		;ab1b   ; el primero
	jr clavos_copia4		;ab1e
clavos_tulipan2:		; Otro (0xB5FB)
	ld hl,0b5fbh		;ab20   ; el segundo
	jr clavos_copia4		;ab23
clavos_tulipan3:		; Otro (0xB61A)
	ld hl,0b61ah		;ab25   ; el tercero
clavos_copia4:
	ld a,008h		;ab28   ; 8 lineas
clavos_copia4_linea:
	ldi		;ab2a   ; 4 bytes por linea
	ldi		;ab2c
	ldi		;ab2e
	ldi		;ab30
	ld bc,0000eh		;ab32   ; la siguiente (18 - 4)
	ex de,hl			;ab35
	add hl,bc			;ab36
	ex de,hl			;ab37
	dec a			;ab38   ; una menos
	jr nz,clavos_copia4_linea		;ab39
	ret			;ab3b
clavos_poste:		; Un poste en el mapa (0xB5B5, 20 lineas de 2 bytes)
	ld hl,0b5b5h		;ab3c   ; el poste
	ld a,014h		;ab3f   ; 20 lineas
clavos_poste_linea:
	ldi		;ab41   ; 2 bytes por linea
	ldi		;ab43
	ld bc,00010h		;ab45   ; la siguiente (18 - 2)
	ex de,hl			;ab48
	add hl,bc			;ab49
	ex de,hl			;ab4a
	dec a			;ab4b   ; una menos
	jr nz,clavos_poste_linea		;ab4c
	ret			;ab4e

; ----------------------------------------------------------------------
; DATOS clavos_maq01_datos: El mapa de los clavos de las maquinas 0 y 1: 147
;   lineas de 9 bytes (la mitad izquierda)
;   0xab4f..0xb07a  (1323 bytes)
DATA_clavos_maq01_datos:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h	; ab4f  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,000h	; ab58  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h,000h	; ab61  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,080h,000h,000h,000h	; ab6a  .........
	defb 0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h	; ab73  .........
	defb 0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h,000h,000h	; ab7c  .........
	defb 0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h,000h,000h	; ab85  .........
	defb 0ffh,0ffh,0ffh,0ffh,080h,000h,000h,000h,000h	; ab8e  .........
	defb 0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h,000h	; ab97  .........
	defb 0ffh,0ffh,0ffh,0f8h,000h,000h,000h,000h,000h	; aba0  .........
	defb 0ffh,0ffh,0ffh,0f0h,000h,000h,000h,000h,000h	; aba9  .........
	defb 0ffh,0ffh,0ffh,0c0h,000h,000h,000h,000h,000h	; abb2  .........
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; abbb  .........
	defb 0ffh,0ffh,0fch,000h,000h,000h,000h,000h,000h	; abc4  .........
	defb 0ffh,0ffh,0f0h,000h,000h,000h,000h,000h,000h	; abcd  .........
	defb 0ffh,0ffh,0c0h,000h,000h,000h,000h,000h,000h	; abd6  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,001h,080h,018h	; abdf  .........
	defb 0ffh,0fch,000h,000h,000h,000h,001h,080h,018h	; abe8  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; abf1  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; abfa  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; ac03  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; ac0c  .........
	defb 0feh,000h,000h,000h,000h,000h,060h,000h,000h	; ac15  ......`..
	defb 0feh,000h,000h,000h,000h,000h,060h,000h,000h	; ac1e  ......`..
	defb 0feh,000h,000h,000h,000h,000h,060h,000h,018h	; ac27  ......`..
	defb 0feh,000h,000h,000h,000h,000h,0f0h,000h,078h	; ac30  ........x
	defb 0feh,000h,000h,000h,000h,001h,0c0h,000h,0e0h	; ac39  .........
	defb 0feh,000h,000h,000h,000h,001h,080h,001h,0c0h	; ac42  .........
	defb 0feh,000h,000h,018h,00ch,003h,000h,003h,000h	; ac4b  .........
	defb 0feh,000h,000h,018h,018h,007h,000h,007h,000h	; ac54  .........
	defb 0feh,000h,000h,000h,000h,006h,000h,006h,000h	; ac5d  .........
	defb 0feh,000h,000h,000h,000h,006h,000h,006h,000h	; ac66  .........
	defb 0feh,000h,000h,000h,000h,00eh,000h,00eh,000h	; ac6f  .........
	defb 0ffh,0ffh,0f0h,000h,000h,00ch,000h,00ch,000h	; ac78  .........
	defb 0ffh,0ffh,0f0h,000h,000h,01ch,000h,01ch,000h	; ac81  .........
	defb 0ffh,0ffh,0c0h,000h,000h,01ch,000h,018h,000h	; ac8a  .........
	defb 0ffh,0ffh,0c0h,000h,000h,018h,000h,018h,000h	; ac93  .........
	defb 0ffh,0ffh,081h,080h,000h,000h,000h,000h,000h	; ac9c  .........
	defb 0ffh,0ffh,081h,080h,000h,000h,000h,000h,000h	; aca5  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,00ch	; acae  .........
	defb 0ffh,0feh,000h,000h,030h,000h,000h,000h,00ch	; acb7  ....0....
	defb 0ffh,0ffh,000h,000h,0f0h,000h,000h,000h,007h	; acc0  .........
	defb 0ffh,0ffh,080h,001h,0c0h,000h,000h,000h,007h	; acc9  .........
	defb 0ffh,0ffh,080h,001h,080h,000h,000h,000h,007h	; acd2  .........
	defb 0ffh,0ffh,0c0h,003h,000h,000h,000h,006h,007h	; acdb  .........
	defb 0ffh,0ffh,0e0h,007h,000h,000h,000h,01fh,007h	; ace4  .........
	defb 0ffh,0e0h,060h,006h,000h,0c0h,000h,07fh,08fh	; aced  ..`......
	defb 0ffh,0c0h,060h,006h,000h,0c0h,001h,0ffh,0ffh	; acf6  ..`......
	defb 0ffh,0c0h,030h,00ch,000h,0c0h,003h,0ffh,0ffh	; acff  ..0......
	defb 0ffh,080h,030h,00ch,000h,0e0h,006h,0ffh,0ffh	; ad08  ..0......
	defb 0ffh,080h,030h,00ch,000h,0e0h,00dh,0ffh,0ffh	; ad11  ..0......
	defb 0ffh,000h,018h,018h,000h,0e0h,00bh,0ffh,0ffh	; ad1a  .........
	defb 0ffh,000h,018h,018h,000h,070h,00dh,0ffh,0ffh	; ad23  .....p...
	defb 0ffh,000h,018h,018h,000h,070h,00bh,0ffh,0ffh	; ad2c  .....p...
	defb 0feh,000h,000h,000h,000h,038h,00dh,0ffh,0ffh	; ad35  .....8...
	defb 0feh,000h,000h,000h,006h,038h,00bh,0ffh,0ffh	; ad3e  .....8...
	defb 0feh,000h,000h,000h,006h,00ch,00dh,0ffh,0ffh	; ad47  .........
	defb 0ffh,000h,000h,000h,006h,00ch,00bh,0ffh,0ffh	; ad50  .........
	defb 0feh,000h,000h,000h,00fh,0f0h,00dh,0ffh,0ffh	; ad59  .........
	defb 0feh,000h,000h,000h,00fh,0f0h,00bh,0ffh,0ffh	; ad62  .........
	defb 0fch,000h,000h,000h,00fh,0f0h,00dh,0ffh,0ffh	; ad6b  .........
	defb 0fch,000h,000h,0c0h,00fh,0f0h,00bh,0ffh,0ffh	; ad74  .........
	defb 0fch,000h,000h,0c0h,00fh,0fch,000h,0ffh,0ffh	; ad7d  .........
	defb 0f8h,000h,000h,000h,00fh,0fch,000h,0ffh,000h	; ad86  .........
	defb 0f8h,000h,000h,000h,007h,0f0h,000h,0ffh,000h	; ad8f  .........
	defb 0f8h,000h,000h,000h,003h,0c0h,000h,0ffh,000h	; ad98  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,0ffh,000h	; ada1  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,0ffh,000h	; adaa  .........
	defb 0f0h,018h,018h,00ch,00ch,000h,000h,0ffh,003h	; adb3  .........
	defb 0f0h,018h,018h,00ch,00ch,000h,000h,0ffh,007h	; adbc  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,0f0h,00fh	; adc5  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,0f0h,00fh	; adce  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,0f0h,00fh	; add7  .........
	defb 0f0h,000h,000h,000h,000h,000h,001h,0f0h,00fh	; ade0  .........
	defb 0f0h,000h,000h,000h,000h,000h,001h,0f0h,00fh	; ade9  .........
	defb 0fch,000h,000h,000h,000h,000h,001h,0f0h,01fh	; adf2  .........
	defb 0fch,000h,001h,080h,000h,000h,001h,0f0h,01fh	; adfb  .........
	defb 0fch,003h,001h,083h,000h,000h,001h,0f0h,03fh	; ae04  ........?
	defb 0fch,003h,001h,083h,000h,000h,001h,0f0h,03fh	; ae0d  ........?
	defb 0fch,003h,001h,083h,000h,000h,001h,0f0h,03fh	; ae16  ........?
	defb 0fch,000h,001h,080h,000h,000h,001h,0f0h,03fh	; ae1f  ........?
	defb 0fch,000h,000h,000h,000h,000h,001h,0f0h,01fh	; ae28  .........
	defb 0fch,000h,000h,000h,000h,000h,001h,0f0h,01fh	; ae31  .........
	defb 0fch,000h,000h,000h,000h,000h,001h,0f0h,00fh	; ae3a  .........
	defb 0fch,000h,000h,000h,000h,000h,007h,0c0h,003h	; ae43  .........
	defb 0fch,000h,000h,000h,000h,000h,007h,0c0h,000h	; ae4c  .........
	defb 0fch,000h,00ch,018h,000h,000h,007h,0c0h,000h	; ae55  .........
	defb 0fch,000h,00ch,018h,000h,000h,007h,0c0h,000h	; ae5e  .........
	defb 0fch,000h,00ch,018h,000h,000h,007h,0c0h,000h	; ae67  .........
	defb 0fch,000h,000h,000h,000h,000h,007h,0c0h,000h	; ae70  .........
	defb 0fch,000h,008h,010h,000h,000h,007h,0c0h,000h	; ae79  .........
	defb 0fch,000h,008h,010h,000h,000h,007h,0c0h,000h	; ae82  .........
	defb 0fch,000h,018h,018h,000h,000h,007h,0c0h,000h	; ae8b  .........
	defb 0fch,000h,018h,018h,000h,000h,007h,0c0h,000h	; ae94  .........
	defb 0fch,000h,038h,01ch,000h,000h,007h,0c0h,000h	; ae9d  ..8......
	defb 0fch,000h,038h,01ch,000h,000h,007h,080h,010h	; aea6  ..8......
	defb 0fch,000h,038h,01ch,000h,000h,007h,080h,030h	; aeaf  ..8.....0
	defb 0fch,000h,038h,01ch,000h,000h,007h,000h,030h	; aeb8  ..8.....0
	defb 0fch,000h,030h,00ch,000h,060h,00fh,000h,07ch	; aec1  ..0..`..|
	defb 0fch,000h,030h,00ch,000h,0f0h,00fh,080h,0ffh	; aeca  ..0......
	defb 0fch,000h,03fh,0fch,000h,0f0h,00fh,0c1h,0ffh	; aed3  ..?......
	defb 0fch,000h,03fh,0fch,000h,060h,007h,0ffh,0ffh	; aedc  ..?..`...
	defb 0fch,000h,03fh,0fch,000h,000h,003h,0ffh,0ffh	; aee5  ..?......
	defb 0fch,000h,01fh,0f8h,000h,000h,000h,03fh,0ffh	; aeee  .......?.
	defb 0fch,000h,00fh,0f0h,000h,000h,000h,003h,0ffh	; aef7  .........
	defb 0fch,000h,003h,0c0h,000h,000h,000h,000h,03fh	; af00  ........?
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; af09  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; af12  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; af1b  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; af24  .........
	defb 0ffh,000h,000h,000h,018h,00ch,000h,000h,000h	; af2d  .........
	defb 0ffh,000h,000h,000h,018h,00ch,001h,080h,000h	; af36  .........
	defb 0ffh,000h,000h,000h,018h,00ch,003h,0c0h,000h	; af3f  .........
	defb 0ffh,080h,000h,000h,030h,00ch,001h,0f8h,000h	; af48  ....0....
	defb 0ffh,080h,000h,000h,030h,00ch,000h,07fh,001h	; af51  ....0....
	defb 0ffh,080h,000h,000h,030h,00ch,000h,007h,001h	; af5a  ....0....
	defb 0ffh,0c0h,000h,000h,060h,006h,000h,000h,000h	; af63  ....`....
	defb 0ffh,0c0h,000h,000h,060h,006h,000h,000h,000h	; af6c  ....`....
	defb 0ffh,0c0h,000h,000h,060h,006h,000h,000h,000h	; af75  ....`....
	defb 0ffh,0e0h,000h,000h,0c0h,003h,000h,000h,000h	; af7e  .........
	defb 0ffh,0e0h,000h,000h,0c0h,003h,000h,000h,000h	; af87  .........
	defb 0ffh,0e0h,000h,001h,080h,001h,0c0h,000h,000h	; af90  .........
	defb 0ffh,0f0h,000h,003h,000h,000h,0e0h,018h,018h	; af99  .........
	defb 0ffh,0f0h,000h,007h,000h,000h,0f0h,018h,018h	; afa2  .........
	defb 0ffh,0f0h,000h,01eh,000h,000h,078h,000h,000h	; afab  ......x..
	defb 0ffh,0f0h,000h,018h,000h,000h,038h,000h,000h	; afb4  ......8..
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; afbd  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; afc6  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; afcf  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; afd8  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,001h,081h	; afe1  .........
	defb 0ffh,0f8h,000h,000h,00ch,018h,000h,001h,081h	; afea  .........
	defb 0ffh,0fch,000h,000h,00ch,018h,000h,000h,000h	; aff3  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; affc  .........
	defb 0ffh,0fch,000h,000h,060h,006h,000h,000h,000h	; b005  ....`....
	defb 0ffh,0fch,000h,000h,060h,006h,000h,000h,000h	; b00e  ....`....
	defb 0ffh,0fch,000h,000h,070h,00eh,000h,000h,000h	; b017  ....p....
	defb 0ffh,0fch,000h,000h,070h,00eh,000h,000h,000h	; b020  ....p....
	defb 0ffh,0feh,000h,000h,07fh,0feh,000h,000h,000h	; b029  .........
	defb 0ffh,0ffh,000h,000h,07fh,0feh,000h,000h,018h	; b032  .........
	defb 0ffh,0ffh,080h,000h,03fh,0fch,000h,000h,018h	; b03b  ....?....
	defb 0ffh,0ffh,0c0h,000h,03fh,0fch,000h,000h,000h	; b044  ....?....
	defb 0ffh,0ffh,0e0h,000h,03fh,0fch,000h,000h,060h	; b04d  ....?...`
	defb 0ffh,0ffh,0f0h,000h,01fh,0f8h,000h,000h,060h	; b056  ........`
	defb 0ffh,0ffh,0f8h,000h,000h,000h,000h,000h,070h	; b05f  ........p
	defb 0ffh,0ffh,0fch,000h,000h,000h,000h,000h,07fh	; b068  .........
	defb 0ffh,0ffh,0feh,000h,000h,000h,000h,000h,07fh	; b071  .........

; ----------------------------------------------------------------------
; DATOS clavos_maq01_resto: Nueve bytes mas, una linea 148 que no se lee
;   0xb07a..0xb083  (9 bytes)
DATA_clavos_maq01_resto:
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,07fh	; b07a  .........

; ----------------------------------------------------------------------
; DATOS clavos_maq2_datos: El mapa de la maquina 2: 147 lineas de 9 bytes
;   0xb083..0xb5ae  (1323 bytes)
DATA_clavos_maq2_datos:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h	; b083  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,000h	; b08c  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h,000h	; b095  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,080h,000h,000h,000h	; b09e  .........
	defb 0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h	; b0a7  .........
	defb 0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h,000h,000h	; b0b0  .........
	defb 0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h,000h,000h	; b0b9  .........
	defb 0ffh,0ffh,0ffh,0ffh,080h,000h,000h,000h,000h	; b0c2  .........
	defb 0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h,000h	; b0cb  .........
	defb 0ffh,0ffh,0ffh,0f8h,000h,000h,000h,000h,000h	; b0d4  .........
	defb 0ffh,0ffh,0ffh,0f0h,000h,000h,000h,000h,000h	; b0dd  .........
	defb 0ffh,0ffh,0ffh,0c0h,000h,000h,000h,000h,000h	; b0e6  .........
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h	; b0ef  .........
	defb 0ffh,0ffh,0fch,000h,000h,000h,000h,000h,000h	; b0f8  .........
	defb 0ffh,0ffh,0f0h,000h,000h,000h,000h,000h,000h	; b101  .........
	defb 0ffh,0ffh,0c0h,000h,000h,000h,000h,000h,000h	; b10a  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b113  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b11c  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; b125  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; b12e  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b137  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b140  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b149  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b152  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b15b  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b164  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b16d  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b176  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b17f  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b188  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b191  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b19a  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b1a3  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b1ac  .........
	defb 0ffh,0ffh,0e0h,000h,000h,000h,000h,000h,000h	; b1b5  .........
	defb 0ffh,0ffh,0c0h,000h,000h,000h,000h,000h,000h	; b1be  .........
	defb 0ffh,0ffh,0c0h,000h,000h,000h,000h,000h,000h	; b1c7  .........
	defb 0ffh,0ffh,080h,000h,000h,000h,000h,000h,000h	; b1d0  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b1d9  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b1e2  .........
	defb 0ffh,0feh,000h,000h,000h,000h,000h,000h,000h	; b1eb  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b1f4  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b1fd  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b206  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b20f  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b218  .........
	defb 0ffh,0e0h,000h,000h,000h,000h,000h,000h,000h	; b221  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; b22a  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; b233  .........
	defb 0ffh,080h,000h,000h,000h,000h,000h,000h,000h	; b23c  .........
	defb 0ffh,080h,000h,000h,000h,000h,000h,000h,000h	; b245  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b24e  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b257  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b260  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b269  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b272  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b27b  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b284  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b28d  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b296  .........
	defb 0fch,000h,000h,000h,000h,000h,000h,000h,000h	; b29f  .........
	defb 0fch,000h,000h,000h,000h,000h,000h,000h,000h	; b2a8  .........
	defb 0fch,000h,000h,000h,000h,000h,000h,000h,000h	; b2b1  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b2ba  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b2c3  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b2cc  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b2d5  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b2de  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b2e7  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b2f0  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b2f9  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b302  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b30b  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b314  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b31d  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b326  .........
	defb 0f1h,000h,000h,000h,000h,000h,000h,000h,000h	; b32f  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b338  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b341  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b34a  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b353  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b35c  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b365  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b36e  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b377  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b380  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b389  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b392  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b39b  .........
	defb 0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3a4  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3ad  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3b6  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3bf  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3c8  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3d1  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3da  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3e3  .........
	defb 0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; b3ec  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b3f5  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b3fe  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b407  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b410  .........
	defb 0f8h,000h,000h,000h,000h,000h,000h,000h,000h	; b419  .........
	defb 0fch,000h,000h,000h,000h,000h,000h,000h,000h	; b422  .........
	defb 0fch,000h,000h,000h,000h,000h,000h,000h,000h	; b42b  .........
	defb 0fch,000h,000h,000h,000h,000h,000h,000h,000h	; b434  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b43d  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b446  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b44f  .........
	defb 0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b458  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b461  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b46a  .........
	defb 0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; b473  .........
	defb 0ffh,080h,000h,000h,000h,000h,000h,000h,000h	; b47c  .........
	defb 0ffh,080h,000h,000h,000h,000h,000h,000h,000h	; b485  .........
	defb 0ffh,080h,000h,000h,000h,000h,000h,000h,000h	; b48e  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; b497  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; b4a0  .........
	defb 0ffh,0c0h,000h,000h,000h,000h,000h,000h,000h	; b4a9  .........
	defb 0ffh,0e0h,000h,000h,000h,000h,000h,000h,000h	; b4b2  .........
	defb 0ffh,0e0h,000h,000h,000h,000h,000h,000h,000h	; b4bb  .........
	defb 0ffh,0e0h,000h,000h,000h,000h,000h,000h,000h	; b4c4  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; b4cd  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; b4d6  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; b4df  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; b4e8  .........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,000h	; b4f1  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; b4fa  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; b503  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; b50c  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; b515  .........
	defb 0ffh,0f8h,000h,000h,000h,000h,000h,000h,000h	; b51e  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b527  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b530  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b539  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b542  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b54b  .........
	defb 0ffh,0fch,000h,000h,000h,000h,000h,000h,000h	; b554  .........
	defb 0ffh,0feh,000h,000h,000h,000h,000h,000h,000h	; b55d  .........
	defb 0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h	; b566  .........
	defb 0ffh,0ffh,080h,000h,000h,000h,000h,000h,000h	; b56f  .........
	defb 0ffh,0ffh,0c0h,000h,000h,000h,000h,000h,000h	; b578  .........
	defb 0ffh,0ffh,0e0h,000h,000h,000h,000h,000h,000h	; b581  .........
	defb 0ffh,0ffh,0f0h,000h,000h,000h,000h,000h,000h	; b58a  .........
	defb 0ffh,0ffh,0f8h,000h,000h,000h,000h,000h,000h	; b593  .........
	defb 0ffh,0ffh,0fch,000h,000h,000h,000h,000h,000h	; b59c  .........
	defb 0ffh,0ffh,0feh,000h,000h,000h,000h,000h,000h	; b5a5  .........

; ----------------------------------------------------------------------
; DATOS clavos_maq2_resto: Siete bytes que no se leen
;   0xb5ae..0xb5b5  (7 bytes)
DATA_clavos_maq2_resto:
	defb 0ffh,0ffh,0ffh,000h,000h,000h,000h	; b5ae

; ----------------------------------------------------------------------
; DATOS clavos_poste_datos: El poste en el mapa: 20 lineas de 2 bytes (el
;   ultimo es el primero del tulipan)
;   0xb5b5..0xb5dc  (39 bytes)
DATA_clavos_poste_datos:
	defb 000h,000h	; b5b5
	defb 018h,018h	; b5b7
	defb 018h,018h	; b5b9
	defb 000h,000h	; b5bb
	defb 008h,010h	; b5bd
	defb 008h,010h	; b5bf
	defb 018h,018h	; b5c1
	defb 018h,018h	; b5c3
	defb 038h,01ch	; b5c5
	defb 038h,01ch	; b5c7
	defb 038h,01ch	; b5c9
	defb 038h,01ch	; b5cb
	defb 030h,00ch	; b5cd
	defb 03fh,0fch	; b5cf
	defb 03fh,0fch	; b5d1
	defb 03fh,0fch	; b5d3
	defb 03fh,0fch	; b5d5
	defb 000h,000h	; b5d7
	defb 000h,000h	; b5d9
	defb 000h	; b5db

; ----------------------------------------------------------------------
; DATOS clavos_tulipan1_datos: Un tulipan: 8 lineas de 4 (el ultimo byte es el
;   primero del siguiente)
;   0xb5dc..0xb5fb  (31 bytes)
DATA_clavos_tulipan1_datos:
	defb 000h,018h,018h,000h	; b5dc
	defb 000h,018h,018h,000h	; b5e0
	defb 000h,018h,018h,000h	; b5e4
	defb 000h,018h,018h,000h	; b5e8
	defb 000h,038h,01ch,000h	; b5ec
	defb 000h,038h,01ch,000h	; b5f0
	defb 000h,038h,01ch,000h	; b5f4
	defb 000h,038h,01ch	; b5f8

; ----------------------------------------------------------------------
; DATOS clavos_tulipan2_datos: Otro tulipan
;   0xb5fb..0xb61a  (31 bytes)
DATA_clavos_tulipan2_datos:
	defb 000h,000h,000h,000h	; b5fb
	defb 000h,000h,000h,000h	; b5ff
	defb 001h,000h,000h,080h	; b603
	defb 001h,080h,001h,080h	; b607
	defb 001h,0c0h,003h,080h	; b60b
	defb 000h,0e0h,007h,000h	; b60f
	defb 000h,0f0h,00fh,000h	; b613
	defb 000h,078h,01eh	; b617

; ----------------------------------------------------------------------
; DATOS clavos_tulipan3_datos: Otro tulipan
;   0xb61a..0xb639  (31 bytes)
DATA_clavos_tulipan3_datos:
	defb 000h,000h,000h,000h	; b61a
	defb 000h,000h,000h,000h	; b61e
	defb 000h,000h,000h,000h	; b622
	defb 00ch,000h,000h,030h	; b626
	defb 00eh,000h,000h,070h	; b62a
	defb 003h,080h,001h,0c0h	; b62e
	defb 003h,0e0h,007h,0c0h	; b632
	defb 000h,0f8h,01fh	; b636

; ----------------------------------------------------------------------
; DATOS clavos_ventana_datos: La ventana del tragaperras en el mapa: 64 lineas
;   de 6 bytes (los dos ultimos son los primeros del centro abierto)
;   0xb639..0xb7b7  (382 bytes)
DATA_clavos_ventana_datos:
	defb 000h,000h,000h,000h,000h,000h	; b639
	defb 000h,000h,00ch,030h,000h,000h	; b63f
	defb 000h,000h,00ch,030h,000h,000h	; b645
	defb 000h,000h,007h,0e0h,000h,000h	; b64b
	defb 000h,000h,007h,0e0h,000h,000h	; b651
	defb 000h,000h,007h,0e0h,000h,000h	; b657
	defb 000h,006h,007h,0e0h,060h,000h	; b65d
	defb 000h,01fh,007h,0e0h,0f8h,000h	; b663
	defb 000h,07fh,08fh,0f1h,0feh,000h	; b669
	defb 001h,0ffh,0ffh,0ffh,0ffh,080h	; b66f
	defb 003h,0ffh,0ffh,0ffh,0ffh,0c0h	; b675
	defb 006h,0ffh,0ffh,0ffh,0ffh,060h	; b67b
	defb 00dh,0ffh,0ffh,0ffh,0ffh,0b0h	; b681
	defb 00bh,0ffh,0ffh,0ffh,0ffh,0d0h	; b687
	defb 00bh,0ffh,0ffh,0ffh,0ffh,0d0h	; b68d
	defb 00dh,0ffh,0ffh,0ffh,0ffh,0b0h	; b693
	defb 007h,0ffh,0ffh,0ffh,0ffh,0e0h	; b699
	defb 007h,0ffh,0ffh,0ffh,0ffh,0e0h	; b69f
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6a5
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6ab
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6b1
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6b7
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6bd
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6c3
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6c9
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6cf
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6d5
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6db
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6e1
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6e7
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6ed
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6f3
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6f9
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b6ff
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b705
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b70b
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b711
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b717
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b71d
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b723
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b729
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b72f
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b735
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b73b
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b741
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b747
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b74d
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b753
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b759
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b75f
	defb 001h,0ffh,0ffh,0ffh,0ffh,080h	; b765
	defb 001h,0ffh,0ffh,0ffh,0ffh,080h	; b76b
	defb 001h,0ffh,0ffh,0ffh,0ffh,080h	; b771
	defb 001h,0ffh,0ffh,0ffh,0ffh,080h	; b777
	defb 000h,0dfh,0ffh,0ffh,0bfh,000h	; b77d
	defb 000h,0dfh,0ffh,0ffh,0bfh,000h	; b783
	defb 000h,06fh,0ffh,0ffh,0f6h,000h	; b789
	defb 000h,06fh,0ffh,0ffh,0f6h,000h	; b78f
	defb 000h,037h,0ffh,0ffh,0ech,000h	; b795
	defb 000h,037h,0ffh,0ffh,0ech,000h	; b79b
	defb 000h,01bh,0ffh,0ffh,0d8h,000h	; b7a1
	defb 000h,01bh,0ffh,0ffh,0ffh,000h	; b7a7
	defb 000h,000h,0bfh,0fdh,000h,000h	; b7ad
	defb 000h,000h,0ffh,0ffh	; b7b3

; ----------------------------------------------------------------------
; DATOS clavos_centro1a_datos: El centro de la maquina 1 abierto: 10 lineas de
;   10
;   0xb7b7..0xb81b  (100 bytes)
DATA_clavos_centro1a_datos:
	defb 000h,000h,007h,0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h	; b7b7  ..........
	defb 000h,000h,01fh,0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h	; b7c1  ..........
	defb 006h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,060h	; b7cb  .........`
	defb 006h,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0c0h,060h	; b7d5  .........`
	defb 006h,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,060h	; b7df  .........`
	defb 006h,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,060h	; b7e9  .........`
	defb 006h,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,060h	; b7f3  .........`
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h	; b7fd  ..........
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h	; b807  ..........
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f0h	; b811  ..........

; ----------------------------------------------------------------------
; DATOS clavos_centro1c_datos: Cerrado: 10 lineas de 10 (los dos ultimos son
;   los primeros del siguiente)
;   0xb81b..0xb87d  (98 bytes)
DATA_clavos_centro1c_datos:
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b81b  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b825  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b82f  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b839  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b843  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b84d  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b857  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b861  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h	; b86b  ..........
	defb 000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h	; b875  ........

; ----------------------------------------------------------------------
; DATOS clavos_centro0a_datos: El centro de la maquina 0 abierto: 17 lineas de
;   10 (los dos ultimos son los primeros del siguiente)
;   0xb87d..0xb925  (168 bytes)
DATA_clavos_centro0a_datos:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b87d  ..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b887  ..........
	defb 018h,000h,000h,000h,003h,0c0h,000h,000h,000h,018h	; b891  ..........
	defb 018h,000h,000h,000h,007h,0e0h,000h,000h,000h,018h	; b89b  ..........
	defb 018h,000h,000h,000h,00fh,0f0h,000h,000h,000h,018h	; b8a5  ..........
	defb 03eh,000h,000h,000h,00fh,0f0h,000h,000h,000h,07ch	; b8af  >........|
	defb 07fh,0c0h,000h,000h,00fh,0f0h,000h,000h,003h,0feh	; b8b9  ..........
	defb 07fh,0f0h,000h,000h,00fh,0f0h,000h,000h,00fh,0feh	; b8c3  ..........
	defb 07fh,0fch,000h,000h,00fh,0f0h,000h,000h,03fh,0feh	; b8cd  ........?.
	defb 07fh,0ffh,000h,000h,01fh,0f8h,000h,000h,0ffh,0feh	; b8d7  ..........
	defb 0ffh,0ffh,0c0h,000h,01fh,0f8h,000h,003h,0ffh,0ffh	; b8e1  ..........
	defb 0ffh,0ffh,0f0h,000h,03fh,0fch,000h,00fh,0ffh,0ffh	; b8eb  ....?.....
	defb 0ffh,0ffh,0fch,000h,03fh,0fch,000h,03fh,0ffh,0ffh	; b8f5  ....?..?..
	defb 0ffh,0ffh,0ffh,0f0h,03fh,0fch,00fh,0ffh,0ffh,0ffh	; b8ff  ....?.....
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; b909  ..........
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; b913  ..........
	defb 000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b91d  ........

; ----------------------------------------------------------------------
; DATOS clavos_centro0c_datos: Cerrado: 17 lineas de 10
;   0xb925..0xb9cf  (170 bytes)
DATA_clavos_centro0c_datos:
	defb 000h,000h,000h,0f0h,000h,000h,00fh,000h,000h,000h	; b925  ..........
	defb 000h,000h,000h,0f0h,000h,000h,00fh,000h,000h,000h	; b92f  ..........
	defb 000h,000h,000h,0f0h,003h,0c0h,00fh,000h,000h,000h	; b939  ..........
	defb 000h,000h,000h,0f0h,007h,0e0h,00fh,000h,000h,000h	; b943  ..........
	defb 000h,000h,000h,0f0h,00fh,0f0h,00fh,000h,000h,000h	; b94d  ..........
	defb 000h,000h,000h,0f0h,00fh,0f0h,00fh,000h,000h,000h	; b957  ..........
	defb 000h,000h,000h,0f0h,00fh,0f0h,00fh,000h,000h,000h	; b961  ..........
	defb 000h,000h,001h,070h,00fh,0f0h,00eh,080h,000h,000h	; b96b  ...p......
	defb 000h,000h,001h,060h,00fh,0f0h,006h,080h,000h,000h	; b975  ...`......
	defb 000h,000h,001h,060h,01fh,0f8h,006h,080h,000h,000h	; b97f  ...`......
	defb 0c0h,000h,002h,060h,01fh,0f8h,006h,040h,000h,003h	; b989  ...`...@..
	defb 0c0h,000h,002h,0c0h,03fh,0fch,003h,040h,000h,003h	; b993  ....?..@..
	defb 000h,000h,002h,0c0h,03fh,0fch,003h,040h,000h,000h	; b99d  ....?..@..
	defb 000h,000h,002h,0c0h,03fh,0fch,003h,040h,000h,000h	; b9a7  ....?..@..
	defb 000h,000h,002h,0c0h,03fh,0fch,003h,040h,000h,000h	; b9b1  ....?..@..
	defb 000h,000h,002h,0c0h,03fh,0fch,003h,040h,000h,000h	; b9bb  ....?..@..
	defb 000h,000h,002h,0c0h,03fh,0fch,003h,040h,000h,000h	; b9c5  ....?..@..

; ======================================================================
; CODIGO 0xb9cf..0xbbfe  (559 bytes)
; ======================================================================


pieza:		; Pone la pieza DE en el canal B y la hace sonar
	push af			;b9cf
	call canal		;b9d0   ; el canal, a su estado inicial
	ld (hl),e			;b9d3   ; el principio de la pieza
	inc hl			;b9d4
	ld (hl),d			;b9d5
	inc hl			;b9d6
	ld (hl),001h		;b9d7   ; suena
	pop af			;b9d9
	ret			;b9da
canal:		; HL = el canal B (0xF102 + B x 0x20), y lo deja en su estado inicial (0xBC16)
	push bc			;b9db
	push de			;b9dc
	ld hl,0f102h		;b9dd
	ld a,b			;b9e0   ; ...de 32 en 32 bytes
	rrca			;b9e1   ; B x 32 (tres rrca)
	rrca			;b9e2
	rrca			;b9e3   ; B por 32
	ld e,a			;b9e4   ; en DE
	ld d,000h		;b9e5
	add hl,de			;b9e7   ; el canal
	push hl			;b9e8   ; HL, el canal...
	inc hl			;b9e9   ; ...y desde +2...
	inc hl			;b9ea   ; desde +2
	ex de,hl			;b9eb
	ld hl,0bc16h		;b9ec   ; ...30 bytes de 0xBC16
	ld bc,0001eh		;b9ef   ; 30 bytes
	ldir		;b9f2
	pop hl			;b9f4
	pop de			;b9f5
	pop bc			;b9f6
	ret			;b9f7
sonido_calla:		; Calla el sonido: los tres canales a cero, el PSG sin ruido y los volumenes a 0
	xor a			;b9f8
	ld (0f100h),a		;b9f9   ; sin transporte
	ld b,a			;b9fc
	call canal		;b9fd
	inc b			;ba00
	call canal		;ba01
	inc b			;ba04
	call canal		;ba05
	ld a,007h		;ba08   ; el registro 7 del PSG (RDPSG)...
	call 00096h		;ba0a
	and 0c0h		;ba0d   ; ...los dos bits de los puertos se quedan...
	or 038h		;ba0f   ; ...los tonos apagados (0x38)...
	ld e,a			;ba11
	ld a,007h		;ba12
	call 00093h		;ba14   ; ...WRTPSG
	xor a			;ba17   ; los tres canales, callados
	ld (0f104h),a		;ba18
	ld (0f124h),a		;ba1b
	ld (0f144h),a		;ba1e
	ld b,002h		;ba21
L_BA23:
	call canal_calla		;ba23
	djnz L_BA23		;ba26
canal_calla:		; El volumen del canal B a 0...
	xor a			;ba28
volumen:		; ...y el volumen E en el registro 8 + B del PSG
	ld e,a			;ba29
	ld a,008h		;ba2a   ; el registro de volumen del canal
	add a,b			;ba2c
	jp 00093h		;ba2d
sonido_cuadro:		; Un cuadro del motor: los tres canales, del 2 al 0
	ld b,002h		;ba30
	ld ix,0f102h		;ba32   ; empieza por el 2
sonido_cuadro_uno:		; Un canal
	call canal_cuadro		;ba36   ; el canal
	ld de,00020h		;ba39   ; el siguiente
	add ix,de		;ba3c
	ld a,(0f101h)		;ba3e   ; el numero de canal...
	ld b,a			;ba41
	djnz sonido_cuadro_uno		;ba42   ; ...uno menos
canal_cuadro:		; Un cuadro de un canal: el tempo, la nota y la envolvente
	ld a,b			;ba44   ; el canal en curso
	ld (0f101h),a		;ba45
	ld a,(ix+002h)		;ba48   ; suena?
	and a			;ba4b
	ret z			;ba4c
	dec (ix+00eh)		;ba4d   ; el tempo: cada tantos cuadros...
	ret nz			;ba50   ; ...aun no
	ld a,(ix+00dh)		;ba51   ; el tempo...
	ld (ix+00eh),a		;ba54   ; ...vuelve a su cuenta
	dec (ix+007h)		;ba57   ; ...la nota acaba?...
	jr z,L_BACC		;ba5a
	dec (ix+006h)		;ba5c   ; ...se acaba lo que suena?
	jr z,canal_calla		;ba5f
	jp p,envolvente		;ba61   ; a cero, no menos
	ld (ix+006h),000h		;ba64
	ret			;ba68
envolvente:		; La envolvente: el paso que toca segun lo que le queda a la nota, y su volumen de la tabla del canal
	ld a,(ix+00bh)		;ba69
	cp 010h		;ba6c   ; acabada?
	ret z			;ba6e
	ld e,000h		;ba6f   ; lo que le queda...
	ld h,e			;ba71
	ld l,(ix+006h)		;ba72   ; ...por 16...
	add hl,hl			;ba75
	add hl,hl			;ba76
	add hl,hl			;ba77
	add hl,hl			;ba78
	ld d,(ix+005h)		;ba79   ; ...entre la duracion
	ld c,b			;ba7c
	xor a			;ba7d
	ld b,008h		;ba7e   ; ocho bits
envolvente_div:		; La division, bit a bit
	push hl			;ba80
	srl d		;ba81   ; el divisor...
	rr e		;ba83
	and a			;ba85
	sbc hl,de		;ba86   ; ...cabe?
	ccf			;ba88
	jr nc,envolvente_bit		;ba89
	ex (sp),hl			;ba8b
envolvente_bit:		; Un bit del cociente
	rla			;ba8c
	pop hl			;ba8d
	djnz envolvente_div		;ba8e
	ld b,c			;ba90
	ld c,a			;ba91
	ld a,010h		;ba92   ; 16 menos el cociente: el paso de la envolvente
	sub c			;ba94
envolvente_paso:		; El paso: el volumen esta en la mitad alta o baja del byte de la tabla
	ld (ix+00bh),a		;ba95
	cp 010h		;ba98   ; 16: la envolvente se ha acabado
	ret z			;ba9a
	srl a		;ba9b   ; el paso entre 2: el byte...
	push af			;ba9d   ; el paso par o impar
	ld e,a			;ba9e
	ld d,000h		;ba9f
	ld l,(ix+009h)		;baa1   ; ...de la envolvente
	ld h,(ix+00ah)		;baa4   ; la envolvente del canal
	add hl,de			;baa7
	pop af			;baa8
	ld a,(hl)			;baa9   ; el byte...
	jr c,envolvente_volumen		;baaa   ; impar: la mitad baja
	rrca			;baac   ; ...su mitad alta o baja
	rrca			;baad
	rrca			;baae
	rrca			;baaf
envolvente_volumen:		; El volumen del paso por el volumen del canal, entre 16
	and 00fh		;bab0
	inc a			;bab2   ; el volumen de la envolvente...
	ld e,a			;bab3
	ld d,(ix+008h)		;bab4   ; ...por el del canal
	xor a			;bab7
	ld c,008h		;bab8   ; ocho bits
envolvente_mult:		; La multiplicacion, bit a bit
	add a,a			;baba
	rl e		;babb
	jr nc,envolvente_mult_sig		;babd
	add a,d			;babf
envolvente_mult_sig:		; El bit siguiente
	dec c			;bac0
	jr nz,envolvente_mult		;bac1
	rrca			;bac3   ; entre 16
	rrca			;bac4
	rrca			;bac5
	rrca			;bac6
	and 00fh		;bac7
	jp volumen		;bac9
L_BACC:
	call pieza_lee		;bacc
	and a			;bacf
	jp p,nota_pon		;bad0
	cpl			;bad3
	add a,a			;bad4
	push de			;bad5
	ld e,a			;bad6
	ld d,000h		;bad7
	ld hl,0bbfeh		;bad9
	add hl,de			;badc
	pop de			;badd
	push hl			;bade
	ld hl,L_BACC		;badf
	ex (sp),hl			;bae2
	ld a,(hl)			;bae3   ; la rutina
	inc hl			;bae4
	ld h,(hl)			;bae5
	ld l,a			;bae6
	jp (hl)			;bae7   ; a la orden
nota_pon:		; Una nota: A el numero, E la duracion, D hasta la siguiente; duracion 0 es un silencio
	ld (ix+005h),e		;bae8   ; la duracion...
	ld (ix+006h),e		;baeb   ; ...lo que le queda...
	ld (ix+007h),d		;baee   ; ...y hasta la siguiente
	inc e			;baf1   ; duracion 0: silencio
	dec e			;baf2
	jp z,canal_calla		;baf3
L_BAF6:
	ld d,a			;baf6
	ld a,(0f100h)		;baf7
	add a,d			;bafa   ; ...mas la nota
	ld c,000h		;bafb   ; la octava
nota_octava:		; La octava: de 12 en 12
	cp 00ch		;bafd   ; de 12 en 12...
	jr c,nota_periodo		;baff
	sub 00ch		;bb01
	inc c			;bb03
	jr nota_octava		;bb04   ; ...una octava mas
nota_periodo:		; El periodo de la nota (0xBC26), partido por 2 por cada octava
	add a,a			;bb06
	ld e,a			;bb07   ; la nota de la tabla...
	ld d,000h		;bb08
	ld hl,0bc26h		;bb0a   ; ...0xBC26
	add hl,de			;bb0d
	ld e,(hl)			;bb0e
	inc hl			;bb0f
	ld d,(hl)			;bb10
	ld a,c			;bb11   ; las octavas de mas...
	and a			;bb12
	jr z,nota_escribe		;bb13
nota_octava_baja:		; Una octava mas arriba
	srl d		;bb15   ; ...el periodo a la mitad
	rr e		;bb17
	dec a			;bb19
	jr nz,nota_octava_baja		;bb1a
nota_escribe:		; El periodo en los registros 2B y 2B+1 del PSG
	ld a,b			;bb1c   ; el registro 2B...
	add a,b			;bb1d
	call 00093h		;bb1e   ; ...la parte baja...
	cp 006h		;bb21
	jr z,nota_envolvente		;bb23
	ld e,d			;bb25
	inc a			;bb26
	call 00093h		;bb27   ; ...y la alta
nota_envolvente:		; Si la envolvente es de las de tabla, desde el paso 0
	ld a,(ix+00ch)		;bb2a   ; la envolvente es de tabla?
	cp 010h		;bb2d
	ret c			;bb2f
	xor a			;bb30   ; desde el paso 0
	jp envolvente_paso		;bb31
L_BB34:
	xor a			;bb34
	ld (ix+002h),a		;bb35
	pop hl			;bb38
	jp canal_calla		;bb39
orden_repite:		; Orden 0xFC: vuelve a la marca si faltan repeticiones
	dec (ix+011h)		;bb3c   ; una repeticion menos...
	ret z			;bb3f   ; ...si es la ultima, sigue
orden_vuelve:		; Orden 0xFD: vuelve a la marca
	ld e,(ix+00fh)		;bb40   ; la marca...
	ld d,(ix+010h)		;bb43
orden_salta:		; Orden 0xF4: salta a DE
	ld (ix+003h),e		;bb46   ; ...por donde va
	ld (ix+004h),d		;bb49
orden_nada:		; Orden 0xFE: nada
	ret			;bb4c
orden_marca:		; Orden 0xFB: la marca de la repeticion y cuantas veces
	ld (ix+011h),d		;bb4d   ; cuantas veces...
	ld e,(ix+003h)		;bb50   ; ...y la marca es por donde va
	ld d,(ix+004h)		;bb53
	ld (ix+00fh),e		;bb56
	ld (ix+010h),d		;bb59
	ret			;bb5c
orden_volumen:		; Orden 0xFA: el volumen del canal
	ld a,d			;bb5d   ; el volumen, de 0 a 15
	and 00fh		;bb5e
	ld (ix+008h),a		;bb60
	ret			;bb63
envolvente_psg:		; La envolvente del PSG: volumen 16 y los registros 11-13
	ld a,010h		;bb64   ; el volumen 16: la envolvente del PSG
	ld (ix+00bh),a		;bb66
	call volumen		;bb69   ; en el registro de volumen
	ld e,d			;bb6c
	ld a,00dh		;bb6d
	call 00093h		;bb6f
	call pieza_lee		;bb72
	ld a,00bh		;bb75   ; ...el periodo en los registros 11...
	call 00093h		;bb77
	inc a			;bb7a
	ld e,d			;bb7b   ; ...y 12
	jp 00093h		;bb7c
orden_envolvente:		; Orden 0xF9: el tipo de envolvente: del PSG o de la tabla 0xBC3E
	ld (ix+00ch),d		;bb7f   ; el tipo de envolvente...
	bit 4,d		;bb82   ; ...bit 4: de tabla
	jr z,envolvente_psg		;bb84
	ld a,d			;bb86   ; la tabla: 8 bytes por envolvente...
	and 00fh		;bb87
	add a,a			;bb89
	add a,a			;bb8a
	add a,a			;bb8b
	ld e,a			;bb8c
	ld d,000h		;bb8d
	ld hl,0bc3eh		;bb8f
	add hl,de			;bb92
	ld (ix+009h),l		;bb93   ; ...la del canal
	ld (ix+00ah),h		;bb96
	ret			;bb99
orden_tempo:		; Orden 0xF8: el tempo del canal (cuadros por paso)
	ld (ix+00dh),d		;bb9a
	ret			;bb9d
orden_transporte:		; Orden 0xF7: el transporte, para los tres canales
	ld a,d			;bb9e
	ld (0f100h),a		;bb9f
	ret			;bba2
orden_mezcla:		; Orden 0xF6: tono y ruido del canal en el registro 7
	ld a,d			;bba3   ; los bits de tono y ruido del canal...
	and 009h		;bba4
	ld l,a			;bba6
	ld h,009h		;bba7   ; ...la mascara
	ld a,b			;bba9
	and a			;bbaa
	jr z,orden_mezcla_pon		;bbab
orden_mezcla_bit:		; Los bits del canal
	add hl,hl			;bbad   ; corridos al canal
	dec a			;bbae
	jr nz,orden_mezcla_bit		;bbaf
orden_mezcla_pon:		; Los escribe
	ld a,007h		;bbb1   ; RDPSG 7
	call 00096h		;bbb3
	ld c,a			;bbb6
	ld a,h			;bbb7   ; fuera los del canal...
	cpl			;bbb8
	and c			;bbb9
	or l			;bbba   ; ...y los nuevos
	and 03fh		;bbbb
	or 080h		;bbbd   ; los puertos de E/S como estaban
	ld e,a			;bbbf
	ld a,007h		;bbc0   ; WRTPSG 7
	jp 00093h		;bbc2
orden_ruido:		; Orden 0xF5: el periodo del ruido y una nota de ruido
	pop af			;bbc5   ; fuera la vuelta...
	push de			;bbc6
	call pieza_lee		;bbc7   ; ...y los tres bytes siguientes
	pop af			;bbca
	ld (ix+005h),e		;bbcb   ; la duracion...
	ld (ix+006h),e		;bbce
	ld (ix+007h),d		;bbd1   ; ...y hasta la siguiente
	inc e			;bbd4
	dec e			;bbd5
	jp z,canal_calla		;bbd6   ; 0: silencio
	ld b,003h		;bbd9
	jp L_BAF6		;bbdb
pieza_lee:		; Los tres bytes siguientes de la pieza: A, E, D
	ld l,(ix+000h)		;bbde   ; el principio de la pieza...
	ld h,(ix+001h)		;bbe1
	ld e,(ix+003h)		;bbe4   ; ...mas por donde va
	ld d,(ix+004h)		;bbe7
	add hl,de			;bbea
	inc de			;bbeb   ; tres mas
	inc de			;bbec
	inc de			;bbed
	ld (ix+003h),e		;bbee
	ld (ix+004h),d		;bbf1
	ld a,(0f101h)		;bbf4   ; el canal...
	ld b,a			;bbf7
	ld a,(hl)			;bbf8
	inc hl			;bbf9
	ld e,(hl)			;bbfa
	inc hl			;bbfb
	ld d,(hl)			;bbfc
	ret			;bbfd

; ----------------------------------------------------------------------
; DATOS ordenes: Las doce ordenes del motor, de la 0xFF a la 0xF4
;   0xbbfe..0xbc16  (24 bytes)
DATA_ordenes:
	defw 0bb34h,0bb4ch	; bbfe  -> L_BB34 orden_nada
	defw 0bb40h,0bb3ch	; bc02  -> orden_vuelve orden_repite
	defw 0bb4dh,0bb5dh	; bc06  -> orden_marca orden_volumen
	defw 0bb7fh,0bb9ah	; bc0a  -> orden_envolvente orden_tempo
	defw 0bb9eh,0bba3h	; bc0e  -> orden_transporte orden_mezcla
	defw 0bbc5h,0bb46h	; bc12  -> orden_ruido orden_salta

; ----------------------------------------------------------------------
; DATOS canal_inicio: El estado inicial de un canal (desde +2): suena, la
;   duracion, el volumen 15, la envolvente 0xBC3E...; la copia de 30 bytes
;   sigue por la tabla de los periodos
;   0xbc16..0xbc26  (16 bytes)
DATA_canal_inicio:
	defb 000h,000h,000h,001h,001h,001h,00fh,03eh,0bch,010h,010h,001h,001h,000h,000h,001h	; bc16  .......>........

; ----------------------------------------------------------------------
; DATOS periodos: Los periodos de las doce notas de la octava mas baja (do a
;   si)
;   0xbc26..0xbc3e  (24 bytes)
DATA_periodos:
	defw 00d5ch,00c9dh,00be7h,00b3ch,00a9bh,00a02h,00973h,008ebh,0086bh,007f2h,00780h,00714h	; bc26

; ----------------------------------------------------------------------
; DATOS envolventes: Las ocho envolventes de tabla: 16 pasos de 4 bits (8
;   bytes cada una)
;   0xbc3e..0xbc7e  (64 bytes)
DATA_envolventes:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bc3e  ........
	defb 0feh,0dch,0bah,098h,076h,054h,032h,010h	; bc46  ....vT2.
	defb 001h,023h,045h,067h,089h,0abh,0cdh,0efh	; bc4e  .#Eg....
	defb 0feh,0dch,0bah,098h,089h,0abh,0cdh,0efh	; bc56  ........
	defb 089h,0abh,0cdh,0efh,0feh,0dch,0bah,098h	; bc5e  ........
	defb 0fdh,0b9h,075h,031h,0ech,0a8h,064h,020h	; bc66  ..u1..d 
	defb 004h,08ch,0feh,0dch,0bah,098h,076h,054h	; bc6e  ......vT
	defb 004h,08ch,0feh,0dch,0bah,0abh,0cdh,0efh	; bc76  ........

; ----------------------------------------------------------------------
; DATOS musica_salida_a: La musica de la primera partida, canal 0; grupos de
;   tres bytes (nota, duracion, espera) u ordenes
;   0xbc7e..0xbcfa  (124 bytes)
DATA_musica_salida_a:
	defb 0fah,000h,00ch	; bc7e
	defb 0f9h,000h,011h	; bc81
	defb 024h,012h,018h	; bc84
	defb 026h,012h,018h	; bc87
	defb 024h,005h,00ch	; bc8a
	defb 024h,005h,006h	; bc8d
	defb 024h,005h,006h	; bc90
	defb 029h,009h,00ch	; bc93
	defb 02dh,009h,00ch	; bc96
	defb 02bh,009h,00ch	; bc99
	defb 02dh,009h,00ch	; bc9c
	defb 02eh,009h,00ch	; bc9f
	defb 02fh,009h,00ch	; bca2
	defb 030h,012h,030h	; bca5
	defb 024h,00eh,012h	; bca8
	defb 02dh,005h,006h	; bcab
	defb 02dh,005h,00ch	; bcae
	defb 02dh,009h,00ch	; bcb1
	defb 02dh,009h,00ch	; bcb4
	defb 02eh,009h,00ch	; bcb7
	defb 02dh,009h,00ch	; bcba
	defb 02bh,009h,00ch	; bcbd
	defb 02bh,009h,00ch	; bcc0
	defb 029h,009h,00ch	; bcc3
	defb 02bh,009h,00ch	; bcc6
	defb 02dh,009h,00ch	; bcc9
	defb 02bh,012h,030h	; bccc
	defb 024h,00eh,012h	; bccf
	defb 02bh,005h,006h	; bcd2
	defb 02bh,005h,00ch	; bcd5
	defb 02bh,009h,00ch	; bcd8
	defb 02bh,009h,00ch	; bcdb
	defb 029h,009h,00ch	; bcde
	defb 028h,009h,00ch	; bce1
	defb 026h,009h,00ch	; bce4
	defb 024h,009h,00ch	; bce7
	defb 026h,009h,00ch	; bcea
	defb 028h,009h,00ch	; bced
	defb 02bh,009h,00ch	; bcf0
	defb 029h,012h,018h	; bcf3
	defb 035h,012h,018h	; bcf6
	defb 0ffh	; bcf9

; ----------------------------------------------------------------------
; DATOS musica_salida_b: canal 1; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbcfa..0xbd61  (103 bytes)
DATA_musica_salida_b:
	defb 0fah,000h,00ch	; bcfa
	defb 0f9h,000h,011h	; bcfd
	defb 030h,000h,0c0h	; bd00
	defb 018h,009h,00ch	; bd03
	defb 021h,009h,00ch	; bd06
	defb 018h,009h,00ch	; bd09
	defb 021h,009h,00ch	; bd0c
	defb 018h,009h,00ch	; bd0f
	defb 022h,009h,00ch	; bd12
	defb 021h,009h,00ch	; bd15
	defb 01fh,009h,00ch	; bd18
	defb 018h,009h,00ch	; bd1b
	defb 01fh,009h,00ch	; bd1e
	defb 018h,009h,00ch	; bd21
	defb 01fh,009h,00ch	; bd24
	defb 018h,009h,00ch	; bd27
	defb 048h,005h,006h	; bd2a
	defb 048h,005h,006h	; bd2d
	defb 048h,005h,00ch	; bd30
	defb 048h,005h,00ch	; bd33
	defb 018h,009h,00ch	; bd36
	defb 01fh,009h,00ch	; bd39
	defb 018h,009h,00ch	; bd3c
	defb 01fh,009h,00ch	; bd3f
	defb 018h,009h,00ch	; bd42
	defb 01fh,009h,00ch	; bd45
	defb 018h,009h,00ch	; bd48
	defb 01fh,009h,00ch	; bd4b
	defb 018h,009h,00ch	; bd4e
	defb 01ah,009h,00ch	; bd51
	defb 01ch,009h,00ch	; bd54
	defb 01fh,009h,00ch	; bd57
	defb 01dh,012h,018h	; bd5a
	defb 029h,012h,018h	; bd5d
	defb 0ffh	; bd60

; ----------------------------------------------------------------------
; DATOS musica_salida_c: canal 2; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbd61..0xbdb6  (85 bytes)
DATA_musica_salida_c:
	defb 0fah,000h,00ch	; bd61
	defb 0f9h,000h,011h	; bd64
	defb 0f6h,000h,000h	; bd67
	defb 0f5h,000h,018h	; bd6a
	defb 000h,012h,018h	; bd6d
	defb 0f5h,000h,018h	; bd70
	defb 000h,012h,018h	; bd73
	defb 0f5h,000h,018h	; bd76
	defb 000h,009h,00ch	; bd79
	defb 0f5h,000h,018h	; bd7c
	defb 000h,005h,006h	; bd7f
	defb 0f5h,000h,018h	; bd82
	defb 000h,005h,006h	; bd85
	defb 0f5h,000h,018h	; bd88
	defb 000h,009h,00ch	; bd8b
	defb 0f5h,000h,018h	; bd8e
	defb 000h,009h,00ch	; bd91
	defb 0f5h,000h,018h	; bd94
	defb 000h,009h,00ch	; bd97
	defb 0f5h,000h,018h	; bd9a
	defb 000h,009h,00ch	; bd9d
	defb 0f5h,000h,018h	; bda0
	defb 000h,009h,00ch	; bda3
	defb 0f5h,000h,018h	; bda6
	defb 000h,009h,00ch	; bda9
	defb 0f5h,000h,018h	; bdac
	defb 000h,012h,030h	; bdaf
	defb 0f6h,000h,008h	; bdb2
	defb 0ffh	; bdb5

; ----------------------------------------------------------------------
; DATOS sonido_ovni: Un OVNI tocado (canal 2); grupos de tres bytes (nota,
;   duracion, espera) u ordenes
;   0xbdb6..0xbdc6  (16 bytes)
DATA_sonido_ovni:
	defb 0fah,000h,00ch	; bdb6
	defb 030h,003h,004h	; bdb9
	defb 02fh,003h,004h	; bdbc
	defb 01dh,003h,004h	; bdbf
	defb 02bh,003h,004h	; bdc2
	defb 0ffh	; bdc5

; ----------------------------------------------------------------------
; DATOS sonido_ovni_malo: El OVNI que quita bolas (canal 2); grupos de tres
;   bytes (nota, duracion, espera) u ordenes
;   0xbdc6..0xbdd6  (16 bytes)
DATA_sonido_ovni_malo:
	defb 0fah,000h,00ch	; bdc6
	defb 024h,003h,004h	; bdc9
	defb 027h,003h,004h	; bdcc
	defb 026h,003h,004h	; bdcf
	defb 025h,003h,004h	; bdd2
	defb 0ffh	; bdd5

; ----------------------------------------------------------------------
; DATOS sonido_ovni_grande: El OVNI grande (canal 2); grupos de tres bytes
;   (nota, duracion, espera) u ordenes
;   0xbdd6..0xbdf2  (28 bytes)
DATA_sonido_ovni_grande:
	defb 0fah,000h,00ch	; bdd6
	defb 030h,003h,004h	; bdd9
	defb 030h,003h,004h	; bddc
	defb 02dh,003h,004h	; bddf
	defb 02dh,003h,004h	; bde2
	defb 02bh,003h,004h	; bde5
	defb 02bh,003h,004h	; bde8
	defb 029h,003h,004h	; bdeb
	defb 029h,003h,004h	; bdee
	defb 0ffh	; bdf1

; ----------------------------------------------------------------------
; DATOS sonido_abre: El centro se abre (canal 2); grupos de tres bytes (nota,
;   duracion, espera) u ordenes
;   0xbdf2..0xbe1d  (43 bytes)
DATA_sonido_abre:
	defb 0fah,000h,00ch	; bdf2
	defb 037h,002h,002h	; bdf5
	defb 036h,002h,002h	; bdf8
	defb 035h,002h,002h	; bdfb
	defb 034h,002h,002h	; bdfe
	defb 033h,002h,002h	; be01
	defb 032h,002h,002h	; be04
	defb 031h,001h,001h	; be07
	defb 030h,001h,001h	; be0a
	defb 02fh,001h,001h	; be0d
	defb 02eh,001h,001h	; be10
	defb 02dh,001h,001h	; be13
	defb 02ch,001h,001h	; be16
	defb 02bh,001h,001h	; be19
	defb 0ffh	; be1c

; ----------------------------------------------------------------------
; DATOS sonido_v: La V (canal 0); grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbe1d..0xbe2a  (13 bytes)
DATA_sonido_v:
	defb 0fah,000h,00ah	; be1d
	defb 0f9h,000h,011h	; be20
	defb 021h,002h,003h	; be23
	defb 0fdh,000h,000h	; be26
	defb 0ffh	; be29

; ----------------------------------------------------------------------
; DATOS musica_maq2: La musica de la maquina 2 (canal 0); grupos de tres bytes
;   (nota, duracion, espera) u ordenes
;   0xbe2a..0xbe49  (31 bytes)
DATA_musica_maq2:
	defb 0fah,000h,00ah	; be2a
	defb 0f9h,000h,011h	; be2d
	defb 03ch,004h,004h	; be30
	defb 03bh,004h,004h	; be33
	defb 03ah,004h,004h	; be36
	defb 039h,004h,004h	; be39
	defb 038h,004h,004h	; be3c
	defb 037h,004h,004h	; be3f
	defb 036h,004h,004h	; be42
	defb 0fdh,000h,000h	; be45
	defb 0ffh	; be48

; ----------------------------------------------------------------------
; DATOS sonido_gordo: El premio gordo del tragaperras (canal 0); grupos de
;   tres bytes (nota, duracion, espera) u ordenes
;   0xbe49..0xbe5b  (18 bytes)
DATA_sonido_gordo:
	defb 0fah,000h,00ah	; be49
	defb 02bh,004h,004h	; be4c
	defb 030h,004h,004h	; be4f
	defb 034h,004h,004h	; be52
	defb 037h,004h,004h	; be55
	defb 0fdh,000h,000h	; be58

; ----------------------------------------------------------------------
; DATOS silencio: Una pieza que acaba en el primer grupo: calla el canal;
;   grupos de tres bytes (nota, duracion, espera) u ordenes
;   0xbe5b..0xbe5c  (1 bytes)
DATA_silencio:
	defb 0ffh	; be5b

; ----------------------------------------------------------------------
; DATOS sonido_puntos: Puntos (canal 1); grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbe5c..0xbe6f  (19 bytes)
DATA_sonido_puntos:
	defb 0fah,000h,00ch	; be5c
	defb 0f9h,000h,011h	; be5f
	defb 037h,002h,003h	; be62
	defb 0fbh,000h,008h	; be65
	defb 03ch,001h,004h	; be68
	defb 0fch,000h,000h	; be6b
	defb 0ffh	; be6e

; ----------------------------------------------------------------------
; DATOS sonido_clavo: La bola contra un clavo (canal 1); grupos de tres bytes
;   (nota, duracion, espera) u ordenes
;   0xbe6f..0xbe76  (7 bytes)
DATA_sonido_clavo:
	defb 0fah,000h,00bh	; be6f
	defb 054h,001h,002h	; be72
	defb 0ffh	; be75

; ----------------------------------------------------------------------
; DATOS musica_game_over_a: GAME OVER (tambien despues de YOU WIN THE GAME!),
;   canal 0; grupos de tres bytes (nota, duracion, espera) u ordenes
;   0xbe76..0xbea7  (49 bytes)
DATA_musica_game_over_a:
	defb 0fah,000h,00ch	; be76
	defb 0f9h,000h,011h	; be79
	defb 02dh,00eh,012h	; be7c
	defb 02bh,015h,01bh	; be7f
	defb 028h,007h,009h	; be82
	defb 028h,00eh,012h	; be85
	defb 024h,00eh,012h	; be88
	defb 026h,015h,01bh	; be8b
	defb 024h,007h,009h	; be8e
	defb 026h,00eh,012h	; be91
	defb 028h,00eh,012h	; be94
	defb 024h,015h,01bh	; be97
	defb 021h,007h,009h	; be9a
	defb 021h,00eh,012h	; be9d
	defb 01fh,00eh,012h	; bea0
	defb 024h,036h,048h	; bea3
	defb 0ffh	; bea6

; ----------------------------------------------------------------------
; DATOS musica_game_over_b: canal 1; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbea7..0xbed8  (49 bytes)
DATA_musica_game_over_b:
	defb 0fah,000h,00bh	; bea7
	defb 0f9h,000h,011h	; beaa
	defb 029h,00eh,012h	; bead
	defb 028h,015h,01bh	; beb0
	defb 024h,007h,009h	; beb3
	defb 024h,00eh,012h	; beb6
	defb 021h,00eh,012h	; beb9
	defb 023h,015h,01bh	; bebc
	defb 021h,007h,009h	; bebf
	defb 023h,00eh,012h	; bec2
	defb 024h,00eh,012h	; bec5
	defb 021h,015h,01bh	; bec8
	defb 01dh,007h,009h	; becb
	defb 01dh,00eh,012h	; bece
	defb 01ch,00eh,012h	; bed1
	defb 01fh,036h,048h	; bed4
	defb 0ffh	; bed7

; ----------------------------------------------------------------------
; DATOS musica_game_over_c: canal 2; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbed8..0xbf03  (43 bytes)
DATA_musica_game_over_c:
	defb 0fah,000h,00bh	; bed8
	defb 0f9h,000h,011h	; bedb
	defb 018h,000h,012h	; bede
	defb 018h,015h,01bh	; bee1
	defb 018h,007h,009h	; bee4
	defb 018h,00eh,024h	; bee7
	defb 01ah,015h,01bh	; beea
	defb 01ah,007h,009h	; beed
	defb 01ah,00eh,024h	; bef0
	defb 018h,015h,01bh	; bef3
	defb 018h,007h,009h	; bef6
	defb 018h,00eh,012h	; bef9
	defb 01fh,00eh,012h	; befc
	defb 024h,036h,048h	; beff
	defb 0ffh	; bf02

; ----------------------------------------------------------------------
; DATOS musica_pattern_clear_a: PATTERN CLEAR, canal 0; grupos de tres bytes
;   (nota, duracion, espera) u ordenes
;   0xbf03..0xbf22  (31 bytes)
DATA_musica_pattern_clear_a:
	defb 0fah,000h,00ch	; bf03
	defb 0fbh,000h,002h	; bf06
	defb 030h,004h,006h	; bf09
	defb 02bh,004h,006h	; bf0c
	defb 030h,004h,006h	; bf0f
	defb 02bh,004h,006h	; bf12
	defb 030h,004h,006h	; bf15
	defb 02bh,004h,006h	; bf18
	defb 030h,024h,036h	; bf1b
	defb 0fch,000h,000h	; bf1e
	defb 0ffh	; bf21

; ----------------------------------------------------------------------
; DATOS musica_pattern_clear_b: canal 1; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbf22..0xbf41  (31 bytes)
DATA_musica_pattern_clear_b:
	defb 0fah,000h,00ch	; bf22
	defb 0fbh,000h,002h	; bf25
	defb 034h,004h,006h	; bf28
	defb 030h,004h,006h	; bf2b
	defb 034h,004h,006h	; bf2e
	defb 030h,004h,006h	; bf31
	defb 034h,004h,006h	; bf34
	defb 030h,004h,006h	; bf37
	defb 034h,024h,036h	; bf3a
	defb 0fch,000h,000h	; bf3d
	defb 0ffh	; bf40

; ----------------------------------------------------------------------
; DATOS musica_pattern_clear_c: canal 2; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbf41..0xbf60  (31 bytes)
DATA_musica_pattern_clear_c:
	defb 0fah,000h,00ch	; bf41
	defb 0fbh,000h,002h	; bf44
	defb 02bh,004h,006h	; bf47
	defb 028h,004h,006h	; bf4a
	defb 02bh,004h,006h	; bf4d
	defb 028h,004h,006h	; bf50
	defb 02bh,004h,006h	; bf53
	defb 028h,004h,006h	; bf56
	defb 02bh,024h,036h	; bf59
	defb 0fch,000h,000h	; bf5c
	defb 0ffh	; bf5f

; ----------------------------------------------------------------------
; DATOS musica_level_clear_a: LEVEL CLEAR de la maquina 2, canal 0; grupos de
;   tres bytes (nota, duracion, espera) u ordenes
;   0xbf60..0xbf79  (25 bytes)
DATA_musica_level_clear_a:
	defb 0fah,000h,00ch	; bf60
	defb 0f9h,000h,011h	; bf63
	defb 024h,009h,00ch	; bf66
	defb 026h,009h,00ch	; bf69
	defb 029h,024h,030h	; bf6c
	defb 02bh,01bh,024h	; bf6f
	defb 02dh,009h,00ch	; bf72
	defb 029h,036h,048h	; bf75
	defb 0ffh	; bf78

; ----------------------------------------------------------------------
; DATOS musica_level_clear_b: canal 1; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbf79..0xbf92  (25 bytes)
DATA_musica_level_clear_b:
	defb 0fah,000h,00ch	; bf79
	defb 0f9h,000h,011h	; bf7c
	defb 018h,009h,00ch	; bf7f
	defb 01ah,009h,00ch	; bf82
	defb 01dh,024h,030h	; bf85
	defb 01fh,01bh,024h	; bf88
	defb 021h,009h,00ch	; bf8b
	defb 01dh,036h,048h	; bf8e
	defb 0ffh	; bf91

; ----------------------------------------------------------------------
; DATOS musica_level_clear_c: canal 2; grupos de tres bytes (nota, duracion,
;   espera) u ordenes
;   0xbf92..0xbfda  (72 bytes)
DATA_musica_level_clear_c:
	defb 0fah,000h,00fh	; bf92
	defb 0f9h,000h,011h	; bf95
	defb 018h,000h,024h	; bf98
	defb 0f6h,000h,000h	; bf9b
	defb 0f5h,000h,018h	; bf9e
	defb 000h,009h,018h	; bfa1
	defb 0f5h,000h,018h	; bfa4
	defb 000h,009h,018h	; bfa7
	defb 0f5h,000h,018h	; bfaa
	defb 000h,009h,018h	; bfad
	defb 0f5h,000h,018h	; bfb0
	defb 000h,009h,018h	; bfb3
	defb 0f5h,000h,018h	; bfb6
	defb 000h,005h,006h	; bfb9
	defb 0f5h,000h,018h	; bfbc
	defb 000h,005h,006h	; bfbf
	defb 0f5h,000h,018h	; bfc2
	defb 000h,005h,00ch	; bfc5
	defb 0f5h,000h,018h	; bfc8
	defb 000h,005h,00ch	; bfcb
	defb 0f5h,000h,018h	; bfce
	defb 000h,009h,018h	; bfd1
	defb 0f6h,000h,008h	; bfd4
	defb 0ffh,043h,06dh	; bfd7

; ----------------------------------------------------------------------
; DATOS relleno: Tres bytes (0x79, 0, 0) y 0xFF hasta el final de la ROM
;   0xbfda..0xc000  (38 bytes)
DATA_relleno:
	defb 079h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfda  y...............
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfea  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bffa
