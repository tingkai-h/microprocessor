#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte  ; external subroutines
extrn	LCD_Setup, LCD_Send_Byte_D
extrn	KeyPad_Setup, KeyPad_read
	
;psect	edata
;    db  0,1,2,3

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
	;bra eeread
eewrite :
	MOVLW 0x00;
	MOVWF EEADRH ; Upper bits of Data Memory Address to write
	MOVLW 0x01 ;
	MOVWF EEADR ; Lower bits of Data Memory Address to write
	MOVLW 0xaa
	MOVWF EEDATA ; Data Memory Value to write
	BCF  EEPGD ; Point to DATA memory EECON1,
	BCF  CFGS ; Access EEPROM ; EECON1,
	clrf EECON1
	BSF  WREN ; Enable writes ; EECON1,
	
	BCF  GIE ; Disable Interrupts , INTCON, 7
	MOVLW 0x55 ;
	MOVWF EECON2 ; Write 55h
	MOVLW 0xAA ;
	MOVWF EECON2 ; Write 0AAh
	BSF  WR ; Set WR bit to begin write EECON1,
	BTFSC  WR ; Wait for write to complete GOTO $-2 EECON1,
	GOTO $-2
	; test code
	movlw 0x02
	movwf LATF, A
	;check interact flag
check :	btfss PIR6, 4
	bra check
	;BSF  GIE ; Enable Interrupts , INTCON, 
	bcf PIR6, 4  
	movlw 0x00
	movwf LATF, A

eeread :	
	;read procedure
	MOVLW 0x00;
	MOVWF EEADRH ; Upper bits of Data Memory Address to write
	MOVLW 0x02 ;
	MOVWF EEADR ; Lower bits of Data Memory Address to write
	BCF  EEPGD ; Point to DATA memory EECON1,
	BCF  CFGS ; Access EEPROM ; EECON1,
	BSF  RD
	MOVF EEDATA, w ; Data Memory Value to write
	movwf LATF, a	
	MOVLW 0x00;
	MOVWF EEADRH ; Upper bits of Data Memory Address to write
	MOVLW 0x02 ;
	MOVWF EEADR ; Lower bits of Data Memory Address to write
	BCF  EEPGD ; Point to DATA memory EECON1,
	BCF  CFGS ; Access EEPROM ; EECON1,
	BSF  RD
	MOVF EEDATA, w ; Data Memory Value to write
	movwf LATF, a	
	bra $
	; User code execution
	BCF  WREN ; Disable writes on write complete (EEIF set) EECON1,
	
	bcf         CFGS     ; point to Flash program memory  
        bsf         EEPGD ; access Flash program memory
        call        UART_Setup      ; setup UART
        call        LCD_Setup         ; setup LCD
        call        KeyPad_Setup   ; setup KeyPad

	movlw 0x0
	movwf 0x50
	movlw 0xFF
	movwf 0x60
	movwf 0x80
	goto	keypad


	
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
	call	UART_Transmit_Byte
	
	;movlw	myTable_l	; output message to LCD
	;addlw	0xff		; don't send the final carriage return to LCD
	;lfsr	2, myArray
	call	LCD_Send_Byte_D
		
	
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

int_ee :
	bcf PIR6, 4
	movlw 0xf0
	
	movwf LATF
	retfie f
	

	end	rst