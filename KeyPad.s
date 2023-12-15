#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_read

psect	udata_acs   ; reserve data space in access ram
low_bits: ds	1
high_bits: ds	1
keyval: ds  1

psect	keypad_code,class=CODE
KeyPad_Setup:
    movlb 15
    bsf REPU
    movlb 0
    clrf LATE
    return

KeyPad_read:
    ;setting PORTE to input for rows and columns
    movlw 0x0F
    movwf TRISE
    movlw 0xFF
    movwf 0x20
    call delay ;delays to allow time for switch between input/output
    movff PORTE, low_bits
    movf PORTE, W
    movlw 0xF0
    movwf TRISE
    movlw 0xFF
    movwf 0x20
    call delay ;delays to allow time for switch between input/output
    movff PORTE, high_bits
    movf high_bits, W, A
    iorwf low_bits, W, A
    movwf keyval,A
    call test_none ;start testing which key has been pressed -> returns ascii of correspoding key to w reg
    return

delay: 
    decfsz 0x20, F, A
    bra delay2
    return

delay2: ;nested delay
    movlw 0xFF
    movwf 0x30, A

    decfsz 0x30, F, A
    goto $-1
    bra delay

test_none:
    movlw 0xFF
    cpfseq keyval, A
    bra test_0
    retlw 0x0
    
test_0:
    movlw 0xBE
    cpfseq keyval, A
    bra test_1
    retlw '0'
    
test_1:
    movlw 0x77
    cpfseq keyval, A
    bra test_2
    retlw '1'

test_2:
    movlw 0xB7
    cpfseq keyval, A
    bra test_3
    retlw '2'

test_3:
    movlw 0xD7
    cpfseq keyval, A
    bra test_4
    retlw '3'

test_4:
    movlw 0x7B
    cpfseq keyval, A
    bra test_5
    retlw '4'
   
test_5:
    movlw 0xBB
    cpfseq keyval, A
    bra test_6
    retlw '5'
    
test_6:
    movlw 0xDB
    cpfseq keyval, A
    bra test_7
    retlw '6'
    
test_7:
    movlw 0x7D
    cpfseq keyval, A
    bra test_8
    retlw '7'
    
test_8:
    movlw 0xBD
    cpfseq keyval, A
    bra test_9
    retlw '8'
    
test_9:
    movlw 0xDD
    cpfseq keyval, A
    bra test_A
    retlw '9'
    
test_A:
    movlw 0x7E
    cpfseq keyval, A
    bra test_B
    retlw 'A'
    
test_B:
    movlw 0xDE
    cpfseq keyval, A
    bra test_C
    retlw 'B'
    
test_C:
    movlw 0xEE
    cpfseq keyval, A
    bra test_D
    retlw 'C'
    
test_D:
    movlw 0xED
    cpfseq keyval, A
    bra test_E
    retlw 'D'
    
test_E:
    movlw 0xEB
    cpfseq keyval, A
    bra test_F
    retlw 'E'
    
test_F:
    movlw 0xE7
    cpfseq keyval, A
    bra err
    retlw 'F'
    
err:    
    retlw 0x0

    