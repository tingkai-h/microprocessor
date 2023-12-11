#include <xc.inc>

global timer_setup, overflow, pwm_width

psect	udata_acs   ; reserve data space in access ram
overflow_counter: ds    1	    ; reserve 1 byte for variable KeyPad_counter
pwm_width:	  ds	1	    ; reserve 1 byte for pwm width
    
psect	pwm_code,class=CODE
    
timer_setup:
	movlw 10
	movwf pwm_width, A
	
	movlw 0x0

	bcf TRISG, 0 ; RG0 used as Servo signal pin output
	
	movlw 0xC3 ; 11000011, 8-bit timer, 16 prescale value
	movwf T0CON ;control register for timer0

	movlw 0xFB ;251 for TMR0 register so timer overflows every 1us
	movwf TMR0L ;low byte
	
	
	
	movlw 0xE0 ;Enable Global Interrupt, peripheral interrupt and TMR0 overflow interrupt
	movwf INTCON ;interrupt control register
	
	movlw 0x00
	movwf overflow_counter, A 

	goto inter1

inter1: 
	btfss  INTCON, 2 ;skip next line if bit 2 is set, i.e. an overflow
	return ; If bit 2 is 0
	goto overflow	;if bit2 is 1, i.e. if TMR0IF flag bit is 1
	
overflow:
    
	movlw 156 ;156 for TMR0 register since there will be one additional instruction cycle during reinitializing
	movwf TMR0L ;low byte
	

	bcf INTCON, 2 ;clear TMR0IF flag bit (bit 2 in INTCON)
	incf overflow_counter, A
	
	
	movf pwm_width, W, A ;moving on-time (duty cycle) value 150 to wreg
	cpfsgt overflow_counter, A
	bra turn_pin_on
	call turn_pin_off
	
	movlw 200 ;moving (on_time+(200-on_time)) which is 200 to wreg 
	cpfslt overflow_counter, A
	clrf overflow_counter, A ;reset file register address of counter
	return

turn_pin_on:
	bsf LATG, 0 ;set RG0 pin
	return

turn_pin_off:
	bcf LATG, 0 ;clear RG0 pin 
	return

	
	




