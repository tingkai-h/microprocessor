#include <xc.inc>
    
global  keypad, pincheckstart

    
psect	udata_acs   ; reserve data space in access ram
check_counter:    ds 1    ; reserve one byte for a counter variable

psect	pincheck_code,class=CODE
keypad:	cpfseq	0xF0
	bra testempty
	retlw 0x2
	
testempty:
	cpfseq	0x50, A
	goto TestVal
	movlw	0xFF
	movwf	0x80
	retlw 0x3
    
	;bra keypad
	
	;movlw	myTable_l	; output message to UART
	;lfsr	2, myArray
TestVal:
	cpfseq	0x80
	goto DisplayVal
	retlw 0x3	
	;bra keypad
	
DisplayVal:
	movwf	0x80
	call StoreVal
	return
	


StoreVal:
	movwf INDF1
	incf FSR1, 1
	return
	
pincheckstart:
	movlw 0x4
	movwf 0xB0
	movwf check_counter, A
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
	;goto incorrect_pin
	retlw 0x0
	decfsz	check_counter, A
	bra pincheck
	retlw 0x1
	;goto correct_pin