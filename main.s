#include <xc.inc>

; external subroutines
extrn	UART_Setup, UART_Transmit_Byte, UART_Transmit_Message  
extrn	LCD_Setup, LCD_Send_Byte_D, LCD_Write_Message, LCD_delay_ms
extrn	KeyPad_Setup, KeyPad_read
extrn	keypad, pincheckstart
extrn	timer_setup, overflow, pwm_width
extrn	pwm_buzzer_setup
    
global pin
	

psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
incorrect_counter:    ds 1

    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x90 ; reserve 128 bytes for message data
input_pin:  ds 4
new_pin:    ds 4
    
psect	code, abs	
main:
	org 0x0
	movlw 0x3 ;alarm triggered after 3 consecutive failed attempts
	movwf incorrect_counter, A
	goto	setup
	
org 0x08 ;high priority interrupt vector addres in program memory
	call overflow ;calling interrupt routine
	retfie f ;exits interrupt routine
		
	org 0x80
pin:	db  '0','0','0','0' ;setting base pin when system is initialised
	myPin	EQU 4
	align 2
	
	org 0x100
correct_message: ;messsage to be displayed on LCD when correct pim entered
	db  'C','o','r','r','e','c','t',0x0a
	myCorrectMessage EQU 8
	align 2

incorrect_message: ;message to be displayed on LCD when incorrect pin entered 
	db  'I','n','c','o','r','r','e','c','t',0x0a
	myIncorrectMessage EQU 10
	align 2

prompt_message: ;pin entry prompt LCD message 
	db  'E','n','t','e','r',' ','P','i','n',':',0x0a
	myPromptMessage EQU 11
	align 2

old_pin_message: ;pin entry prompt LCD message when reset requested
	db  'O','l','d',' ','P','i','n',':',0x0a
	myOldPinMessage EQU 9
	align 2
	
new_pin_message: ;new pin entry prompt LCD message 
	db  'N','e','w',' ','P','i','n',':',0x0a
	myNewPinMessage	EQU 9
	align 2
	
	org 0x200
	
	; ******* Programme FLASH read Setup Code ***********************
setup:  bcf CFGS ; point to Flash program memory
	bsf EEPGD ; access Flash program memory
	
	
	call	    timer_setup	    ;setup timer
	call         UART_Setup      ; setup UART
        call        LCD_Setup         ; setup LCD
        call        KeyPad_Setup   ; setup KeyPad
	
	;Defining variables stored in file registers
	movlw 0x0
	movwf 0x50 ;for comparing W regiter values with 0/off
	movwf 0x0C2 ;pinreset on/off
	movwf 0x0C3 ;time to store new pin checker
	movlw 0x1
	movwf 0x51 ;for comparing W register values with 1/on
	movlw 0x4 ;maximum digits in pin (4)
	movwf 0x0B0 ;storing maximum 
	movlw 0x0A0 ;file register address where keypad inputs are stored
	movwf FSR1 
	movlw 'C' ;pin reset triggered when 'C' key pressed
	movwf 0x0F0
	movlw 0x3 ;when no keys are pressed, PinCheck.s returns 3 in W reg
	movwf 0x0C0 ;for checking if no keys are pressed
	movlw 0x2 ;when key is held down, PinCheck.s returns 2 in W reg
	movwf 0x0C1 ;for checking if key is held down to avoid unwanted repeat inputs
	
	goto start
	

	
start:	call	prompt	;prompting user to enter pin
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
	
incorrect_loop:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz counter, A
	bra incorrect_loop
	
	movlw	myIncorrectMessage
	lfsr	2,myArray
	call	UART_Transmit_Message
	
	movlw	myIncorrectMessage ;output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	movlw 0xff
	call LCD_delay_ms
	call LCD_delay_ms
	call LCD_delay_ms
	decfsz incorrect_counter
	goto setup
	call	    pwm_buzzer_setup
	goto setup
	
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
	movwf	pwm_width, A ;sets correct pwm_width so servomotor turns
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
	
	movlw	myCorrectMessage ;output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	movlw 0xff
	call LCD_delay_ms
	call LCD_delay_ms
	call LCD_delay_ms
	movlw 0x3
	movwf incorrect_counter, A
	CLRF CCP4CON ;turn off buzzer
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
	
	movlw	myPromptMessage ;output message to LCD
	addlw	0xff		; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	return

pinreset:
	movlw 0x0A0
	movwf FSR1
	movlw 0x4 ;maximum digits in pin (4)
	movwf 0x0B0 ;storing maximum 
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
	goto ERASE_BLOCK

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

