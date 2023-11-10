	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0

	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISJ, A	    ; Port C all outputs
	bra 	test
loop:
	movff 	0x06, PORTJ
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0x63
	cpfsgt 	0x06, A
	movlw 0xFF
	movwf 0x20, A
	
	call	delay
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start

SPI_MasterInit:	; Set Clock edge to negative
   bcf	CKE2	; CKE bit in SSP2STAT, 
   ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
   movlw 	(SSP2CON1_SSPEN_MASK)|(SSP2CON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK
   movwf 	SSP2CON1, A
   ; SDO2 output; SCK2 output
   bcf	TRISD, PORTD_SDO2_POSN, A	; SDO2 output
   bcf	TRISD, PORTD_SCK2_POSN, A	; SCK2 output
   return

SPI_MasterTransmit:  ; Start transmission of data (held in W)
   movwf 	SSP2BUF, A 	; write data to output buffer
   
Wait_Transmit:	; Wait for transmission to complete 
    btfss 	SSP2IF		; check interrupt flag to see if data has been sent
    bra 	Wait_Transmit
    bcf 	SSP2IF		; clear interrupt flag
    return	

delay:
	decfsz 0x20, F, A
	bra delay2
	return

delay2:
	movlw 0xFF
	movwf 0x30, A
	decfsz 0x30, F, A
	goto $-1
	bra delay
	
	
	end	main