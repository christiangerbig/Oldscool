; #################################
; # Programm: old'scool-intro.asm #
; # Autor:    Christian Gerbig    #
; # Datum:    10.07.2023          #
; # Version:  1.0 beta            #
; # CPU:      68020+              #
; # FASTMEM:  -                   #
; # Chipset:  AGA                 #
; # OS:       3.0+                #
; #################################

; Version 1.0 beta

; Ausführungszeit 68020: n Rasterzeilen

  SECTION code_and_variables,CODE

  MC68040


; ** Library-Includes V.3.x nachladen **
; --------------------------------------
  INCDIR "Daten:include3.5/"

  INCLUDE "exec/exec.i"
  INCLUDE "exec/exec_lib.i"

  INCLUDE "dos/dos.i"
  INCLUDE "dos/dos_lib.i"
  INCLUDE "dos/dosextens.i"

  INCLUDE "graphics/gfxbase.i"
  INCLUDE "graphics/graphics_lib.i"
  INCLUDE "graphics/videocontrol.i"

  INCLUDE "intuition/intuition.i"
  INCLUDE "intuition/intuition_lib.i"

  INCLUDE "libraries/any_lib.i"

  INCLUDE "resources/cia_lib.i"

  INCLUDE "hardware/adkbits.i"
  INCLUDE "hardware/blit.i"
  INCLUDE "hardware/cia.i"
  INCLUDE "hardware/custom.i"
  INCLUDE "hardware/dmabits.i"
  INCLUDE "hardware/intbits.i"

  INCDIR "Daten:Asm-Sources.AGA/normsource-includes/"


; ** Konstanten **
; ----------------

  INCLUDE "equals.i"

requires_68030           EQU FALSE  
requires_68040           EQU FALSE
requires_68060           EQU FALSE
requires_fast_memory     EQU FALSE
requires_multiscan_monitor EQU FALSE

workbench_start_enabled  EQU FALSE
workbench_fade_enabled         EQU FALSE
text_output_enabled      EQU FALSE

pt_v3.0b
pt_ciatiming_enabled     EQU TRUE
pt_usedfx                EQU %1111010001011001
pt_usedefx               EQU %0000100000000000
pt_finetune_enabled      EQU FALSE
  IFD pt_v3.0b
pt_metronome_enabled     EQU FALSE
  ENDC
pt_track_volumes_enabled   EQU FALSE
pt_track_periods_enabled        EQU FALSE
pt_music_fader_enabled   EQU TRUE
pt_split_module_enabled     EQU TRUE

dma_bits                 EQU DMAF_COPPER+DMAF_MASTER+DMAF_SETCLR

  IFEQ pt_ciatiming_enabled
intena_bits              EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ELSE
intena_bits              EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ENDC

ciaa_icr_bits            EQU CIAICRF_SETCLR
  IFEQ pt_ciatiming_enabled
ciab_icr_bits            EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
  ELSE
ciab_icr_bits            EQU CIAICRF_TB+CIAICRF_SETCLR
  ENDC

copcon_bits              EQU 0

pf1_x_size1              EQU 0
pf1_y_size1              EQU 0
pf1_depth1               EQU 0
pf1_x_size2              EQU 0
pf1_y_size2              EQU 0
pf1_depth2               EQU 0
pf1_x_size3              EQU 0
pf1_y_size3              EQU 0
pf1_depth3               EQU 0
pf1_colors_number        EQU 0 ;1

pf2_x_size1              EQU 0
pf2_y_size1              EQU 0
pf2_depth1               EQU 0
pf2_x_size2              EQU 0
pf2_y_size2              EQU 0
pf2_depth2               EQU 0
pf2_x_size3              EQU 0
pf2_y_size3              EQU 0
pf2_depth3               EQU 0
pf2_colors_number        EQU 0
pf_colors_number         EQU pf1_colors_number+pf2_colors_number
pf_depth                 EQU pf1_depth3+pf2_depth3

extra_pf_number          EQU 0

spr_number               EQU 0
spr_x_size1              EQU 0
spr_y_size1              EQU 0
spr_x_size2              EQU 0
spr_y_size2              EQU 0
spr_depth                EQU 0
spr_colors_number        EQU 0

  IFD pt_v2.3a
