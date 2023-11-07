	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISC, A	    ; Port C all outputs
	bra 	test
loop:
	movff 	0x06, PORTC
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0x63
	cpfsgt 	0x06, A
	
	
	movlw 0x10
	movwf 0x20, A
	call	delay
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start

delay:
	decfsz 0x20, F, A
	call delay2 
	goto $-1
	return
	
delay2:
	movlw 0x10
	movwf 0x30, A
	decfsz 0x30, F, A
	goto $-1
	return    
	
	end	main
