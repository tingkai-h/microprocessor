#include <xc.inc>
    
global  keypad, pincheckstart

    
psect	udata_acs   ; reserve data space in access ram
check_counter:    ds 1    ; reserve one byte for a counter variable

psect	pincheck_code, class=CODE
keypad:	cpfseq	0xF0 ;check if 'C' is pressed
	bra testempty
	retlw 0x2 ;return 0x2 to W reg indicating that pin reset has been requested
	
testempty:
	cpfseq	0x50, A
	goto TestVal
	movlw	0xFF
	movwf	0x80 ;tracking if pin is being held to avoid unwanted repeat inputs
	retlw 0x3 ;return 0x3 to W reg indcating that no pin pressed

TestVal:
	cpfseq	0x80
	goto DisplayVal
	retlw 0x3	
	
DisplayVal:
	movwf	0x80
	call StoreVal
	return
	


StoreVal:
	movwf INDF1 ;store inputted digit into file register pointed to by FSR1
	incf FSR1, 1 ;increment FSR1 so next digit stored in successive register
	return
	
pincheckstart:
	movlw 0x4
	movwf 0xB0 ;number of digits entered checker
	movwf check_counter, A
	movlw 0x0A0
	movwf FSR1, A
	goto pincheck

pincheck:
	tblrd*+
	movff	TABLAT, POSTINC0
	movf	TABLAT, W
	movwf	0xE0 ;moving inividual digits of correct pin into file register for comparison with inputted pin
	movf	INDF1, W, A
	incf	FSR1, A
	cpfseq	0x0E0
	retlw 0x0 ;if a digit is incorrect return 0 to indicate failed attempt
	decfsz	check_counter, A
	bra pincheck ;repeat pincheck with next digit until all 4 have been checked
	retlw 0x1 ;if all digits are correct return 1 to indicate succesful attempt