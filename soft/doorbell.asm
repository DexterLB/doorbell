;.FILE           "doorbell.asm"
                  LIST    p=16F84 ; PIC16F844 is the target processor

                  #include "p16f84.inc" ; Include header file

				__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_OFF & _XT_OSC

In              equ     PORTA
Out             equ     PORTB
LedTris         equ     TRISA
LedTrisNorm     equ     0xFF
LedTrisPlaying  equ     b'00000010'
LedOut          equ     PORTA
Led             equ     3
LedSpecial      equ     2

; set the number of tunes here. Does not include the last "special" tune
; which is played when the special button (aka Mute) is pressed
NumTunes        equ     .8

; Button inputs mask (inverse: 0 -> button)
BtnMaskNorm     equ     b'11100001'
BtnMaskPlaying  equ     b'11111101'

                CBLOCK 0x10   ; Temporary storage
                    btnstate
                    countOut
                    countIn
                    flags
                    tune
                    note
                    spk
                    tempw
                    temp
                    tempstatus
                    tone
                    length
                    addrHi
                    addrLo
                    btnmask
                    tempPort
                ENDC
; flags:
btnNoise        equ     0
playing         equ     1
nohold          equ     2

                ORG   0
entrypoint      goto  init

                ORG   4
intvector       movwf   tempw               ; save register state
                swapf   STATUS,w
                movwf   tempstatus

                bcf     STATUS,RP0          ; bank 0

                ; actual stuff
                movf    tone,w              ; use tone to set time til next interrupt
                btfss   STATUS,Z
                goto    toggle
                clrf    Out                 ; if tone is 0x00 /pause/, clear the output
                goto    intdone

toggle          movwf   TMR0                ; tone is still in W
                movf    Out,w               ; otherwise
                xorwf   spk,w               ; toggle speaker outputs
                movwf   Out

intdone         swapf   tempstatus,w        ; restore register state
                movwf   STATUS
                swapf   tempw,f
                swapf   tempw,w
                bcf     INTCON,T0IF
                retfie
                ; w ~ 20


init            ; Register set up:
                clrf    PORTA             ; Ensure PORTB is zero before we enable it.
                clrf    PORTB             ; Ensure PORTB is zero before we enable it.
                bsf     STATUS,RP0        ; Select Bank 1
                clrf    TRISB             ; Port B is outputs

                ; Set up timer 0 for tone generation
                movlw   b'00000011'       ; Prescaler on, internal clocking, divide by 16
                movwf   OPTION_REG
                bcf     STATUS,RP0        ; Back to bank 0

                clrf    tone            ; so the interrupt doesn't do anything

 	            bcf     INTCON,T0IF     ; Clear Timer Interrupt
        	    bsf     INTCON,T0IE     ; Enable interrupts for Timer 0
	            bsf     INTCON,GIE

normstate       
                bsf     STATUS,RP0      ; bank 1
                movlw   LedTrisNorm
                movwf   LedTris
                bcf     STATUS,RP0      ; bank 0

                clrf    flags
                clrf    tone
                clrf    length
                clrf    temp
                
                movlw   BtnMaskNorm
                movwf   btnmask

                bsf     LedOut,Led      ; turn off LED (0-activated)

wait            btfss   flags,playing
                call    inctune         ; ensure random tune (only if not playing)

                bcf     flags,btnNoise
                clrf    countIn
                movlw   .50
                movwf   countOut
                ; w15

loop            decfsz  countIn,F       ; short internal loop
                goto    loop            ; 256*3 instructions
                movf    temp,W
                movwf   btnstate

                movf    In,W
                iorwf   btnmask,w       ; Button inputs mask (inverse: 0 -> button)
                xorlw   0xFF            ; Invert button state: 1 -> pressed button
                movwf   temp
                subwf   btnstate,W      ; check if current state equals saved state
                btfss   STATUS,Z
                bsf     flags,btnNoise  ; if not, assume noise

                decfsz  countOut        ; outer counter
                goto    loop            ; continue looping until we get enough cycles
                ; w 256*3 + 11

                ; if states are the same, and have been the same
                ; for enough time, we're ready to go

                btfsc   flags,btnNoise  ; if all we got was noise,
                goto    play            ; skip this shit
