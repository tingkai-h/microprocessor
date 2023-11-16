#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_Transmit_Message

psect	udata_acs   ; reserve data space in access ram
KeyPad_counter: ds    1	    ; reserve 1 byte for variable KeyPad_counter
KeyPad_input: ds    1
KeyPad_output: ds   1

psect	keypad_code,class=CODE
KeyPad_Setup:
    bsf REPU
    clrf LATE
    movlw 0x0F
    movf TRISE, A

KeyPad_read:
    

test_none:
    movlw 0xFF
    cpfseq keyval, A
    bra test_0
    retlw 0x00
    
test_0:
    movlw 0xFF
    cpfseq keyval, A
    bra test_1
    retlw 0x00
    
test_1:
    movlw 0xFF
    cpfseq keyval, A
    bra test_2
    retlw 0x00

test_2:
    movlw 0xFF
    cpfseq keyval, A
    bra test_3
    retlw 0x00

test_3:
    movlw 0xFF
    cpfseq keyval, A
    bra test_4
    retlw 0x00

test_4:
    movlw 0xFF
    cpfseq keyval, A
    bra test_5
    retlw 0x00
   
test_5:
    movlw 0xFF
    cpfseq keyval, A
    bra test_6
    retlw 0x00
    
test_6:
    movlw 0xFF
    cpfseq keyval, A
    bra test_7
    retlw 0x00
    
test_7:
    movlw 0xFF
    cpfseq keyval, A
    bra ;;;;;;;;;;;;;;;
    retlw 0x00