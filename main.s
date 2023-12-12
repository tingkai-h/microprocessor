#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Send_Byte_D, LCD_Write_Message, LCD_delay_ms
extrn	KeyPad_Setup, KeyPad_read
extrn	keypad, pincheckstart
extrn	timer_setup, overflow, pwm_width ;,pwm_setup
extrn	pwm_buzzer_setup
    
global pin
	

psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
incorrect_counter:    ds 1
BUFFER_ADDR_HIGH:   ds 1
BUFFER_ADDR_LOW:    ds 1
CODE_ADDR_UPPER:    ds 1
CODE_ADDR_HIGH:	    ds 1
CODE_ADDR_LOW:	    ds 1
DATA_ADDR_HIGH:	    ds 1
DATA_ADDR_LOW:	    ds 1
NEW_DATA_LOW:	    ds 1
NEW_DATA_HIGH:	    ds 1





;delay_count:ds 1    ; reserve one byte for  counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x90 ; reserve 128 bytes for message data
input_pin:  ds 4
new_pin:    ds 4
    
psect	code, abs	
main:
	org 0x0
	movlw 0x3
	movwf incorrect_counter, A
	goto	setup
	
org 0x08
	call overflow
	retfie f
		
	org 0x80
pin:	db  '0','0','0','0'
	myPin	EQU 4
	;counter	EQU 0x10
	align 2
	
	org 0x100
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
	
	org 0x200
	
	; ******* Programme FLASH read Setup Code ***********************
setup:  bcf CFGS ; point to Flash program memory
	bsf EEPGD ; access Flash program memory
	clrf TRISF, A
	movlw 0xff
	movwf LATF, A
	bcf PIR6, 4
	call	    pwm_buzzer_setup
	call	    timer_setup
	call         UART_Setup      ; setup UART
        call        LCD_Setup         ; setup LCD
        call        KeyPad_Setup   ; setup KeyPad

	movlw 0x0
	movwf 0x50
	movwf 0x0D0 ;tracking number of eeprom digits read
	movwf 0x0C2 ;pinreset on/off
	movwf 0x0C3 ;time to store new pin checker
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
	movf 0x0C3,W
	cpfseq 0x51
	bra PinEntry
	bra new_pin_store

	
	
incorrect_pin:
	;movlw	0x0
	;movwf	0x0C3
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
	;movf	0x0C2,W
	;cpfseq	0x51, A
	movlw 0xff
	call LCD_delay_ms
	call LCD_delay_ms
	call LCD_delay_ms
	decfsz incorrect_counter
	goto setup
	goto $
	
	;movlw	0x0
	;goto	pinreset_check
	;bra PinEntry
	
	;goto keypad
	;return
	
correct_pin:
	;movlw	0x1
	;movwf	0x0C3
	movf	0x0C2,W
	cpfseq	0x50
	goto	pinreset_check
	movlw	20
	movwf	pwm_width, A
	call	LCD_Setup
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
	
	movlw 0xff
	call LCD_delay_ms
	call LCD_delay_ms
	call LCD_delay_ms
	movlw 0x3
	movwf incorrect_counter, A
	goto setup
	

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
	;movf 0x0C3,W
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
	movlw 0x1
	movwf 0x0C3
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
	;movlw 0x4
	;movwf counter
	;movf 0x0A4, W
	;movwf pin
	;movf 0x0A5, W
	;movwf pin+1
	;movf 0x0A6,W
	;movwf pin+2
	;movf 0x0A7,W
	;movwf pin+3
	;call        LCD_Setup
	;goto setup
	
;	MOVLW 4 ; number of bytes in erase block
;	MOVWF counter
;	MOVLW BUFFER_ADDR_HIGH ; point to buffer
;	MOVWF FSR0H
;	MOVLW BUFFER_ADDR_LOW
;	MOVWF FSR0L
;	MOVLW CODE_ADDR_UPPER ; Load TBLPTR with the base
;	MOVWF TBLPTRU ; address of the memory block
;	MOVLW CODE_ADDR_HIGH
;	MOVWF TBLPTRH
;	MOVLW CODE_ADDR_LOW
;	MOVWF TBLPTRL
;READ_BLOCK:
;	TBLRD*+ ; read into TABLAT, and inc
;	MOVF TABLAT, W ; get data
;	MOVWF POSTINC0 ; store data
;	DECFSZ counter ; done?
;	BRA READ_BLOCK ; repeat
;MODIFY_WORD:
;	MOVLW DATA_ADDR_HIGH ; point to buffer
;	MOVWF FSR0H
;	MOVLW DATA_ADDR_LOW
;	MOVWF FSR0L
;	MOVLW NEW_DATA_LOW ; update buffer word
;	MOVWF POSTINC0
;	MOVLW NEW_DATA_HIGH
;	MOVWF INDF0
ERASE_BLOCK:
	movlw	low highword(pin)
	movwf	TBLPTRU, A
	movlw	high(pin)
	movwf	TBLPTRH
	movlw	low(pin)
	movwf	TBLPTRL, A
	BSF EEPGD ; point to Flash program memory EECON1, 
	BCF CFGS ; access Flash program memory EECON1, 
	BSF WREN ; enable write to memory EECON1, 
	BSF FREE ; enable Row Erase operation EECON1, 
	BCF GIE ; disable interrupts INTCON, 
	MOVLW 0x55
	MOVWF EECON2 ; write 55h
	MOVLW 0xAA
	MOVWF EECON2 ; write 0AAh
	BSF WR ; start erase (CPU stall) EECON1, W
	BSF GIE ; re-enable interrupts INTCON, 
	TBLRD*- ; dummy read decrement
;	MOVLW BUFFER_ADDR_HIGH ; point to buffer
;	MOVWF FSR0H
;	MOVLW BUFFER_ADDR_LOW
;	MOVWF FSR0L
;	lfsr	0, new_pin
	lfsr	0, 0x0A4
WRITE_BUFFER_BACK:
	MOVLW 4 ; number of bytes in holding register
	MOVWF  counter
WRITE_BYTE_TO_HREGS:
	MOVFF POSTINC0, WREG ; get low byte of buffer data
	MOVWF TABLAT ; present data to table latch
	TBLWT+* ; write data, perform a short write
	; to internal TBLWT holding register.
	DECFSZ counter ; loop until buffers are full
	BRA WRITE_BYTE_TO_HREGS
PROGRAM_MEMORY:
	BSF EEPGD ; point to Flash program memory EECON1, 
	BCF CFGS ; access Flash program memory EECON1, 
	BSF WREN ; enable write to memory EECON1, 
	BCF GIE ; disable interrupts INTCON, 
	MOVLW 0x55
	MOVWF EECON2 ; write 55h
	MOVLW 0xAA
	MOVWF EECON2 ; write 0AAh
	BSF WR ; start program (CPU stall) EECON1, 
	BSF GIE ; re-enable interrupts INTCON, 
	BCF WREN ; disable write to memory EECON1, 
	goto setup
	
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