;                clrf    btnstate        ; assume no button was pressed

                movf    btnstate,W      ; check if a button has been pressed
                addlw   0
                btfss   STATUS,Z
                goto    bpress          ; we have a pressed button!
                bsf     flags,nohold    ; no button pressed, so no button is being held
                goto    play            ; nothing to do here
                ; w 9

bpress          btfss   flags,nohold
                goto    play            ; no actual press, the button is just being held. ignore.
                bcf     flags,nohold

                bsf     flags,playing   ; we have a pressed button! this time for real!
                movlw   BtnMaskPlaying
                movwf   btnmask

                clrf    note
                clrf    tone
                movlw   0x01            ; set length to 1, so that it becomes 0 at first decrement
                movwf   length
                

                ; set up speaker outputs
                clrf    spk
                
                btfss   btnstate, 1     ; Button4
                goto    $+5
                movlw   b'00001000'     ; monitor only
                movwf   spk
                movlw   NumTunes        ; last tune - chime
                movwf   tune

                btfss   btnstate, 2     ; button1
                goto    $+3
                movlw   b'10001000'     ; monitor, spk1 (PB7)
                movwf   spk

                btfss   btnstate, 3     ; button2
                goto    $+3
                movlw   b'01011000'     ; monitor, spk2 (PB6), spk3 (PB5)
                movwf   spk

                btfss   btnstate, 4     ; button3
                goto    $+3
                movlw   b'01011000'     ; monitor, spk2 (PB6), spk3 (PB5)
                movwf   spk

                ; light up!
                bsf     STATUS,RP0      ; bank 1
                movlw   LedTrisPlaying
                movwf   LedTris
                bcf     STATUS,RP0      ; bank 0

                movlw   0xFF
                andlw   (1 << Led) ^ 0xFF
                btfsc   btnstate,1      ; button 4 - special
                andlw   (1 << LedSpecial) ^ 0xFF
                movwf   LedOut

play            btfss   flags,playing
                goto    wait            ; we're not playing, so do nothing

                decfsz  length
                goto    nonewnote       ; nothing to do, just loopin'
                ; w 11

                ; need to get a new note
                call    getnote
                movwf   tone            ; get the tone
                incf    tone,w          ; test if tone is 0xFF /stop/
                btfsc   STATUS,Z        ; if it is 0xFF,
                goto    normstate       ; stop playing, return to init
                call    getnote
                movwf   length          ; get the note length


                goto    wait

                ; add little clicks between notes
nonewnote       movlw   2               ; 2-cycle long pause
                subwf   length,W        ; at the end of each note
                btfss   STATUS,C
                clrf    tone
                goto    wait


; cycles to the next tune (and resets counter if >NumTunes)
inctune         incf    tune,F
                movlw   NumTunes
                subwf   tune,w
                btfsc   STATUS,C
                clrf    tune
                return                 ; 9 instructions

; gets a note from the current tune and increments the note counter
getnote         clrf    PCLATH          ; bank 0
                movf    tune,w
                call    tuneTableHi
                movwf   addrHi
                movf    tune,w
                call    tuneTableLo
                addwf   note,w          ; add note number to tune start addr (sets C)
                movwf   addrLo
                btfsc   STATUS,C        ; if we have Carry, the low addr has overflown
                incf    addrHi,f        ; so we're in the next bank.
                
                incf    note,f          ; next note

                movf    addrHi,w
                movwf   PCLATH
                movf    addrLo,w
                movwf   PCL             ; jump!

