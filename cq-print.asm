
swordGoDown:
	LDA #$2c
	STA swordDown
	LDA #$1c
	STA swordDown2
	LDA #$80
	STA swordFlip
	RTS

swordGoUp:
	LDA #0
	STA swordDown
	STA swordDown2
	STA swordFlip
	RTS

tryShowEnemy:
	LDA cur_enemy_dead
	CMP #0
	BNE tryShowEnemyDead
	LDA cur_enemy_y
	STA paddletop
	LDA cur_enemy_x
	STA paddlex
	LDA #$20 * 4
	CLC
	ADC sprite_round
	STA paddleFrstSp
	LDA #LOW(en_sprite_pos)
	STA sprite_pos
	LDA #HIGH(en_sprite_pos)
	STA sprite_pos_hi
	JSR PaddleSp  ;;set ball/paddle sprites from po
	CLC
	JMP tryShowEnemyOut

tryShowEnemyDead:
	LDA #$20 * 4
	CLC
	ADC sprite_round
	TAX
	LDA #$f1
	STA $200, x
	STA $210, x
	STA $220, x
	STA $230, x

tryShowEnemyOut:
	LDA sprite_round
	ADC #$10
	STA sprite_round
	RTS

PaddleSp:
	;;update paddle sprites
	LDY #4			; paddle 4 sp len
ShowPaddle:
	CLC
	DEY
	LDA paddleSpPos, y	; sprite pos
	ADC paddleFrstSp 	; sprite threshold for player 1/2
	TAX			; set y
	LDA paddletop
	CLC
	ADC incry, y
	STA $200, x
	LDA sprite_pos
	LDA sprite_pos_hi
	LDA [sprite_pos],y
	STA $0201, x
	LDA pc_sprite_attribute, y
	STA $0202, x
	LDA paddlex
	ADC incrx, y
	STA $0203, x
	CPY #0
	BNE ShowPaddle
	RTS

UpdateSprites:
	LDA pcy
	STA paddletop
	LDA pcx
	STA paddlex
	LDA #0
	STA paddleFrstSp
	LDA #LOW(pc_sprite_pos)
	STA sprite_pos
	LDA #HIGH(pc_sprite_pos)
	STA sprite_pos_hi
	JSR PaddleSp  ;;set ball/paddle sprites from positions
	LDA #0
	STA sprite_round

	LDA enemy0_dead
	STA cur_enemy_dead
	LDA enemy0_x
	STA cur_enemy_x
	LDA enemy0_y
	STA cur_enemy_y
	JSR tryShowEnemy

	LDA enemy1_dead
	STA cur_enemy_dead
	LDA enemy1_x
	STA cur_enemy_x
	LDA enemy1_y
	STA cur_enemy_y
	JSR tryShowEnemy

showSwordUpDown:
	;; sword is aboce pc, carry setLDA pcy
	LDX #SWORD_FRST_SP
	LDA pcy
	SEC
	SBC #16
	CLC
	ADC swordDown
	STA $200, x
	LDA #$65
	STA $0201, x
	LDA #$02
	ADC swordFlip
	STA $0202, x
	LDA pcx
	STA $0203, x

	TXA
	CLC
	ADC #4 			; 2nd part
	TAX
	LDA pcy
	SEC
	SBC #16
	CLC
	ADC swordDown
	STA $200, x
	LDA #$65
	STA $0201, x
	LDA #$42
	ADC swordFlip
	STA $0202, x
	LDA pcx
	CLC
	ADC #8
	STA $0203, x

	CLC
	TXA
	ADC #4 			; 3rd part
	TAX
	LDA pcy
	SEC
	SBC #8
	CLC
	ADC swordDown2
	STA $200, x
	LDA #$75
	STA $0201, x
	LDA #$02
	ADC swordFlip
	STA $0202, x
	LDA pcx
	STA $0203, x

	TXA
	CLC
	ADC #4			; last part
	TAX
	LDA pcy
	SEC
	SBC #8
	CLC
	ADC swordDown2
	STA $200, x
	LDA #$75
	STA $0201, x
	LDA #$42
	ADC swordFlip
	STA $0202, x
	LDA pcx
	CLC
	ADC #8
	STA $0203, x

	RTS 			; < UpdateSprites


DrawBG:
	LDA $2002             ; read PPU status to reset the high/low latch

	LDA gamestate
	CMP #STATETITLE
	BEQ DrawBGTitle    ;;game is displaying title screen
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
	AND #%00001111
	CLC
	ADC #$30
	STA $2007             ; write to PPU

	LDA #$20

	STA $2006             ; write the high byte of $2000 address
	LDA #$54
	STA $2006             ; write the low byte of $
	LDA #$53	      ; 'S'
	STA $2007
	LDA #$63	      ; 'c'
	STA $2007
	LDA #$6f	      ; 'o'
	STA $2007
	LDA #$72		; 'r'
	STA $2007
	LDA #$65		; 'e'
	STA $2007
	LDA #$00		; SPACEEEE
	STA $2007

	LDA score
	LSR A
	LSR A
	LSR A
	LSR A
	CLC
	ADC #$30
	STA $2007             ; write to PPU

	LDA score
	AND #%00001111
	ADC #$30
	STA $2007             ; write to PPU

DrawBGTitle:
	LDA #$21
	STA $2006             ; write the high byte of $2000 address
	LDA #$43
	STA $2006             ; write the low byte
BGTitleLoop:
	LDA gamestate
	CMP #STATETITLE
	BEQ BGTitleLoadAscii   ;;game is displaying title s
	LDA gamestate
	CMP #STATEGAMEOVER
	BEQ BGLoseLoadAscii   ;;game is displaying title s
	LDA #0
BGTitlePrint:
	STA $2007
	INX
	CPX #14
	BNE BGTitleLoop

	JMP	DrawBGDone

BGLoseLoadAscii:
	LDA you_lose, x
	JMP BGTitlePrint

BGTitleLoadAscii:
	LDA title, x
	JMP BGTitlePrint

DrawBGDone:
	;;draw score on screen using background tiles
	;;or using many sprites
  RTS
