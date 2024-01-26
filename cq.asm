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

sprite_pos	.rs 1
sprite_pos_hi	.rs 1

sprite_round .rs 1

SWORD_FRST_SP = $10
paddlebot   .rs 1
pcx         .rs 1  ; horizontal position for PC
life     .rs 1  ; player 1 score, 0-15
score	.rs 1

swordDown .rs 1
swordDown2 .rs 1
swordFlip .rs 1

buttons1   .rs 1  ; player 1 gamepad buttons, one bit per button
buttons2   .rs 1  ; player 2 gamepad buttons, one bit per button

beginBigWallPrint	.rs 1

;;; enemies
enemy0_dead .rs 1
enemy0_patern .rs 1
enemy0_x .rs 1
enemy0_y .rs 1
enemy1_dead .rs 1
enemy1_patern .rs 1
enemy1_x .rs 1
enemy1_y .rs 1
enemy2_dead .rs 1
enemy2_patern .rs 1
enemy2_x .rs 1
enemy2_y .rs 1

move_mask_1 .rs 1
move_mask_1_cnt .rs 1

tmp .rs 1

cur_enemy_x .rs 1
cur_enemy_y .rs 1
cur_enemy_dead .rs 1

seed .rs 1
seed_hi .rs 1
move_mask .rs 1
add_x .rs 1
add_y .rs 1

;; DECLARE SOME CONSTANTS HERE
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move paddles/ball, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen

RIGHTWALL      = $F4  ; when ball reaches one of these, do something
TOPWALL        = $60
BOTTOMWALL     = $80
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

	CPY #4
	BNE CheckBgUpWall
	CPX #BOTTOMWALL
	BNE BgBlank

	LDA #BOTTOMWALL
	JMP BgWallLoopIn

CheckBgUpWall:
	CPY #0
	BNE BgBlank
	CPX #TOPWALL
	BNE BgBlank
	LDA #TOPWALL
BgWallLoopIn:
	CLC
	ADC #$20
	STA beginBigWallPrint
BgWallLoop:
	LDA #$7E
	STA $2007             ; write to PPU
	INX
	CPX beginBigWallPrint
	BNE BgWallLoop

BgBlank:
	TXA
	AND #$1f
	BNE BgIsRightWall
	LDA #$7E
	JMP BgPushTile

BgIsRightWall:
	TXA
	CMP #$1f
	BEQ BgRightWallLoad
	CMP #$3f
	BEQ BgRightWallLoad
	CMP #$5f
	BEQ BgRightWallLoad
	CMP #$7f
	BEQ BgRightWallLoad
	CMP #$9f
	BEQ BgRightWallLoad
	CMP #$bf
	BEQ BgRightWallLoad
	JMP BgEmpty
BgRightWallLoad:
	LDA #$7E
	JMP BgPushTile

BgEmpty:
	LDA #$0     ; load data from address (background + the value in x)

BgPushTile:
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

	JSR initGame


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

  JSR DrawBG

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
  

  RTI             ; return from interrupt
 
 
 
 
;;;;;;;;
 
EngineTitle:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load game screen
  ;;  set starting paddle/ball position
  ;;  go to Playing State
	;;  turn screen on
  	CLC
	LDA buttons1
	AND #%00100000
	BEQ GameEngineDone
	LDA #STATEPLAYING
	STA gamestate
	JSR initGame

  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  	CLC
	LDA buttons1
	AND #%00010000
	BEQ GameEngineDone
	LDA #STATETITLE
	STA gamestate
  JMP GameEngineDone
 
;;;;;;;;;;;
 
EnginePlaying:

	LDA life
	CMP #0
	BNE NotDead
	LDA #STATEGAMEOVER
	STA gamestate
	JMP GameEngineDone

NotDead:

	LDA #LOW(enemy0_patern)
	STA cur_enemy_x
	LDA #HIGH(enemy0_patern)
	STA cur_enemy_y
	LDY #0
	LDX #0

MoveMonsterLoop:

	LDA [cur_enemy_x], y
	INY			; enemyX_patern -> enemyX_x
	JSR LoadMoveMask
