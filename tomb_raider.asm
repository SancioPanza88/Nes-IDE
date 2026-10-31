; =====================================================================
;  TOMB RAIDER - THE PROPHECY  (demake NES, visuale isometrica)
;  Per NES IDE: APRI questo file e premi RUN.
;  Comandi: frecce = muovi (8 direzioni)   X = salta   Z = spara
;           spingi i blocchi camminandoci contro   Invio = Start
;  Obiettivo: chiave -> porta -> blocco sulla piastra -> trova l’Ankh
; =====================================================================
; ---- costanti generate dal costruttore grafico ----
DIG0=2
HFULL=5
HEMPTY=6
TL_SHADOW=96
TL_BULLET=98

.mirror v
PPUCTRL=$2000
PPUMASK=$2001
PPUSTATUS=$2002
OAMADDR=$2003
PPUSCROLL=$2005
PPUADDR=$2006
PPUDATA=$2007
OAMDMA=$4014
JOY=$4016
OAM=$0200
ubuf=$0300
cmap=$0400

; ---- variabili in zero page ----
nmif=$00
frm=$01
pad=$02
padn=$03
gst=$04       ; 0 titolo, 1 gioco, 2 morte, 3 vittoria, 4 schermata finale
rm=$05
t0=$06
t1=$07
t2=$08
t3=$09
t4=$0A
t5=$0B
t6=$0C
t7=$0D
ptr=$0E
ptr2=$10
lpi=$12       ; posizione Lara in mappa (1/16 di cella)
lpj=$13
lpz=$14       ; altezza (salto)
lfc=$15       ; direzione 0-7
lan=$16
lhp=$17
lky=$18
ljt=$19       ; timer salto
linv=$1A
lscd=$1B
pshc=$1C
flg=$1D
ulen=$1E
mst=$1F
oamn=$20
spx=$21
spy=$22
spa=$23
hudd=$24
bhid=$25
mvd=$26
lwk=$27
dtm=$28
rst0=$29      ; stato stanze (3 byte)
u0=$2C
u1=$2D
u2=$2E
u3=$2F
u4=$30
u5=$31
u6=$32
u7=$33
etp=$34       ; nemici (3): tipo
eei=$37
eej=$3A
eeh=$3D
eet=$40
bli=$43       ; proiettili (2)
blj=$45
bld=$47
bll=$49
iti=$4B       ; oggetti (3)
iii=$4E
iij=$51
itf=$54
smode=$57
u8=$58
u9=$59

.org $8000
reset:
  sei
  cld
  ldx #$FF
  txs
  inx
  stx PPUCTRL
  stx PPUMASK
rs1: bit PPUSTATUS
  bpl rs1
rs2: bit PPUSTATUS
  bpl rs2
  lda #0
  tax
rs3: sta $00,x
  sta $0300,x
  sta $0400,x
  inx
  bne rs3
  jsr clear_oam
  jsr show_title
mainloop:
  jsr wait_nmi
  inc frm
  jsr read_pad
  jsr dispatch
  jmp mainloop

nmi:
  pha
  txa
  pha
  tya
  pha
  lda #0
  sta OAMADDR
  lda #>OAM
  sta OAMDMA
  jsr drain_ubuf
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #%10001000
  sta PPUCTRL
  lda #1
  sta nmif
  pla
  tay
  pla
  tax
  pla
  rti

wait_nmi:
  lda #0
  sta nmif
wn1: lda nmif
  beq wn1
  rts

read_pad:
  lda pad
  sta t0
  lda #1
  sta JOY
  lda #0
  sta JOY
  ldx #8
rp1: lda JOY
  lsr a
  rol pad
  dex
  bne rp1
  lda t0
  eor #$FF
  and pad
  sta padn
  rts

clear_oam:
  lda #$FF
  ldx #0
co1: sta OAM,x
  inx
  bne co1
  rts

; ---------------- scrittura PPU ----------------
drain_ubuf:
  lda ulen
  beq du_e
  bit PPUSTATUS
  ldx #0
du_r: lda ubuf,x
  sta PPUADDR
  inx
  lda ubuf,x
  sta PPUADDR
  inx
  ldy ubuf,x
  inx
du_b: lda ubuf,x
  sta PPUDATA
  inx
  dey
  bne du_b
  cpx ulen
  bcc du_r
  lda #0
  sta ulen
du_e: rts

queue_list:          ; ptr -> lista di record [hi,lo,n,dati] terminata da 0
  ldy #0
ql_r: lda (ptr),y
  beq ql_e
  ldx ulen
  sta ubuf,x
  inx
  iny
  lda (ptr),y
  sta ubuf,x
  inx
  iny
  lda (ptr),y
  sta ubuf,x
  inx
  iny
  sta t0
ql_b: lda (ptr),y
  sta ubuf,x
  inx
  iny
  dec t0
  bne ql_b
  stx ulen
  jmp ql_r
ql_e: rts

queue_trans:         ; applica la patch di transizione dello stato corrente della stanza
  ldx rm
  lda rst0,x
  clc
  adc pbase,x
  tax
  lda ptrans_lo,x
  sta ptr
  lda ptrans_hi,x
  sta ptr+1
  jmp queue_list

scr_off:
  lda #0
  sta PPUCTRL
  sta PPUMASK
  sta ulen
  bit PPUSTATUS
  rts

scr_on:
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #%10001000
  sta PPUCTRL
  lda #%00011110
  sta PPUMASK
  rts

