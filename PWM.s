#include <xc.inc>

global timer_setup, overflow;,pwm_setup


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
	banksel TRISG     ; Select the register bank containing TRISG
	bcf TRISG, 3 ; RG3 used as Servo signal pin output
	
	;movlw 0xC3 ; 11000011, 8-bit timer, 16 prescale value
	;movlw 0xC4 ; 11000100, 8-bit timer, 32 prescale value
	;movlw 0xC5 ; 11000101, 8-bit timer, 64 prescale value
	movlw 11000111B ; 11000101, 8-bit timer, 256 prescale value
	movwf T0CON ;control register for timer0

	movlw 0xFB ;251 for TMR0 register so timer overflows every 1us
	movwf TMR0L ;low byte
	
	
	;Enable Global Interrupt, peripheral interrupt and TMR0 overflow interrupt
	movlw 0xE0 ;11100000
	 
	movwf INTCON ;interrupt control register
	
	;making counter to count no. of - delete later
	movlw 0x00
	movwf 0x10 ;file register address of counter

	goto inter1

inter1: 
	;bsf INTCON, 2
	btfss  INTCON, 2 ;skip next line if bit 2 is set, i.e. an overflow
	return ; If bit 2 is 0
	goto overflow	;if bit2 is 1, i.e. if TMR0IF flag bit is 1
	
overflow:
    
	movlw 0xFC ;252 for TMR0 register since there will be one additional instruction cycle during reinitializing
	movwf TMR0L ;low byte
	;has this cleared the prescaler as we wrote to TMR0

	bcf INTCON, 2 ;clear TMR0IF flag bit (bit 2 in INTCON)
	incf 0x10, 1
	
	movlw 0xA0 ;moving on-time (duty cycle) value 150 to wreg
	cpfslt 0x10 ;compare on-time w count and skip next line if count is lower
	call turn_pin_on
	movlw 0xC8 ;moving (on_time+(200-on_time)) which is 200 to wreg 
	cpfslt 0x10
	call turn_pin_off
	
	return

turn_pin_on:
	bsf LATG, 3 ;set RG3 pin
	return

turn_pin_off:
	bcf LATG, 3 ;clear RG3 pin 
	clrf 0x10 ;reset file register address of counter
	return

	




