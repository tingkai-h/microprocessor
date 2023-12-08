#include <xc.inc>

global timer_setup, overflow, pwm_width

psect	udata_acs   ; reserve data space in access ram
overflow_counter: ds    1	    ; reserve 1 byte for variable KeyPad_counter
pwm_width:	  ds	1	    ; reserve 1 byte for pwm width
    
psect	pwm_code,class=CODE

;pwm_setup:
    
  
;    clrf PORTC
    
;    movlw 0xFF ;pwm period calculation needed see equation 19.1
;    movwf PR2
    
;    clrf CCPTMRS1 ;timer 2 for ccp4
    
;    movlw 0x0A ;write 8 most significant bits of 10 bit duty cycle here
;    movwf CCPR4L
    
;    movlw 0x3C ;loads the 2 least significant bits of 10 bit duty cycle
;    movwf CCP4CON ; writing to CCP4CON<5:4>
    
;    bcf TRISG, 3 ; clears tristate port g register and sets pin 3 as output
    
    ;movlw 0x04 ;prescale value
    ;movwf T2CON
    
;    bsf T2CON, 2
    
;    return
    
timer_setup:
	movlw 10
	movwf pwm_width, A
	
	movlw 0x0

	bcf TRISG, 0 ; RG0 used as Servo signal pin output
	
	movlw 0xC3 ; 11000011, 8-bit timer, 16 prescale value
	;movlw 0xC4 ; 11000100, 8-bit timer, 32 prescale value
	;movlw 11000101B ; 11000101, 8-bit timer, 64 prescale value
	;movlw 11000111B ; 11000101, 8-bit timer, 256 prescale value
	movwf T0CON ;control register for timer0

	movlw 0xFB ;251 for TMR0 register so timer overflows every 1us
	movwf TMR0L ;low byte
	
	
	;Enable Global Interrupt, peripheral interrupt and TMR0 overflow interrupt
	movlw 0xE0 ;11100000
	 
	movwf INTCON ;interrupt control register
	
	;making counter to count no. of - delete later
	movlw 0x00
	movwf overflow_counter, A ;file register address of counter

	goto inter1

inter1: 
	;bsf INTCON, 2
	btfss  INTCON, 2 ;skip next line if bit 2 is set, i.e. an overflow
	return ; If bit 2 is 0
	goto overflow	;if bit2 is 1, i.e. if TMR0IF flag bit is 1
	
overflow:
    
	movlw 156 ;156 for TMR0 register since there will be one additional instruction cycle during reinitializing
	movwf TMR0L ;low byte
	;has this cleared the prescaler as we wrote to TMR0

	bcf INTCON, 2 ;clear TMR0IF flag bit (bit 2 in INTCON)
	incf overflow_counter, A
	
	
	movf pwm_width, W, A ;moving on-time (duty cycle) value 150 to wreg
	cpfsgt overflow_counter, A ;compare on-time w count and skip next line if count is lower
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

	;
	




