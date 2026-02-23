;
; LAB3-Micros.asm
;
; Created: 21/02/2026 10:53:22
; Author : kevin
;
; Descripción: Contador binario de 4 bits con interrupciones PCINT
; Laboratorio 3 - Interrupciones
; CONFIGURACIÓN CORRECTA:
;   - Botones en A0 (PC0) y A1 (PC1)
;   - Transistores en A2 (PC2) y A3 (PC3)
;   - Display 7-seg en PD0-PD6 (TX1-D6)
;   - LEDs binarios en PB1-PB4 (D9-D12)

;============================================================================
; PRELAB - Contadores simultáneos
; ATmega328P - 16MHz
; - Contador botones (PCINT)
; - Contador hexadecimal por Timer0 (1 segundo)
;============================================================================
; ATmega328P - 16MHz
; - 2 Displays multiplexados (Timer0)
; - Contador hexadecimal cada 1 segundo
; - Contador binario por botones (PCINT)
;============================================================================

.INCLUDE "M328PDEF.INC"

;====================================================
; DEFINICION DE REGISTROS
;====================================================
.DEF TEMP              = R16
.DEF COUNTER_UNI       = R17
.DEF COUNTER_DEC       = R18
.DEF TICK              = R19
.DEF DISPLAY_SEL       = R20
.DEF SEG_DATA          = R21
.DEF COUNTER_BTN       = R22
.DEF PREV_BTN          = R23
.DEF CURR_BTN          = R24
.DEF MASK_BTN          = R25

;====================================================
; VECTORES
;====================================================
.CSEG
.ORG 0X0000
    RJMP RESET

.ORG 0X0008
    RJMP PCINT1_ISR

.ORG 0X0020
    RJMP TIMER0_OVF

;====================================================
; TABLA 7 SEGMENTOS (0–9)
;====================================================
.ORG 0X0100
TABLA:
    .DB 0X3F,0X06,0X5B,0X4F,0X66,0X6D,0X7D,0X07,0X7F,0X6F

;====================================================
; RESET
;====================================================
.ORG 0X0120
RESET:

; STACK
    LDI TEMP, HIGH(RAMEND)
    OUT SPH, TEMP
    LDI TEMP, LOW(RAMEND)
    OUT SPL, TEMP

; Inicializar contadores
    CLR COUNTER_UNI
    CLR COUNTER_DEC
    CLR TICK
    CLR DISPLAY_SEL
    CLR COUNTER_BTN

;====================================================
; CONFIGURACION PUERTOS
;====================================================

; LEDs binarios PB1–PB4
    LDI TEMP, 0B00011110
    OUT DDRB, TEMP
    CLR TEMP
    OUT PORTB, TEMP

; Segmentos PD0–PD6
    LDI TEMP, 0B01111111
    OUT DDRD, TEMP
    CLR TEMP
    OUT PORTD, TEMP

; PC2 y PC3 salidas (transistores)
; PC0 y PC1 entradas (botones)
    LDI TEMP, 0B00001100
    OUT DDRC, TEMP

; Pull-ups botones
    LDI TEMP, 0B00000011
    OUT PORTC, TEMP

; Guardar estado inicial botones
    IN PREV_BTN, PINC

;====================================================
; CONFIGURACION PCINT
;====================================================
    LDI TEMP, (1<<PCIE1)
    STS PCICR, TEMP

    LDI TEMP, (1<<PCINT8)|(1<<PCINT9)
    STS PCMSK1, TEMP

;====================================================
; CONFIGURACION TIMER0 (10ms)
;====================================================
    CLR TEMP
    OUT TCCR0A, TEMP

    LDI TEMP, (1<<CS02)|(1<<CS00)
    OUT TCCR0B, TEMP

    LDI TEMP, 100
    OUT TCNT0, TEMP

    LDI TEMP, (1<<TOIE0)
    STS TIMSK0, TEMP

    SEI

MAIN:
    RJMP MAIN

;====================================================
; ISR PCINT1 – BOTONES
;====================================================
PCINT1_ISR:

    PUSH TEMP
    PUSH CURR_BTN
    PUSH MASK_BTN
    PUSH PREV_BTN
    IN TEMP, SREG
    PUSH TEMP

    IN CURR_BTN, PINC

    MOV MASK_BTN, PREV_BTN
    EOR MASK_BTN, CURR_BTN
    MOV TEMP, PREV_BTN
    AND TEMP, MASK_BTN

; Incrementar (PC1)
    SBRS TEMP,1
    RJMP CHECK_DEC

    INC COUNTER_BTN
    ANDI COUNTER_BTN,0X0F
    RJMP UPDATE_LED

CHECK_DEC:
; Decrementar (PC0)
    SBRS TEMP,0
    RJMP UPDATE_LED

    DEC COUNTER_BTN
    ANDI COUNTER_BTN,0X0F

UPDATE_LED:
    MOV TEMP, COUNTER_BTN
    LSL TEMP
    ANDI TEMP,0B00011110
    OUT PORTB, TEMP

    MOV PREV_BTN, CURR_BTN

    POP TEMP
    OUT SREG, TEMP
    POP PREV_BTN
    POP MASK_BTN
    POP CURR_BTN
    POP TEMP
    RETI

;====================================================
; ISR TIMER0 – MULTIPLEXADO + RELOJ
;====================================================
TIMER0_OVF:

    PUSH TEMP
    PUSH SEG_DATA
    IN TEMP, SREG
    PUSH TEMP

; Recargar 10ms
    LDI TEMP,100
    OUT TCNT0,TEMP

; Apagar ambos displays
    CBI PORTC,2
    CBI PORTC,3

; Seleccionar qué mostrar
    TST DISPLAY_SEL
    BRNE SHOW_DEC

SHOW_UNI:
    MOV TEMP, COUNTER_UNI
    RJMP LOAD_SEG

SHOW_DEC:
    MOV TEMP, COUNTER_DEC

LOAD_SEG:
    LDI ZH,HIGH(TABLA<<1)
    LDI ZL,LOW(TABLA<<1)
    ADD ZL,TEMP
    CLR TEMP
    ADC ZH,TEMP
    LPM SEG_DATA,Z
    OUT PORTD,SEG_DATA

; Activar transistor
    TST DISPLAY_SEL
    BRNE ACT_DEC

ACT_UNI:
    SBI PORTC,2
    LDI DISPLAY_SEL,1
    RJMP AFTER_MUX

ACT_DEC:
    SBI PORTC,3
    CLR DISPLAY_SEL

AFTER_MUX:

; Conteo 1 segundo (100 x 10ms)
    INC TICK
    CPI TICK,20   ;<< aqui podemos editar la velocidad del contador en los display's, 100 = normal (cada segundo)
    BRNE END_TIMER

    CLR TICK

    INC COUNTER_UNI
    CPI COUNTER_UNI,10
    BRLO END_TIMER

    CLR COUNTER_UNI
    INC COUNTER_DEC

    CPI COUNTER_DEC,6
    BRLO END_TIMER

    CLR COUNTER_DEC

END_TIMER:

    POP TEMP
    OUT SREG,TEMP
    POP SEG_DATA
    POP TEMP
    RETI