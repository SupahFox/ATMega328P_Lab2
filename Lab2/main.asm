;
; Lab2.asm
;
; Created: 7/9/2023 19:36:17
; Author : fabuz
;

;
; Ejemplo_Interrupcion_Timer0.asm
;
; Created: 12/9/2021 22:00:38
; Author : curso de microprocesadores
;

; Empiezo con los vectores de interrupción
.ORG 0x0000 ;rutina estándar
	jmp		start		;dirección de comienzo (vector de reset)
.org	0x0008 ;rutina de interrupcion externa
	jmp		interrupcion_externa 
.ORG 0x001C ;rutina del timer
	jmp		_tmr0_int	;salto atención a rutina de comparación A del timer 0


; ---------------------------------------------------------------------------------------
; acá empieza el programa
start:
;configuro los puertos:
;	PB2 PB3 PB4 PB5	- son los LEDs del shield
    ldi	r16,	0b00111101	;edefino los led que voy a usar
	out	DDRB,	r16			;los defino como salida
	out	PORTB,	r16			;apago los LEDs

	ldi	r16,	0b00000000	
	out	DDRC,	r16			;3 botones del shield son entradas
;-------------------------------------------------------------------------------------

;Configuro el TMR0 y su interrupcion.
	ldi	r16,	0b00000010	
	out	TCCR0A,	r16			;configuro para que cuente hasta OCR0A y vuelve a cero (reset on compare), ahí dispara la interrupción
	ldi	r16,	0b00000101	;
	out	TCCR0B,	r16			;prescaler = 1024
	ldi	r16,	124			;
	out	OCR0A,	r16			;comparo con 124, cuando esto llega a 1024 interrumpe, entonces el led hace lo que le pedimos, pero no va a hacer nada si no habilitamos las int globales
	ldi	r16,	0b00000010	;
	sts	TIMSK0,	r16			;habilito la interrupción (falta habilitar global)
;-------------------------------------------------------------------------------------
;Inicializo algunos registros que voy a usar como variables.
	ldi	r24,	0x00		;inicializo r24 para un contador genérico
	ldi	r18,	0;mi registro de incrementos
	ldi	r19,	0;el registro del segundo bit
	ldi	r20,	0;el registro del tercer bit
;-------------------------------------------------------------------------------------
	ldi	r16, 0b00000010
	sts	PCICR,r16; habilito la interrupcion
	ldi	r16, 0b00000100
	sts	PCMSK1,r16; habilito la interrupt del portC



; Programa principal ... acá puedo hacer lo que quiero

comienzo:
	sei							; habilito las interrupciones globales(set interrupt flag)

loop1:
	nop
	nop
	nop
	nop
	ori r16, 0xFF
	nop
	nop
	nop
	brne loop1  //branch not equal 0 la zero flag es 0 salta si la operacion anterior da cero por ende va a loop 2
loop2:
	nop
	nop
	nop
fin:
	rjmp loop2

;RUTINAS
;-------------------------------------------------------------------------------------

; ------------------------------------------------
; Rutina de atención a la interrupción del Timer0.
; ------------------------------------------------
; recordar que el timer 0 fue configurado para interrumpir cada 125 ciclos (5^3), y tiene un prescaler 1024 = 2^10.
; El reloj de I/O está configurado @ Fclk = 16.000.000 Hz = 2^10*5^6; entonces voy a interrumpir 125 veces por segundo
; esto sale de dividir Fclk por el prescaler y el valor de OCR0A.
; 
; Esta rutina por ahora no hace casi nada, Ud puede ir agregando funcionalidades.
; Por ahora solo: cambia el valor de un LED en la placa, e incrementa un contador en r24.

_tmr0_int: 					; interrupt del timer
	in r17,SREG 			; este es el contexto
	inc	r24					; podemos incrementar r24 por cada ciclo del clock
	cpi	r24,125				; comparamos
	breq count_secs			; aca comparamos el count_secs con 125, si es 125 
	rjmp _tmr0_out			; vamos al _tmr0_out

count_secs:
	sbi PINB, 5			; aca indicamos el led 5 como salida, lo que vamos a hacer es comparar el status del led 5 para que cuente
	inc r18				; para 2 seg
	inc r19				; para 4 seg
	inc r20				; para 8 seg
	rjmp cambio_led 	; aca vamos a empezar a cambiar los led, hay que cambiar los led e ir comparandolos unos con otros.

cambio_led:
	cpi r18, 2 			; compara si el r18 vale 2, si vale 2:
	breq cambio_led2 	; la instruccion anterior es igual, así que pasa cambio_led2, sino
	cpi r19, 4			; compara otra vez, si es igual
	breq cambio_led3 	; cambia cambio_led3, sino:
	cpi r20, 8			; compara otra vez, siempre agregando y comparando el status anterior
	breq cambio_led4
	cpi r20, 15			; como solo tenemos 4 leds, el número máximo es 15, si llega a 15:
	breq reiniciar_count; volvemos a iniciar el conteo y la secuencia
	rjmp _tmr0_out

cambio_led2:
	sbi PINB, 4
	ldi r18, 0
	rjmp cambio_led

cambio_led3:
	sbi PINB, 3
	ldi r19, 0
	rjmp cambio_led

cambio_led4:
	sbi PINB, 2
	ldi r20, 0
	rjmp cambio_led

reiniciar_count:
	ldi r18, 0
	ldi r19, 0
	ldi r20, 0
	rjmp _tmr0_out

_tmr0_out:
	out	SREG,r17				; básicamente tmr_0_our devuelve el contexto
	reti						; retorno de la rutina

interrupcion_externa:
					
	in r17,SREG 	
	rjmp wait
					
wait:				; en este caso wait se usa cuando tocamos un botón, lo que hace que el procesador quede dando vueltitas hasta esperar que toquemos otro botón.
	sbis PINC, 1 	; BOTON S1_A1 QUE CONTINUA EL PROGRAMA
	rjmp salir
	sbis PINC, 3 	; BOTON S3_A3 QUE REINICIA
	rjmp reiniciar
	rjmp wait
								
salir: 				; FUNCION PARA CONTINUAR EL PROGRAMA, CARGANDO EL CONTEXTO
	out SREG,r17
	reti

reiniciar: 			; FUNCION PARA REINICIAR EL PROGRAMA, PONEMOS TODOS LOS REGISTROS EN 0 Y COMENZAMOS DE NUEVO
	ldi r18, 0
	ldi r19, 0
	ldi r20, 0
	ldi r16, 0b00111100
	out PORTB, r16
	rjmp salir
	
					; BOTON S1_A1: CONTINUA EL PROGRAMA
					; BOTON S2_A2: PAUSA EL PROGRAMA
					; BOTON S3_A3: REINICIA EL PROGRAMA