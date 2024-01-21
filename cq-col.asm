
SwordColKill:
	;; move enemy out of screem
	LDA #$f1
	STA [cur_enemy_x], y
	;; set y so it get enemy0_dead
	LDY #2
	LDA #0
	STA [cur_enemy_x], y
	LDA score
	CLC
	ADC #1
	STA score
	RTS

EnemyCol:
	LDY #0
	LDA pcx
	CLC
	ADC #8
	SEC
	CMP [cur_enemy_x], y
	BCC SwordCol
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCS SwordCol
	;; set y so it get enemy0_y
	LDY #1
	LDA pcy
	CMP [cur_enemy_x], y
	BCC SwordCol
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCS SwordCol
	;; deal dmg and kill enemy
	LDA life
	SEC
	SBC #1
	STA life
	JSR SwordColKill
SwordCol:
SwordUpColision:
	LDY #0
	LDA swordDown
	CMP #0
	BNE SwordDownColision
	;; pcx > enemy_x and pcx < enemy_x + 16
	LDA pcx
	CLC
	ADC #8
	SEC
	CMP [cur_enemy_x], y
	BCC SwordDownColision
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCS SwordDownColision
	;; set y so it get enemy0_y
	LDY #1
	LDA pcy
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCC SwordDownColision
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCS SwordDownColision
	JSR SwordColKill

SwordDownColision:
	LDY #0
	LDA swordDown
	CMP #0
	BEQ SwordColOut
	;; pcx > enemy_x and pcx < enemy_x + 16
	LDA pcx
	CLC
	ADC #8
	SEC
	CMP [cur_enemy_x], y
	BCC SwordColOut
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCS SwordColOut
	;; set y so it get enemy0_y
	LDY #1
	LDA pcy
	CLC
	ADC #32
	CMP [cur_enemy_x], y
	BCC SwordColOut
	SEC
	SBC #16
	CMP [cur_enemy_x], y
	BCS SwordColOut

	JSR SwordColKill

SwordColOut:
	RTS