MonsterDoMv:
	LDA move_mask
	AND #$05
	STA add_x
	LDA move_mask
	LSR A
	LSR A
	AND #$05
	STA add_y

	LDA move_mask
	AND #%00010000
	BEQ MonsetLeft
	LDA [cur_enemy_x], y
	CLC
	ADC add_x
	STA [cur_enemy_x], y
	JMP MonsterIsUP
MonsetLeft:
	LDA [cur_enemy_x], y
	SEC
	SBC add_x
	STA [cur_enemy_x], y

MonsterIsUP:
	CLC
	INY			; enemyX_y
	LDA move_mask
	AND #%00100000
	BEQ MonsetDown
	LDA [cur_enemy_x], y
	ADC add_y
	STA [cur_enemy_x], y
	JMP MonsterCheckLoop
MonsetDown:
	LDA [cur_enemy_x], y
	SEC
	SBC add_y
	STA [cur_enemy_x], y

MonsterCheckLoop:
	CLC
	INY 			; enemyX_dead
	INY			; enemyX_patern
	INX
	CPX #3
	BNE MoveMonsterLoop

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
	CMP #$20
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
	CMP #$06
	BCS MovePcLeftDone
	LDA pcx
	CLC
	ADC #2
	STA pcx
MovePcLeftDone:

	CLC
	LDA buttons1
	AND #%00000001
	BEQ MovePcRightDone

	LDA pcx
	ADC #2
	STA pcx
	CMP #$Ea
	BCC MovePcRightDone
	LDA pcx
	CLC
	SBC #1
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
	ADC #PADDLELEN_PIX
	CMP #$E8
	BCC MovePCDownDone
	LDA pcy
	CLC
	SBC #1
	STA pcy
  ;;if down button pressed
  ;;  if paddle bottom < bottom wall
  ;;    move paddle top and bottom down
MovePCDownDone:

	LDA #LOW(enemy0_x)
	STA cur_enemy_x
	LDA #HIGH(enemy0_x)
	STA cur_enemy_y
	JSR EnemyCol

	LDA #LOW(enemy1_x)
	STA cur_enemy_x
	LDA #HIGH(enemy1_x)
	STA cur_enemy_y
	JSR EnemyCol

	LDA #LOW(enemy2_x)
	STA cur_enemy_x
	LDA #HIGH(enemy2_x)
	STA cur_enemy_y
	JSR EnemyCol

	JSR UpdateSprites  ; print sprite

  JMP GameEngineDone

	.INCLUDE "cq-col.asm"

LoadMoveMask:
	CMP #0
	BEQ rnd_patern
	LDA move_mask_1
	STA move_mask
	LDA move_mask_1_cnt
	SEC
	SBC #1
	STA move_mask_1_cnt
	CMP #0
	BNE LoadMoveMaskOut
	STY tmp
	JSR prng
	LDY tmp
	LDA seed
	STA move_mask_1
	STA move_mask
	LDA #20
	STA move_mask_1_cnt

	RTS

rnd_patern:
	STY tmp
	JSR prng
	LDY tmp

	LDA seed
	STA move_mask
LoadMoveMaskOut:
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

initGame:

	;; init seed
	LDA #24
	ADC buttons1
	STA seed
	;; initialize PC
	LDA #$03
	STA life
	LDA #$45
	STA pcy
	LDA #$45
	STA pcx

	LDA #1
	STA move_mask_1_cnt
	LDA #0

	;b; init score
	STA score
	;; init enemies
	STA enemy0_dead
	STA enemy1_dead
	STA enemy2_dead
	STA enemy0_patern
	STA enemy1_patern

	LDA #1
	STA enemy2_patern

	LDA #50
	STA enemy0_x
	STA enemy0_y

	LDA #$B0
	STA enemy1_x
	STA enemy1_y

	LDA #$A0
	STA enemy2_x
	STA enemy2_y

	;; init sword
	JSR swordGoDown
	RTS

	.INCLUDE "misc.asm"
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

en_sprite_pos:
	.db $22, $22, $32, $32

pc_sprite_pos:
	.db $95, $95, $A5, $A5

pc_sprite_attribute:
	.db $00, $40, $00, $40

sword_sprite_pos:
	.db $65, $65, $75, $75

title:
	.db "CLEM QUEST !!!"

you_lose:
	.db "You Lose !!!"

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
