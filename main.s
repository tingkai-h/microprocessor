#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Send_Byte_D, LCD_Write_Message
extrn	KeyPad_Setup, KeyPad_read
	

;psect	udata_acs   ; reserve data space in access ram
;counter:    ds 1    ; reserve one byte for a counter variable
;delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
;psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
;myArray:    ds 0x80 ; reserve 128 bytes for message data


psect	code, abs	
main:
	org 0x0
	goto	setup
	
	org 0x100
	

	; ******* Programme FLASH read Setup Code ***********************
setup:  bcf CFGS ; point to Flash program memory
	bsf EEPGD ; access Flash program memory
	clrf TRISF, A
	movlw 0xff
	movwf LATF, A
	bcf PIR6, 4  
	call        UART_Setup      ; setup UART
        call        LCD_Setup         ; setup LCD
        call        KeyPad_Setup   ; setup KeyPad

	movlw 0x0
	movwf 0x50
	movwf 0x0D0 ;tracking number of eeprom digits read
	movlw 0x4 ;maximum digits in pin (4)
	movwf 0x0B0 ;storing maximum 
	movlw 0xFF
	movwf 0x60
	movwf 0x80
	movlw 0x0A0
	movwf FSR1
	
	goto start
	
pin:	db  '1','2','3','4'
	myPin	EQU 0x400
	counter	EQU 0x10
	align 2

correct_message:
	db  'C','o','r','r','e','c','t'
	myCorrectMessage EQU 0x500

incorrect_message:
	db  'I','n','c','o','r','r','e','c','t'
	myIncorrectMessage EQU 0x600
	
start:	lfsr	0, myPin
	movlw	low highword(pin)
	movwf	TBLPTRU, A
	movlw	high(pin)
	movwf	TBLPTRH
	movlw	low(pin)
	movwf	TBLPTRL, A
	movlw	4
	movwf	counter, A
	goto keypad

loop:	
	goto keypad
	
keypad:	call	KeyPad_read
	cpfseq	0x50, A
	goto TestVal
	movlw	0xFF
	movwf	0x80
	bra keypad
    
	;bra keypad
	
	;movlw	myTable_l	; output message to UART
	;lfsr	2, myArray
TestVal:
	cpfseq	0x80
	goto DisplayVal
		
	bra keypad
	
DisplayVal:
	movwf	0x80
	call StoreVal
	
DisplayAsterisk:	
	movlw	'*'
	call	UART_Transmit_Byte
	
	;movlw	myTable_l	; output message to LCD
	;addlw	0xff		; don't send the final carriage return to LCD
	;lfsr	2, myArray
	call	LCD_Send_Byte_D
		
	
	goto keypad

StoreVal:
	movwf INDF1
	incf FSR1, 1
	decfsz 0xB0
	goto DisplayAsterisk
	movlw 0x4
	movwf 0xB0
	movlw 0x0A0
	movwf FSR1
	goto pincheck

pincheck:
	tblrd*+
	movff	TABLAT, POSTINC0
	movf	TABLAT, W
	movwf	0xE0
	movf	INDF1, W
	incf	FSR1, 1
	cpfseq	0x0E0
	goto incorrect_pin
	decfsz	counter, A
	bra pincheck
	goto correct_pin
	return
	


incorrect_pin:
	movlw	'N'
	call	UART_Transmit_Byte
	
	;movlw	myTable_l	; output message to LCD
	;addlw	0xff		; don't send the final carriage return to LCD
	;lfsr	2, myArray
	call	LCD_Send_Byte_D
		
	
	goto keypad
	return

correct_pin:
	lfsr	0, myCorrectMessage
	movlw	low highword(correct_message)
	movwf	TBLPTRU, A
	movlw	high(correct_message)
	movwf	TBLPTRH
	movlw	low(correct_message)
	movwf	TBLPTRL, A
	movlw	7
	movwf	counter, A
	
correct_loop:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz counter, A
	bra correct_loop
	
	movlw	correct_message
	lfsr	2,myCorrectMessage
	call	UART_Transmit_Message
	
	movlw	correct_message
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myCorrectMessage
	call	LCD_Write_Message
		
	
	goto keypad
	return
	
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