audio_memory_size               EQU 0
  ENDC
  IFD pt_v3.0b
audio_memory_size               EQU 2
  ENDC

disk_memory_size                EQU 0

extra_memory_size           EQU 0

chip_memory_size            EQU 0
  IFEQ pt_ciatiming_enabled
ciab_cra_bits            EQU CIACRBF_LOAD
  ENDC
ciab_crb_bits            EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
ciaa_ta_time            EQU 0
ciaa_tb_time            EQU 0
  IFEQ pt_ciatiming_enabled
ciab_ta_time            EQU 14187 ;= 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;ciab_ta_time            EQU 14318 ;= 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
  ELSE
ciab_ta_time            EQU 0
  ENDC
ciab_tb_time            EQU 362 ;= 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled       EQU FALSE
ciaa_tb_continuous_enabled       EQU FALSE
  IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled       EQU TRUE
  ELSE
ciab_ta_continuous_enabled       EQU FALSE
  ENDC
ciab_tb_continuous_enabled       EQU FALSE

beam_position            EQU $136

bplcon0_bits             EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0) 
bplcon3_bits1            EQU 0
bplcon3_bits2            EQU bplcon3_bits1+BPLCON3F_LOCT
bplcon4_bits             EQU 0
color00_bits             EQU $001122

cl1_hstart               EQU $00
cl1_vstart               EQU beam_position&$ff

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC

  IFEQ pt_music_fader_enabled
pt_fade_out_delay        EQU 2 ;Ticks
  ENDC



; ** Struktur, die alle Exception-Vektoren-Offsets enthält **
; -----------------------------------------------------------

  INCLUDE "except-vectors-offsets.i"


; ** Struktur, die alle Eigenschaften des Extra-Playfields enthält **
; -------------------------------------------------------------------

  INCLUDE "extra-pf-attributes-structure.i"


; ** Struktur, die alle Eigenschaften der Sprites enthält **
; ----------------------------------------------------------

  INCLUDE "sprite-attributes-structure.i"


; ** Struktur, die alle Registeroffsets der ersten Copperliste enthält **
; -----------------------------------------------------------------------
  RSRESET

cl1_begin        RS.B 0

  INCLUDE "copperlist1-offsets.i"

cl1_BPLCON3_2    RS.L 1
cl1_WAIT1        RS.L 1
cl1_WAIT2        RS.L 1
cl1_INTREQ       RS.L 1

cl1_end          RS.L 1

copperlist1_SIZE RS.B 0


; ** Struktur, die alle Registeroffsets der zweiten Copperliste enthält **
; ------------------------------------------------------------------------
  RSRESET

cl2_begin        RS.B 0

cl2_end          RS.L 1

copperlist2_SIZE RS.B 0


; ** Konstanten für die größe der Copperlisten **
; -----------------------------------------------
cl1_size1        EQU 0
cl1_size2        EQU 0
cl1_size3        EQU copperlist1_SIZE
cl2_size1        EQU 0
cl2_size2        EQU 0
cl2_size3        EQU copperlist2_SIZE

; ** Konstanten für die Größe der Spritestrukturen **
; ---------------------------------------------------
spr0_x_size1     EQU spr_x_size1
spr0_y_size1     EQU 0
spr1_x_size1     EQU spr_x_size1
spr1_y_size1     EQU 0
spr2_x_size1     EQU spr_x_size1
spr2_y_size1     EQU 0
spr3_x_size1     EQU spr_x_size1
spr3_y_size1     EQU 0
spr4_x_size1     EQU spr_x_size1
spr4_y_size1     EQU 0
spr5_x_size1     EQU spr_x_size1
spr5_y_size1     EQU 0
spr6_x_size1     EQU spr_x_size1
spr6_y_size1     EQU 0
spr7_x_size1     EQU spr_x_size1
spr7_y_size1     EQU 0

spr0_x_size2     EQU spr_x_size2
spr0_y_size2     EQU 0
spr1_x_size2     EQU spr_x_size2
spr1_y_size2     EQU 0
spr2_x_size2     EQU spr_x_size2
spr2_y_size2     EQU 0
spr3_x_size2     EQU spr_x_size2
spr3_y_size2     EQU 0
spr4_x_size2     EQU spr_x_size2
spr4_y_size2     EQU 0
spr5_x_size2     EQU spr_x_size2
spr5_y_size2     EQU 0
spr6_x_size2     EQU spr_x_size2
spr6_y_size2     EQU 0
spr7_x_size2     EQU spr_x_size2
spr7_y_size2     EQU 0

