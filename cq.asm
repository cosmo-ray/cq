  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

;; DECLARE SOME VARIABLES HERE
  .rsset $0000  ;;start variables at ram location 0
  
gamestate  .rs 1  ; .rs 1 means reserve one byte of space

pcy   .rs 1  ; player 1 paddle top vertical position
paddletop   .rs 1  ; player 2 paddle bottom vertical position
paddlex	    .rs 1
paddleFrstSp .rs 1
SWORD_FRST_SP = $10
paddlebot   .rs 1
pcx         .rs 1  ; horizontal position for PC
life     .rs 1  ; player 1 score, 0-15

swordDown .rs 1
swordDown2 .rs 1
swordFlip .rs 1

buttons1   .rs 1  ; player 1 gamepad buttons, one bit per button
buttons2   .rs 1  ; player 2 gamepad buttons, one bit per button


;; DECLARE SOME CONSTANTS HERE
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move paddles/ball, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen
  
RIGHTWALL      = $F4  ; when ball reaches one of these, do something
TOPWALL        = $20
BOTTOMWALL     = $E0
LEFTWALL       = $04
  

PADDLELEN	= $4
PADDLELEN_PIX	= 3 * 8
;;;;;;;;;;;;;;;;;;



  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down


LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
	LDX #$00              ; start out at 0
	LDY #0
LoadBackgroundLoop:
	LDA #$0     ; load data from address (background + the value in x)
	STA $2007             ; write to PPU
	INX                   ; X = X + 1
	CPX #$c0              ; Compare X to hex $80, decimal 128 - copying 128 bytes
	BNE NoIncrY  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
	INY
	LDX #0
NoIncrY:
	CPY #5
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down


;;;Set some initial ball stats
	LDA #$03
	STA life

	;; initialize PC
	LDA #$45
	STA pcy
	LDA #$45
	STA pcx

	;; init sword
	JSR swordGoDown


;;:Set starting game state
  LDA #STATETITLE
  STA gamestate


              
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop, waiting for NMI
  
 

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  JSR DrawPlayerInfo

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
    
  ;;;all graphics updates done by here, run game engine


  JSR ReadController1  ;;get the current button data for player 1
  JSR ReadController2  ;;get the current button data for player 2
  
GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BEQ EngineTitle    ;;game is displaying title screen

  LDA gamestate
  CMP #STATEGAMEOVER
  BEQ EngineGameOver  ;;game is displaying ending screen
  
  LDA gamestate
  CMP #STATEPLAYING
  BEQ EnginePlaying   ;;game is playing
GameEngineDone:  
  
	JSR UpdateSprites  ;;set ball/paddle sprites from positions

  RTI             ; return from interrupt
 
 
 
 
;;;;;;;;
 
EngineTitle:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load game screen
  ;;  set starting paddle/ball position
  ;;  go to Playing State
  ;;  turn screen on
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  JMP GameEngineDone
 
;;;;;;;;;;;
 
EnginePlaying:


MovePCUp:
	CLC
	LDA buttons1
	AND #%00001000
	BEQ MovePCUpDone

	JSR swordGoUp

	LDA pcy
	CLC
	SBC #1
	STA pcy
	LDA pcy
	CMP #TOPWALL
	BCS MovePCUpDone
	LDA pcy
	CLC
	ADC #2
	STA pcy
  ;;if up button pressed
  ;;  if paddle top > top wall
  ;;    move paddle top and bottom up
MovePCUpDone:

	CLC
	LDA buttons1
	AND #%00000010
	BEQ MovePcLeftDone

	LDA pcx
	SBC #1
	STA pcx
MovePcLeftDone:

	CLC
	LDA buttons1
	AND #%00000001
	BEQ MovePcRightDone

	LDA pcx
	ADC #2
	STA pcx
MovePcRightDone:

MovePCDown:
	CLC
	LDA buttons1
	AND #%00000100
	BEQ MovePCDownDone

	JSR swordGoDown

	LDA pcy
	ADC #2
	STA pcy
	LDA pcy
	ADC #PADDLELEN_PIX
	CMP #BOTTOMWALL
	BCC MovePCDownDone
	LDA pcy
	CLC
	SBC #1
	STA pcy
  ;;if down button pressed
  ;;  if paddle bottom < bottom wall
  ;;    move paddle top and bottom down
MovePCDownDone:


  JMP GameEngineDone


DrawPlayerInfo:

	LDA $2002             ; read PPU status to reset the high/low latch
	LDA #$20
	STA $2006             ; write the high byte of $2000 address
	LDA #$43
	STA $2006             ; write the low byte of $2000 address
	LDX #$00              ; start out at 0

	LDA #$4C
	STA $2007
	LDA #$69
	STA $2007
	LDA #$66
	STA $2007
	LDA #$65
	STA $2007
	LDA #$00
	STA $2007
	LDA life
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$30
	STA $2007             ; write to PPU

	LDA life
	AND #%00001111
	ADC #$30
	STA $2007             ; write to PPU

	;;draw score on screen using background tiles
	;;or using many sprites
  RTS
  
ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  RTS
  
ReadController2:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController2Loop:
  LDA $4017
  LSR A            ; bit0 -> Carry
  ROL buttons2     ; bit0 <- Carry
  DEX
  BNE ReadController2Loop
  RTS  
  
  
    
	.INCLUDE "cq-print.asm"

;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
  .db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette


attribute:
	.db %00000000, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000
	.db %00000000, %00010000


sprites:
     ;vert tile attr horiz
  .db $80, $32, $00, $80   ;sprite 0
  .db $80, $33, $00, $88   ;sprite 1
  .db $88, $34, $00, $80   ;sprite 2
  .db $88, $35, $00, $88   ;sprite 3

paddleSpPos:
	.db $00, $04, $08, $0c

incrx:
	.db 0, 8, 0, 8
incry:
	.db 0,0,8,8

pc_sprite_pos:
	.db $95, $95, $A5, $A5

pc_sprite_attribute:
	.db $00, $40, $00, $40

sword_sprite_pos:
	.db $65, $65, $75, $75


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "guntner.chr"   ;includes 8KB graphics file from SMB1