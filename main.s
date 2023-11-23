#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte  ; external subroutines
extrn	LCD_Setup, LCD_Send_Byte_D
extrn	KeyPad_Setup, KeyPad_read
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

;psect	data    
	; ******* myTable, data in programme memory, and its length *****
;myTable:
;	db	'a','b','c','d','e','f ','g','h','i','j','k','l',0x0a
;					; message, plus carriage return
;	myTable_l   EQU	13	; length of data
;	align	2
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	call	KeyPad_Setup	; setup KeyPad
	movlw 0x0
	movwf 0x50
	movlw 0xFF
	movwf 0x60
	movwf 0x80
	goto	keypad
	
	; ******* Main programme ****************************************
;start: 	lfsr	0, myArray	; Load FSR0 with address in RAM	
;	movlw	low highword(myTable)	; address of data in PM
;	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
;	movlw	high(myTable)	; address of data in PM
;	movwf	TBLPTRH, A		; load high byte to TBLPTRH
;	movlw	low(myTable)	; address of data in PM
;	movwf	TBLPTRL, A		; load low byte to TBLPTRL
;	movlw	myTable_l	; bytes to read
;	movwf 	counter, A		; our counter register
;loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
;	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
;	decfsz	counter, A		; count down to zero
;	bra	loop		; keep going until finished
	
keypad:	call	KeyPad_read
	cpfseq	0x50, A
	goto TestVal
	bra keypad
    
	;bra keypad
	
	;movlw	myTable_l	; output message to UART
	;lfsr	2, myArray
TestVal:
	cpfseq	0x80
	goto DisplayVal
	movlw 0x0
	bra keypad
	
DisplayVal:
	movwf	0x80
	call	UART_Transmit_Byte
	
	;movlw	myTable_l	; output message to LCD
	;addlw	0xff		; don't send the final carriage return to LCD
	;lfsr	2, myArray
	call	LCD_Send_Byte_D
	;call delay
	
	goto keypad
	
	
	;goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz 0x60, F, A
	bra delay2
	return

delay2:	movlw 0xFF
	movwf 0x70
	decfsz 0x70, F, A
	goto $-1
	bra delay
	

	end	rst