; ** Struktur, die alle Variablenoffsets enthält **
; -------------------------------------------------

  INCLUDE "variables-offsets.i"

; ** Relative offsets for variables **
; ------------------------------------

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-variables-offsets.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-variables-offsets.i"
  ENDC

variables_size RS.B 0


; **** PT-Replay ****
; ** PT-Song-Structure **
; -----------------------
  INCLUDE "music-tracker/pt-song-structure.i"

; ** Temporary channel structure **
; ---------------------------------
  INCLUDE "music-tracker/pt-temp-channel-structure.i"


; ## Makrobefehle ##
; ------------------

  INCLUDE "macros.i"


  INCLUDE "sys-wrapper.i"

; ** Eigene Variablen initialisieren **
; -------------------------------------
  CNOP 0,4
init_own_variables

; **** PT-Replay ****
  IFD pt_v2.3a
    PT2_INIT_VARIABLES
  ENDC
  IFD pt_v3.0b
    PT3_INIT_VARIABLES
  ENDC
  rts

; ** Alle Initialisierungsroutinen ausführen **
; ---------------------------------------------
  CNOP 0,4
init_all
  bsr.s   pt_DetectSysFrequ
  bsr.s   init_CIA_timers
  bsr.s   init_color_registers
  bsr     pt_InitRegisters
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  IFEQ pt_finetune_enabled
    bsr     pt_InitFtuPeriodTableStarts
  ENDC
  bsr     init_first_copperlist
  bra     init_second_copperlist

; ** Detect system frequency NTSC/PAL **
; --------------------------------------
  PT_DETECT_SYS_FREQUENCY

; ** CIA-Timer initialisieren **
; ------------------------------
  CNOP 0,4
init_CIA_timers
  PT_INIT_TIMERS
  rts

; ** Farbregister initialisieren **
; ---------------------------------
  CNOP 0,4
init_color_registers
  CPU_SELECT_COLOR_HIGH_BANK 0
  CPU_INIT_COLOR_HIGH COLOR00,1,pf1_color_table

  CPU_SELECT_COLOR_LOW_BANK 0
  CPU_INIT_COLOR_LOW COLOR00,1,pf1_color_table
  rts

; ** Audioregister initialisieren **
; ----------------------------------
   PT_INIT_REGISTERS

; ** Temporäre Audio-Kanal-Struktur initialisieren **
; ---------------------------------------------------
   PT_INIT_AUDIO_TEMP_STRUCTURES

; ** Höchstes Pattern ermitteln und Tabelle mit Zeigern auf Samples initialisieren **
; -----------------------------------------------------------------------------------
   PT_EXAMINE_SONG_STRUCTURE

  IFEQ pt_finetune_enabled
; ** FineTuning-Offset-Tabelle initialisieren **
; ----------------------------------------------
    PT_INIT_FINETUNING_PERIOD_TABLE_STARTS
  ENDC


; ** 1. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_first_copperlist
  move.l  cl1_display(a3),a0 ;Darstellen-CL
  bsr.s   cl1_init_playfield_registers
  bsr     cl1_init_copper_interrupt
  COP_LISTEND
  rts

  COP_INIT_PLAYFIELD_REGISTERS cl1,BLANK

  COP_INIT_COPINT cl1,cl1_HSTART,cl1_VSTART,YWRAP

; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_display(a3),a0 ;Darstellen-CL
  COP_LISTEND
  rts


; ## Hauptprogramm ##
; -------------------
; a3 ... Basisadresse aller Variablen
; a4 ... CIA-A-Base
; a5 ... CIA-B-Base
; a6 ... DMACONR
  CNOP 0,4
main_routine
  bsr.s   no_sync_routines
  bra.s   beam_routines


; ## Routinen, die nicht mit der Bildwiederholfrequenz gekoppelt sind ##
; ----------------------------------------------------------------------
  CNOP 0,4
no_sync_routines
  rts


; ## Rasterstahl-Routinen ##
; --------------------------
  CNOP 0,4