load_pals:           ; ptr2 = 16 byte palette sfondo (gli sprite prima, cosi' $3F00 resta quello di sfondo)
  lda #$3F
  sta PPUADDR
  lda #$10
  sta PPUADDR
  ldx #0
lp1: lda sprpal,x
  sta PPUDATA
  inx
  cpx #16
  bne lp1
  lda #$3F
  sta PPUADDR
  lda #0
  sta PPUADDR
  ldy #0
lp2: lda (ptr2),y
  sta PPUDATA
  iny
  cpy #16
  bne lp2
  rts

rle_get:
  ldy #0
  lda (ptr),y
  inc ptr
  bne rg1
  inc ptr+1
rg1: cmp #0
  rts

load_nt:             ; ptr = dati RLE della nametable 0
  lda #$20
  sta PPUADDR
  lda #0
  sta PPUADDR
rl_n: jsr rle_get
  beq rl_e
  bmi rl_run
  tax
rl_l: jsr rle_get
  sta PPUDATA
  dex
  bne rl_l
  jmp rl_n
rl_run:
  and #$7F
  tax
  inx
  jsr rle_get
rl_r: sta PPUDATA
  dex
  bne rl_r
  jmp rl_n
rl_e: rts

show_screen:         ; A = 0 titolo, 1 game over, 2 vittoria
  tax
  lda scr_nt_lo,x
  sta ptr
  lda scr_nt_hi,x
  sta ptr+1
  lda scr_pal_lo,x
  sta ptr2
  lda scr_pal_hi,x
  sta ptr2+1
  jsr scr_off
  jsr load_pals
  jsr load_nt
  jsr clear_oam
  jmp scr_on

show_title:
  lda #0
  jsr show_screen
  lda #0
  sta gst
  rts

; ---------------- stati ----------------
dispatch:
  lda gst
  cmp #1
  beq dsp_play
  cmp #0
  beq dsp_title
  cmp #2
  beq dsp_dying
  cmp #3
  beq dsp_win
  lda padn
  and #$10
  beq dsp_e
  jmp show_title
dsp_e: rts
dsp_title:
  lda padn
  and #$10
  beq dsp_e
  jmp new_game
dsp_play: jmp play_frame
dsp_dying:
  dec dtm
  bne dsp_e
  lda #1
  jsr show_screen
  lda #4
  sta gst
  rts
dsp_win:
  dec dtm
  bne dsp_e
  lda #2
  jsr show_screen
  lda #4
  sta gst
  rts

new_game:
  lda #6
  sta lhp
  lda #0
  sta lky
  sta flg
  sta rst0
  sta rst0+1
  sta rst0+2
  sta rm
  sta linv
  sta lscd
  sta pshc
  sta mst
  sta lan
  lda #1
  sta gst
  lda #0
  jmp load_room

; ---------------- stanze ----------------
load_room:           ; A = modo di arrivo: 0 inizio, 1 porta d'ingresso, 2 porta d'uscita
  sta smode
  ldx rm
  lda rt_nt_lo,x
  sta ptr
  lda rt_nt_hi,x
  sta ptr+1
  lda rt_pal_lo,x
  sta ptr2
  lda rt_pal_hi,x
  sta ptr2+1
  jsr scr_off
  jsr load_pals
  jsr load_nt
  ldx rm
  lda rt_map_lo,x
  sta ptr
  lda rt_map_hi,x
  sta ptr+1
  ldy #63
lr_m: lda (ptr),y
  sta cmap,y
  dey
  bpl lr_m
  ldx rm
  lda rst0,x
  beq lr_np
  clc
  adc pbase,x
  tax
  lda pfull_lo,x
  sta ptr
  lda pfull_hi,x
  sta ptr+1
  jsr queue_list
  jsr drain_ubuf
lr_np:
  lda rm
  cmp #1
  bne lr_nb
  lda #0
  sta cmap+43
  lda rst0+1
  clc
  adc #43
  tax
  lda #5
  sta cmap,x
lr_nb:
  lda smode
  jsr set_spawn
  lda #0
  sta lan
  sta lwk
  sta bll
  sta bll+1
  ldx #2
lr_c: sta etp,x
  sta iti,x
  dex
  bpl lr_c
  ldx rm
  lda rt_en_lo,x
  sta ptr
  lda rt_en_hi,x
  sta ptr+1
  ldy #0
  lda (ptr),y
  sta t0
  iny
  ldx #0
lr_e: lda t0
  beq lr_ed
  lda (ptr),y
  sta etp,x
  iny
  lda (ptr),y
  sta eei,x
  iny
  lda (ptr),y
  sta eej,x
  iny
  stx t1
  lda etp,x
  tax
  lda ehp0,x
  ldx t1
  sta eeh,x
  lda #0
  sta eet,x
  inx
  dec t0
  jmp lr_e
lr_ed:
  ldx rm
  lda rt_it_lo,x
  sta ptr
  lda rt_it_hi,x
  sta ptr+1
  ldy #0
  lda (ptr),y
  sta t0
  iny
  ldx #0
lr_i: lda t0
  beq lr_id
  lda (ptr),y
  sta t2
  iny
  lda (ptr),y
  sta t3
  iny
  lda (ptr),y
  sta t4
  iny
  lda (ptr),y
  sta t5
  iny
  and flg
  bne lr_is
  lda t2
  sta iti,x
  lda t3
  sta iii,x
  lda t4
  sta iij,x
  lda t5
  sta itf,x
  inx
lr_is: dec t0
  jmp lr_i
lr_id:
  lda #1
  sta hudd
  lda #0
  sta mst
  jsr scr_on
  lda smode
  bne lr_x
  lda rm
  bne lr_x
  lda #8
  jsr show_msg
lr_x: rts

set_spawn:           ; A = modo
  sta t0
  lda rm
  asl a
  clc
  adc rm
  clc
  adc t0
  tax
  lda sp_i,x
  sta lpi
  lda sp_j,x
  sta lpj
  lda sp_f,x
  sta lfc
  lda #0
  sta ljt
  sta lpz
  rts

respawn:
  lda #1
  ldx rm
  bne rsp1
  lda #0
rsp1: jmp set_spawn

; ---------------- mappa e collisioni ----------------
getcell:             ; t0=pi, t1=pj -> A = tipo cella ($FF fuori)
  lda t0
  bmi gc_o
  lda t1
  bmi gc_o
  lsr a
  lsr a
  lsr a
  lsr a
  asl a
  asl a
  asl a
  sta t2
  lda t0
  lsr a
  lsr a
  lsr a
  lsr a
  ora t2
  tax
  lda cmap,x
  rts
gc_o: lda #$FF
  rts

blk4:                ; t4,t5 = posizione piedi. C=1 se bloccato (celle dispari = solide)
  ldy #3
b4l: lda t4
  clc
  adc b4dx,y
  sta t0
  lda t5
  clc
  adc b4dy,y
  sta t1
  jsr getcell
  and #1
  bne b4h
  dey
  bpl b4l
  clc
  rts
b4h: sec
  rts

blkw:                ; come blk4 ma anche le fosse bloccano (lupi)
  jsr blk4
  bcs bw_r
  lda t4
  sta t0
  lda t5
  sta t1
  jsr getcell
  cmp #2
  beq bw_b
  clc
  rts
bw_b: sec
bw_r: rts

absd:                ; A = |A - t0|
  sec
  sbc t0
  bcs ad_o
  eor #$FF
  clc
  adc #1
ad_o: rts

move_lara:           ; muove di (t6,t7) con scivolamento sui muri
  lda t6
  beq ml_j
  clc
  adc lpi
  sta t4
  lda lpj
  sta t5
  jsr blk4
  bcs ml_j
  lda t4
  sta lpi
  inc mvd
ml_j: lda t7
  beq ml_e
  clc
  adc lpj
  sta t5
  lda lpi
  sta t4
  jsr blk4
  bcs ml_e
  lda t5
  sta lpj
  inc mvd
ml_e: rts

hurt:                ; A = danno
  sta t0
  lda lhp
  sec
  sbc t0
  bcs hu_o
  lda #0
hu_o: sta lhp
  lda #1
  sta hudd
  lda lhp
  bne hu_e
  lda #2
  sta gst
  lda #80
  sta dtm
hu_e: rts

; ---------------- Lara ----------------
lara_update:
  lda linv
  beq lu1
  dec linv
lu1: lda lscd
  beq lu2
  dec lscd
lu2: lda ljt
  bne lu_air
  lda padn
  and #$80
  beq lu_walk
  lda #24
  sta ljt
  lda #0
  sta lwk
  jmp lu_air
lu_walk:
  jsr lara_walk
  jsr lara_pit_check
  jmp lu_sh
lu_air: jsr lara_jump
lu_sh: lda padn
  and #$40
  beq lu_d
  lda lscd
  bne lu_d
  jsr fire
lu_d: jmp lara_doors

lara_walk:
  lda #0
  sta mvd
  sta lwk
  lda pad
  and #$0F
  tax
  lda dirtab,x
  bmi lw_e
  sta lfc
  lda #1
  sta lwk
  inc lan
  lda lfc
  and #1
  bne lw_dg
  lda frm
  and #1
  bne lw_e
  jmp lw_go
lw_dg: lda frm
  and #3
  cmp #3
  beq lw_e
lw_go: ldx lfc
  lda dI,x
  sta t6
  lda dJ,x
  sta t7
  jsr move_lara
lw_e: jmp push_check

lara_jump:
  dec ljt
  ldx ljt
  lda jztab,x
  sta lpz
  ldx lfc
  lda dI,x
  sta t6
  lda dJ,x
  sta t7
  jsr move_lara
  jsr move_lara
  lda ljt
  bne lj_e
  jsr lara_pit_check
lj_e: rts

lara_pit_check:
  lda lpi
  sta t0
  lda lpj
  sta t1
  jsr getcell
  cmp #2
  bne lpc_e
  lda #2
  jsr hurt
  lda #5
  jsr show_msg
  jsr respawn
lpc_e: rts

push_check:
  lda lfc
  cmp #1
  bne pc_no
  lda mvd
  bne pc_no
  lda lwk
  beq pc_no
  lda lpi
  clc
  adc #6
  sta t0
  lda lpj
  sta t1
  jsr getcell
  cmp #5
  bne pc_no
  inc pshc
  lda pshc
  cmp #28
  bcc pc_r
  lda #0
  sta pshc
  jmp do_push
pc_no: lda #0
  sta pshc
pc_r: rts

do_push:
  lda rm
  cmp #1
  bne dp_x
  lda rst0+1
  cmp #3
  bcs dp_x
  lda lpj
  lsr a
  lsr a
  lsr a
  lsr a
  asl a
  asl a
  asl a
  sta t2
  lda lpi
  clc
  adc #6
  lsr a
  lsr a
  lsr a
  lsr a
  ora t2
  tax
  txa
  and #7
  cmp #7
  beq dp_x
  lda cmap+1,x
  beq dp_ok
  cmp #4
  bne dp_x
dp_ok: lda #0
  sta cmap,x
  lda #5
  sta cmap+1,x
  inc rst0+1
  jsr queue_trans
  lda rst0+1
  cmp #3
  bne dp_x
  lda #7
  jmp show_msg
dp_x: rts

fire:
  ldx #1
fi_l: lda bll,x
  beq fi_f
  dex
  bpl fi_l
  rts
fi_f: lda lpi
  sta bli,x
  lda lpj
  sta blj,x
  lda lfc
  sta bld,x
  lda #36
  sta bll,x
  lda #14
  sta lscd
  rts

lara_doors:
  ldx rm
  lda lpj
  cmp #7
  bcs ld_en
  lda lpi
  lsr a
  lsr a
  lsr a
  lsr a
  cmp xdi,x
  bne ld_en
  lda rst0,x
  cmp ropen,x
  bcs ld_nx
  cpx #0
  bne ld_lm
  lda lky
  beq ld_lm
  dec lky
  lda #1
  sta rst0
  jsr queue_trans
  lda #1
  sta hudd
  lda #3
  jmp show_msg
ld_lm: lda mst
  bne ld_x
  lda lockmsg,x
  jmp show_msg
ld_nx: inc rm
  lda #1
  jmp load_room
ld_en: ldx rm
  beq ld_x
  lda lpi
  cmp #7
  bcs ld_x
  lda lpj
  lsr a
  lsr a
  lsr a
  lsr a
  cmp edj,x
  bne ld_x
  dec rm
  lda #2
  jmp load_room
ld_x: rts

; ---------------- proiettili ----------------
bullets_update:
  ldx #1
bu_l: lda bll,x
  beq bu_n
  sec
  sbc #1
  sta bll,x
  ldy bld,x
  lda dI3,y
  clc
  adc bli,x
  sta bli,x
  lda dJ3,y
  clc
  adc blj,x
  sta blj,x
  lda bli,x
  sta t0
  lda blj,x
  sta t1
  stx t3
  jsr getcell
  ldx t3
  and #1
  beq bu_ok
  lda #0
  sta bll,x
  jmp bu_n
bu_ok: jsr bullet_hit
bu_n: dex
  bpl bu_l
  rts

bullet_hit:          ; X = proiettile
  ldy #2
bh_l: lda etp,y
  beq bh_n
  lda eei,y
  sta t0
  lda bli,x
  jsr absd
  cmp #11
  bcs bh_n
  lda eej,y
  sta t0
  lda blj,x
  jsr absd
  cmp #11
  bcs bh_n
  lda #0
  sta bll,x
  lda #8
  sta eet,y
  lda eeh,y
  sec
  sbc #1
  sta eeh,y
  bne bh_e
  lda #0
  sta etp,y
bh_e: rts
bh_n: dey
  bpl bh_l
  rts

; ---------------- nemici ----------------
enemies_update:
  ldx #2
eu_l: lda etp,x
  bne eu_a
  jmp eu_n
eu_a: lda eet,x
  beq eu_b
  sec
  sbc #1
  sta eet,x
eu_b: lda frm
  and #3
  cmp #1
  bcs eu_mv
  jmp eu_c
eu_mv: lda etp,x
  cmp #2
  bne eu_ok
  lda frm
  and #3
  cmp #2
  bcs eu_ok
  jmp eu_c
eu_ok: lda eei,x
  sta t0
  lda lpi
  jsr absd
  cmp #72
  bcs eu_cc
  lda eej,x
  sta t0
  lda lpj
  jsr absd
  cmp #72
  bcc eu_o2
eu_cc: jmp eu_c
eu_o2: lda lpi
  cmp eei,x
  beq s1z
  bcs s1p
  lda #$FF
  jmp s1s
s1p: lda #1
  jmp s1s
s1z: lda #0
s1s: sta t6
  lda lpj
  cmp eej,x
  beq s2z
  bcs s2p
  lda #$FF
  jmp s2s
s2p: lda #1
  jmp s2s
s2z: lda #0
s2s: sta t7
  lda etp,x
  cmp #1
  bne eu_go
  lda frm
  lsr a
  lsr a
  lsr a
  lsr a
  stx t0
  clc
  adc t0
  and #3
  cmp #3
  bne eu_go
  lda t6
  eor #$FF
  clc
  adc #1
  sta t6
  lda t7
  eor #$FF
  clc
  adc #1
  sta t7
eu_go: lda etp,x
  cmp #2
  beq eu_wf
  lda eei,x
  clc
  adc t6
  cmp #124
  bcs eb_j
  sta eei,x
eb_j: lda eej,x
  clc
  adc t7
  cmp #124
  bcs eu_c
  sta eej,x
  jmp eu_c
eu_wf: lda t6
  beq ew_j
  clc
  adc eei,x
  sta t4
  lda eej,x
  sta t5
  stx t3
  jsr blkw
  ldx t3
  bcs ew_j
  lda t4
  sta eei,x
ew_j: lda t7
  beq eu_c
  clc
  adc eej,x
  sta t5
  lda eei,x
  sta t4
  stx t3
  jsr blkw
  ldx t3
  bcs eu_c
  lda t5
  sta eej,x
eu_c: lda linv
  bne eu_n
  lda eei,x
  sta t0
  lda lpi
  jsr absd
  cmp #8
  bcs eu_n
  lda eej,x
  sta t0
  lda lpj
  jsr absd
  cmp #8
  bcs eu_n
  lda #70
  sta linv
  stx t3
  lda #1
  jsr hurt
  ldx t3
eu_n: dex
  bmi eu_d
  jmp eu_l
eu_d: rts

; ---------------- oggetti ----------------
items_update:
  ldx #2
it_l: lda iti,x
  beq it_n
  lda iii,x
  sta t0
  lda lpi
  jsr absd
  cmp #14
  bcs it_n
  lda iij,x
  sta t0
  lda lpj
  jsr absd
  cmp #14
  bcs it_n
  lda iti,x
  cmp #2
  bne it_t
  lda lhp
  cmp #6
  beq it_n
it_t: stx t3
  jsr item_take
  ldx t3
it_n: dex
  bpl it_l
  rts

item_take:
  lda itf,x
  ora flg
  sta flg
  lda iti,x
  pha
  lda #0
  sta iti,x
  pla
  cmp #1
  beq itk_k
  cmp #2
  beq itk_m
  lda #3
  sta gst
  lda #70
  sta dtm
  rts
itk_k: inc lky
  lda #1
  sta hudd
  lda #1
  jmp show_msg
itk_m: lda lhp
  clc
  adc #3
  cmp #7
  bcc itk_o
  lda #6
itk_o: sta lhp
  lda #1
  sta hudd
  lda #4
  jmp show_msg

; ---------------- HUD e messaggi ----------------
hud_upd:
  ldx ulen
  lda #$20
  sta ubuf,x
  inx
  lda #$26
  sta ubuf,x
  inx
  lda #6
  sta ubuf,x
  inx
  ldy #0
hu_l: cpy lhp
  bcs hu_em
  lda #HFULL
  jmp hu_s
hu_em: lda #HEMPTY
hu_s: sta ubuf,x
  inx
  iny
  cpy #6
  bne hu_l
  lda #$20
  sta ubuf,x
  inx
  lda #$30
  sta ubuf,x
  inx
  lda #1
  sta ubuf,x
  inx
  lda lky
  clc
  adc #DIG0
  sta ubuf,x
  inx
  stx ulen
  rts

show_msg:            ; A = numero messaggio (0 = cancella)
  sta t0
  tax
  lda msg_lo,x
  sta ptr
  lda msg_hi,x
  sta ptr+1
  ldx ulen
  lda #$23
  sta ubuf,x
  inx
  lda #$80
  sta ubuf,x
  inx
  lda #32
  sta ubuf,x
  inx
  ldy #0
sm_l: lda (ptr),y
  sta ubuf,x
  inx
  iny
  cpy #32
  bne sm_l
  stx ulen
  lda t0
  beq sm_e
  lda #150
  sta mst
sm_e: rts

; ---------------- frame di gioco ----------------
play_frame:
  jsr lara_update
  lda gst
  cmp #1
  bne pf_x
  jsr bullets_update
  jsr enemies_update
  jsr items_update
  jsr build_oam
  lda hudd
  beq pf_m
  lda #0
  sta hudd
  jsr hud_upd
pf_m: lda mst
  beq pf_x
  dec mst
  bne pf_x
  lda #0
  jsr show_msg
pf_x: rts

; ---------------- disegno sprite ----------------
put_spr:             ; A = tile; spx,spy (angolo alto-sinistra), spa
  ldx oamn
  pha
  lda spy
  sec
  sbc #1
  sta OAM,x
  pla
  sta OAM+1,x
  lda spa
  sta OAM+2,x
  lda spx
  sta OAM+3,x
  inx
  inx
  inx
  inx
  stx oamn
  rts

drawblk:             ; blocco di sprite 2 colonne x u3 righe: x=u1 y=u2 base=u4 attr=u5 flip=u6 (0/1)
  ldy #0
db_r: tya
  asl a
  asl a
  asl a
  clc
  adc u2
  sta spy
  lda u5
  sta spa
  tya
  asl a
  asl a
  asl a
  asl a
  clc
  adc u4
  sta u7
  lda u1
  sta spx
  lda u7
  clc
  adc u6
  jsr put_spr
  lda u1
  clc
  adc #8
  sta spx
  lda u6
  eor #1
  clc
  adc u7
  jsr put_spr
  iny
  cpy u3
  bne db_r
  rts

behind_check:        ; bhid = $20 se c'e' un ostacolo alto davanti a Lara
  lda #0
  sta bhid
  ldy #5
bc_l: lda lpi
  clc
  adc bdI,y
  bcs bc_n
  sta t0
  lda lpj
  clc
  adc bdJ,y
  bcs bc_n
  sta t1
  jsr getcell
  and #3
  cmp #1
  bne bc_n
  lda #$20
  sta bhid
  rts
bc_n: dey
  bpl bc_l
  rts

build_oam:
  ldx #0
  lda #$FF
bo_h: sta OAM,x
  inx
  inx
  inx
  inx
  bne bo_h
  lda #0
  sta oamn
  jsr draw_lara
  jsr draw_bullets
  jsr draw_enemies
  jmp draw_items

draw_lara:
  lda linv
  beq dl_v
  lda frm
  and #2
  beq dl_v
  rts
dl_v: lda lpi
  sec
  sbc lpj
  clc
  adc #128
  sta u0
  lda lpi
  clc
  adc lpj
  lsr a
  clc
  adc #72
  sta u8
  jsr behind_check
  ldx lfc
  lda fart,x
  sta t3
  lda fflp,x
  sta u6
  lda fatt,x
  ora bhid
  sta u5
  lda ljt
  bne dl_f1
  lda lwk
  beq dl_f0
  lda lan
  lsr a
  lsr a
  lsr a
  and #1
  clc
  adc #1
  jmp dl_fk
dl_f1: lda #1
  jmp dl_fk
dl_f0: lda #0
dl_fk: sta t4
  lda t3
  asl a
  clc
  adc t3
  clc
  adc t4
  tax
  lda lbase,x
  sta u4
  lda u0
  sec
  sbc #8
  bcs dl_x
  lda #0
dl_x: cmp #241
  bcc dl_x2
  lda #240
dl_x2: sta u1
  lda u8
  sec
  sbc lpz
  sec
  sbc #24
  sta u2
  lda #3
  sta u3
  jsr drawblk
  lda u1
  sta spx
  lda u8
  sec
  sbc #4
  sta spy
  lda #1
  ora bhid
  sta spa
  lda #TL_SHADOW
  jsr put_spr
  lda u1
  clc
  adc #8
  sta spx
  lda #TL_SHADOW+1
  jmp put_spr

draw_bullets:
  ldx #1
dbu_l: lda bll,x
  beq dbu_n
  lda bli,x
  sec
  sbc blj,x
  clc
  adc #124
  sta spx
  lda bli,x
  clc
  adc blj,x
  lsr a
  clc
  adc #60
  sta spy
  lda #1
  sta spa
  stx u0
  lda #TL_BULLET
  jsr put_spr
  ldx u0
dbu_n: dex
  bpl dbu_l
  rts

draw_enemies:
  ldx #2
de_l: lda etp,x
  beq de_n
  stx u0
  lda eei,x
  sec
  sbc eej,x
  clc
  adc #128
  sta u9
  sec
  sbc #8
  bcs de_x
  lda #0
de_x: cmp #241
  bcc de_x2
  lda #240
de_x2: sta u1
  lda eei,x
  clc
  adc eej,x
  lsr a
  clc
  adc #56
  sta u2
  lda etp,x
  cmp #1
  bne de_w
  lda u2
  sec
  sbc #8
  sta u2
de_w: lda frm
  lsr a
  lsr a
  lsr a
  and #1
  sta t3
  lda etp,x
  asl a
  clc
  adc t3
  tay
  lda ebase,y
  sta u4
  lda #2
  ldy eet,x
  beq de_a
  lda #3
de_a: sta u5
  lda lpi
  sec
  sbc lpj
  clc
  adc #128
  cmp u9
  bcs de_nf
  lda u5
  ora #$40
  sta u5
  lda #1
  jmp de_f
de_nf: lda #0
de_f: sta u6
  lda #2
  sta u3
  jsr drawblk
  ldx u0
de_n: dex
  bpl de_l
  rts

draw_items:
  ldx #2
di_l: lda iti,x
  bne di_a
  jmp di_n
di_a: stx u0
  lda iii,x
  sec
  sbc iij,x
  clc
  adc #128
  sec
  sbc #8
  bcs di_x
  lda #0
di_x: sta u1
  lda frm
  lsr a
  lsr a
  lsr a
  and #3
  tay
  lda bobt,y
  sta t3
  lda iii,x
  clc
  adc iij,x
  lsr a
  clc
  adc #56
  sec
  sbc t3
  sta u2
  ldy iti,x
  cpy #3
  bne di_t
  lda u2
  sec
  sbc #10
  sta u2
di_t: lda itbase,y
  sta u4
  lda itatt,y
  sta u5
  lda #0
  sta u6
  lda #2
  sta u3
  jsr drawblk
  ldx u0
di_n: dex
  bmi di_e
  jmp di_l
di_e: rts


r0_pal:
  .byte $27,$0F,$17,$37,$27,$0F,$16,$30,$27,$0F,$27,$30,$27,$0F,$0F,$0F
r0_map:
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$02,$02
  .byte $02,$02,$02,$02,$02,$02,$02,$02,$00,$00,$00,$00,$00,$00,$01,$00
  .byte $00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
r0_en:
  .byte $02,$01,$28,$18,$01,$68,$28
r0_it:
  .byte $02,$01,$68,$18,$01,$02,$18,$28,$02
r0_nt:
  .byte $A0,$01,$05,$6C,$6D,$6E,$6F,$01,$85,$05,$05,$01,$01,$07,$70,$02
  .byte $8F,$01,$0F,$71,$6F,$72,$73,$6C,$6F,$01,$6F,$74,$71,$75,$76,$74
  .byte $77,$6F,$BD,$01,$04,$08,$09,$0A,$0B,$99,$01,$08,$08,$0C,$0D,$0E
  .byte $0F,$10,$11,$0B,$95,$01,$0C,$08,$0C,$0D,$12,$13,$14,$0F,$15,$16
  .byte $10,$11,$0B,$91,$01,$10,$08,$0C,$0D,$12,$13,$17,$18,$0E,$0F,$19
  .byte $0F,$15,$16,$10,$11,$0B,$8D,$01,$14,$08,$0C,$0D,$12,$13,$17,$18
  .byte $12,$13,$14,$0F,$15,$16,$19,$0F,$15,$1A,$10,$11,$0B,$89,$01,$18
  .byte $08,$0C,$0D,$12,$13,$17,$18,$12,$13,$17,$1B,$1C,$1D,$1E,$0F,$15
  .byte $16,$19,$1F,$20,$16,$10,$11,$0B,$85,$01,$0C,$08,$0C,$0D,$21,$13
  .byte $17,$18,$12,$13,$17,$1B,$1C,$83,$00,$1A,$1D,$1E,$0F,$15,$22,$23
  .byte $0F,$15,$16,$10,$11,$0B,$01,$01,$08,$0C,$0D,$12,$24,$25,$18,$12
  .byte $13,$17,$1B,$1C,$87,$00,$18,$1D,$1E,$26,$27,$16,$19,$0F,$15,$16
  .byte $10,$11,$0B,$28,$12,$13,$17,$29,$2A,$13,$17,$2B,$2C,$2D,$2E,$89
  .byte $00,$18,$2F,$30,$0F,$15,$16,$19,$0F,$15,$16,$31,$18,$17,$18,$12
  .byte $29,$2A,$2B,$2C,$32,$33,$34,$35,$2D,$2E,$89,$00,$18,$1D,$1E,$0F
  .byte $15,$16,$19,$0F,$36,$18,$12,$13,$17,$37,$38,$39,$3A,$3B,$3C,$3D
  .byte $3E,$3F,$40,$2D,$2E,$89,$00,$0A,$1D,$1E,$0F,$15,$16,$41,$18,$17
  .byte $1B,$1C,$83,$00,$0C,$42,$43,$44,$45,$01,$01,$3F,$40,$46,$47,$48
  .byte $49,$87,$00,$06,$1D,$1E,$0F,$36,$1B,$1C,$85,$00,$04,$4A,$4B,$4C
  .byte $4D,$83,$01,$04,$4E,$3C,$3D,$4F,$89,$00,$04,$1D,$50,$51,$52,$85
  .byte $00,$0E,$4A,$43,$44,$53,$54,$55,$01,$01,$56,$43,$44,$57,$2D,$2E
  .byte $87,$00,$06,$58,$59,$5A,$5B,$5C,$52,$83,$00,$10,$4A,$4B,$4C,$5D
  .byte $00,$00,$54,$55,$56,$4B,$4C,$5E,$3F,$40,$2D,$2E,$83,$00,$10,$58
  .byte $5F,$60,$61,$01,$01,$62,$5B,$5C,$52,$00,$00,$63,$64,$65,$66,$83
  .byte $00,$0E,$42,$43,$44,$45,$01,$01,$3F,$40,$2D,$2E,$58,$5F,$60,$67
  .byte $85,$01,$04,$62,$5B,$5C,$52,$87,$00,$04,$4A,$4B,$4C,$4D,$83,$01
  .byte $04,$68,$69,$60,$67,$89,$01,$04,$62,$5B,$5C,$52,$85,$00,$0A,$63
  .byte $64,$65,$66,$54,$55,$6A,$6B,$60,$67,$8D,$01,$04,$62,$5B,$5C,$52
  .byte $87,$00,$04,$58,$5F,$60,$67,$91,$01,$04,$62,$5B,$5C,$52,$83,$00
  .byte $04,$58,$5F,$60,$67,$95,$01,$08,$62,$5B,$5C,$52,$58,$5F,$60,$67
  .byte $99,$01,$04,$62,$5B,$60,$67,$FF,$01,$8D,$01,$87,$55,$AF,$00,$87
  .byte $05,$00
r1_pal:
  .byte $10,$0F,$00,$20,$10,$0F,$16,$30,$10,$0F,$27,$30,$10,$0F,$0F,$0F
r1_map:
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$00,$00,$04,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00
r1_en:
  .byte $02,$02,$68,$28,$01,$48,$68
r1_it:
  .byte $01,$02,$18,$68,$04
r1_nt:
  .byte $A0,$01,$05,$6C,$6D,$6E,$6F,$01,$85,$05,$05,$01,$01,$07,$70,$02
  .byte $8F,$01,$11,$71,$A7,$6F,$01,$A8,$6C,$A9,$77,$AA,$01,$77,$A7,$76
  .byte $72,$A8,$6F,$75,$BB,$01,$04,$08,$09,$0A,$0B,$99,$01,$08,$08,$0C
  .byte $0D,$0E,$0F,$10,$11,$0B,$95,$01,$0C,$08,$0C,$0D,$12,$13,$14,$0F
  .byte $15,$16,$10,$11,$0B,$91,$01,$10,$08,$0C,$0D,$21,$13,$17,$18,$0E
  .byte $0F,$19,$0F,$15,$16,$10,$11,$0B,$8D,$01,$14,$08,$0C,$0D,$12,$7E
  .byte $7F,$18,$12,$13,$14,$0F,$15,$16,$19,$0F,$15,$16,$10,$11,$0B,$89
  .byte $01,$18,$08,$0C,$0D,$12,$13,$17,$7A,$7B,$13,$17,$1B,$1C,$1D,$1E
  .byte $0F,$15,$16,$19,$0F,$15,$16,$10,$11,$0B,$85,$01,$0C,$08,$0C,$0D
  .byte $12,$13,$17,$18,$12,$7A,$7B,$1B,$1C,$83,$00,$1A,$1D,$1E,$0F,$15
  .byte $16,$19,$0F,$15,$1A,$10,$11,$0B,$01,$01,$08,$0C,$0D,$12,$13,$17
  .byte $18,$12,$13,$17,$80,$81,$87,$00,$16,$1D,$1E,$0F,$15,$16,$19,$82
  .byte $83,$16,$10,$11,$0B,$28,$12,$13,$17,$18,$12,$13,$17,$1B,$1C,$87
  .byte $00,$16,$84,$85,$48,$49,$1D,$1E,$0F,$15,$86,$87,$0F,$15,$16,$31
  .byte $18,$17,$18,$12,$13,$17,$1B,$1C,$89,$00,$14,$88,$3C,$3D,$89,$00
  .byte $00,$1D,$1E,$8A,$8B,$16,$19,$0F,$36,$18,$12,$13,$17,$1B,$1C,$8B
  .byte $00,$04,$4A,$43,$44,$53,$83,$00,$0A,$8C,$8D,$0F,$15,$16,$41,$18
  .byte $17,$1B,$1C,$85,$00,$04,$8E,$8F,$90,$91,$83,$00,$04,$4A,$4B,$4C
  .byte $5D,$85,$00,$06,$1D,$1E,$0F,$36,$1B,$1C,$87,$00,$04,$92,$93,$94
  .byte $95,$83,$00,$04,$4A,$43,$44,$53,$87,$00,$04,$1D,$50,$51,$52,$87
  .byte $00,$0C,$96,$97,$98,$99,$48,$49,$00,$00,$4A,$4B,$4C,$5D,$87,$00
  .byte $06,$58,$59,$5A,$5B,$5C,$52,$85,$00,$0C,$9A,$9B,$9C,$3C,$3D,$89
  .byte $00,$00,$63,$64,$65,$66,$85,$00,$0A,$58,$5F,$60,$61,$01,$01,$62
  .byte $5B,$5C,$52,$85,$00,$04,$4A,$43,$44,$53,$89,$00,$04,$58,$5F,$60
  .byte $67,$85,$01,$04,$62,$5B,$5C,$52,$83,$00,$08,$4A,$4B,$4C,$5D,$9D
  .byte $9E,$9F,$A0,$83,$00,$04,$58,$5F,$60,$67,$89,$01,$14,$62,$5B,$5C
  .byte $52,$00,$00,$4A,$43,$44,$53,$A1,$A2,$A3,$A4,$00,$00,$58,$5F,$60
  .byte $67,$8D,$01,$08,$62,$5B,$5C,$52,$4A,$4B,$4C,$5D,$83,$00,$04,$58
  .byte $5F,$60,$67,$91,$01,$0C,$62,$5B,$A5,$A6,$65,$66,$00,$00,$58,$5F
  .byte $60,$67,$95,$01,$08,$62,$5B,$5C,$52,$58,$5F,$60,$67,$99,$01,$04
  .byte $62,$5B,$60,$67,$FF,$01,$8D,$01,$87,$55,$AF,$00,$87,$05,$00
r2_pal:
  .byte $17,$0F,$06,$27,$17,$0F,$16,$30,$17,$0F,$27,$30,$17,$0F,$0F,$0F
r2_map:
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00
  .byte $00,$00,$02,$01,$00,$00,$01,$00,$00,$00,$02,$00,$00,$00,$00,$00
r2_en:
  .byte $03,$02,$68,$38,$02,$38,$58,$01,$48,$28
r2_it:
  .byte $01,$03,$58,$48,$08
r2_nt:
  .byte $A0,$01,$05,$6C,$6D,$6E,$6F,$01,$85,$05,$05,$01,$01,$07,$70,$02
  .byte $8F,$01,$09,$71,$A7,$6F,$01,$DB,$76,$DC,$6C,$71,$C3,$01,$04,$08
  .byte $09,$0A,$0B,$99,$01,$08,$08,$0C,$0D,$0E,$0F,$10,$11,$0B,$95,$01
  .byte $0C,$08,$0C,$0D,$12,$13,$14,$0F,$15,$16,$10,$11,$0B,$91,$01,$10
  .byte $08,$0C,$0D,$12,$13,$17,$18,$0E,$0F,$19,$0F,$15,$16,$10,$11,$0B
  .byte $8D,$01,$14,$08,$0C,$0D,$21,$13,$17,$18,$12,$13,$14,$0F,$15,$16
  .byte $19,$0F,$15,$16,$10,$11,$0B,$89,$01,$18,$08,$0C,$0D,$12,$7E,$7F
  .byte $18,$12,$13,$17,$1B,$1C,$1D,$1E,$0F,$15,$16,$19,$0F,$15,$16,$10
  .byte $11,$0B,$85,$01,$0C,$08,$0C,$0D,$12,$13,$17,$7A,$7B,$13,$17,$1B
  .byte $1C,$83,$00,$1A,$1D,$1E,$0F,$15,$16,$19,$0F,$15,$16,$10,$11,$0B
  .byte $01,$01,$08,$0C,$0D,$12,$13,$17,$18,$12,$7A,$7B,$1B,$1C,$87,$00
  .byte $16,$1D,$1E,$0F,$15,$16,$19,$0F,$15,$16,$10,$11,$0B,$28,$12,$13
  .byte $17,$18,$12,$13,$17,$80,$81,$8B,$00,$16,$1D,$1E,$0F,$15,$16,$19
  .byte $0F,$15,$16,$31,$18,$17,$18,$12,$13,$17,$1B,$1C,$84,$85,$48,$49
  .byte $8B,$00,$14,$1D,$1E,$0F,$15,$16,$19,$0F,$36,$18,$12,$13,$17,$1B
  .byte $1C,$00,$00,$88,$3C,$3D,$89,$8D,$00,$0A,$1D,$1E,$0F,$15,$16,$41
  .byte $18,$17,$1B,$1C,$83,$00,$04,$4A,$43,$44,$53,$8F,$00,$06,$1D,$1E
  .byte $0F,$36,$1B,$1C,$85,$00,$0A,$C6,$4B,$4C,$C7,$00,$00,$84,$85,$48
  .byte $49,$8B,$00,$04,$1D,$50,$51,$52,$83,$00,$0E,$C8,$C9,$CA,$43,$44
  .byte $CB,$00,$00,$88,$3C,$3D,$CC,$CD,$CE,$89,$00,$16,$58,$59,$5A,$5B
  .byte $5C,$52,$C8,$C9,$CF,$D0,$D1,$4B,$4C,$5D,$00,$00,$4A,$43,$44,$D2
  .byte $D3,$D4,$87,$00,$18,$58,$5F,$60,$61,$01,$01,$62,$5B,$D5,$D6,$D7
  .byte $D8,$63,$64,$65,$66,$00,$00,$4A,$4B,$4C,$D9,$DA,$A4,$85,$00,$04
  .byte $58,$5F,$60,$67,$85,$01,$04,$62,$5B,$5C,$52,$85,$00,$04,$4A,$43
  .byte $44,$53,$85,$00,$04,$58,$5F,$60,$67,$89,$01,$04,$62,$5B,$5C,$52
  .byte $83,$00,$04,$4A,$4B,$4C,$5D,$83,$00,$04,$58,$5F,$60,$67,$8D,$01
  .byte $10,$62,$5B,$5C,$52,$00,$00,$63,$64,$65,$66,$00,$00,$58,$5F,$60
  .byte $67,$91,$01,$04,$62,$5B,$5C,$52,$83,$00,$04,$58,$5F,$60,$67,$95
  .byte $01,$08,$62,$5B,$5C,$52,$58,$5F,$60,$67,$99,$01,$04,$62,$5B,$60
  .byte $67,$FF,$01,$8D,$01,$87,$55,$AF,$00,$87,$05,$00
scr_title_nt:
  .byte $A4,$01,$16,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$01,$01,$E8,$E9,$EA
  .byte $E5,$EB,$01,$EC,$E5,$E8,$E3,$E8,$E9,$89,$01,$16,$ED,$01,$EE,$EF
  .byte $F0,$F0,$F1,$EF,$01,$01,$F2,$F3,$F0,$F0,$F4,$01,$F1,$EF,$F1,$F3
  .byte $F2,$F3,$8E,$01,$0C,$71,$A7,$6F,$01,$73,$75,$A9,$73,$A7,$6F,$77
  .byte $DD,$97,$01,$04,$08,$09,$0A,$0B,$99,$01,$08,$08,$0C,$0D,$0E,$0F
  .byte $10,$11,$0B,$95,$01,$0C,$08,$0C,$0D,$12,$13,$14,$0F,$15,$16,$10
  .byte $11,$0B,$91,$01,$10,$08,$0C,$0D,$12,$13,$17,$18,$0E,$0F,$19,$0F
  .byte $15,$16,$10,$11,$0B,$8D,$01,$14,$08,$0C,$0D,$12,$13,$17,$18,$12
  .byte $13,$14,$0F,$15,$16,$19,$0F,$15,$1A,$10,$11,$0B,$89,$01,$18,$08
  .byte $0C,$0D,$12,$13,$17,$18,$12,$13,$17,$1B,$1C,$1D,$1E,$0F,$15,$16
  .byte $19,$1F,$20,$16,$10,$11,$0B,$85,$01,$0C,$08,$0C,$0D,$21,$13,$17
  .byte $18,$12,$13,$17,$1B,$1C,$83,$00,$1A,$1D,$1E,$0F,$15,$22,$23,$0F
  .byte $15,$16,$10,$11,$0B,$01,$01,$08,$0C,$0D,$12,$24,$25,$18,$12,$13
  .byte $17,$1B,$1C,$87,$00,$18,$1D,$1E,$26,$27,$16,$19,$0F,$15,$16,$10
  .byte $11,$0B,$28,$12,$13,$17,$29,$2A,$13,$17,$2B,$2C,$2D,$2E,$89,$00
  .byte $18,$2F,$30,$0F,$15,$16,$19,$0F,$15,$16,$31,$18,$17,$18,$12,$29
  .byte $2A,$2B,$2C,$32,$33,$34,$35,$2D,$2E,$89,$00,$18,$1D,$1E,$0F,$15
  .byte $16,$19,$0F,$36,$18,$12,$13,$17,$37,$38,$39,$3A,$3B,$3C,$3D,$3E
  .byte $3F,$40,$2D,$2E,$89,$00,$0A,$1D,$1E,$0F,$15,$16,$41,$18,$17,$1B
  .byte $1C,$83,$00,$0C,$42,$43,$44,$45,$01,$01,$3F,$40,$46,$47,$48,$49
  .byte $87,$00,$06,$1D,$1E,$0F,$36,$1B,$1C,$85,$00,$04,$4A,$4B,$4C,$4D
  .byte $83,$01,$04,$4E,$3C,$3D,$4F,$89,$00,$04,$1D,$50,$51,$52,$85,$00
  .byte $0E,$4A,$43,$44,$53,$54,$55,$01,$01,$56,$43,$44,$57,$2D,$2E,$87
  .byte $00,$06,$58,$59,$5A,$5B,$5C,$52,$83,$00,$10,$4A,$4B,$4C,$5D,$00
  .byte $00,$54,$55,$56,$4B,$4C,$5E,$3F,$40,$2D,$2E,$83,$00,$10,$58,$5F
  .byte $60,$61,$01,$01,$62,$5B,$5C,$52,$00,$00,$63,$64,$65,$66,$83,$00
  .byte $0E,$42,$43,$44,$45,$01,$01,$3F,$40,$2D,$2E,$58,$5F,$60,$67,$85
  .byte $01,$04,$62,$5B,$5C,$52,$87,$00,$04,$4A,$4B,$4C,$4D,$83,$01,$04
  .byte $68,$69,$60,$67,$89,$01,$04,$62,$5B,$5C,$52,$85,$00,$0A,$63,$64
  .byte $65,$66,$54,$55,$6A,$6B,$60,$67,$8D,$01,$04,$62,$5B,$5C,$52,$87
  .byte $00,$04,$58,$5F,$60,$67,$91,$01,$04,$62,$5B,$5C,$52,$83,$00,$04
  .byte $58,$5F,$60,$67,$95,$01,$08,$62,$5B,$5C,$52,$58,$5F,$60,$67,$99
  .byte $01,$04,$62,$5B,$60,$67,$97,$01,$0B,$73,$75,$6F,$DE,$DE,$01,$DE
  .byte $71,$76,$75,$71,$AF,$01,$16,$76,$74,$01,$6D,$DE,$A9,$72,$6F,$71
  .byte $75,$6D,$77,$01,$76,$DF,$DB,$6F,$74,$71,$DC,$75,$6F,$A4,$01,$87
  .byte $AA,$AF,$00,$87,$05,$00
scr_over_nt:
  .byte $FF,$01,$FF,$01,$C7,$01,$0F,$DD,$A9,$DC,$01,$A7,$76,$DB,$6F,$01
  .byte $6E,$76,$6C,$6C,$6F,$74,$AC,$01,$17,$71,$A7,$6F,$01,$71,$A9,$72
  .byte $A8,$01,$77,$6C,$76,$6D,$72,$DE,$01,$76,$74,$A9,$71,$A7,$6F,$75
  .byte $AF,$01,$0A,$76,$DF,$DB,$6F,$74,$71,$DC,$75,$6F,$75,$FF,$01,$F4
  .byte $01,$0B,$73,$75,$6F,$DE,$DE,$01,$DE,$71,$76,$75,$71,$FF,$01,$EA
  .byte $01,$B7,$55,$87,$05,$00
scr_win_nt:
  .byte $FF,$01,$E7,$01,$0F,$77,$A9,$74,$E0,$75,$76,$71,$DC,$6C,$76,$71
  .byte $6D,$A9,$74,$DE,$CD,$01,$15,$DD,$A9,$DC,$01,$6E,$A9,$DC,$74,$DF
  .byte $01,$71,$A7,$6F,$01,$76,$74,$AA,$A7,$01,$A9,$6E,$AF,$01,$0C,$71
  .byte $A7,$6F,$01,$73,$75,$A9,$73,$A7,$6F,$77,$DD,$CE,$01,$15,$71,$A7
  .byte $6F,$01,$71,$A9,$72,$A8,$01,$6E,$76,$6C,$6C,$DE,$01,$DE,$6D,$6C
  .byte $6F,$74,$71,$AB,$01,$13,$76,$74,$DF,$01,$6C,$76,$75,$76,$01,$E1
  .byte $76,$6C,$AA,$DE,$01,$6D,$74,$71,$A9,$B0,$01,$0C,$71,$A7,$6F,$01
  .byte $DF,$76,$DD,$6C,$6D,$E0,$A7,$71,$D3,$01,$0B,$73,$75,$6F,$DE,$DE
  .byte $01,$DE,$71,$76,$75,$71,$FF,$01,$EA,$01,$B7,$55,$87,$05,$00
scr_title_pal:
  .byte $27,$0F,$17,$37,$27,$0F,$16,$30,$27,$0F,$27,$30,$27,$0F,$0F,$0F
scr_text_pal:
  .byte $0F,$0F,$0F,$0F,$0F,$0F,$16,$30,$0F,$0F,$27,$30,$0F,$0F,$0F,$0F
scr_nt_lo: .byte <scr_title_nt,<scr_over_nt,<scr_win_nt
scr_nt_hi: .byte >scr_title_nt,>scr_over_nt,>scr_win_nt
scr_pal_lo: .byte <scr_title_pal,<scr_text_pal,<scr_text_pal
scr_pal_hi: .byte >scr_title_pal,>scr_text_pal,>scr_text_pal
sprpal:
  .byte $0F,$37,$2C,$07, $0F,$0F,$16,$30, $0F,$0F,$00,$16, $0F,$07,$28,$30
rt_nt_lo: .byte <r0_nt,<r1_nt,<r2_nt
rt_nt_hi: .byte >r0_nt,>r1_nt,>r2_nt
rt_pal_lo: .byte <r0_pal,<r1_pal,<r2_pal
rt_pal_hi: .byte >r0_pal,>r1_pal,>r2_pal
rt_map_lo: .byte <r0_map,<r1_map,<r2_map
rt_map_hi: .byte >r0_map,>r1_map,>r2_map
rt_en_lo: .byte <r0_en,<r1_en,<r2_en
rt_en_hi: .byte >r0_en,>r1_en,>r2_en
rt_it_lo: .byte <r0_it,<r1_it,<r2_it
rt_it_hi: .byte >r0_it,>r1_it,>r2_it
sp_i:
  .byte $58,$18,$38,$18,$18,$58,$18,$18,$18
sp_j:
  .byte $68,$58,$18,$28,$28,$18,$38,$38,$18
sp_f:
  .byte $07,$01,$03,$01,$01,$03,$01,$01,$03
edj: .byte 255,2,3
xdi: .byte 3,5,255
ropen: .byte 1,3,255
pbase: .byte 0,2,6
lockmsg: .byte 2,6,2
pf1:
  .byte $21,$36,$02,$78,$79,$21,$56,$02,$7A,$7B,$21,$76,$02,$7A,$7B,$21
  .byte $96,$02,$7C,$7D,$00
pt1:
  .byte $21,$36,$02,$78,$79,$21,$56,$02,$7A,$7B,$21,$76,$02,$7A,$7B,$21
  .byte $96,$02,$7C,$7D,$00
pf3:
  .byte $21,$EA,$04,$00,$00,$00,$00,$22,$0A,$06,$00,$00,$8E,$8F,$90,$91
  .byte $22,$2A,$06,$00,$00,$AB,$AC,$AD,$AE,$22,$4A,$06,$00,$00,$AF,$3C
  .byte $3D,$B0,$22,$6C,$04,$B1,$43,$44,$B2,$00
pt3:
  .byte $21,$EA,$04,$00,$00,$00,$00,$22,$0A,$06,$00,$00,$8E,$8F,$90,$91
  .byte $22,$2A,$06,$00,$00,$AB,$AC,$AD,$AE,$22,$4A,$06,$00,$00,$AF,$3C
  .byte $3D,$B0,$22,$6C,$04,$B1,$43,$44,$B2,$00
pf4:
  .byte $21,$EA,$04,$00,$00,$00,$00,$22,$0A,$04,$00,$00,$00,$00,$22,$2A
  .byte $08,$00,$00,$84,$85,$B3,$B4,$90,$91,$22,$4A,$08,$00,$00,$88,$3C
  .byte $3D,$B5,$94,$95,$22,$6F,$03,$B6,$B7,$B8,$22,$8F,$03,$B9,$BA,$BB
  .byte $00
pt4:
  .byte $22,$0C,$04,$00,$00,$00,$00,$22,$2C,$06,$84,$85,$B3,$B4,$90,$91
  .byte $22,$4C,$06,$88,$3C,$3D,$B5,$94,$95,$22,$6C,$06,$4A,$43,$44,$B6
  .byte $B7,$B8,$22,$8F,$03,$B9,$BA,$BB,$00
pf5:
  .byte $21,$7A,$02,$78,$79,$21,$9A,$02,$7A,$7B,$21,$BA,$02,$7A,$7B,$21
  .byte $DA,$02,$7C,$7D,$21,$EA,$04,$00,$00,$00,$00,$22,$0A,$04,$00,$00
  .byte $00,$00,$22,$2A,$04,$00,$00,$84,$85,$22,$4A,$0A,$00,$00,$88,$3C
  .byte $3D,$89,$8E,$8F,$BC,$BD,$22,$70,$04,$92,$93,$94,$95,$22,$90,$04
  .byte $BE,$BF,$C0,$C1,$22,$B0,$04,$C2,$C3,$C4,$C5,$00
pt5:
  .byte $21,$7A,$02,$78,$79,$21,$9A,$02,$7A,$7B,$21,$BA,$02,$7A,$7B,$21
  .byte $DA,$02,$7C,$7D,$22,$2E,$04,$48,$49,$00,$00,$22,$4F,$05,$89,$8E
  .byte $8F,$BC,$BD,$22,$6F,$05,$53,$92,$93,$94,$95,$22,$8F,$05,$5D,$BE
  .byte $BF,$C0,$C1,$22,$B0,$04,$C2,$C3,$C4,$C5,$00
pfull_lo: .byte 0,<pf1,0,<pf3,<pf4,<pf5,0
pfull_hi: .byte 0,>pf1,0,>pf3,>pf4,>pf5,0
ptrans_lo: .byte 0,<pt1,0,<pt3,<pt4,<pt5,0
ptrans_hi: .byte 0,>pt1,0,>pt3,>pt4,>pt5,0
msg0:
  .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
msg1:
  .byte $01,$01,$01,$01,$01,$DD,$A9,$DC,$01,$6E,$A9,$DC,$74,$DF,$01,$76,$01,$E0,$A9,$6C,$DF,$6F,$74,$01,$AA,$6F,$DD,$01,$01,$01,$01,$01
msg2:
  .byte $01,$01,$01,$01,$01,$01,$01,$71,$A7,$6F,$01,$DF,$A9,$A9,$75,$01,$6D,$DE,$01,$6C,$A9,$77,$AA,$6F,$DF,$01,$01,$01,$01,$01,$01,$01
msg3:
  .byte $01,$01,$01,$01,$01,$01,$71,$A7,$6F,$01,$6C,$A9,$77,$AA,$01,$77,$6C,$6D,$77,$AA,$DE,$01,$A9,$73,$6F,$74,$01,$01,$01,$01,$01,$01
msg4:
  .byte $01,$01,$01,$72,$6F,$DF,$6D,$73,$76,$77,$AA,$01,$01,$A7,$6F,$76,$6C,$71,$A7,$01,$75,$6F,$DE,$71,$A9,$75,$6F,$DF,$01,$01,$01,$01
msg5:
  .byte $01,$01,$01,$01,$01,$DD,$A9,$DC,$01,$6E,$6F,$6C,$6C,$01,$6D,$74,$71,$A9,$01,$71,$A7,$6F,$01,$73,$6D,$71,$01,$01,$01,$01,$01,$01
msg6:
  .byte $01,$01,$01,$01,$01,$01,$6D,$71,$01,$E1,$A9,$74,$71,$01,$A8,$DC,$DF,$E0,$6F,$F5,$F5,$F5,$01,$DD,$6F,$71,$01,$01,$01,$01,$01,$01
msg7:
  .byte $01,$01,$01,$01,$01,$01,$76,$01,$DE,$71,$A9,$74,$6F,$01,$E0,$75,$6D,$74,$DF,$DE,$01,$A9,$73,$6F,$74,$01,$01,$01,$01,$01,$01,$01
msg8:
  .byte $01,$01,$70,$F6,$F7,$DC,$72,$73,$01,$01,$F8,$F6,$6E,$6D,$75,$6F,$01,$01,$73,$DC,$DE,$A7,$01,$A8,$6C,$A9,$77,$AA,$DE,$01,$01,$01
msg_lo: .byte <msg0,<msg1,<msg2,<msg3,<msg4,<msg5,<msg6,<msg7,<msg8
msg_hi: .byte >msg0,>msg1,>msg2,>msg3,>msg4,>msg5,>msg6,>msg7,>msg8
lbase: .byte 0,2,4,6,8,10,12,14,48
fart: .byte 2,0,0,0,2,1,1,1
fflp: .byte 0,0,0,1,1,1,0,0
fatt: .byte 0,0,0,$40,$40,$40,0,0
ebase: .byte 0,0,112,114,116,118
ehp0: .byte 0,2,3
itbase: .byte 0,120,122,124
itatt: .byte 0,3,1,3
dirtab: .byte $FF,0,4,$FF,2,1,3,2,6,7,5,6,$FF,0,4,$FF
dI: .byte 1,1,1,0,255,255,255,0
dJ: .byte 255,0,1,1,1,0,255,255
dI3: .byte 3,3,3,0,253,253,253,0
dJ3: .byte 253,0,3,3,3,0,253,253
bdI: .byte 16,0,16,32,16,32
bdJ: .byte 0,16,16,16,32,32
b4dx: .byte 253,3,253,3
b4dy: .byte 253,253,3,3
bobt: .byte 0,1,2,1
jztab:
  .byte $00,$02,$05,$07,$0A,$0B,$0D,$0E,$10,$10,$11,$11,$12,$11,$11,$10
  .byte $10,$0E,$0D,$0B,$0A,$07,$05,$02,$00

.org $FFFA
.word nmi, reset, 0

; <GFX> tile generati dall’editor grafico
.chr 1
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11333111
.tile 13111311
.tile 13113311
.tile 13131311
.tile 13311311
.tile 13111311
.tile 11333111
.tile 11111111
.tile 11131111
.tile 11331111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11333111
.tile 11111111
.tile 11333111
.tile 13111311
.tile 11111311
.tile 11113111
.tile 11131111
.tile 11311111
.tile 13333311
.tile 11111111
.tile 11111111
.tile 12212211
.tile 22222221
.tile 22222221
.tile 12222211
.tile 11222111
.tile 11121111
.tile 11111111
.tile 11111111
.tile 13313311
.tile 31131131
.tile 31111131
.tile 13111311
.tile 11313111
.tile 11131111
.tile 11111111
.tile 11111111
.tile 13311111
.tile 31131111
.tile 31131111
.tile 13311111
.tile 11311111
.tile 11331111
.tile 11313111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111113
.tile 11111333
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111331
.tile 11133331
.tile 13333121
.tile 33322211
.tile 32212221
.tile 11111111
.tile 11111111
.tile 13111111
.tile 13331111
.tile 12333311
.tile 12223333
.tile 12222233
.tile 12222222
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 33111111
.tile 33331111
.tile 11111111
.tile 11111111
.tile 11111113
.tile 11111333
.tile 11133332
.tile 13333122
.tile 33322212
.tile 32212221
.tile 11133332
.tile 13333122
.tile 33322212
.tile 32212221
.tile 12221221
.tile 11222112
.tile 12111212
.tile 11112221
.tile 12221221
.tile 21222111
.tile 22111211
.tile 21112221
.tile 12221221
.tile 11222121
.tile 12122211
.tile 12212221
.tile 11222222
.tile 12112222
.tile 12221122
.tile 12222211
.tile 12222222
.tile 12222222
.tile 12222222
.tile 12222222
.tile 22333311
.tile 22223333
.tile 22222233
.tile 22222222
.tile 11222222
.tile 12112222
.tile 12221122
.tile 12222211
.tile 11111111
.tile 11111111
.tile 33111111
.tile 33331111
.tile 12333311
.tile 12223333
.tile 12222233
.tile 12222222
.tile 12221221
.tile 21222112
.tile 22111212
.tile 21112221
.tile 12221222
.tile 11222122
.tile 12122212
.tile 12212221
.tile 12221222
.tile 21222122
.tile 22122212
.tile 22212221
.tile 12221221
.tile 21222112
.tile 22111212
.tile 21112221
.tile 12221221
.tile 11222111
.tile 12111211
.tile 11112221
.tile 12221221
.tile 21222121
.tile 22122211
.tile 22212221
.tile 12222222
.tile 12222222
.tile 12222222
.tile 12222222
.tile 11222222
.tile 22112222
.tile 22221122
.tile 22222211
.tile 11222222
.tile 22112222
.tile 22221122
.tile 22222211
.tile 22222222
.tile 22222222
.tile 22222222
.tile 22222222
.tile 12221221
.tile 11222112
.tile 12111212
.tile 11112221
.tile 12221222
.tile 21222122
.tile 22122212
.tile 22212221
.tile 12221222
.tile 11222122
.tile 12122212
.tile 12212221
.tile 12221221
.tile 11222112
.tile 12111212
.tile 11112221
.tile 22222222
.tile 22222222
.tile 22222222
.tile 22222222
.tile 11222222
.tile 12112222
.tile 12221122
.tile 12222211
.tile 11222222
.tile 22112222
.tile 22221122
.tile 22222211
.tile 12222222
.tile 11122222
.tile 13111122
.tile 13331111
.tile 12221222
.tile 11222122
.tile 12122212
.tile 12212221
.tile 1222111.
.tile 11211...
.tile 111.....
.tile 1.......
.tile 1222111.
.tile 21211...
.tile 211.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile .1122222
.tile ...11222
.tile .....112
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile 22222222
.tile 22222222
.tile 22222222
.tile 12222222
.tile .1122222
.tile ...11222
.tile .....112
.tile .......1
.tile 13333311
.tile 13323333
.tile 13321223
.tile 13322122
.tile 13322222
.tile 13322212
.tile 13312221
.tile 13322222
.tile 11222222
.tile 11111222
.tile 33111112
.tile 23331111
.tile 22223311
.tile 22122331
.tile 22212331
.tile 22222331
.tile 12221221
.tile 21222112
.tile 22111212
.tile 21112221
.tile 12221111
.tile 11221111
.tile 12111111
.tile 11111331
.tile 13321222
.tile 13322122
.tile 13322222
.tile 13322212
.tile 13312221
.tile 13322222
.tile 13321222
.tile 13322123
.tile 12221331
.tile 21222331
.tile 22222331
.tile 22122331
.tile 22212331
.tile 22222331
.tile 12221331
.tile 33222331
.tile 12221211
.tile 21221111
.tile 22111113
.tile 21111332
.tile 11133222
.tile 13332221
.tile 13322111
.tile 13311112
.tile 11131331
.tile 13122331
.tile 32222331
.tile 22211331
.tile 21111331
.tile 11122331
.tile 12222331
.tile 22211331
.tile 13322223
.tile 13322213
.tile 13312221
.tile 13322222
.tile 13321222
.tile 13322122
.tile 13322222
.tile 13322212
.tile 13222331
.tile 13122331
.tile 22212331
.tile 22222331
.tile 12221331
.tile 21222331
.tile 22222331
.tile 22122331
.tile 11133332
.tile 13333122
.tile 13322212
.tile 12212221
.tile 12221221
.tile 11222112
.tile 12111212
.tile 11112221
.tile 13311222
.tile 13322221
.tile 13322111
.tile 13311112
.tile 13311222
.tile 13322221
.tile 13322111
.tile 13311112
.tile 21111331
.tile 11122331
.tile 12222331
.tile 22211331
.tile 21111331
.tile 11122331
.tile 12222331
.tile 22211331
.tile 12221222
.tile 11222122
.tile 12122212
.tile 12212221
.tile 12221111
.tile 11211212
.tile 11112121
.tile 12121212
.tile 12221112
.tile 21211222
.tile 21122222
.tile 12121212
.tile 21212121
.tile 12121212
.tile 21212121
.tile 12121212
.tile 3.......
.tile 232.....
.tile 32323...
.tile 2323232.
.tile 32323232
.tile 23232323
.tile 32323232
.tile 22222222
.tile ........
.tile ........
.tile ........
.tile ........
.tile 3.......
.tile 232.....
.tile 32323...
.tile 2222222.
.tile .3312221
.tile ...32222
.tile .....132
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile 22212331
.tile 22222331
.tile 12221331
.tile 31222331
.tile .1332331
.tile ...11331
.tile .....111
.tile .......1
.tile 22333311
.tile 22223331
.tile 22222231
.tile 22222221
.tile 11222221
.tile 12112221
.tile 12221121
.tile 12222211
.tile 11212121
.tile 11121212
.tile 11111121
.tile 11111112
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111113
.tile 21212121
.tile 12121212
.tile 21212121
.tile 12121113
.tile 11211333
.tile 11133333
.tile 13333333
.tile 33333333
.tile 22222222
.tile 22222222
.tile 12222222
.tile 31122222
.tile 33311221
.tile 33333111
.tile 33333331
.tile 33333333
.tile 22222221
.tile 22222111
.tile 22211111
.tile 21111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 31111111
.tile 12222221
.tile 12222221
.tile 12222221
.tile 12222221
.tile 11222221
.tile 22112221
.tile 22221121
.tile 22222211
.tile 13311222
.tile 13322221
.tile 13322111
.tile 13311113
.tile 1331121.
.tile 13321...
.tile 133.....
.tile 1.......
.tile 2111311.
.tile 11131...
.tile 131.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile .1212121
.tile ...21212
.tile .....121
.tile .......2
.tile ........
.tile ........
.tile ........
.tile ........
.tile 21212121
.tile 12121212
.tile 21212121
.tile 12121111
.tile .1211111
.tile ...11111
.tile .....111
.tile .......1
.tile 11111113
.tile 11111211
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 33333333
.tile 13333333
.tile 11133333
.tile 22111333
.tile 22221113
.tile 22222211
.tile 22222221
.tile 22222221
.tile 33333333
.tile 33333331
.tile 33333112
.tile 33311211
.tile 31121122
.tile 11112122
.tile 11122212
.tile 12212221
.tile 31111111
.tile 11111111
.tile 11111111
.tile 22211111
.tile 12211111
.tile 21211111
.tile 22111111
.tile 22211111
.tile 22222222
.tile 22222222
.tile 12222222
.tile 11122222
.tile 11111221
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22222221
.tile 22222111
.tile 22211111
.tile 21111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22222221
.tile 22222221
.tile 22222221
.tile 22222221
.tile 11222221
.tile 12112221
.tile 12221121
.tile 12222211
.tile .1111122
.tile ...11211
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile 22222221
.tile 22222221
.tile 11222221
.tile 22112221
.tile 22221121
.tile 22221211
.tile 22221221
.tile 22221221
.tile 12221222
.tile 11222122
.tile 12122212
.tile 12212211
.tile 12221122
.tile 11112122
.tile 11122212
.tile 22212221
.tile 12211111
.tile 21111111
.tile 11111111
.tile 12211111
.tile 12211111
.tile 11211111
.tile 12111111
.tile 12211111
.tile 3.......
.tile 232.....
.tile 32323...
.tile 2323232.
.tile 32323232
.tile 23232323
.tile 32323231
.tile 22222113
.tile ........
.tile ........
.tile .......1
.tile .....113
.tile 3..11333
.tile 21133333
.tile 13333333
.tile 33333333
.tile ........
.tile ........
.tile 1.......
.tile 311.....
.tile 33311...
.tile 3333311.
.tile 33333331
.tile 33333333
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile 311.....
.tile ....1122
.tile ....1211
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile 22221221
.tile 22221221
.tile 11221221
.tile 22111221
.tile 22221121
.tile 22222211
.tile 22222221
.tile 22222221
.tile 12221222
.tile 21222122
.tile 22122212
.tile 22212211
.tile 12221122
.tile 21112122
.tile 11122212
.tile 12212221
.tile 12211111
.tile 11111111
.tile 11111111
.tile 22211111
.tile 12211111
.tile 21211111
.tile 2211.111
.tile 2221...1
.tile 22221113
.tile 22221211
.tile 12221222
.tile 11121222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 3111....
.tile 1111....
.tile 1111....
.tile 2221....
.tile 1221....
.tile 2121....
.tile 22113...
.tile 2221222.
.tile 22222221
.tile 22222221
.tile 22222221
.tile 12222221
.tile .1122221
.tile ...11221
.tile .....111
.tile .......1
.tile 1.......
.tile 111.....
.tile 12311...
.tile 1222311.
.tile 12222231
.tile 12222222
.tile 12222222
.tile 12222222
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile 311.....
.tile 22311...
.tile 2222311.
.tile 1221....
.tile 2111....
.tile 1111....
.tile 1221....
.tile 1221....
.tile 1121....
.tile 1211....
.tile 1221....
.tile .1111111
.tile ...11111
.tile .....111
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile .1111111
.tile ...11111
.tile .....111
.tile .......1
.tile 11111122
.tile 11111211
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 12212221
.tile 21112111
.tile 11111111
.tile 12211111
.tile 12211111
.tile 11211111
.tile 12111111
.tile 12211111
.tile ........
.tile ........
.tile ........
.tile ........
.tile .......1
.tile .....111
.tile ...11222
.tile .1122222
.tile .......1
.tile .....111
.tile ...11221
.tile .1122221
.tile 12121211
.tile 21212121
.tile 22222221
.tile 22222221
.tile 12222222
.tile 11222222
.tile 11112222
.tile 11111122
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22222231
.tile 22222222
.tile 22222222
.tile 22222222
.tile 22222222
.tile 11222222
.tile 11112222
.tile 11111122
.tile 1.......
.tile 311.....
.tile 22311...
.tile 2222311.
.tile 22222231
.tile 22222222
.tile 22222222
.tile 22222222
.tile 1221....
.tile 1111....
.tile 1111....
.tile 2221....
.tile 1221....
.tile 2121....
.tile 2211....
.tile 2221....
.tile 12211111
.tile 11111111
.tile 11111111
.tile 22211111
.tile 12211111
.tile 21211111
.tile 22111111
.tile 22211111
.tile .......1
.tile .....111
.tile ...11222
.tile .1122222
.tile 12121212
.tile 21212121
.tile 22222222
.tile 22222222
.tile 12121212
.tile 21212121
.tile 22222222
.tile 22222222
.tile 12121212
.tile 21212121
.tile 22222111
.tile 22211111
.tile 12121211
.tile 21212121
.tile 22222111
.tile 22211111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22222222
.tile 11222222
.tile 11112222
.tile 11111122
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile .....112
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 22222221
.tile 12222221
.tile .1122221
.tile ...11221
.tile .....111
.tile .......1
.tile ........
.tile ........
.tile 12221222
.tile 11222121
.tile 1212211.
.tile 12211...
.tile 111.....
.tile 1.......
.tile ........
.tile ........
.tile 111.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 12121212
.tile 21212121
.tile 22222111
.tile 22211111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22222222
.tile 22222222
.tile 12222222
.tile 11122222
.tile 11111221
.tile 11111111
.tile 11111222
.tile 11122222
.tile 22222221
.tile 22222111
.tile 22211222
.tile 21122222
.tile 12121212
.tile 21212121
.tile 22222222
.tile 22222222
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111222
.tile 11122222
.tile 11111111
.tile 11111111
.tile 11111222
.tile 11122222
.tile 12121212
.tile 21212121
.tile 22222222
.tile 22222222
.tile 13111111
.tile 13111111
.tile 13111111
.tile 13111111
.tile 13111111
.tile 13111111
.tile 13333311
.tile 11111111
.tile 11333111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11333111
.tile 11111111
.tile 13333311
.tile 13111111
.tile 13111111
.tile 13333111
.tile 13111111
.tile 13111111
.tile 13111111
.tile 11111111
.tile 13333311
.tile 13111111
.tile 13111111
.tile 13333111
.tile 13111111
.tile 13111111
.tile 13333311
.tile 11111111
.tile 13111311
.tile 13111311
.tile 11313111
.tile 11131111
.tile 11313111
.tile 13111311
.tile 13111311
.tile 11111111
.tile 13333311
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11111111
.tile 13111311
.tile 13313311
.tile 13131311
.tile 13131311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11111111
.tile 13333111
.tile 13111311
.tile 13111311
.tile 13333111
.tile 13111111
.tile 13111111
.tile 13111111
.tile 11111111
.tile 13111311
.tile 13311311
.tile 13131311
.tile 13113311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11111111
.tile 13333111
.tile 13111311
.tile 13111311
.tile 13333111
.tile 13131111
.tile 13113111
.tile 13111311
.tile 11111111
.tile 11333111
.tile 13111311
.tile 13111311
.tile 13333311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11111111
.tile 11333111
.tile 13111311
.tile 13111111
.tile 13111111
.tile 13111111
.tile 13111311
.tile 11333111
.tile 11111111
.tile 13333311
.tile 13313333
.tile 13311113
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 11222222
.tile 11111222
.tile 33111112
.tile 13331111
.tile 11113311
.tile 11111331
.tile 11111331
.tile 11111331
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311111
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile .3311111
.tile ...31111
.tile .....131
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile 11111331
.tile 11111331
.tile 11111331
.tile 31111331
.tile .1331331
.tile ...11331
.tile .....111
.tile .......1
.tile 12221211
.tile 21221111
.tile 22111113
.tile 21111331
.tile 11133111
.tile 13331111
.tile 13311111
.tile 13311111
.tile 11131331
.tile 13111331
.tile 31111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 11111331
.tile 13311111
.tile 13311111
.tile 13311111
.tile 13311113
.tile 1331111.
.tile 13311...
.tile 133.....
.tile 1.......
.tile 1111311.
.tile 11131...
.tile 131.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile 13333311
.tile 13323333
.tile 13312223
.tile 13322222
.tile 13321222
.tile 13322122
.tile 13322222
.tile 13322212
.tile 11222222
.tile 11111222
.tile 33111112
.tile 23331111
.tile 12223311
.tile 21222331
.tile 22222331
.tile 22122331
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile .......1
.tile .....113
.tile ........
.tile ........
.tile .......1
.tile .....113
.tile ...11333
.tile .1133333
.tile 13333333
.tile 33333333
.tile 13312221
.tile 13322222
.tile 13321222
.tile 13322122
.tile 13322222
.tile 13322212
.tile 13312221
.tile 13322223
.tile 22212331
.tile 22222331
.tile 12221331
.tile 21222331
.tile 22222331
.tile 22122331
.tile 22212331
.tile 33222331
.tile ....1113
.tile ....1211
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile 3111....
.tile 1111....
.tile 1111....
.tile 2221....
.tile 1221....
.tile 2121....
.tile 2211....
.tile 2221....
.tile 13321223
.tile 13322123
.tile 13322222
.tile 13322212
.tile 13312221
.tile 13322222
.tile 13321222
.tile 13322122
.tile 13221331
.tile 13222331
.tile 22222331
.tile 22122331
.tile 22212331
.tile 22222331
.tile 12221331
.tile 21222331
.tile .3322222
.tile ...32212
.tile .....131
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile 22222331
.tile 22122331
.tile 22212331
.tile 32222331
.tile .1331331
.tile ...11331
.tile .....111
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile .......1
.tile .....113
.tile ...11333
.tile ........
.tile .......1
.tile .....113
.tile ...11333
.tile .1133333
.tile 13333333
.tile 33333333
.tile 33333333
.tile ........
.tile 1.......
.tile 311.....
.tile 33311...
.tile 3333311.
.tile 33333331
.tile 33333333
.tile 33333333
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile 311.....
.tile 33311...
.tile ..111333
.tile ..122113
.tile ..122221
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile 33333333
.tile 33333333
.tile 13333333
.tile 21133333
.tile 22211333
.tile 22222113
.tile 22222221
.tile 22222221
.tile 33333333
.tile 33333333
.tile 33333331
.tile 33333111
.tile 33311211
.tile 31121122
.tile 12112212
.tile 11212221
.tile 333111..
.tile 311211..
.tile 121121..
.tile 112121..
.tile 122211..
.tile 112221..
.tile 121221..
.tile 122121..
.tile ..122221
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile 12222221
.tile 21122221
.tile 22212221
.tile 22222221
.tile 22222221
.tile 22222221
.tile 22222221
.tile 22222221
.tile 12221222
.tile 21222122
.tile 22122212
.tile 22212221
.tile 12221211
.tile 21221122
.tile 22112211
.tile 11212113
.tile 122211..
.tile 112211..
.tile 121121.1
.tile 11212113
.tile 12211333
.tile 21133333
.tile 13333333
.tile 33333333
.tile ...11222
.tile .....112
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 22222221
.tile 22222221
.tile 12222221
.tile .1122221
.tile ...11221
.tile .....111
.tile .......1
.tile ........
.tile 12221113
.tile 11221211
.tile 12121222
.tile 12211222
.tile 12211222
.tile 111.1222
.tile 1...1222
.tile ....1222
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile .......1
.tile ........
.tile ........
.tile ........
.tile .......1
.tile .....113
.tile ...11333
.tile .1133333
.tile 13333332
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile 311.....
.tile 33311...
.tile 3333311.
.tile 23333331
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 13333332
.tile .1133333
.tile ...11333
.tile .....113
.tile .......1
.tile ........
.tile ........
.tile ........
.tile 23333331
.tile 3333311.
.tile 33311...
.tile 311.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1....112
.tile 311....1
.tile 22311...
.tile 2222311.
.tile 22222231
.tile 22222222
.tile 22222222
.tile 22222222
.tile 22222221
.tile 12222221
.tile .1122221
.tile ...11221
.tile 1....111
.tile 311....1
.tile 22311...
.tile 2222311.
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13333311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11111111
.tile 13333111
.tile 13111311
.tile 13111311
.tile 13333111
.tile 13111311
.tile 13111311
.tile 13333111
.tile 11111111
.tile 11333111
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11333111
.tile 11111111
.tile 13111311
.tile 13113111
.tile 13131111
.tile 13311111
.tile 13131111
.tile 13113111
.tile 13111311
.tile 11111111
.tile ..111333
.tile ..122113
.tile ..122221
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122221
.tile ..122113
.tile 33333333
.tile 33333333
.tile 13333331
.tile 21133113
.tile 22211333
.tile 21133333
.tile 13333333
.tile 33333333
.tile 33333333
.tile 33333333
.tile 13333331
.tile 31133111
.tile 33311211
.tile 33333112
.tile 33333331
.tile 33333333
.tile 333111..
.tile 311211..
.tile 121121..
.tile 112121..
.tile 122211..
.tile 112221..
.tile 121221..
.tile 311121..
.tile ..121113
.tile ..121211
.tile ..121222
.tile ..121222
.tile ..121222
.tile ..121222
.tile ..121222
.tile ..121222
.tile 311111..
.tile 111111..
.tile 111121..
.tile 222121..
.tile 122111..
.tile 212121..
.tile 221121..
.tile 222121..
.tile ...11122
.tile ....1211
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile 12211...
.tile 2111....
.tile 1111....
.tile 1221....
.tile 1221....
.tile 1121....
.tile 1211....
.tile 1221....
.tile ........
.tile ........
.tile 1.......
.tile 311.....
.tile 33311...
.tile 33333111
.tile 33333331
.tile 33333333
.tile ........
.tile .......1
.tile .....113
.tile ...11333
.tile .1133333
.tile 13333333
.tile 13333333
.tile 31133333
.tile 31113333
.tile 11113333
.tile 11113333
.tile 22213333
.tile 12211333
.tile 21212113
.tile 22112221
.tile 22212221
.tile 12212221
.tile 21112221
.tile 11112221
.tile 12212221
.tile 12212221
.tile 11212221
.tile 12112221
.tile 12212221
.tile 12221222
.tile 21222122
.tile 22122212
.tile 22212221
.tile 12221211
.tile 21221122
.tile 22112212
.tile 11212221
.tile 122211..
.tile 112211..
.tile 121121..
.tile 112121..
.tile 122211..
.tile 212221..
.tile 221221..
.tile 222121..
.tile 12212221
.tile 11112221
.tile 11112221
.tile 22212221
.tile 12211221
.tile 2121.111
.tile 2211...1
.tile 2221....
.tile 12221222
.tile 11222122
.tile 12122211
.tile 1221211.
.tile 12211...
.tile 111.....
.tile 1.......
.tile .......1
.tile 12211...
.tile 211.....
.tile 1.......
.tile .......1
.tile .....113
.tile ...11333
.tile .1133333
.tile 13333332
.tile .....112
.tile 1......1
.tile 311.....
.tile 33311...
.tile 3333311.
.tile 33333331
.tile 33333333
.tile 33333333
.tile 22222221
.tile 12222221
.tile .1122221
.tile ...11221
.tile .....111
.tile 1......1
.tile 311.....
.tile 33311...
.tile ..122221
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122222
.tile ..122221
.tile 12222221
.tile 21122221
.tile 22212221
.tile 22222221
.tile 22222112
.tile 22211222
.tile 21122222
.tile 12222222
.tile 12221222
.tile 21222122
.tile 22122212
.tile 12212221
.tile 21121211
.tile 22211122
.tile 22222112
.tile 22222221
.tile 122211..
.tile 112211..
.tile 121121..
.tile 112121..
.tile 122211..
.tile 212221..
.tile 221221..
.tile 122121..
.tile ...11221
.tile .....112
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 12222222
.tile 21122222
.tile 12211222
.tile .1122112
.tile ...11221
.tile .....111
.tile .......1
.tile ........
.tile 22222221
.tile 22222112
.tile 22211211
.tile 2111211.
.tile 12211...
.tile 111.....
.tile 1.......
.tile ........
.tile 12211...
.tile 211.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ....1122
.tile ....1211
.tile ....1222
.tile ....1222
.tile ....1222
.tile ....1222
.tile ...11222
.tile .2121222
.tile 1221....
.tile 1111....
.tile 1111....
.tile 2221....
.tile 1221....
.tile 2121....
.tile 22113...
.tile 2221222.
.tile ........
.tile ........
.tile ........
.tile ........
.tile .......1
.tile .....212
.tile ...12121
.tile .2121212
.tile .......2
.tile .....222
.tile ...22222
.tile .2121212
.tile 21212121
.tile 12121212
.tile 21212121
.tile 12121212
.tile 11211122
.tile 11121211
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 1221222.
.tile 21112...
.tile 1111....
.tile 1221....
.tile 1221....
.tile 1121....
.tile 1211....
.tile 1221....
.tile 3111....
.tile 1111...1
.tile 1111.113
.tile 22211333
.tile 12213333
.tile 21213333
.tile 22113333
.tile 22213333
.tile ........
.tile 1.......
.tile 311.....
.tile 33311...
.tile 3333311.
.tile 33333331
.tile 33333331
.tile 33333111
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile 11......
.tile 11......
.tile 11212121
.tile 11121212
.tile 11111121
.tile 11111112
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 21212121
.tile 12121212
.tile 21212121
.tile 12121111
.tile 11211111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111122
.tile 11111211
.tile 11111222
.tile 11111222
.tile 11111222
.tile 11111222
.tile 111.1222
.tile 1...1222
.tile 12211333
.tile 21112113
.tile 11112221
.tile 12212221
.tile 12212221
.tile 11212221
.tile 12112221
.tile 12212221
.tile 33311222
.tile 31122122
.tile 12122211
.tile 22211121
.tile 12111222
.tile 11222122
.tile 12122212
.tile 12212221
.tile 11......
.tile 11......
.tile 21......
.tile 21......
.tile 11......
.tile 21......
.tile 21......
.tile 21......
.tile 11212121
.tile 31121212
.tile 22311121
.tile 22223112
.tile 22222231
.tile 22222222
.tile 22222222
.tile 22222222
.tile 21212121
.tile 12121212
.tile 21212121
.tile 12121111
.tile 11211111
.tile 31111111
.tile 22311111
.tile 22223111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 1111111.
.tile 11111...
.tile 111.....
.tile 1.......
.tile 1111111.
.tile 11111...
.tile 111.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile ........
.tile 12212221
.tile 11112221
.tile 11111221
.tile 2221.111
.tile 1221...1
.tile 2121....
.tile 2211....
.tile 2221....
.tile 12221221
.tile 1122211.
.tile 12111...
.tile 111.....
.tile 1.......
.tile ........
.tile ........
.tile ........
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11313111
.tile 11131111
.tile 11111111
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 11333111
.tile 11111111
.tile 13111311
.tile 13111311
.tile 11313111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11131111
.tile 11111111
.tile 11333311
.tile 13111111
.tile 13111111
.tile 11333111
.tile 11111311
.tile 11111311
.tile 13333111
.tile 11111111
.tile 13333111
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13333111
.tile 11111111
.tile 11333111
.tile 13111311
.tile 13111111
.tile 13133311
.tile 13111311
.tile 13111311
.tile 11333111
.tile 11111111
.tile 13111311
.tile 13111311
.tile 13111311
.tile 13131311
.tile 13131311
.tile 13313311
.tile 13111311
.tile 11111111
.tile 22222222
.tile 22222222
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11222222
.tile 11222222
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22221122
.tile 22221122
.tile 22112211
.tile 22112211
.tile 22112211
.tile 22112211
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22222222
.tile 22222222
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22222222
.tile 22222222
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 11222222
.tile 11222222
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22222222
.tile 22222222
.tile 11222222
.tile 11222222
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 22222222
.tile 22222222
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 11222222
.tile 11222222
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22111111
.tile 22222222
.tile 22222222
.tile 11111111
.tile 11111111
.tile 22112211
.tile 22112211
.tile 22111122
.tile 22111122
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 22111111
.tile 22111111
.tile 11111111
.tile 11111111
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11112211
.tile 11222222
.tile 11222222
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11111111
.tile 11331111
.tile 11331111
.tile 11111111
.tile 11111111
.tile 11331111
.tile 11331111
.tile 11111111
.tile 11331111
.tile 11331111
.tile 11111111
.tile 11111111
.tile 11133311
.tile 11113111
.tile 11113111
.tile 11113111
.tile 11113111
.tile 13113111
.tile 11331111
.tile 11111111
.tile 13333311
.tile 11111311
.tile 11113111
.tile 11131111
.tile 11311111
.tile 13111111
.tile 13333311
.tile 11111111
.chr 256
.tile ......33
.tile ......33
.tile .....333
.tile .....311
.tile ..333311
.tile ..333311
.tile ..33.311
.tile ..33.311
.tile 33......
.tile 33......
.tile 333.....
.tile 111.....
.tile 111.....
.tile 313.....
.tile 111.....
.tile 111.....
.tile ......33
.tile ......33
.tile .....333
.tile .....311
.tile ..333311
.tile ..333311
.tile ..33.311
.tile ..33.311
.tile 33......
.tile 33......
.tile 333.....
.tile 111.....
.tile 111.....
.tile 313.....
.tile 111.....
.tile 111.....
.tile ......33
.tile ......33
.tile .....333
.tile .....311
.tile ..333311
.tile ..333311
.tile ..33.311
.tile ..33.311
.tile 33......
.tile 33......
.tile 333.....
.tile 111.....
.tile 111.....
.tile 313.....
.tile 111.....
.tile 111.....
.tile ......33
.tile ......33
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile 33......
.tile 33......
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile ......33
.tile ......33
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile 33......
.tile 33......
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile ......33
.tile ......33
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile .....333
.tile 33......
.tile 33......
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile ......33
.tile ......33
.tile .....333
.tile .....333
.tile .3333331
.tile .3333331
.tile .333.331
.tile .333.331
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 1111....
.tile 1131....
.tile 1111....
.tile 1111....
.tile ......33
.tile ......33
.tile .....333
.tile .....333
.tile .3333331
.tile .3333331
.tile .333.331
.tile .333.331
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 1111....
.tile 1131....
.tile 1111....
.tile 1111....
.tile ..33...1
.tile ..332222
.tile ..312222
.tile ..312222
.tile ...12222
.tile ...12222
.tile ..332222
.tile ..33.333
.tile 1.......
.tile 2222....
.tile 22221...
.tile 22221...
.tile 22221...
.tile 22221...
.tile 2222333.
.tile 333.333.
.tile ..33...1
.tile ..332222
.tile ..312222
.tile ..312222
.tile ...12222
.tile ...12222
.tile ..332222
.tile ..33.333
.tile 1.......
.tile 2222....
.tile 22221...
.tile 22221...
.tile 22221...
.tile 22221...
.tile 2222333.
.tile 333.333.
.tile ..33...1
.tile ..332222
.tile ..312222
.tile ..312222
.tile ...12222
.tile ...12222
.tile ..332222
.tile ..33.333
.tile 1.......
.tile 2222....
.tile 22221...
.tile 22221...
.tile 22221...
.tile 22221...
.tile 2222333.
.tile 333.333.
.tile .....113
.tile ....2223
.tile ...12223
.tile ...12223
.tile ...12223
.tile ...12223
.tile ..332222
.tile ..33.333
.tile 331.....
.tile 3322....
.tile 33221...
.tile 33221...
.tile 33221...
.tile 33221...
.tile 2222333.
.tile 333.333.
.tile .....113
.tile ....2223
.tile ...12223
.tile ...12223
.tile ...12223
.tile ...12223
.tile ..332222
.tile ..33.333
.tile 331.....
.tile 3322....
.tile 33221...
.tile 33221...
.tile 33221...
.tile 33221...
.tile 2222333.
.tile 333.333.
.tile .....113
.tile ....2223
.tile ...12223
.tile ...12223
.tile ...12223
.tile ...12223
.tile ..332222
.tile ..33.333
.tile 331.....
.tile 3322....
.tile 33221...
.tile 33221...
.tile 33221...
.tile 33221...
.tile 2222333.
.tile 333.333.
.tile .333...1
.tile .333.222
.tile .333.222
.tile .333.222
.tile .333.222
.tile .....222
.tile .....222
.tile .....333
.tile 1.......
.tile 222.....
.tile 21113333
.tile 21113333
.tile 222.....
.tile 222.....
.tile 222.....
.tile 333.....
.tile .333...1
.tile .333.222
.tile .333.222
.tile .333.222
.tile .333.222
.tile .....222
.tile .....222
.tile .....333
.tile 1.......
.tile 222.....
.tile 21113333
.tile 21113333
.tile 222.....
.tile 222.....
.tile 222.....
.tile 333.....
.tile ....3333
.tile ....3333
.tile ....3111
.tile .....111
.tile .....111
.tile .....111
.tile ....3333
.tile ....3333
.tile 3333....
.tile 3333....
.tile .111....
.tile .111....
.tile .111....
.tile .111....
.tile .3333...
.tile .3333...
.tile ....3333
.tile ....3333
.tile ....3111
.tile .....111
.tile .....111
.tile ....3333
.tile ....3333
.tile ........
.tile 3333....
.tile 3333....
.tile .111....
.tile .111....
.tile .111....
.tile .111....
.tile .3333...
.tile .3333...
.tile ....3333
.tile ....3333
.tile ....3111
.tile .....111
.tile .....111
.tile .....111
.tile ....3333
.tile ....3333
.tile 3333....
.tile 3333....
.tile .111....
.tile .111....
.tile .111....
.tile .3333...
.tile .3333...
.tile ........
.tile .....333
.tile .....333
.tile .....111
.tile .....111
.tile .....111
.tile .....111
.tile ....3333
.tile ....3333
.tile 333.....
.tile 333.....
.tile .111....
.tile .111....
.tile .111....
.tile .111....
.tile .3333...
.tile .3333...
.tile .....333
.tile .....333
.tile .....111
.tile .....111
.tile .....111
.tile .....111
.tile ....3333
.tile ....3333
.tile 333.....
.tile 333.....
.tile .111....
.tile .111....
.tile .111....
.tile .3333...
.tile .3333...
.tile ........
.tile .....333
.tile .....333
.tile .....111
.tile .....111
.tile .....111
.tile ....3333
.tile ....3333
.tile ........
.tile 333.....
.tile 333.....
.tile .111....
.tile .111....
.tile .111....
.tile .111....
.tile .3333...
.tile .3333...
.tile .....333
.tile .....333
.tile ......11
.tile ......11
.tile ......11
.tile ......11
.tile .....333
.tile .....333
.tile 333.....
.tile 333.....
.tile 11......
.tile 11......
.tile 11......
.tile 11......
.tile 333.....
.tile 333.....
.tile .....333
.tile .....333
.tile ....111.
.tile ....111.
.tile ....111.
.tile ....111.
.tile ...3333.
.tile ...3333.
.tile 333.....
.tile 333.....
.tile ..111...
.tile ..111...
.tile ..111...
.tile ..3333..
.tile ..3333..
.tile ........
.tile ......33
.tile ......33
.tile .....333
.tile .....333
.tile .3333331
.tile .3333331
.tile .333.331
.tile .333.331
.tile 333.....
.tile 333.....
.tile 333.....
.tile 333.....
.tile 1111....
.tile 1131....
.tile 1111....
.tile 1111....
.chr 320
.tile .333...1
.tile .333.222
.tile .333.222
.tile .333.222
.tile .333.222
.tile .....222
.tile .....222
.tile .....333
.tile 1.......
.tile 222.....
.tile 21113333
.tile 21113333
.tile 222.....
.tile 222.....
.tile 222.....
.tile 333.....
.chr 336
.tile .....333
.tile .....333
.tile ....111.
.tile ....111.
.tile ....111.
.tile ...3333.
.tile ...3333.
.tile ........
.tile 333.....
.tile 333.....
.tile ..111...
.tile ..111...
.tile ..111...
.tile ..111...
.tile ..3333..
.tile ..3333..
.chr 352
.tile ........
.tile .....111
.tile ...11111
.tile ..111111
.tile ...11111
.tile .....111
.tile ........
.tile ........
.tile ........
.tile 111.....
.tile 11111...
.tile 111111..
.tile 11111...
.tile 111.....
.tile ........
.tile ........
.tile ........
.tile ........
.tile ...2....
.tile ..233...
.tile ...332..
.tile ....2...
.tile ........
.tile ........
.chr 368
.tile ........
.tile ........
.tile .1......
.tile .11.....
.tile .111..1.
.tile .111...1
.tile .1111..3
.tile .11111.1
.tile ........
.tile ........
.tile ......1.
.tile .....11.
.tile .1..111.
.tile 1...111.
.tile 3..1111.
.tile 1.11111.
.tile ........
.tile ........
.tile ........
.tile ........
.tile ......1.
.tile .......1
.tile .......3
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile .1......
.tile 1.......
.tile 3.......
.tile 1.......
.tile ........
.tile ........
.tile .2......
.tile .222....
.tile .222....
.tile ...11112
.tile ...22222
.tile ...22222
.tile ........
.tile ........
.tile ....12..
.tile ...2222.
.tile ...2232.
.tile 22222222
.tile 22222221
.tile 22222222
.tile ........
.tile ........
.tile .2......
.tile .222....
.tile .222....
.tile ...11112
.tile ...22222
.tile ...22222
.tile ........
.tile ........
.tile ....12..
.tile ...2222.
.tile ...2232.
.tile 22222222
.tile 22222221
.tile 22222222
.tile ........
.tile ........
.tile ...1111.
.tile ..133221
.tile ..121121
.tile ..121121
.tile ..122222
.tile ...11122
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1.......
.tile 21......
.tile ........
.tile ........
.tile ......11
.tile .......1
.tile ...11111
.tile ...13333
.tile ...13332
.tile ...13332
.tile ........
.tile ........
.tile 11......
.tile 1.......
.tile 11111...
.tile 33331...
.tile 23331...
.tile 23331...
.tile ......11
.tile .....122
.tile .....123
.tile .....123
.tile .....122
.tile ......12
.tile ...11113
.tile ..123222
.tile 11......
.tile 221.....
.tile 321.....
.tile 321.....
.tile 221.....
.tile 21......
.tile 21111...
.tile 222321..
.chr 384
.tile .1211111
.tile .1122111
.tile ...11211
.tile .....111
.tile ........
.tile ........
.tile ........
.tile ........
.tile 1111121.
.tile 1112211.
.tile 11211...
.tile 111.....
.tile ........
.tile ........
.tile ........
.tile ........
.tile .....111
.tile ...11211
.tile .1122111
.tile .1211..1
.tile .11.....
.tile ........
.tile ........
.tile ........
.tile 111.....
.tile 11211...
.tile 1112211.
.tile 1..1121.
.tile .....11.
.tile ........
.tile ........
.tile ........
.tile ...22222
.tile ...11111
.tile ...11111
.tile ....1122
.tile ....1122
.tile ....1122
.tile ....11..
.tile ........
.tile 2222222.
.tile 1111....
.tile 1111....
.tile .1122...
.tile .1122...
.tile .1122...
.tile ...22...
.tile ........
.tile ...22222
.tile ...11111
.tile ...11111
.tile ....1122
.tile ....1122
.tile ....1122
.tile ......22
.tile ........
.tile 2222222.
.tile 1111....
.tile 1111....
.tile .1122...
.tile .1122...
.tile .1122...
.tile .11.....
.tile ........
.tile ......12
.tile .......1
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile ........
.tile 221.....
.tile 2221....
.tile 12221...
.tile .12221..
.tile 1333321.
.tile .113321.
.tile ...111..
.tile ........
.tile ...13222
.tile ...13332
.tile ...13332
.tile ...13333
.tile ...11111
.tile ........
.tile ........
.tile ........
.tile 22231...
.tile 23331...
.tile 23331...
.tile 33331...
.tile 11111...
.tile ........
.tile ........
.tile ........
.tile ..122222
.tile ...11113
.tile ......12
.tile ......12
.tile ......12
.tile ......12
.tile .....122
.tile ......11
.tile 222221..
.tile 21111...
.tile 21......
.tile 21......
.tile 21......
.tile 21......
.tile 221.....
.tile 11......
; </GFX>
