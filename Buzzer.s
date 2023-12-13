#include <xc.inc>

global pwm_buzzer_setup

psect	buzzer_code,class=CODE

pwm_buzzer_setup:
  
    clrf PORTC
    
    movlw 0xFF ; from pwm period calculation, datasheet equation 19.1
    movwf PR2
    
    clrf CCPTMRS1 ;timer 2 for ccp4
    
    movlw 10000000B ;write 8 most significant bits of 10 bit duty cycle here
    movwf CCPR4L
    
    movlw 00001100B ;loads the 2 least significant bits of 10 bit duty cycle
    movwf CCP4CON ; writing to CCP4CON<5:4>

    bcf TRISG, 3 ; clears tristate port g register and sets pin 3 as output
    
    bsf T2CON, 2
    bsf T2CON, 1 ;setting Timer2 Clock Prescale 16
    
    return