 ;*analogcomparator.asm
 ;This program uses an analog comparator interrupt to cause an interrupt service procedure to be
 ;performed whenever the analog comparator toggles its output. The interrupt service procedure
 ;will output an ASCII string message "ALARM" one time. 
 ;
 ;
 .INCLUDE <m48def.inc>


.CSEG
.DEF BRRH = R17	; Baud Rate Register High
.DEF BRRL = R16	; Baud Rate Register Low

.ORG 0x0000 
	RJMP MAIN

.ORG 0X017  ; ANALOG COMPARATOR INTERUPT VECTOR
	RJMP ANALOGCOMPARE




MAIN:
	CLI

	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16

	RCALL USART0_INITIALIZE
	RCALL ANALOG_COMPARE_SETUP
	SEI

LOOP:
	RJMP LOOP
USART0_INITIALIZE:
	; Set baud rate
	LDI BRRL, 25
	LDI BRRH, 0	; Baud Rate of 19.2K at f = 8 MHz
	STS UBRR0H, BRRH
	STS UBRR0L, BRRL

	; Set frame format: 8 data, 2 stop bit, Odd Parity
	; umsel1 umsel0 upmn1 upmn0 usbsn ucszn1 ucszn0 ucpoln
	;   0	0	1    1	  1	1    1	  0
	LDI R18, 0x3E
	STS UCSR0C, R18

	; Enable transmitter, ucszn2 = for 8 bit, no interupts
	;rxcien txcien udrien rxenn txenn ucszn2 rxb8n txb8n
	;   0	0       0	     0	  1	0    0	 0
	LDI R18, 0x08
	STS UCSR0B, R18
	RET

USART0_TRANSMIT:
	; Wait for empty transmit buffer
	LDS	R20,UCSR0A
	SBRS R20,UDRE0
	RJMP USART0_TRANSMIT
	LDI R16,'A'
	STS UDR0,R16
TRANS_L:	
	LDS R20,UCSR0A
	SBRS R20,UDRE0
	RJMP TRANS_L
	LDI R16,'L'
	STS UDR0,R16
TRANS_A:	
	LDS R20,UCSR0A
	SBRS R20,UDRE0
	RJMP TRANS_A
	LDI R16,'A'
	STS UDR0,R16
TRANS_R:	
	LDS	R20,UCSR0A
	SBRS R20,UDRE0
	RJMP TRANS_R
	LDI R16,'R'
	STS UDR0,R16
TRANS_M:	
	LDS	R20,UCSR0A
	SBRS R20,UDRE0
	RJMP TRANS_M
	LDI R16,'M'
	STS UDR0,R16
	RET

ANALOG_COMPARE_SETUP:
	;SET ADCSRB FOR ACME=1
	LDS R16,ADCSRB ;SET ACME IN THE SFIOR
	ORI R16,0b01000000 ; SETS BIT 6 AND LEAVES OTHER BITS UNAFFECTED
	STS ADCSRB,R16
	;SET ACSR, ACD = 0, ACBG = 1, ACO = d, ACI = d, ACIE = 1, ACIC = 0, ACIS1/0 = 00
	LDI R16,0X48
	OUT ACSR,R16
	LDS R16,ADCSRA
	CBR R16,0x80 ;DISABLE ADC WHILE USING COMPARATOR
	STS ADCSRA,R16
RET

ANALOGCOMPARE:
	CLI
	RCALL USART0_TRANSMIT
	RETI