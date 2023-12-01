#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte  ; external subroutines
extrn	LCD_Setup, LCD_Send_Byte_D
extrn	KeyPad_Setup, KeyPad_read
	
psect	edata
    db  '1','2','3','4'

psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

    
psect	code, abs	
rst: 	org 0x0
 	goto	setup
	
int_hi : org 00008
	goto int_ee
	
	
	org	0x100	
	; ******* Programme FLASH read Setup Code ***********************
setup:  
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
	movwf FSR0
	
	bra keypad

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
	movwf INDF0
	incf FSR0, 1
	decfsz 0xB0
	goto DisplayAsterisk
	movlw 0x4
	movwf 0xB0
	goto eeread
	
eeread: 
	movlw 0x0A0
	movwf FSR0
	MOVLW 0x00;
	MOVWF EEADRH ; Upper bits of Data Memory Address to write
	MOVF 0x0D0, w
	MOVWF EEADR ; Lower bits of Data Memory Address to write
	BCF  EEPGD ; Point to DATA memory EECON1,
	BCF  CFGS ; Access EEPROM ; EECON1,
	BSF  RD
	MOVF EEDATA, W; Data Memory Value to write
	movwf 0xE0
	movf INDF0, w
	cpfseq 0xE0, A
	goto incorrect_pin
	incf FSR0, 1
	incf 0x0D0, 1
	decfsz 0xB0
	goto eeread
	goto correct_pin

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
	movlw	'Y'
	call	UART_Transmit_Byte
	
	;movlw	myTable_l	; output message to LCD
	;addlw	0xff		; don't send the final carriage return to LCD
	;lfsr	2, myArray
	call	LCD_Send_Byte_D
		
	
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

int_ee :
	bcf PIR6, 4
	movlw 0xf0
	
	movwf LATF
	retfie f
	

	end	rst