beam_routines
  bsr     wait_copint
  IFEQ pt_music_fader_enabled
    bsr.s   pt_mouse_handler
  ENDC
  btst    #CIAB_GAMEPORT0,CIAPRA(a4) ;Auf linke Maustaste warten
  bne.s   beam_routines
  rts

  IFEQ pt_music_fader_enabled
; ** Mouse-Handler **
; -------------------
    CNOP 0,4
pt_mouse_handler
    btst    #POTINPB_DATLY,POTINP-DMACONR(a6) ;Rechte Mustaste gedrückt?
    bne.s   pt_no_mouse_handler ;Nein -> verzweige
    clr.w   pt_fade_out_music_active(a3) ;Fader an
pt_no_mouse_handler
    rts
  ENDC


; ## Interrupt-Routinen ##
; ------------------------
  
  INCLUDE "int-autovectors-handlers.i"

  IFEQ pt_ciatiming_enabled
; ** CIA-B timer A interrupt server **
; ------------------------------------
  CNOP 0,4
ciab_ta_int_server
  ENDC

  IFNE pt_ciatiming_enabled
; ** Vertical blank interrupt server **
; -------------------------------------
  CNOP 0,4
VERTB_int_server
  ENDC

  IFEQ pt_music_fader_enabled
    bsr.s   pt_fade_out_music
    bra.s   pt_PlayMusic

; ** Musik ausblenden **
; ----------------------
  PT_FADE_OUT

  ENDC

; ** PT-replay routine **
; -----------------------
  IFEQ pt_music_fader_enabled
    CNOP 0,4
  ENDC
  IFD pt_v2.3a
    PT2_REPLAY
  ENDC
  IFD pt_v3.0b
    PT3_REPLAY
  ENDC

; ** CIA-B Timer B interrupt server **
  CNOP 0,4
ciab_tb_int_server
  PT_TIMER_INTERRUPT_SERVER

; ** Level-6-Interrupt-Server **
; ------------------------------
  CNOP 0,4
EXTER_int_server
  rts

; ** Level-7-Interrupt-Server **
; ------------------------------
  CNOP 0,4
NMI_int_server
  rts


; ## Hilfsroutinen ##
; -------------------

  INCLUDE "help-routines.i"


; ## Speicherstellen für Tabellen und Strukturen ##
; -------------------------------------------------

  INCLUDE "sys-structures.i"

; ** Farben des ersten Playfields **
; ----------------------------------
  CNOP 0,4
pf1_color_table
  DC.L color00_bits

; ** Tables for effect commands **
; --------------------------------
; ** "Invert Loop" **
  INCLUDE "music-tracker/pt-invert-table.i"

; ** "Vibrato/Tremolo" **
  INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

; ** "Arpeggio/Tone Portamento" **
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-period-table.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-period-table.i"
  ENDC

; ** Temporary channel structures **
; ----------------------------------
  INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

; ** Pointers to samples **
; -------------------------
  INCLUDE "music-tracker/pt-sample-starts-table.i"

; ** Pointers to priod tables for different tuning **
; ---------------------------------------------------
  INCLUDE "music-tracker/pt-finetune-starts-table.i"


; ## Speicherstellen allgemein ##
; -------------------------------

  INCLUDE "sys-variables.i"


; ## Speicherstellen für Namen ##
; -------------------------------

  INCLUDE "sys-names.i"


; ## Speicherstellen für Texte ##
; -------------------------------

  INCLUDE "error-texts.i"

; ** Programmversion für Version-Befehl **
; ----------------------------------------
program_version DC.B "$VER: old'scool-intro 1.0 beta (10.7.23)",TRUE
  EVEN


; ## Audiodaten nachladen ##
; --------------------------

; **** PT-Replay ****
  IFNE pt_split_module_enabled
pt_auddata SECTION audio,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/old'scool-intro/module/mod.ClassicTune14remix"
  ELSE
pt_auddata SECTION audio,DATA
    INCBIN "Daten:Asm-Sources.AGA/old'scool-intro/module/MOD.ClassicTune14Remix.song"

pt_audsmps SECTION audio2,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/old'scool-intro/module/MOD.ClassicTune14Remix.smps"
  ENDC

  END
