;******************************************************************************
;Universidad del Valle de Guatemala
;IE2023: Programación de Microcontroladores
; Prelab_1.asm
;Autor: Pablo Cano
;Proyecto: Prelab3
;Hardware: ATMEGA328P
;Creado: 11/02/2024
;Última modificación: 28/01/2024
;******************************************************************************

;******************************************************************************
; ENCABEZADO
;******************************************************************************

.include "M328PDEF.inc"
.cseg
.org 0x0000
	JMP SETUP
.org 0x0006
	JMP ISR_INT0
.org 0x0020
	JMP ISR_TIMER0_OVF

;******************************************************************************
; Configuración de la Pila
;******************************************************************************
SETUP:
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17

;******************************************************************************
; CONFIGURACIÓN
;******************************************************************************

LDI		R16, 0x00		;Deshabilitando RX y TX
STS		UCSR0B, R16		

LDI		R16, 0xFF		;Habilitando los puertos D como salida
OUT		DDRD, R16		
LDI		R16, 0x00
OUT		PORTD, R16
CALL	Init_T0

;Contador 1
LDI		ZH, HIGH(TABLA7SEG << 1)	;Apuntar a el espacio más significativo de donde se ubica TABLA7SEG
LDI		ZL, LOW(TABLA7SEG << 1)		;Apuntar a el espacio menos significativo de donde se ubica TABLA7SEG


; Configurar puertos de salida para los transistores
LDI		R16, (1 << DDB2) | (1 << DDB3)  ; Habilitar PB2 y PB3 del puerto B como salida
OUT		DDRB, R16

LDI		R16, (1 << DDC0) | (1 << DDC1) | (1 << DDC2) | (1 << DDC3)  ; Habilitar PC0, PC1, PC2 y PC3 del puerto C como salida
OUT		DDRC, R16
	
SBI		DDRC, PC0		;Habilitando PB0 el puerto B como salida
SBI		DDRC, PC1		;Habilitando PB1 el puerto B como salida
SBI		DDRC, PC2		;Habilitando PB2 el puerto B como salida
SBI		DDRC, PC3		;Habilitando PB3 el puerto B como salida
CBI		DDRB, PB0		;Habilitando PD0 del puerto C como entrada
CBI		DDRB, PB1		;Habilitando PD1 del puerto C como entrada
SBI		PORTB, PB0		;Habilitar el PD0 como pullup
SBI		PORTB, PB1		;Habilitar el PD1 como pullup
LDI		R17, 0x00		
	
	
LDI		R16, (1 << PCINT0) | (1 << PCINT1)
STS		PCMSK0, R16

LDI		R16, (1 << PCIE0)
STS		PCICR, R16
SEI


;******************************************************************************
; MAIN
;******************************************************************************
TABLA7SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F

MAIN_LOOP:
	OUT		PORTC, R22			//Para las leds sumadoras

	//Fuera segundos
	SBI		PORTB, PB2			
	LDI		ZL, LOW(TABLA7SEG << 1)
	ADD		ZL, R17
	LPM		R18, Z
	OUT		PORTD, R18

	RCALL	Delay
	CBI		PORTB, PB2

	

	//Fuera decenas
	SBI		PORTB, PB3
	LDI		ZL, LOW(TABLA7SEG << 1)
	ADD		ZL, R19
	LPM		R21, Z
	OUT		PORTD, R21

	RCALL	Delay
	CBI		PORTB, PB3

	

	//Resto del codigo
	CPI		R20, 100
	BRNE	MAIN_LOOP
	CLR		R20
	INC		R17
	CPI		R17, 0b0000_1010
	BREQ	RESETEO
	RJMP	MAIN_LOOP	

RESETEO:
	LDI		ZL, LOW(TABLA7SEG << 1)
	LDI		R17, 0x00
	INC		R19
	CPI		R19, 0b0000_0110
	BREQ	RESETEO2
	RJMP	MAIN_LOOP

RESETEO2:
	LDI		R19, 0x00
	RJMP	MAIN_LOOP

FS1:
	//SBI		PORTB, PB2
	RET

;******************************************************************************
; Inicializar Timer 0
;******************************************************************************
Init_T0: 
	LDI		R16, (1 << CS02) | (1 << CS00) ;Configurar el prescaler a 1024 
	OUT		TCCR0B, R16

	LDI		R16, 99						;Cargar el valor de desbordamiento
	OUT		TCNT0, R16					;Cargar el valor inicial del contador

	LDI		R16, (1<<TOIE0)
	STS		TIMSK0, R16	
	RET

;******************************************************************************
; SUBRUTINAS
;******************************************************************************
ISR_INT0:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	IN		R16, PINB

	SBRC	R16, PB0		//La intención es sumar
	RJMP	RESTA
	INC		R22
	SBRC	R22, 4
	CLR		R22
	RJMP	SALTAR


	RESTA:
	SBRS	R16, PB1
	DEC		R22
	SBRC	R22, 4
	LDI		R22, 0x0F
	RJMP	SALTAR

	SALTAR:
	SBI		PCIFR, PCIF0
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI 



;******************************************************************************
; SUBRUTINA DE ISR TIMER 0 OVERFLOW
;******************************************************************************
ISR_TIMER0_OVF:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	LDI		R16, 99
	OUT		TCNT0, R16
	SBI		TIFR0, TOV0
	INC		R20

	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

Delay:
	LDI R16, 100
	Delay_Espera:
	DEC R16
	BRNE Delay_Espera
	RET

;******************************************************************************
; TABLA
;******************************************************************************
//TABLA7SEG: .DB 0x00,0x60,0xDA,0xF2,0x66,0xB8,0xBD,0xD0,0xFD,0xE6,0xEE,0xFD,0x9C,0xFD,0x9E,0x8E
//TABLA7SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71