tuneTableLo     addwf   PCL,F
;                dt      LOW     (_tune8)
                dt      LOW     (_tune0)
                dt      LOW     (_tune1)
                dt      LOW     (_tune2)
                dt      LOW     (_tune3)
                dt      LOW     (_tune4)
                dt      LOW     (_tune5)
                dt      LOW     (_tune6)
                dt      LOW     (_tune7)
                dt      LOW     (_tunez)

tuneTableHi     addwf   PCL,F
;                dt      HIGH    (_tune8)
                dt      HIGH    (_tune0)
                dt      HIGH    (_tune1)
                dt      HIGH    (_tune2)
                dt      HIGH    (_tune3)
                dt      HIGH    (_tune4)
                dt      HIGH    (_tune5)
                dt      HIGH    (_tune6)
                dt      HIGH    (_tune7)
                dt      HIGH    (_tunez)

; 
; _tune8
; ; start tune 'StarTrekTNG'
;                 retlw   0xab    ; f
;                 retlw   0x12    ; d
;                 retlw   0xc0    ; f
;                 retlw   0x05    ; d
;                 retlw   0xcd    ; f
;                 retlw   0x05    ; d
;                 retlw   0xc7    ; f
;                 retlw   0x12    ; d
;                 retlw   0xb8    ; f
;                 retlw   0x05    ; d
;                 retlw   0xd9    ; f
;                 retlw   0x05    ; d
;                 retlw   0xd5    ; f
;                 retlw   0x25    ; d
;                 retlw   0xb8    ; f
;                 retlw   0x05    ; d
;                 retlw   0xd0    ; f
;                 retlw   0x05    ; d
;                 retlw   0xd5    ; f
;                 retlw   0x05    ; d
;                 retlw   0xd9    ; f
;                 retlw   0x05    ; d
;                 retlw   0xd0    ; f
;                 retlw   0x05    ; d
;                 retlw   0xcd    ; f
;                 retlw   0x0c    ; d
;                 retlw   0xc7    ; f
;                 retlw   0x0c    ; d
;                 retlw   0xc0    ; f
;                 retlw   0x12    ; d
;                 retlw   0xcd    ; f
;                 retlw   0x05    ; d
;                 retlw   0xc0    ; f
;                 retlw   0x05    ; d
;                 retlw   0xc7    ; f
;                 retlw   0x49    ; d
;                 retlw   0x00    ; CD
;                 retlw   0xfe
;                 retlw   0xff    ; end
; ; end tune 'StarTrekTNG'
; 
_tune0:
                retlw   0xa6    ; f
                retlw   0x04    ; d
                retlw   0xa6    ; f
                retlw   0x04    ; d
                retlw   0xa6    ; f
                retlw   0x04    ; d
                retlw   0xbc    ; f
                retlw   0x1a    ; d
                retlw   0xd2    ; f
                retlw   0x1a    ; d
                retlw   0xcd    ; f
                retlw   0x04    ; d
                retlw   0xca    ; f
                retlw   0x04    ; d
                retlw   0xc3    ; f
                retlw   0x04    ; d
                retlw   0xdd    ; f
                retlw   0x1a    ; d
                retlw   0xd2    ; f
                retlw   0x0d    ; d
                retlw   0xcd    ; f
                retlw   0x04    ; d
                retlw   0xca    ; f
                retlw   0x04    ; d
                retlw   0xc3    ; f
                retlw   0x04    ; d
                retlw   0xdd    ; f
                retlw   0x1a    ; d
                retlw   0xd2    ; f
                retlw   0x0d    ; d
                retlw   0xcd    ; f
                retlw   0x04    ; d
                retlw   0xca    ; f
                retlw   0x04    ; d
                retlw   0xcd    ; f
                retlw   0x04    ; d
                retlw   0xc3    ; f
                retlw   0x11    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end

