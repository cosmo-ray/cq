
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
