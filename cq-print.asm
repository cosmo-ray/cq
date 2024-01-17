
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

PaddleSp:
	;;update paddle sprites
	LDX #4 			; paddle 4 sp len
ShowPaddle:
	CLC
	DEX
	LDA paddleSpPos, x	; sprite pos
	ADC paddleFrstSp 	; sprite threshold for player 1/2
	TAY			; set y
	LDA paddletop
	CLC
	ADC incry, x
	STA $200, y
	LDA pc_sprite_pos, x
	STA $0201, y
	LDA pc_sprite_attribute, x
	STA $0202, y
	LDA paddlex
	ADC incrx, x
	STA $0203, y
	CPX #0
	BNE ShowPaddle
	RTS

UpdateSprites:

	LDA pcy
	STA paddletop
	LDA pcx
	STA paddlex
	LDA #0
	STA paddleFrstSp
	JSR PaddleSp  ;;set ball/paddle sprites from positions
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
	LDA #$00
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
	LDA #$40
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
	LDA #$00
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
	LDA #$40
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

DrawBGTitle:
	LDA #$21
	STA $2006             ; write the high byte of $2000 address
	LDA #$43
	STA $2006             ; write the low byte
BGTitleLoop:
	LDA gamestate
	CMP #STATETITLE
	BEQ BGTitleLoadAscii   ;;game is displaying title s
	LDA #0
BGTitlePrint:
	STA $2007
	INX
	CPX #14
	BNE BGTitleLoop

	JMP	DrawBGDone
BGTitleLoadAscii:
	LDA title, x
	JMP BGTitlePrint

DrawBGDone:
	;;draw score on screen using background tiles
	;;or using many sprites
  RTS
