	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISB, A	    ; Port C all outputs
	bra 	test
loop:
	movff 	0x06, PORTB
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0x63
	cpfsgt 	0x06, A
		call delay
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start

delay:
    movlw 0x00

Dloop:
    decf 0x11, f, A
    subwfb 0x10, f, A
    bc dloop
    return
   
	
	end	main
