#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Send_Byte_D, LCD_Write_Message
extrn	KeyPad_Setup, KeyPad_read
extrn	keypad, pincheckstart
extrn	timer_setup, overflow ;,pwm_setup 

	

psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
;delay_count:ds 1    ; reserve one byte for counter in the delay routine

    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

pin:	db  '1','2','3','4'
	myPin	EQU 4
	;counter	EQU 0x10
	align 2

correct_message:
	db  'C','o','r','r','e','c','t',0x0a
	myCorrectMessage EQU 8
	align 2

incorrect_message:
	db  'I','n','c','o','r','r','e','c','t',0x0a
	myIncorrectMessage EQU 10
	align 2

prompt_message:
	db  'E','n','t','e','r',' ','P','i','n',':',0x0a
	myPromptMessage EQU 11
	align 2

old_pin_message:
	db  'O','l','d',' ','P','i','n',':',0x0a
	myOldPinMessage EQU 9
	align 2
	
new_pin_message:
	db  'N','e','w',' ','P','i','n',':',0x0a
	myNewPinMessage	EQU 9
	align 2
    
psect	code, abs	
main:
	org 0x0
	goto	setup
	
org 0x08
	goto overflow
	movlw 0x0
	retfie
	
	org 0x100
	

	; ******* Programme FLASH read Setup Code ***********************
setup:  bcf CFGS ; point to Flash program memory
	bsf EEPGD ; access Flash program memory
	clrf TRISF, A
	movlw 0xff
	movwf LATF, A
	bcf PIR6, 4  
	;call	    pwm_setup
	;call	    timer_setup
	call        UART_Setup      ; setup UART
        call        LCD_Setup         ; setup LCD
        call        KeyPad_Setup   ; setup KeyPad

	movlw 0x0
	movwf 0x50
	movwf 0x0D0 ;tracking number of eeprom digits read
	movwf 0x0C2 ;pinreset on/off
	movlw 0x1
	movwf 0x51
	movlw 0x4 ;maximum digits in pin (4)
	movwf 0x0B0 ;storing maximum 
	movlw 0xFF
	movwf 0x60
	movwf 0x80
	movlw 0x0A0
	movwf FSR1
	movlw 'C'
	movwf 0x0F0
	movlw 0x3
	movwf 0x0C0
	movlw 0x2
	movwf 0x0C1
	
	goto start
	

	
start:	call	prompt	
	lfsr	0, myArray
	movlw	low highword(pin)
	movwf	TBLPTRU, A
	movlw	high(pin)
	movwf	TBLPTRH
	movlw	low(pin)
	movwf	TBLPTRL, A
	movlw	4
	movwf	counter, A
	
PinEntry:	
	call KeyPad_read
	call keypad
	cpfseq 0x0C1
	goto EmptyCheck
	goto pinreset
	
EmptyCheck:
	cpfseq 0x0C0
	goto PinProcess
	bra PinEntry
	
PinProcess:
	decfsz 0xB0
	goto DisplayAsterisk
	call pincheckstart
	
	cpfseq 0x50
	goto correct_pin
	goto incorrect_pin

	

	
	

DisplayAsterisk:
	movlw	'*'
	call	UART_Transmit_Byte
	
	;movlw	myTable_l	; output message to LCD
	;addlw	0xff		; don't send the final carriage return to LCD
	;lfsr	2, myArray
	call	LCD_Send_Byte_D
	movf 0x0C2,W
	cpfseq 0x51
	bra PinEntry
	bra new_pin_store

	
	
incorrect_pin:
	call LCD_Setup
	lfsr	0, myArray
	movlw	low highword(incorrect_message)
	movwf	TBLPTRU, A
 	movlw	high(incorrect_message)
	movwf	TBLPTRH
	movlw	low(incorrect_message)
	movwf	TBLPTRL, A
	movlw	9
	movwf	counter, A
	;movlw	'N'
	;call	UART_Transmit_Byte
	
	;;movlw	myTable_l	; output message to LCD
	;;addlw	0xff		; don't send the final carriage return to LCD
	;;lfsr	2, myArray
	;call	LCD_Send_Byte_D
		
	
	;goto keypad
	;return
incorrect_loop:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz counter, A
	bra incorrect_loop
	
	movlw	myIncorrectMessage
	lfsr	2,myArray
	call	UART_Transmit_Message
	
	movlw	myIncorrectMessage
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	movf	0x0C2,W
	cpfseq	0x51, A
	bra PinEntry
	movlw	0x0
	goto	pinreset_check
	;bra PinEntry
	
	;goto keypad
	;return
	
correct_pin:
	call LCD_Setup
	lfsr	0, myArray
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
	
	movlw	myCorrectMessage
	lfsr	2,myArray
	call	UART_Transmit_Message
	
	movlw	myCorrectMessage
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	movf	0x0C2,W
	cpfseq	0x51, A
	bra PinEntry
	movlw	0x1
	goto	pinreset_check
	
	
	;goto keypad
	;return

prompt:
	call LCD_Setup
	lfsr	0, myArray
	movlw	low highword(prompt_message)
	movwf	TBLPTRU, A
	movlw	high(prompt_message)
	movwf	TBLPTRH
	movlw	low(prompt_message)
	movwf	TBLPTRL, A
	movlw	10
	movwf	counter, A
	
prompt_loop:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz counter, A
	bra prompt_loop
	
	movlw	myPromptMessage
	lfsr	2,myArray
	call	UART_Transmit_Message
	
	movlw	myPromptMessage
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	return

pinreset:
	movlw 0x1
	movwf 0x0C2
	call LCD_Setup
	lfsr	0, myArray
	movlw	low highword(old_pin_message)
	movwf	TBLPTRU, A
	movlw	high(old_pin_message)
	movwf	TBLPTRH
	movlw	low(old_pin_message)
	movwf	TBLPTRL, A
	movlw	8
	movwf	counter, A
	
pinreset_loop:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz counter, A
	bra pinreset_loop
	
	movlw	myOldPinMessage
	lfsr	2,myArray
	call	UART_Transmit_Message
	
	movlw	myOldPinMessage
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	lfsr	0, myArray
	movlw	low highword(pin)
	movwf	TBLPTRU, A
	movlw	high(pin)
	movwf	TBLPTRH
	movlw	low(pin)
	movwf	TBLPTRL, A
	movlw	4
	movwf	counter, A
	
	call PinEntry

pinreset_check:
	cpfseq 0x50, A
	goto SetNewPin
	goto start
	
SetNewPin:
	call LCD_Setup
	lfsr	0, myArray
	movlw	low highword(new_pin_message)
	movwf	TBLPTRU, A
	movlw	high(new_pin_message)
	movwf	TBLPTRH
	movlw	low(new_pin_message)
	movwf	TBLPTRL, A
	movlw	8
	movwf	counter, A
	
new_pin_loop:
	tblrd*+
	movff TABLAT, POSTINC0
	decfsz counter, A
	bra new_pin_loop
	movlw myNewPinMessage
	lfsr 2,myArray
	call UART_Transmit_Message
	movlw myNewPinMessage
	addlw 0xff
	lfsr	2, myArray
	call	LCD_Write_Message
	movlw 0x4
	movwf 0x0B0

new_pin_store:
	call KeyPad_read
	call keypad
	cpfseq 0x0C0
	goto new_pin_store_process
	bra new_pin_store

new_pin_store_process:
	decfsz 0xB0
	goto DisplayAsterisk
	goto new_pin_write

new_pin_write:
	movlw 0x4
	movwf counter

	
	
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