_tune1:
; start tune 'aadams'
                retlw   0x88    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x0a    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x0a    ; d
                retlw   0x88    ; f
                retlw   0x05    ; d
                retlw   0x80    ; f
                retlw   0x0a    ; d
                retlw   0xaf    ; f
                retlw   0x13    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x0a    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x0a    ; d
                retlw   0x41    ; f
                retlw   0x05    ; d
                retlw   0x71    ; f
                retlw   0x0a    ; d
                retlw   0xa6    ; f
                retlw   0x13    ; d
                retlw   0x88    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x0a    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x0a    ; d
                retlw   0x88    ; f
                retlw   0x05    ; d
                retlw   0x80    ; f
                retlw   0x0a    ; d
                retlw   0xaf    ; f
                retlw   0x13    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x0a    ; d
                retlw   0x88    ; f
                retlw   0x05    ; d
                retlw   0x95    ; f
                retlw   0x0a    ; d
                retlw   0xa0    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x26    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'aadams'

_tune2:
; start tune 'Bolero'
                retlw   0xc3    ; f
                retlw   0x13    ; d
                retlw   0xc3    ; f
                retlw   0x0a    ; d
                retlw   0xc0    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xc0    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x0a    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x13    ; d
                retlw   0xc3    ; f
                retlw   0x0a    ; d
                retlw   0xc0    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x26    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x05    ; d
                retlw   0x95    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x13    ; d
                retlw   0xaf    ; f
                retlw   0x13    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xc0    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x05    ; d
                retlw   0x95    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x05    ; d
                retlw   0x95    ; f
                retlw   0x05    ; d
                retlw   0x88    ; f
                retlw   0x0a    ; d
                retlw   0x88    ; f
                retlw   0x0a    ; d
                retlw   0x88    ; f
                retlw   0x05    ; d
                retlw   0x95    ; f
                retlw   0x05    ; d
                retlw   0xa0    ; f
                retlw   0x0a    ; d
                retlw   0xa6    ; f
                retlw   0x0a    ; d
                retlw   0x95    ; f
                retlw   0x13    ; d
                retlw   0xaf    ; f
                retlw   0x26    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'Bolero'

_tune3:
; start tune 'getred'
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x06    ; d
                retlw   0x88    ; f
                retlw   0x06    ; d
                retlw   0x88    ; f
                retlw   0x06    ; d
                retlw   0x95    ; f
                retlw   0x06    ; d
                retlw   0x95    ; f
                retlw   0x06    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x06    ; d
                retlw   0xbc    ; f
                retlw   0x06    ; d
                retlw   0xbc    ; f
                retlw   0x06    ; d
                retlw   0xc3    ; f
                retlw   0x06    ; d
                retlw   0xc3    ; f
                retlw   0x06    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x06    ; d
                retlw   0x88    ; f
                retlw   0x06    ; d
                retlw   0x88    ; f
                retlw   0x06    ; d
                retlw   0x95    ; f
                retlw   0x06    ; d
                retlw   0x95    ; f
                retlw   0x06    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x09    ; d
                retlw   0xaf    ; f
                retlw   0x06    ; d
                retlw   0xbc    ; f
                retlw   0x06    ; d
                retlw   0xbc    ; f
                retlw   0x06    ; d
                retlw   0xc3    ; f
                retlw   0x06    ; d
                retlw   0xca    ; f
                retlw   0x06    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'getred'

_tune4:
; start tune 'Looney'
                retlw   0xc3    ; f
                retlw   0x0b    ; d
                retlw   0xd2    ; f
                retlw   0x05    ; d
                retlw   0xd0    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x10    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xd2    ; f
                retlw   0x05    ; d
                retlw   0xd0    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xcd    ; f
                retlw   0x05    ; d
                retlw   0xd0    ; f
                retlw   0x10    ; d
                retlw   0xd0    ; f
                retlw   0x05    ; d
                retlw   0xd0    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xd0    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x05    ; d
                retlw   0xb8    ; f
                retlw   0x05    ; d
                retlw   0xa6    ; f
                retlw   0x05    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'Looney'

