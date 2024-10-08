; AudioTest.asm
; Displays the value from the audio peripheral

ORG 0


Start:
	IN Switches
    JZERO SwUp
    JUMP Start

SwUp:
	;configure time + volume to hard coded value
    LOAD TMin
    OR  SIGN
    OUT Sound
    LOAD VMin
    OUT Sound
	LOADI 0
	STORE SignalCount
	STORE StateMem
	STORE tFilter
	STORE Tme

	IN Switches
    JPOS PulledUp
    JUMP SwUp
    
PulledUp:
	;write 0 to the device
    LOADI 0
    OUT Sound
    
Loop:
	; Get data from the audio peripheral
	IN     Sound
	JNEG Tstart
	STORE 	tFilter	; store the time until the next snap found
	Jump 	Continue ; no sound detected, continue on the loop
	
Tstart: 
	LOAD tFilter		; load the latest positive number
	CALL Define

Continue:
    CALL   Abs
    OUT    LEDs

    
    LOADI 1
    CALL Wait
    
	; Do it again
    IN Switches
    JPOS Loop
    JZERO Start
    
AEnd:   
	JUMP AEnd	; infinity loop of the whole program
	
; Subroutine to get the absolute value.
; Additional subroutine for negation is made available,
; since that's required for absolute value anyway.
Abs:
	JNEG   Negate
    RETURN ; positive or zero; just return
Negate:
	STORE  NegTemp
    SUB    NegTemp
    SUB    NegTemp
	RETURN
NegTemp: DW 0





Define:
    STORE   Tme         
    SUB     TEnd        ; Detect if it is end of letter or not (5s).
    JPOS    End      ; If end of string, Loop back to this whole subroutines to get new input from Alan.
    LOAD	SignalCount	; check if all four signals detected
	ADDI	-4
	JPOS	End
	
Detect:   
	LOAD    Tme         ; Detect dash or dot.
    SUB     Tdash
    JPOS    DetectDsh




DetectDot:              ; Your code if you detect dot is here.
    LOAD    StateMem 
    ADD     Adot
	SHIFT	1
    STORE   StateMem    ; store the StateMem, it should be shift left once and then add 1 or 0 by now
    JUMP    SeeA

DetectDsh:              ; Your code if you detect dash is here.
    LOAD    StateMem 
    ADD     ADash
	SHIFT	1
    STORE   StateMem    ; store the StateMem, it should be shift left once and then add 1 or 0 by now

SeeA:                   ; check if the conditions are met to display A
    LOAD StateMem
    SUB CheckA
    JZERO A
SeeB:                   ; check if the conditions are met to display A
    LOAD StateMem
    SUB CheckB
    JZERO B
SeeC:                   ; check if the conditions are met to display A
    LOAD StateMem
    SUB CheckC
    JZERO C
SeeD:                   ; check if the conditions are met to display A
    LOAD StateMem
    SUB CheckD
    JZERO D
SeeE:                   ; check if the conditions are met to display A
    LOAD StateMem
    SUB CheckE
    JZERO E
SeeF:                   ; check if the conditions are met to display A
    LOAD StateMem
    SUB CheckF
    JZERO F
	
PlayNum:                ;This occurs only when none of letters (A-F for now) is met.
    LOADI	-1
    JUMP Play       ; Just show the time. Change the out put as you wish

A:
	LOADI 10
	JUMP Play
B:
	LOADI 11
	JUMP Play
C:
	LOADI 12
	JUMP Play
D:
	LOADI 13
	JUMP Play
E:
	LOADI 14
	JUMP Play
F:
	LOADI 15
	JUMP Play
	
	
Play:                  ; display letter
    STORE TempOut
	LOAD SignalCount	; one signal found, add one and store it 
	ADDI 1
	STORE SignalCount
    LOAD Tme
    RETURN
	


End:                    ; everytime the SCOMP uses the HEX output, it MUST use this subroutine.
    
	LOAD   TempOut     ; Load the temperate outputs
    OUT    Hex0        ; This should be the only output statement to display letter on Hex. 
    LOADI 0            
    STORE   StateMem    ; initialize the StateMem to 1
	storE SignalCount	; reset signal count
	LOAD Tme
    RETURN


; To make things happen on a human timescale, the timer is
; used to delay for half a second.
Wait:
    STORE WaitInterval
	OUT    Timer
WaitingLoop:
	IN     Timer
	SUB WaitInterval
	JNEG   WaitingLoop
	RETURN
WaitInterval: DW &H000

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
Sound:     EQU &H50

; Config constants
SIGN: DW &H8000
TMin: DW &H0003
VMin: DW &H0200
Tme:        DW 20        ; Temp storage for sound.
;TempOut:    DW 40        ;  Temp storage for output.
TempOut:    DW -1   ; Initial out to 0
TEnd:       DW 30   ; Make this equal to 5 seconds for end of string. Or whatever second we want to determine end of string.em
Tdash:      DW 15   ; Make this equal to whatever time you want the dash to be detected.
;StateMem:   DW 60       ; Reserve Memory for state machine mimic Memory.
StateMem:   DW 0   ; Reserve Memory for state machine mimic Memory.
ADash:      DW 5   ; Everytime a dash found, increase StateMem by 100
Adot:       DW 3   ; Everytime a dot found, increase StateMem by 1
CheckA:     DW 22   ; Set the Output A Check
CheckB:     DW 122   ; Set the Output B Check
CheckC:     DW 134   ; Set the Output C Check
CheckD:     DW 58  ; Set the Output D Check
CheckE:     DW 6  ; Set the Output E Check
CheckF:     DW 90   ; Set the Output F Check
SignalCount:	DW 0	; Set the signal counter to 0
tFilter: DW 0
; READ ME
; READ ME 
; Here is the logic of Subroutine "Define"
; the subroutine will accept the sound output and determine if it is a dot or dash or the end of a letter.
; then it will modify the "state memory" accordingly. the "state memory" is actually a pointer.
; Each unique state memory points to the unique letter output.
; the letter output is stored in "temp output". Only when the machine is sure that one letter is ended,
; it will output the letter.
; * special cases: the state memory should be intialized if the letter is end.
; Which means, "state memory" re-initials when: 1, "null signal" detected 2, already 4 signals detected. 
; The current bug is that "State memory" can not be pushed if the first input is a "dot". 
; The program is running in a huge infinity loop between "call define" and "play E"