_tune5:
; start tune 'Money'
                retlw   0xd0    ; f
                retlw   0x07    ; d
                retlw   0xd0    ; f
                retlw   0x07    ; d
                retlw   0xd0    ; f
                retlw   0x07    ; d
                retlw   0xd0    ; f
                retlw   0x07    ; d
                retlw   0xd0    ; f
                retlw   0x07    ; d
                retlw   0xd0    ; f
                retlw   0x07    ; d
                retlw   0xa0    ; f
                retlw   0x03    ; d
                retlw   0xb8    ; f
                retlw   0x03    ; d
                retlw   0xc3    ; f
                retlw   0x03    ; d
                retlw   0xd0    ; f
                retlw   0x03    ; d
                retlw   0xcd    ; f
                retlw   0x07    ; d
                retlw   0xcd    ; f
                retlw   0x07    ; d
                retlw   0xcd    ; f
                retlw   0x07    ; d
                retlw   0xcd    ; f
                retlw   0x07    ; d
                retlw   0xcd    ; f
                retlw   0x07    ; d
                retlw   0xcd    ; f
                retlw   0x07    ; d
                retlw   0xa6    ; f
                retlw   0x03    ; d
                retlw   0xb8    ; f
                retlw   0x03    ; d
                retlw   0xc3    ; f
                retlw   0x03    ; d
                retlw   0xcd    ; f
                retlw   0x03    ; d
                retlw   0xca    ; f
                retlw   0x0e    ; d
                retlw   0xc3    ; f
                retlw   0x07    ; d
                retlw   0xb8    ; f
                retlw   0x07    ; d
                retlw   0xc3    ; f
                retlw   0x07    ; d
                retlw   0xc3    ; f
                retlw   0x0e    ; d
                retlw   0xb8    ; f
                retlw   0x1b    ; d
                retlw   0xb8    ; f
                retlw   0x02    ; d
                retlw   0xc3    ; f
                retlw   0x02    ; d
                retlw   0xd0    ; f
                retlw   0x02    ; d
                retlw   0xdb    ; f
                retlw   0x07    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'Money'

_tune6:
; start tune 'Popcorn'
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0x9b    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0x88    ; f
                retlw   0x0a    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0x9b    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0x88    ; f
                retlw   0x0a    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xcd    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x02    ; d
                retlw   0xcd    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x02    ; d
                retlw   0xcd    ; f
                retlw   0x05    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x02    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x02    ; d
                retlw   0xca    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x05    ; d
                retlw   0xaf    ; f
                retlw   0x05    ; d
                retlw   0xbc    ; f
                retlw   0x05    ; d
                retlw   0xc3    ; f
                retlw   0x0a    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'Popcorn'

_tune7:
; start tune 'Smoke'
                retlw   0x88    ; f
                retlw   0x0e    ; d
                retlw   0x9b    ; f
                retlw   0x0e    ; d
                retlw   0xa6    ; f
                retlw   0x15    ; d
                retlw   0x88    ; f
                retlw   0x0e    ; d
                retlw   0x9b    ; f
                retlw   0x0e    ; d
                retlw   0xab    ; f
                retlw   0x07    ; d
                retlw   0xa6    ; f
                retlw   0x0e    ; d
                retlw   0x00    ; f
                retlw   0x0e    ; d
                retlw   0x88    ; f
                retlw   0x0e    ; d
                retlw   0x9b    ; f
                retlw   0x0e    ; d
                retlw   0xa6    ; f
                retlw   0x15    ; d
                retlw   0x9b    ; f
                retlw   0x0e    ; d
                retlw   0x88    ; f
                retlw   0x0e    ; d
                retlw   0x00    ; CD
                retlw   0xfe
                retlw   0xff    ; end
; end tune 'Smoke'

_tunez:
                retlw   0x00
                retlw   .10
                retlw   0xbc
                retlw   .4
                retlw   0xa6
                retlw   .4
                retlw   0x00    ; big CD
                retlw   0xFE
                retlw   0x00    ; second part of big CD
                retlw   0xFE
                retlw   0xFF    ; stop


               END
