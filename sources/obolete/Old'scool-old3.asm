; ##############################
; # Programm: Old'scool.asm    #
; # Autor:    Christian Gerbig #
; # Datum:    31.08.2023       #
; # Version:  1.0              #
; # CPU:      68020+           #
; # FASTMEM:  -                #
; # Chipset:  AGA              #
; # OS:       3.0+             #
; ##############################

; V.1.0 beta
; - Erstes Release

; V.1.1 beta
; - Mit aktueller Greetings-List

; V.1.2 beta
; - Optimierung der Copperlist2. Wenn kein Rotator/Zoomer dargestellt wird, dann
;   wird kein BPLCON4-Chunky-Screen dargestellt und die CPU entlastet, da der
;   Copper weniger Memory-Slots bei nur 2 CMOVEs ben�tigt
; - Die Credits werden jetzt durch das Modul getriggert
; - Umstellung auf VERTB main loop
; - Mit Grass' Titelbild in 64 Farben

; V.1.3 beta
; - Mit Grass' Zoomer/Rotator-Textur
; - W�rfelfarbe and Textur angepasst und Maximalwertpr�fung bei Helligkeit des
;   W�rfels
; - ge�nderte Schrift
; - Mit �berarbeitetem Titelbild in 128 Farben
; - Bugfix: Low-Farbwerte des Zoomers wurden falsch initislidiert

; V.1.4 beta
; - W�rfelfarbe an Textur abgepasst, da W�rfel zu dunkel
; - Mit Grass# Font

; V.1.5 beta
; - Mit Ber�cksichtigung vorzeitiger Ausstieg des Users
; - WB-Start
; - Befehl 870/71 -> 860/61
; - F1 roter Rahmen, F2 = gr�ner Rahmen, F3 = blauer Rahmen

; V.1.6 beta
; - Alle States, die mit not.w gesetzt werden durch move.w ersetzt
; - Bugfix: Delay f�r Tastatur l�uft jetzt �ber CIA-A Timer-B, da Timer-A
;   von der Tastatur benutzt wird. Jetzt ist auch vom Freezer eine R�ckkehr
;   ohne Fehler m�glich

; V.1.7 beta
; - Keyboard-Handler: Handshake-Delay auf 200 �s hochgesetzt und es wird keine
;   Tastaturleitung mehr manuell gesetzt. Die passiert automatisch beim Wechsel
;   von SP input -> SP output -> SP input laut Toni Wilen

; V.1.8 beta
; - Code optimiert
; - Bugfix: Nach dem Einblenden wurde f�lschlicherweise der Title-Part
;           deaktiviert und bei einem vozeitigen User-Abbruch das Titelbild
;           nicht mehr ausgeblendet

; V.1.0
; - Endversion
; - Code optimiert
; - Mit �berarbeitetem Tracker-Modul
; - Bugfix: Bitplane-DMA wird nur f�r das Intro und den Title-Screen aktiviert,
;   um die Anzeige von Datenm�ll im Hauptteil zu Brginn zu vermeiden
; - Image-Fader: Abfrage der RGB-Werte beim Vergleich verfeinert. ble -> bls
; - Rotationen 1-10 ge�ndert damit die Unterschiede offensichtlicher sind
; - Modul leicht ge�ndert

; PT 8xy-Befehl
; 800 Restart intro
; 810 Enable horizontal scrolltext
; 820 Fade title in
; 830 Fade title out
; 840 Fade in rotation zoomer
; 850 Zoom cube in
; 860 Enable zoomer
; 861 Disable zoomer

; Ausf�hrungszeit 68020: 231 Rasterzeilen

  SECTION code_and_variables,CODE

  MC68040


; ** Library-Includes V.3.x nachladen **
; --------------------------------------
  ;INCDIR  "OMA:include/"
  INCDIR "Daten:include3.5/"

  INCLUDE "dos/dos.i"
  INCLUDE "dos/dosextens.i"
  INCLUDE "libraries/dos_lib.i"

  INCLUDE "exec/exec.i"
  INCLUDE "exec/exec_lib.i"

  INCLUDE "graphics/GFXBase.i"
  INCLUDE "graphics/videocontrol.i"
  INCLUDE "graphics/graphics_lib.i"

  INCLUDE "intuition/intuition.i"
  INCLUDE "intuition/intuition_lib.i"

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

requires_68030                  EQU FALSE
requires_68040                  EQU FALSE
requires_68060                  EQU FALSE
requires_fast_memory            EQU FALSE
requires_multiscan_monitor      EQU FALSE

workbench_start_enabled EQU FALSE
workbench_fade_enabled          EQU TRUE
text_output_enabled     EQU FALSE

pt_v3.0b
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC
pt_ciatiming_enabled    EQU TRUE
pt_usedfx                       EQU %1111010101011001
pt_usedefx                      EQU %0000100000000000
pt_finetune_enabled     EQU FALSE
  IFD pt_v3.0b
pt_metronome_enabled    EQU FALSE
  ENDC
pt_track_volumes_enabled        EQU FALSE
pt_track_periods_enabled        EQU FALSE
pt_music_fader_enabled  EQU TRUE
pt_split_module_enabled EQU TRUE

open_border_enabled     EQU TRUE
rz_table_length_256             EQU FALSE
bv_EpRGB_check_max_enabled      EQU TRUE

DMABITS                         EQU DMAF_BLITTER+DMAF_SPRITE+DMAF_COPPER+DMAF_RASTER+DMAF_MASTER+DMAF_SETCLR
  IFEQ pt_ciatiming_enabled
INTENABITS                      EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ELSE                             
INTENABITS                      EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ENDC

CIAAICRBITS EQU CIAICRF_SETCLR
  IFEQ pt_ciatiming_enabled
CIABICRBITS                     EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
  ELSE
CIABICRBITS                     EQU CIAICRF_TB+CIAICRF_SETCLR
  ENDC

COPCONBITS                     EQU 0

pf1_x_size1                     EQU 0
pf1_y_size1                     EQU 0
pf1_depth1                      EQU 0
pf1_x_size2                     EQU 0
pf1_y_size2                     EQU 0
pf1_depth2                      EQU 0
pf1_x_size3                     EQU 320
pf1_y_size3                     EQU 256
pf1_depth3                      EQU 7
pf1_colors_number               EQU 128

pf2_x_size1                     EQU 0
pf2_y_size1                     EQU 0
pf2_depth1                      EQU 0
pf2_x_size2                     EQU 0
pf2_y_size2                     EQU 0
pf2_depth2                      EQU 0
pf2_x_size3                     EQU 0
pf2_y_size3                     EQU 0
pf2_depth3                      EQU 0
pf2_colors_number               EQU 0
pf_colors_number                EQU pf1_colors_number+pf2_colors_number
pf_depth                        EQU pf1_depth3+pf2_depth3

extra_pf_number                 EQU 3
extra_pf1_x_size                EQU 128
extra_pf1_y_size                EQU 128
extra_pf1_depth                 EQU 2
extra_pf2_x_size                EQU 128
extra_pf2_y_size                EQU 128
extra_pf2_depth                 EQU 2
extra_pf3_x_size                EQU 128
extra_pf3_y_size                EQU 128
extra_pf3_depth                 EQU 2

spr_number                      EQU 8
spr_x_size1                     EQU 64
spr_x_size2                     EQU 64
spr_depth                       EQU 2
spr_colors_number               EQU 16
spr_odd_color_table_select      EQU 8
spr_even_color_table_select     EQU 8
spr_used_number                 EQU 6
spr_swap_number                 EQU 2

  IFD pt_v2.3a
audio_memory_size               EQU 0
  ENDC
  IFD pt_v3.0b
audio_memory_size               EQU 2
  ENDC

disk_memory_size                EQU 0

chip_memory_size                EQU 0
CIAACRBBITS                     EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;oneshot
  IFEQ pt_ciatiming_enabled
CIABCRABITS                     EQU CIACRBF_LOAD
  ENDC
CIABCRBBITS                     EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
CIAA_TA_time                   EQU 0
CIAA_TB_time                   EQU 142 ;0.709379 MHz * 200 �s
  IFEQ pt_ciatiming_enabled
CIAB_TA_time                   EQU 14187 ;= 0.709379 MHz * [20000 �s = 50 Hz duration for one frame on a PAL machine]
;CIAB_TA_time                   EQU 14318 ;= 0.715909 MHz * [20000 �s = 50 Hz duration for one frame on a NTSC machine]
  ELSE
CIAB_TA_time                   EQU 0
  ENDC
CIAB_TB_time                   EQU 362 ;= 0.709379 MHz * [511.43 �s = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                        ;= 0.715909 MHz * [506.76 �s = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
CIAA_TA_continuous_enabled      EQU FALSE
CIAA_TB_continuous_enabled      EQU FALSE
  IFEQ pt_ciatiming_enabled
CIAB_TA_continuous_enabled      EQU TRUE
  ELSE
CIAB_TA_continuous_enabled      EQU FALSE
  ENDC
CIAB_TB_continuous_enabled      EQU FALSE

beam_position                   EQU VSTOP_256_lines

pixel_per_line                  EQU 320
visible_pixels_number           EQU 320
visible_lines_number            EQU 256
MINROW                          EQU VSTART_256_lines

pf_pixel_per_datafetch          EQU 64 ;4x
DDFSTRTBITS                     EQU DDFSTART_320_pixel
DDFSTOPBITS                     EQU DDFSTOP_320_pixel_4x
spr_pixel_per_datafetch         EQU 64 ;4x

display_window_HSTART           EQU HSTART_320_pixel
display_window_VSTART           EQU MINROW
DIWSTRTBITS                     EQU ((display_window_VSTART&$ff)*DIWSTRTF_V0)+(display_window_HSTART&$ff)
display_window_HSTOP            EQU HSTOP_320_pixel
display_window_VSTOP            EQU VSTOP_256_lines
DIWSTOPBITS                     EQU ((display_window_VSTOP&$ff)*DIWSTOPF_V0)+(display_window_HSTOP&$ff)

pf1_plane_width                 EQU pf1_x_size3/8
data_fetch_width                EQU pixel_per_line/8
pf1_plane_moduli                EQU (pf1_plane_width*(pf1_depth3-1))+pf1_plane_width-data_fetch_width
extra_pf1_plane_width           EQU extra_pf1_x_size/8
extra_pf2_plane_width           EQU extra_pf2_x_size/8
extra_pf3_plane_width           EQU extra_pf3_x_size/8

BPLCON0BITS                     EQU BPLCON0F_ECSENA+BPLCON0F_COLOR
BPLCON0BITS2                    EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0) ;lores
BPLCON1BITS                     EQU 0
BPLCON2BITS                    EQU 0
BPLCON3BITS1                    EQU BPLCON3F_SPRES0
BPLCON3BITS2                    EQU BPLCON3BITS1+BPLCON3F_LOCT
BPLCON4BITS                     EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)+(BPLCON4F_ESPRM4*spr_even_color_table_select)
DIWHIGHBITS                 EQU DIWHIGHF_HSTOP1+(((display_window_HSTOP&$100)>>8)*DIWHIGHF_HSTOP8)+(((display_window_VSTOP&$700)>>8)*DIWHIGHF_VSTOP8)+DIWHIGHF_HSTART1+(((display_window_HSTART&$100)>>8)*DIWHIGHF_HSTART8)+((display_window_VSTART&$700)>>8)
FMODEBITS                       EQU FMODEF_BPL32+FMODEF_BPAGEM+FMODEF_SPR32+FMODEF_SPAGEM
COLOR00BITS                     EQU $090909

rz_display_y_scale_factor       EQU 4

cl2_display_x_size              EQU visible_pixels_number+8
cl2_display_width               EQU cl2_display_x_size/8
cl2_display_y_size              EQU visible_lines_number/rz_display_y_scale_factor
  IFNE open_border_enabled
cl1_HSTART1                     EQU display_window_HSTART-(7*CMOVE_slot_period)
  ELSE
cl1_HSTART1                     EQU display_window_HSTART-(8*CMOVE_slot_period)
  ENDC
cl1_VSTART1                     EQU MINROW
cl1_HSTART2                     EQU $00
cl1_VSTART2                     EQU beam_position&$ff

sine_table_length               EQU 512

; **** Background-Image ****
bg_image_x_size                 EQU 320
bg_image_plane_width            EQU bg_image_x_size/8
bg_image_y_size                 EQU 256
bg_image_depth                  EQU 7
bg_image_colors_number          EQU 128

; **** PT-Replay ****
pt_fade_out_delay               EQU 2 ;Ticks

; **** Rotation-Zoomer ****
rz_image_x_size                 EQU 256
rz_image_plane_width            EQU rz_image_x_size/8
rz_image_y_size                 EQU 256
rz_image_depth                  EQU 7

rz_Ax                           EQU -40
rz_Ay                           EQU -32
rz_Bx                           EQU  40
rz_By                           EQU -32

rz_z_rotation_x_center          EQU rz_image_x_size/2
rz_z_rotation_y_center          EQU rz_image_y_size/2
rz_z_rotation_angle_speed       EQU 3

rz_d                            EQU 220
rz_zoom_radius                  EQU 1024
rz_zoom_center                  EQU 1024+rz_d
rz_zoom_angle_speed             EQU 1

; **** Wave-Scrolltext ****
wst_used_sprites_number         EQU 6

wst_image_x_size                EQU 640
wst_image_plane_width           EQU wst_image_x_size/8
wst_image_depth                 EQU 2

wst_origin_character_x_size     EQU 64
wst_origin_character_y_size     EQU 56
wst_origin_character_depth      EQU wst_image_depth

wst_text_character_x_size       EQU wst_origin_character_x_size
wst_text_character_width        EQU wst_text_character_x_size/8
wst_text_character_y_size       EQU wst_origin_character_y_size
wst_text_character_depth        EQU wst_image_depth

wst_horiz_scroll_window_x_size  EQU visible_pixels_number+wst_text_character_x_size
wst_horiz_scroll_window_width   EQU wst_horiz_scroll_window_x_size/8
wst_horiz_scroll_window_y_size  EQU wst_text_character_y_size
wst_horiz_scroll_window_depth   EQU wst_text_character_depth
wst_horiz_scroll_speed          EQU 12
wst_horiz_scroll_speed_slow     EQU 10
wst_horiz_scroll_speed_fast     EQU 17

wst_text_character_x_restart    EQU wst_horiz_scroll_window_x_size*4 ;*4 da superhires Pixel
wst_text_characters_number      EQU wst_horiz_scroll_window_x_size/wst_text_character_x_size

wst_y_radius                    EQU (visible_lines_number-wst_text_character_y_size)/2
wst_y_center                    EQU ((visible_lines_number-wst_text_character_y_size)/2)+display_window_VSTART
wst_y_angle_speed               EQU 5
wst_y_angle_step                EQU sine_table_length/wst_text_characters_number

; **** Blenk-Vectors ****
bv_rotation_d                   EQU 256
bv_rotation_xy_center           EQU extra_pf2_x_size/2
bv_rotation_x_angle_speed1      EQU 4
bv_rotation_y_angle_speed1      EQU 2
bv_rotation_z_angle_speed1      EQU 6

bv_rotation_x_angle_speed2      EQU -2
bv_rotation_y_angle_speed2      EQU -3
bv_rotation_z_angle_speed2      EQU -1

bv_rotation_x_angle_speed3      EQU 0
bv_rotation_y_angle_speed3      EQU 1
bv_rotation_z_angle_speed3      EQU 4

bv_rotation_x_angle_speed4      EQU -7
bv_rotation_y_angle_speed4      EQU -4
bv_rotation_z_angle_speed4      EQU -2

bv_rotation_x_angle_speed5      EQU 2
bv_rotation_y_angle_speed5      EQU 0
bv_rotation_z_angle_speed5      EQU 5

bv_rotation_x_angle_speed6      EQU 0
bv_rotation_y_angle_speed6      EQU -6
bv_rotation_z_angle_speed6      EQU -4

bv_rotation_x_angle_speed7      EQU 4
bv_rotation_y_angle_speed7      EQU 0
bv_rotation_z_angle_speed7      EQU 0

bv_rotation_x_angle_speed8      EQU -5
bv_rotation_y_angle_speed8      EQU 0
bv_rotation_z_angle_speed8      EQU -3

bv_rotation_x_angle_speed9      EQU 3
bv_rotation_y_angle_speed9      EQU 5
bv_rotation_z_angle_speed9      EQU 1

bv_rotation_x_angle_speed10     EQU 0
bv_rotation_y_angle_speed10     EQU -5
bv_rotation_z_angle_speed10     EQU 0

bv_object_edge_points_number    EQU 8
bv_object_edge_points_per_face  EQU 4
bv_object_faces_number          EQU 6

bv_object_face1_color           EQU 1
bv_object_face1_lines_number    EQU 4
bv_object_face2_color           EQU 1
bv_object_face2_lines_number    EQU 4
bv_object_face3_color           EQU 2
bv_object_face3_lines_number    EQU 4
bv_object_face4_color           EQU 2
bv_object_face4_lines_number    EQU 4
bv_object_face5_color           EQU 3
bv_object_face5_lines_number    EQU 4
bv_object_face6_color           EQU 3
bv_object_face6_lines_number    EQU 4

bv_light_z_coordinate           EQU -56
bv_EpRGB                        EQU $3f ;Intensit�t der Lichtquelle
bv_kdRGB                        EQU 6 ;Reflexion der Fl�che = Helligkeit des Objekts
bv_D0                           EQU 15 ;Helligkeitsverlust, Schutz vor Division durch Null
bv_EpRGB_max                    EQU 63 ;L�nge der Farbtabelle - 1

bv_light_z_radius               EQU 16
bv_light_z_center               EQU 16

bv_image_x_size                 EQU 128
bv_image_y_size                 EQU 128
bv_image_depth                  EQU 2

bv_used_sprites_number          EQU 2

bv_sprite_x_direction_speed     EQU 3
bv_sprite_y_direction_speed     EQU 2
bv_sprite_x_center              EQU display_window_HSTART*4
bv_sprite_y_center              EQU display_window_VSTART
bv_sprite_x_min                 EQU 0
bv_sprite_x_max                 EQU (visible_pixels_number-(bv_image_x_size+80+60))*4
bv_sprite_y_min                 EQU 0
bv_sprite_y_max                 EQU visible_lines_number-bv_image_y_size

bv_wobble_x_radius              EQU 80/2
bv_wobble_x_center              EQU 80/2
bv_wobble_x_radius_angle_speed  EQU 1
bv_wobble_x_radius_angle_step   EQU 2
bv_wobble_x_angle_speed         EQU 2
bv_wobble_x_angle_step          EQU 1

; **** Clear-Blit ****
bv_clear_blit_x_size            EQU extra_pf1_x_size
bv_clear_blit_y_size            EQU extra_pf1_y_size
bv_clear_blit_depth             EQU extra_pf1_depth

; **** Fill-Blit ****
bv_fill_blit_x_size             EQU extra_pf1_x_size
bv_fill_blit_y_size             EQU extra_pf1_y_size
bv_fill_blit_depth              EQU extra_pf1_depth

; **** Image-Fader ****
if_colors_number                EQU pf1_colors_number

; **** Image-Fader-In ****
ifi_fader_speed_max             EQU 4
ifi_fader_radius                EQU ifi_fader_speed_max
ifi_fader_center                EQU ifi_fader_speed_max+1
ifi_fader_angle_speed           EQU 1

; **** Image-Fader-Out ****
ifo_fader_speed_max             EQU 8
ifo_fader_radius                EQU ifo_fader_speed_max
ifo_fader_center                EQU ifo_fader_speed_max+1
ifo_fader_angle_speed           EQU 1

; **** Blind-Fader ****
bf_lamellas_number              EQU 8
bf_lamella_height               EQU 8
bf_step1                        EQU 1
bf_step2                        EQU 1
bf_speed                        EQU 1
bf_table_length                 EQU bf_lamella_height*4

; **** Cube-Zoomer-In ****
czi_zoom_radius                 EQU 32768
czi_zoom_center                 EQU 32768
czi_zoom_angle_speed            EQU 1

color_values_number1            EQU 64
segments_number1                EQU 1


extra_memory_size               EQU rz_image_x_size*rz_image_y_size*BYTESIZE


; ## Makrobefehle ##
; ------------------

  INCLUDE "macros.i"


; ** Struktur, die alle Exception-Vektoren-Offsets enth�lt **
; -----------------------------------------------------------

  INCLUDE "except-vectors-offsets.i"


; ** Struktur, die alle Eigenschaften des Extra-Playfields enth�lt **
; -------------------------------------------------------------------

  INCLUDE "extra-pf-attributes-structure.i"


; ** Struktur, die alle Eigenschaften der Sprites enth�lt **
; ----------------------------------------------------------

  INCLUDE "sprite-attributes-structure.i"


; ** Struktur, die alle Registeroffsets der ersten Copperliste enth�lt **
; -----------------------------------------------------------------------
  RSRESET

cl1_subextension1      RS.B 0
cl1_subext1_WAIT       RS.L 1
cl1_subext1_SPR6POS    RS.L 1
cl1_subext1_SPR7POS    RS.L 1
cl1_subext1_COP1LCH    RS.L 1
cl1_subext1_COP1LCL    RS.L 1
cl1_subext1_COPJMP2    RS.L 1
cl1_subextension1_SIZE RS.B 0

  RSRESET

cl1_extension1               RS.B 0
cl1_ext1_COP2LCH             RS.L 1
cl1_ext1_COP2LCL             RS.L 1
cl1_ext1_subextension1_entry RS.B cl1_subextension1_SIZE*rz_display_y_scale_factor
cl1_extension1_SIZE          RS.B 0

  RSRESET

cl1_begin            RS.B 0

  INCLUDE "copperlist1-offsets.i"


cl1_extension1_entry RS.B cl1_extension1_SIZE*cl2_display_y_size
;cl1_WAIT1            RS.L 1
cl1_WAIT2            RS.L 1
cl1_INTENA           RS.L 1

cl1_end              RS.L 1

copperlist1_SIZE     RS.B 0


; ** Struktur, die alle Registeroffsets der zweiten Copperliste enth�lt **
; ------------------------------------------------------------------------

  RSRESET

cl2_extension1      RS.B 0

  IFEQ open_border_enabled 
cl2_ext1_BPL1DAT    RS.L 1
  ENDC
cl2_ext1_BPLCON4_1  RS.L 1
cl2_ext1_BPLCON4_2  RS.L 1
cl2_ext1_BPLCON4_3  RS.L 1
cl2_ext1_BPLCON4_4  RS.L 1
cl2_ext1_BPLCON4_5  RS.L 1
cl2_ext1_BPLCON4_6  RS.L 1
cl2_ext1_BPLCON4_7  RS.L 1
cl2_ext1_BPLCON4_8  RS.L 1
cl2_ext1_BPLCON4_9  RS.L 1
cl2_ext1_BPLCON4_10 RS.L 1
cl2_ext1_BPLCON4_11 RS.L 1
cl2_ext1_BPLCON4_12 RS.L 1
cl2_ext1_BPLCON4_13 RS.L 1
cl2_ext1_BPLCON4_14 RS.L 1
cl2_ext1_BPLCON4_15 RS.L 1
cl2_ext1_BPLCON4_16 RS.L 1
cl2_ext1_BPLCON4_17 RS.L 1
cl2_ext1_BPLCON4_18 RS.L 1
cl2_ext1_BPLCON4_19 RS.L 1
cl2_ext1_BPLCON4_20 RS.L 1
cl2_ext1_BPLCON4_21 RS.L 1
cl2_ext1_BPLCON4_22 RS.L 1
cl2_ext1_BPLCON4_23 RS.L 1
cl2_ext1_BPLCON4_24 RS.L 1
cl2_ext1_BPLCON4_25 RS.L 1
cl2_ext1_BPLCON4_26 RS.L 1
cl2_ext1_BPLCON4_27 RS.L 1
cl2_ext1_BPLCON4_28 RS.L 1
cl2_ext1_BPLCON4_29 RS.L 1
cl2_ext1_BPLCON4_30 RS.L 1
cl2_ext1_BPLCON4_31 RS.L 1
cl2_ext1_BPLCON4_32 RS.L 1
cl2_ext1_BPLCON4_33 RS.L 1
cl2_ext1_BPLCON4_34 RS.L 1
cl2_ext1_BPLCON4_35 RS.L 1
cl2_ext1_BPLCON4_36 RS.L 1
cl2_ext1_BPLCON4_37 RS.L 1
cl2_ext1_BPLCON4_38 RS.L 1
cl2_ext1_BPLCON4_39 RS.L 1
cl2_ext1_BPLCON4_40 RS.L 1
cl2_ext1_BPLCON4_41 RS.L 1
cl2_ext1_COPJMP1    RS.L 1

cl2_extension1_SIZE RS.B 0


  RSRESET

cl2_extension2      RS.B 0

  IFEQ open_border_enabled 
cl2_ext2_BPL1DAT    RS.L 1
  ENDC
cl2_ext2_COPJMP1    RS.L 1

cl2_extension2_SIZE RS.B 0


  RSRESET

cl2_begin            RS.B 0

cl2_extension1_entry RS.B cl2_extension1_SIZE*cl2_display_y_size
cl2_extension2_entry RS.B cl2_extension2_SIZE

copperlist2_SIZE     RS.B 0


; ** Konstanten f�r die gr��e der Copperlisten **
; -----------------------------------------------
cl1_size1 EQU 0
cl1_size2 EQU copperlist1_SIZE
cl1_size3 EQU copperlist1_SIZE
cl2_size1 EQU 0
cl2_size2 EQU copperlist2_SIZE
cl2_size3 EQU copperlist2_SIZE


; ** Sprite0-Zusatzstruktur **
; ----------------------------
  RSRESET

spr0_extension1      RS.B 0

spr0_ext1_header     RS.L 1*(spr_pixel_per_datafetch/16)
spr0_ext1_planedata  RS.L (spr_pixel_per_datafetch/16)*wst_text_character_y_size

spr0_extension1_SIZE RS.B 0

; ** Sprite0-Hauptstruktur **
; ---------------------------
  RSRESET

spr0_begin            RS.B 0

spr0_extension1_entry RS.B spr0_extension1_SIZE

spr0_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite0_SIZE          RS.B 0

; ** Sprite1-Zusatzstruktur **
; ----------------------------
  RSRESET

spr1_extension1      RS.B 0

spr1_ext1_header     RS.L 1*(spr_pixel_per_datafetch/16)
spr1_ext1_planedata  RS.L (spr_pixel_per_datafetch/16)*wst_text_character_y_size

spr1_extension1_SIZE RS.B 0

; ** Sprite1-Hauptstruktur **
; ---------------------------
  RSRESET

spr1_begin            RS.B 0

spr1_extension1_entry RS.B spr1_extension1_SIZE

spr1_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite1_SIZE          RS.B 0

; ** Sprite2-Zusatzstruktur **
; ----------------------------
  RSRESET

spr2_extension1      RS.B 0

spr2_ext1_header     RS.L 1*(spr_pixel_per_datafetch/16)
spr2_ext1_planedata  RS.L (spr_pixel_per_datafetch/16)*wst_text_character_y_size

spr2_extension1_SIZE RS.B 0

; ** Sprite2-Hauptstruktur **
; ---------------------------
  RSRESET

spr2_begin            RS.B 0

spr2_extension1_entry RS.B spr2_extension1_SIZE

spr2_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite2_SIZE          RS.B 0

; ** Sprite3-Zusatzstruktur **
; ----------------------------
  RSRESET

spr3_extension1      RS.B 0

spr3_ext1_header     RS.L 1*(spr_pixel_per_datafetch/16)
spr3_ext1_planedata  RS.L (spr_pixel_per_datafetch/16)*wst_text_character_y_size

spr3_extension1_SIZE RS.B 0

; ** Sprite3-Hauptstruktur **
; ---------------------------
  RSRESET

spr3_begin            RS.B 0

spr3_extension1_entry RS.B spr3_extension1_SIZE

spr3_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite3_SIZE          RS.B 0

; ** Sprite4-Zusatzstruktur **
; ----------------------------
  RSRESET

spr4_extension1      RS.B 0

spr4_ext1_header     RS.L 1*(spr_pixel_per_datafetch/16)
spr4_ext1_planedata  RS.L (spr_pixel_per_datafetch/16)*wst_text_character_y_size

spr4_extension1_SIZE RS.B 0

; ** Sprite4-Hauptstruktur **
; ---------------------------
  RSRESET

spr4_begin            RS.B 0

spr4_extension1_entry RS.B spr4_extension1_SIZE

spr4_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite4_SIZE          RS.B 0

; ** Sprite5-Zusatzstruktur **
; ----------------------------
  RSRESET

spr5_extension1      RS.B 0

spr5_ext1_header     RS.L 1*(spr_pixel_per_datafetch/16)
spr5_ext1_planedata  RS.L (spr_pixel_per_datafetch/16)*wst_text_character_y_size

spr5_extension1_SIZE RS.B 0

; ** Sprite5-Hauptstruktur **
; ---------------------------
  RSRESET

spr5_begin            RS.B 0

spr5_extension1_entry RS.B spr5_extension1_SIZE

spr5_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite5_SIZE          RS.B 0

; ** Sprite6-Zusatzstruktur **
; ----------------------------
  RSRESET

spr6_extension1       RS.B 0

spr6_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr6_ext1_planedata   RS.L bv_image_y_size*(spr_pixel_per_datafetch/16)

spr6_extension1_SIZE  RS.B 0

; ** Sprite6-Hauptstruktur **
; ---------------------------
  RSRESET

spr6_begin            RS.B 0

spr6_extension1_entry RS.B spr6_extension1_SIZE

spr6_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite6_SIZE          RS.B 0

; ** Sprite7-Zusatzstruktur **
; ----------------------------
  RSRESET

spr7_extension1       RS.B 0

spr7_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr7_ext1_planedata   RS.L bv_image_y_size*(spr_pixel_per_datafetch/16)

spr7_extension1_SIZE  RS.B 0

; ** Sprite7-Hauptstruktur **
; ---------------------------
  RSRESET

spr7_begin            RS.B 0

spr7_extension1_entry RS.B spr7_extension1_SIZE

spr7_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite7_SIZE          RS.B 0


; ** Konstanten f�r die Gr��e der Spritestrukturen **
; ---------------------------------------------------
spr0_x_size1 EQU spr_x_size1
spr0_y_size1 EQU sprite0_SIZE/(spr_pixel_per_datafetch/4)
spr1_x_size1 EQU spr_x_size1
spr1_y_size1 EQU sprite1_SIZE/(spr_pixel_per_datafetch/4)
spr2_x_size1 EQU spr_x_size1
spr2_y_size1 EQU sprite2_SIZE/(spr_pixel_per_datafetch/4)
spr3_x_size1 EQU spr_x_size1
spr3_y_size1 EQU sprite3_SIZE/(spr_pixel_per_datafetch/4)
spr4_x_size1 EQU spr_x_size1
spr4_y_size1 EQU sprite4_SIZE/(spr_pixel_per_datafetch/4)
spr5_x_size1 EQU spr_x_size1
spr5_y_size1 EQU sprite5_SIZE/(spr_pixel_per_datafetch/4)
spr6_x_size1 EQU spr_x_size1
spr6_y_size1 EQU sprite6_SIZE/(spr_pixel_per_datafetch/4)
spr7_x_size1 EQU spr_x_size1
spr7_y_size1 EQU sprite7_SIZE/(spr_pixel_per_datafetch/4)

spr0_x_size2 EQU spr_x_size2
spr0_y_size2 EQU sprite0_SIZE/(spr_pixel_per_datafetch/4)
spr1_x_size2 EQU spr_x_size2
spr1_y_size2 EQU sprite1_SIZE/(spr_pixel_per_datafetch/4)
spr2_x_size2 EQU spr_x_size2
spr2_y_size2 EQU sprite2_SIZE/(spr_pixel_per_datafetch/4)
spr3_x_size2 EQU spr_x_size2
spr3_y_size2 EQU sprite3_SIZE/(spr_pixel_per_datafetch/4)
spr4_x_size2 EQU spr_x_size2
spr4_y_size2 EQU sprite4_SIZE/(spr_pixel_per_datafetch/4)
spr5_x_size2 EQU spr_x_size2
spr5_y_size2 EQU sprite5_SIZE/(spr_pixel_per_datafetch/4)
spr6_x_size2 EQU spr_x_size2
spr6_y_size2 EQU sprite6_SIZE/(spr_pixel_per_datafetch/4)
spr7_x_size2 EQU spr_x_size2
spr7_y_size2 EQU sprite7_SIZE/(spr_pixel_per_datafetch/4)


; ** Struktur, die alle Variablenoffsets enth�lt **
; -------------------------------------------------

  INCLUDE "variables-offsets.i"

; ** Relative offsets for variables **
; ------------------------------------

save_a7                            RS.L 1

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-variables-offsets.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-variables-offsets.i"
  ENDC

pt_effects_handler_active               RS.W 1

; **** Rotation-Zoomer ****
rz_active                          RS.W 1
rz_zoomer_active                   RS.W 1
rz_z_rotation_angle                RS.W 1
rz_zoom_angle                      RS.W 1

; **** Wave-Scrolltext ****
wst_active                         RS.W 1
  RS_ALIGN_LONGWORD
wst_image                          RS.L 1
wst_text_table_start               RS.W 1
wst_y_angle                        RS.W 1
wst_variable_y_angle_speed         RS.W 1
wst_variable_y_angle_step          RS.W 1
wst_variable_horiz_scroll_speed    RS.W 1

; **** Blenk-Vectors ****
bv_active                          RS.W 1
bv_rotation_x_angle                RS.W 1
bv_rotation_y_angle                RS.W 1
bv_rotation_z_angle                RS.W 1
bv_variable_rotation_x_angle_speed RS.W 1
bv_variable_rotation_y_angle_speed RS.W 1
bv_variable_rotation_z_angle_speed RS.W 1

bv_variable_light_z_coordinate     RS.W 1

bv_sprite_x_coordinate             RS.W 1
bv_sprite_y_coordinate             RS.W 1
bv_sprite_x_direction              RS.W 1
bv_sprite_y_direction              RS.W 1

bv_wobble_x_radius_angle           RS.W 1
bv_wobble_x_angle                  RS.W 1

  RS_ALIGN_LONGWORD
bv_zoom_distance                   RS.L 1

; **** Image-Fader ****
if_colors_counter                  RS.W 1
if_copy_colors_active              RS.W 1

; **** Image-Fader-In ****
ifi_active                         RS.W 1
ifi_fader_angle                    RS.W 1

; **** Image-Fader-Out ****
ifo_active                         RS.W 1
ifo_fader_angle                    RS.W 1

; **** Blind-Fader ****
bf_address_offsets_table_start     RS.W 1

; **** Blind-Fader-In ****
bfi_active                         RS.W 1

; **** Blind-Fader-Out ****
bfo_active                         RS.W 1

; **** Cube-Zoomer-In ****
czi_active                         RS.W 1
czi_zoom_angle                     RS.W 1

; **** Keyboard-Handler ****
kh_key_code                        RS.B 1
kh_key_flag                        RS.B 1

; **** Main ****
fx_active                          RS.W 1
part_title_active                  RS.W 1
part_main_active                   RS.W 1

variables_SIZE                     RS.B 0


; **** PT-Replay ****
; ** PT-Song-Structure **
; -----------------------
  INCLUDE "music-tracker/pt-song-structure.i"

; ** Temporary channel structure **
; ---------------------------------
  INCLUDE "music-tracker/pt-temp-channel-structure.i"

; **** Blenk-Vectors ****
; ** Objekt-Info-Struktur **
; --------------------------
  RSRESET

bv_object_info              RS.B 0

bv_object_info_edge_table   RS.L 1
bv_object_info_face_color   RS.W 1
bv_object_info_lines_number RS.W 1

bv_object_info_SIZE         RS.B 0


; ## Beginn des Initialisierungsprogramms ##
; ------------------------------------------

  INCLUDE "sys-init.i"

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

  move.w  d0,pt_effects_handler_active(a3)

init_own_variables2
; **** Rotation-Zoomer ****
  moveq   #FALSE,d1
  move.w  d1,rz_active(a3)
  move.w  d1,rz_zoomer_active(a3)
  moveq   #0,d0
  move.w  d0,rz_z_rotation_angle(a3) ;0 Grad
  move.w  #(sine_table_length/4)*3,rz_zoom_angle(a3) ;270 Grad

; **** Wave-Scrolltext ****
  move.w  d1,wst_active(a3)
  lea     wst_image_data,a0
  move.l  a0,wst_image(a3)
  move.w  d0,wst_text_table_start(a3)
  move.w  d0,wst_y_angle(a3) ;0 Grad
  moveq   #wst_y_angle_speed,d2
  move.w  d2,wst_variable_y_angle_speed(a3)
  moveq   #wst_y_angle_step,d2
  move.w  d2,wst_variable_y_angle_step(a3)
  moveq   #wst_horiz_scroll_speed,d2
  move.w  d2,wst_variable_horiz_scroll_speed(a3)

; **** Blenk-Vectors ****
  move.w  d1,bv_active(a3)
  move.w  d0,bv_rotation_x_angle(a3) ;0 Grad
  move.w  d0,bv_rotation_y_angle(a3) ;0 Grad
  move.w  d0,bv_rotation_z_angle(a3) ;0 Grad
  moveq   #bv_rotation_x_angle_speed1,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed1,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed1,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)

  move.w  #bv_light_z_coordinate,bv_variable_light_z_coordinate(a3)

  move.w  d0,bv_sprite_x_coordinate(a3)
  move.w  d0,bv_sprite_y_coordinate(a3)
  moveq   #bv_sprite_x_direction_speed,d2
  move.w  d2,bv_sprite_x_direction(a3)
  moveq   #bv_sprite_y_direction_speed,d2
  move.w  d2,bv_sprite_y_direction(a3)

  move.w  #sine_table_length/4,bv_wobble_x_radius_angle(a3) ;90 Grad
  move.w  d0,bv_wobble_x_angle(a3) ;0 Grad

  move.l  #czi_zoom_radius,bv_zoom_distance(a3)

; **** Image-Fader ****
  move.w  d0,if_colors_counter(a3)
  move.w  d1,if_copy_colors_active(a3)

  move.w  d1,ifi_active(a3)
  move.w  #sine_table_length/4,ifi_fader_angle(a3) ;90 Grad

  move.w  d1,ifo_active(a3)
  move.w  #sine_table_length/4,ifo_fader_angle(a3) ;90 Grad

; **** Blind-Fader ****
  move.w  d0,bf_address_offsets_table_start(a3)

; **** Blind-Fader-In ****
  move.w  d1,bfi_active(a3)

; **** Blind-Fader-Out ****
  move.w  d1,bfo_active(a3)

; **** Cube-Zoomer-In ****
  move.w  d1,czi_active(a3)
  move.w  d0,czi_zoom_angle(a3) ;90 Grad

; **** Keyboard-Handler ****
  move.b  d0,kh_key_code(a3)
  move.b  d0,kh_key_flag(a3)

; **** Main ****
  move.w  d1,fx_active(a3)
  move.w  d1,part_title_active(a3)
  move.w  d1,part_main_active(a3)
  rts

; ** Alle Initialisierungsroutinen ausf�hren **
; ---------------------------------------------
  CNOP 0,4
init_all
  bsr.s   pt_DetectSysFrequ
  bsr.s   init_CIA_timers
  bsr     init_sprites
  bsr     pt_InitRegisters
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  IFEQ pt_finetune_enabled
    bsr     pt_InitFtuPeriodTableStarts
  ENDC
  bsr     rz_convert_image_data
  bsr     wst_init_characters_offsets
  bsr     wst_init_characters_x_positions
  bsr     bv_convert_color_table
  bsr     bv_init_object_info_table
  bsr     bg_copy_image_to_bitplane
  bsr     init_first_copperlist
  bra     init_second_copperlist

; **** PT-Replay ****
; ** Detect system frequency NTSC/PAL **
; --------------------------------------
  PT_DETECT_SYS_FREQUENCY

; ** CIA-Timer initialisieren **
; ------------------------------
  CNOP 0,4
init_CIA_timers
  MOVEF.W CIAA_TB_time&$ff,d0
  move.b  d0,CIATBLO(a4)     ;Timer-B Low-Bits
  moveq   #CIAA_TB_time>>8,d0
  move.b  d0,CIATBHI(a4)     ;Timer-B High-Bits
  moveq   #CIAACRBBITS,d0
  move.b  d0,CIACRB(a4)

  PT_INIT_TIMERS
  rts

; ** Sprites initialisieren **
; ----------------------------
  CNOP 0,4
init_sprites
  bsr.s   spr_init_pointers_table
  bra     spr_copy_structures

; ** Tabelle mit Zeigern auf Sprites initialisieren **
; ----------------------------------------------------
  INIT_SPRITE_POINTERS_TABLE

; ** Spritedaten kopieren **
; --------------------------
  COPY_SPRITE_STRUCTURES

; **** PT-Replay ****
; ** Audioregister initialisieren **
; ----------------------------------
   PT_INIT_REGISTERS

; ** Tempor�re Audio-Kanal-Struktur initialisieren **
; ---------------------------------------------------
   PT_INIT_AUDIO_TEMP_STRUCTURES

; ** H�chstes Pattern ermitteln und Tabelle mit Zeigern auf Samples initialisieren **
; -----------------------------------------------------------------------------------
   PT_EXAMINE_SONG_STRUCTURE

  IFEQ pt_finetune_enabled
; ** FineTuning-Offset-Tabelle initialisieren **
; ----------------------------------------------
    PT_INIT_FINETUNING_PERIOD_TABLE_STARTS
  ENDC

; **** Rotation-Zoomer ****
; ** Bilddaten in Switchwerte umwandeln **
; ----------------------------------------
  CONVERT_IMAGE_TO_BPLCON4_CHUNKY.B rz,extra_memory,a3

; **** Wave-Scrolltext ****
; ** Offsets der Buchstaben im Characters-image berechnen **
; ------------------------------------------ --------------
  INIT_CHARACTERS_OFFSETS.W wst

; ** X-Positionen der Chars berechnen **
; --------------------------------------
  INIT_CHARACTERS_X_POSITIONS wst,SHIRES

; ** RGB8-Farbwerte in RGB4 Hi/Lo-Werte umwandeln **
; --------------------------------------------------------
  RGB8_TO_RGB8_HILO bv,segments_number1*color_values_number1

; ** Object-Info-Tabelle initialisieren **
; ----------------------------------------
  CNOP 0,4
bv_init_object_info_table
  lea     bv_object_info_table+bv_object_info_edge_table(pc),a0 ;Zeiger auf Object-Info-Tabelle
  lea     bv_object_edge_table(pc),a1 ;Zeiger auf Tebelle mit Eckpunkten
  move.w  #bv_object_info_SIZE,a2
  moveq   #bv_object_faces_number-1,d7 ;Anzahl der Fl�chen
bv_init_object_info_table_loop
  move.w  bv_object_info_lines_number(a0),d0
  addq.w  #2,d0              ;Anzahl der Linien + 1 = Anzahl der Eckpunkte
  move.l  a1,(a0)            ;Zeiger auf Tabelle mit Eckpunkten eintragen
  lea     (a1,d0.w*2),a1     ;Zeiger auf Eckpunkte-Tabelle erh�hen
  add.l   a2,a0              ;Object-Info-Struktur der n�chsten Fl�che
  dbf     d7,bv_init_object_info_table_loop
  rts

; ** Objekt ins Playfield kopieren **
; -----------------------------------
  COPY_IMAGE_TO_BITPLANE bg


; ** 1. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_first_copperlist
  move.l  cl1_construction2(a3),a0 ;CL
  bsr.s   cl1_init_playfield_registers
  bsr.s   cl1_init_sprite_pointers
  bsr     cl1_init_color_registers
  bsr     cl1_init_bitplane_pointers
  bsr     cl1_init_branches_pointers
  bsr     cl1_init_copint
  COPLISTEND
  bsr     cl1_set_sprite_pointers
  bsr     cl1_set_bitplane_pointers
  bsr     copy_first_copperlist
  bra     cl1_set_branches_pointers

  COP_INIT_PLAYFIELD_REGISTERS cl1
  COP_INIT_SPRITE_POINTERS cl1

  CNOP 0,4
cl1_init_color_registers
  COP_INIT_COLORHI COLOR00,32,pf1_color_table
  COP_SELECT_COLORHI_BANK 1
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 2
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 3
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 4
  COP_INIT_COLORHI COLOR00,16,spr_color_table

  COP_SELECT_COLORLO_BANK 0
  COP_INIT_COLORLO COLOR00,32,pf1_color_table
  COP_SELECT_COLORLO_BANK 1
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 2
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 3
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 4
  COP_INIT_COLORLO COLOR00,16,spr_color_table
  rts

  COP_INIT_BITPLANE_POINTERS cl1

  CNOP 0,4
cl1_init_branches_pointers
  move.l  #(((cl1_VSTART1<<24)+(((cl1_HSTART1/4)*2)<<16))|$10000)|$fffe,d0 ;WAIT-Befehl
  moveq   #2,d1              ;X-Verschiebung $00020000
  swap    d1
  moveq   #1,d2
  ror.l   #8,d2              ;Y-Additionswert $01000000
  moveq   #cl2_display_y_size-1,d7 ;Anzahl der Zeilen
cl1_init_branches_pointers_loop1
  COPMOVEQ TRUE,COP2LCH
  COPMOVEQ TRUE,COP2LCL
  moveq   #rz_display_y_scale_factor-1,d6 ;Anzahl der Abschnitte f�r Y-Skalierung
cl1_init_branches_pointers_loop2
  move.l  d0,(a0)+           ;WAIT x,y
  COPMOVEQ TRUE,SPR6POS
  COPMOVEQ TRUE,SPR7POS
  COPMOVEQ TRUE,COP1LCH
  eor.l   d1,d0              ;X-Shift
  COPMOVEQ TRUE,COP1LCL
  add.l   d2,d0              ;n�chste Zeile
  COPMOVEQ TRUE,COPJMP2
  dbf     d6,cl1_init_branches_pointers_loop2
  dbf     d7,cl1_init_branches_pointers_loop1
  rts

  COP_INIT_COPINT cl1,cl1_HSTART2,cl1_VSTART2

  COP_SET_SPRITE_POINTERS cl1,construction2,spr_number

  COP_SET_BITPLANE_POINTERS cl1,construction2,pf1_depth3

  COPY_COPPERLIST cl1,2

  CNOP 0,4
cl1_set_branches_pointers
  move.l  cl1_construction2(a3),a0 ;Aufbau-CL1
  moveq   #cl1_subextension1_SIZE,d2
  move.l  cl2_construction2(a3),d0 ;Einsprungadresse = Aufbau-CL2
  add.l   #cl2_extension2_entry,d0
  moveq   #cl1_extension1_SIZE,d4
  bsr.s   cl1_set_jump_entry_pointers
  move.l  cl1_display(a3),a0 ;Darstellen-CL1
  move.l  cl2_display(a3),d0 ;Einsprungadresse = Darstellen-CL2
  add.l   #cl2_extension2_entry,d0

; ** Routine set-jump-entry_pointers **
; a0 ... Copperliste1
; d0 ... Einsprungadresse Copperliste2
; d2 ... cl1_subextension1_SIZE
; d4 ... cl1_extension1_SIZE
cl1_set_jump_entry_pointers
  MOVEF.L cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subextension1_SIZE,d1 ;Offset R�cksprungadresse CL1
  add.l   a0,d1              ;+ R�cksprungadresse CL1
  lea     cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subext1_COP1LCH+2(a0),a1
  ADDF.W  cl1_extension1_entry+cl1_ext1_COP2LCH+2,a0
  moveq   #cl2_display_y_size-1,d7 ;Anzahl der Zeilen
cl1_set_branches_loop1
  swap    d0                 ;High
  move.w  d0,(a0)            ;COP2LCH
  swap    d0                 ;Low
  move.w  d0,4(a0)           ;COP2LCL
  moveq   #rz_display_y_scale_factor-1,d6 ;Anzahl der Abschnitte f�r Y-Skalierung
cl1_set_branches_loop2
  swap    d1                 ;High-Wert
  move.w  d1,(a1)            ;COP1LCH
  swap    d1                 ;Low-Wert
  move.w  d1,4(a1)           ;COP1LCL
  add.l   d2,d1              ;R�cksprungadresse CL1 erh�hen
  add.l   d2,a1              ;n�chste Zeile in Unterabschnitt der CL1
  dbf     d6,cl1_set_branches_loop2
  add.l   d4,a0              ;n�chste Zeile in CL1
  addq.l  #8,d1              ;CMOVE COP2LCH + CMOVE COP2LCL �berspringen
  addq.w  #8,a1              ;CMOVE COP2LCH + CMOVE COP2LCL �berspringen
  dbf     d7,cl1_set_branches_loop1
  rts

; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_construction2(a3),a0 ;Aufbau-CL
  bsr     cl2_init_BPLCON4_registers
  bsr     cl2_init_noop
  bra     copy_second_copperlist

  CNOP 0,4
cl2_init_BPLCON4_registers
  move.l  #(BPLCON4<<16)+BPLCON4BITS,d0
  IFEQ open_border_enabled 
    move.l  #BPL1DAT<<16,d1
  ENDC
  moveq   #cl2_display_y_size-1,d7
cl2_init_BPLCON4_registers_loop1
  IFEQ open_border_enabled 
    move.l  d1,(a0)+         ;BPL1DAT
  ENDC
  moveq   #cl2_display_width-1,d6 ;Anzahl der Spalten
cl2_init_BPLCON4_registers_loop2
  move.l  d0,(a0)+           ;BPLCON4
  dbf     d6,cl2_init_BPLCON4_registers_loop2
  COPMOVEQ TRUE,COPJMP1
  dbf     d7,cl2_init_BPLCON4_registers_loop1
  rts

  CNOP 0,4
cl2_init_noop
  IFEQ open_border_enabled 
    COPMOVEQ TRUE,BPL1DAT
  ENDC
  COPMOVEQ TRUE,COPJMP1
  rts

  COPY_COPPERLIST cl2,2


; ** CIA-Timer starten **
; -----------------------

  INCLUDE "continuous-timers-start.i"


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
  bsr     wait_vbi
  bsr     wave_scrolltext
  bsr     bv_draw_lines
  bsr     bv_fill_image
  bsr     rotation_zoomer
  bsr     cube_zoomer_in
  bsr     bv_move_lightsource
  bsr     bv_clear_image
  bsr     bv_rotation
  bsr     bv_move_sprites
  bsr     bv_wobble_sprites
  bsr     bv_copy_image
  bsr     image_fader_in
  bsr     image_fader_out
  bsr     keyboard_handler
  bsr     mouse_handler
  bsr     wait_copint
  bsr     swap_first_copperlist
  bsr     swap_second_copperlist
  bsr     spr_swap_structures
  bsr     swap_images
  bsr     if_copy_color_table
  bsr     blind_fader_in
  bsr     blind_fader_out
  tst.w   fx_active(a3)      ;Effekte beendet ?
  bne.s   beam_routines      ;Nein -> verzweige
  rts


; ** Copperlisten vertauschen **
; ------------------------------
  SWAP_COPPERLIST cl1,2

  SWAP_COPPERLIST cl2,2,NOSET

; ** Sprite-Strukturen vertauschen **
; -----------------------------------
  SWAP_SPRITES_STRUCTURES spr,spr_swap_number,6

; ** Images vertauschen **
; ------------------------
  CNOP 0,4
swap_images
  move.l  extra_pf1(a3),a0
  move.l  extra_pf3(a3),extra_pf1(a3)
  move.l  extra_pf2(a3),a1
  move.l  a0,extra_pf2(a3)
  move.l  a1,extra_pf3(a3)
  rts


; ** Laufschrift **
; -----------------
  CNOP 0,4
wave_scrolltext
  tst.w   wst_active(a3)     ;Wave-Scrolltext an ?
  bne     no_wave_scrolltext ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  wst_y_angle(a3),d4  ;Y-Winkel
  move.w  d4,d0              
  add.w   wst_variable_y_angle_speed(a3),d0 ;n�chster Y-Winkel
  and.w   #sine_table_length-1,d0 ;�berlauf entfernen
  move.w  d0,wst_y_angle(a3) 
  moveq   #wst_image_plane_width-4,d3
  lea     wst_characters_x_positions(pc),a2 ;X-Positionen der Chars
  lea     spr_pointers_display(pc),a4 ;Zeiger auf Sprites
  lea     sine_table(pc),a5
  move.w  wst_variable_horiz_scroll_speed(a3),a6
  moveq   #wst_text_characters_number-1,d7 ;Anzahl der Chars
wave_scrolltext_loop1
  move.l  (a4)+,a1           ;Zeiger auf Sprite-Struktur
  move.w  (a2),d5            ;X-Position
  move.w  d5,d0              
  move.l  (a5,d4.w*4),d1     ;sin(w)
  MULUF.L wst_y_radius*2,d1,d2 ;y'=(yr*sin(w))/2^15
  add.w   #(display_window_HSTART-wst_text_character_x_size)*4,d0 ;X-Zentrierung
  swap    d1
  sub.w   wst_variable_y_angle_step(a3),d4 ;n�chster Buchstabe
  add.w   #wst_y_center,d1  ;Y-Zentrierung
  moveq   #wst_text_character_y_size,d2 ;H�he
  add.w   d1,d2              ;H�he zu Y-Position addieren
  SET_SPRITE_POSITION d0,d1,d2
  move.w  d1,(a1)            ;SPRxPOS
  and.w   #sine_table_length-1,d4 ;�berlauf entfernen
  move.w  d2,spr_pixel_per_datafetch/8(a1) ;SPRxCTL
  sub.w   a6,d5              ;X-Position reduzieren
  bpl.s   wst_set_character_x_position ;Wenn positiv -> verzweige
wst_new_character_image
  add.w   #wst_text_character_x_restart,d5 ;X-Pos zur�cksetzen
  bsr.s   wst_get_new_character_image
  move.l  d0,a0              ;Neues Bild f�r Character
  add.l   #(spr_pixel_per_datafetch/8)*2,a1 ;Sprite-Header �berpsringen
  moveq   #wst_text_character_y_size-1,d6 ;Anzahl der Zeilen zum kopieren
wave_scrolltext_loop2
  move.l  (a0)+,(a1)+        ;64 Pixel BP0
  move.l  (a0),(a1)+
  add.l   d3,a0              ;n�chste Zeile in Quelle
  move.l  (a0)+,(a1)+        ;64 Pixel BP1
  move.l  (a0),(a1)+
  add.l   d3,a0              ;n�chste Zeile in Quelle
  dbf     d6,wave_scrolltext_loop2
wst_set_character_x_position
  move.w  d5,(a2)+           ;X-Position retten
  dbf     d7,wave_scrolltext_loop1
  movem.l (a7)+,a4-a6
no_wave_scrolltext
  rts

; ** Neues Image f�r Character ermitteln **
; -----------------------------------------
  GET_NEW_CHARACTER_IMAGE.W wst,wst_check_control_codes,NORESTART

  CNOP 0,4
wst_check_control_codes
  cmp.b   #"�",d0            ;Standart-Scroll ?
  beq.s   wst_set_standard_scroll ;Ja -> verzweige
  cmp.b   #"�",d0            ;Y-Winkel zur�cksetzen?
  beq.s   wst_clear_y_angle_step
  cmp.b   #"�",d0            ;Y-Step setzen ?
  beq.s   wst_set_y_angle_step
  cmp.b   #"�",d0            ;Y-Winkel setzen ?
  beq.s   wst_set_y_angle_speed
  cmp.b   #"",d0
  beq.s   wst_set_horiz_scroll_speed_slow
  cmp.b   #"
",d0
  beq.s   wst_set_horiz_scroll_speed_medium
  cmp.b   #"",d0
  beq.s   wst_set_horiz_scroll_speed_fast
  cmp.b   #"",d0
  beq.s   wst_stop_scrolltext
  rts
  CNOP 0,4
wst_set_standard_scroll
  move.w  #sine_table_length/2,wst_y_angle(a3) ;Y-Winkel = 180�
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  move.w  d0,wst_variable_y_angle_speed(a3) ;Y-Winkel-Geschwindigkeit = Null
  rts
  CNOP 0,4
wst_clear_y_angle_step
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  move.w  d0,wst_variable_y_angle_step(a3) ;Y-Winkel-Schrittweite = Null
  rts
  CNOP 0,4
wst_set_y_angle_step
  moveq   #wst_y_angle_step,d0
  move.w  d0,wst_variable_y_angle_step(a3) ;Y-Winkel-Schrittweite setzen
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  rts
  CNOP 0,4
wst_set_y_angle_speed
  moveq   #wst_y_angle_speed,d0
  move.w  d0,wst_variable_y_angle_speed(a3) ;Y-Winkel-Geschwindigkeit setzen
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  rts
  CNOP 0,4
wst_set_horiz_scroll_speed_slow
  moveq   #wst_horiz_scroll_speed_slow,d2
  move.w  d2,wst_variable_horiz_scroll_speed(a3)
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  rts
  CNOP 0,4
wst_set_horiz_scroll_speed_medium
  moveq   #wst_horiz_scroll_speed,d2
  move.w  d2,wst_variable_horiz_scroll_speed(a3)
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  rts
  CNOP 0,4
wst_set_horiz_scroll_speed_fast
  moveq   #wst_horiz_scroll_speed_fast,d2
  move.w  d2,wst_variable_horiz_scroll_speed(a3)
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  rts
  CNOP 0,4
wst_stop_scrolltext
  moveq   #FALSE,d0
  move.w  d0,wst_active(a3) ;Scrolltext aus
  moveq   #0,d0          ;R�ckgabewert TRUE = Steuerungscode gefunden
  rts

; ** Bild l�schen **
; ------------------
  CNOP 0,4
bv_clear_image
  move.l  extra_pf1(a3),a0
  WAITBLITTER
  move.l  (a0),a0
  move.l  #BC0F_DEST<<16,BLTCON0-DMACONR(a6) ;Minterm L�schen
  move.l  a0,BLTDPT-DMACONR(a6)
  moveq   #0,d0
  move.w  d0,BLTDMOD-DMACONR(a6) ;D-Mod
  move.w  #(bv_clear_blit_y_size*bv_clear_blit_depth*64)+(bv_clear_blit_x_size/16),BLTSIZE-DMACONR(a6)
  rts

; ** Lichtquelle bewegen **
; -------------------------
  CNOP 0,4
bv_move_lightsource
  move.w  rz_zoom_angle(a3),d0 ;Zoom-Winkel 
  lea     sine_table(pc),a0  
  move.l  (a0,d0.w*4),d0     ;-sin(w)
  neg.l   d0
  MULUF.L bv_light_z_radius*2,d0,d1 ;z'=(zr*(-sin(w)))/2^15
  swap    d0
  add.w   #bv_light_z_center,d0 ;z' + Z-Mittelpunkt
  moveq   #bv_light_z_coordinate,d1
  sub.w   d0,d1              ;+ Z-Koodinate der Lichtquelle
  move.w  d1,bv_variable_light_z_coordinate(a3) ;neue Z-Koordinate retten
  rts

; ** Rotate-Routine **
; --------------------
  CNOP 0,4
bv_rotation
  movem.l a4-a5,-(a7)
  move.w  bv_rotation_x_angle ;X-Winkel
  move.w  d1,d0              ;retten
  lea     sine_table(pc),a2
  move.w  2(a2,d0.w*4),d4    ;sin(a)
  move.w  #sine_table_length/4,a4
  MOVEF.W sine_table_length-1,d3
  add.w   a4,d0              ;+ 90 Grad
  swap    d4                 ;Bits 16-31 = sin(a)
  and.w   d3,d0              ;�bertrag entfernen
  move.w  2(a2,d0.w*4),d4    ;Bits  0-15 = cos(a)
  add.w   bv_variable_rotation_x_angle_speed(a3),d1 ;n�chster X-Winkel
  and.w   d3,d1              ;�bertrag entfernen
  move.w  d1,bv_rotation_x_angle(a3) 
  move.w  bv_rotation_y_angle ;Y-Winkel
  move.w  d1,d0              ;retten
  move.w  2(a2,d0.w*4),d5    ;sin(b)
  add.w   a4,d0              ;+ 90 Grad
  swap    d5                 ;Bits 16-31 = sin(b)
  and.w   d3,d0              ;�bertrag entfernen
  move.w  2(a2,d0.w*4),d5    ;Bits  0-15 = cos(b)
  add.w   bv_variable_rotation_y_angle_speed(a3),d1 ;n�chster Y-Winkel
  and.w   d3,d1              ;�bertrag entfernen
  move.w  d1,bv_rotation_y_angle(a3) 
  move.w  bv_rotation_z_angle ;Z-Winkel
  move.w  d1,d0              ;retten
  move.w  2(a2,d0.w*4),d6    ;sin(c)
  add.w   a4,d0              ;+ 90 Grad
  swap    d6                 ;Bits 16-31 = sin(c)
  and.w   d3,d0              ;�bertrag entfernen
  move.w  2(a2,d0.w*4),d6    ;Bits  0-15 = cos(c)
  add.w   bv_variable_rotation_z_angle_speed(a3),d1 ;n�chster Z-Winkel
  and.w   d3,d1              ;�bertrag entfernen
  move.w  d1,bv_rotation_z_angle(a3) 
  lea     bv_object_coordinates(pc),a0 ;Koordinaten der Linien
  lea     bv_rotation_xyz_coordinates(pc),a1 ;Koord.-Tab.
  move.w  #bv_rotation_d*8,a4 ;d
  add.l   bv_zoom_distance(a3),a4
  move.w  #bv_rotation_xy_center,a5 ;X+Y-Mittelpunkt
  moveq   #bv_object_edge_points_number-1,d7 ;Anzahl der Punkte
bv_rotation_loop
  move.w  (a0)+,d0           ;X-Koord.
  move.l  d7,a2              
  move.w  (a0)+,d1           ;Y-Koord.
  move.w  (a0)+,d2           ;Z-Koord.
  ROTATE_X_AXIS
  ROTATE_Y_AXIS
  ROTATE_Z_AXIS
; ** Zentralprojektion und Translation **
  move.w  d2,d3              ;z -> d3
  ext.l   d0                 ;Auf 32 Bit erweitern
  add.w   a4,d3              ;z+d
  MULUF.L bv_rotation_d,d0,d7 ;x*d  X-Projektion
  ext.l   d1                 ;Auf 32 Bit erweitern
  divs.w  d3,d0              ;x' = (x*d)/(z+d)
  MULUF.L bv_rotation_d,d1,d7 ;y*d  Y-Projektion
  add.w   a5,d0              ;x' + X-Mittelpunkt
  move.w  d0,(a1)+           ;X-Pos.
  divs.w  d3,d1              ;y' = (y*d)/(z+d)
  add.w   a5,d1              ;y' + Y-Mittelpunkt
  move.w  d1,(a1)+           ;Y-Pos.
  asr.w   #3,d2              ;Z/8
  move.l  a2,d7              ;Schleifenz�hler 
  move.w  d2,(a1)+           ;Z-Pos.
  dbf     d7,bv_rotation_loop
  movem.l (a7)+,a4-a5
  rts

; ** Linien ziehen **
; -------------------
  CNOP 0,4
bv_draw_lines
  tst.w   bv_active(a3)
  bne     bv_no_draw_lines
  movem.l a3-a5,-(a7)
  move.l  a7,save_a7(a3)     ;Alten Stackpointer retten
  bsr     bv_draw_lines_init
  lea     bv_object_info_table(pc),a0 ;Zeiger auf Info-Daten zum Objekt
  lea     bv_rotation_xyz_coordinates(pc),a1 ;Zeiger auf XYZ-Koordinaten
  move.l  extra_pf2(a3),a2   ;Plane0
  move.l  (a2),a2
  move.l  cl1_construction2(a3),a4 ;CL<<16
  move.l  #((BC0F_SRCA+BC0F_SRCC+BC0F_DEST+NANBC+NABC+ABNC)<<16)+(BLTCON1F_LINE+BLTCON1F_SING),a3
  ADDF.W  cl1_COLOR12_high5+2,a4 ;Farbregister
  lea     bv_color_table(pc),a7 ;Zeiger auf Tabelle mit Farbverlaufwerten
  moveq   #bv_object_faces_number-1,d7 ;Anzahl der Fl�chen
bv_draw_lines_loop1
; ** Z-Koordinate des Vektors N durch das Kreuzprodukt u x v berechnen **
  move.l  (a0)+,a5           ;Zeiger auf Startwerte der Punkte
  swap    d7                 ;Fl�chenz�hler retten
  move.w  (a5),d4            ;P1-Startwert
  move.w  2(a5),d5           ;P2-Startwert
  move.w  4(a5),d6           ;P3-Startwert
  movem.w (a1,d5.w*2),d0-d1  ;P2(x,y)
  movem.w (a1,d6.w*2),d2-d3  ;P3(x,y)
  sub.w   d0,d2              ;xv = xp3-xp2
  sub.w   (a1,d4.w*2),d0     ;xu = xp2-xp1
  sub.w   d1,d3              ;yv = yp3-yp2
  sub.w   2(a1,d4.w*2),d1    ;yu = yp2-yp1
  muls.w  d3,d0              ;xu*yv
  muls.w  d2,d1              ;yu*xv
  sub.l   d0,d1              ;zn = (yu*xv)-(xu*yv)
  bpl     bv_draw_lines_no_face ;Wenn zn positiv -> verzweige
; ** Mittlere Z-Koordinate der Fl�che berechnen **
  move.w  6(a5),d7           ;P4-Startwert 
  move.w  4(a1,d4.w*2),d0    ;zm = zp1+zp2+zp3+zp4
  add.w   4(a1,d5.w*2),d0
  add.w   4(a1,d6.w*2),d0
  move.l  #bv_kdRGB*bv_EpRGB,d1 ;(kdRGB*EpRGB)
  add.w   4(a1,d7.w*2),d0
  IFEQ bv_object_edge_points_per_face-4
    asr.w   #2,d0            ;zm / Anzahl der Eckpunkte
  ELSE
    ext.l   d0               ;Auf 32 Bit erweitern
    divs.w  #bv_object_edge_points_per_face,d0 ;zm / Anzahl der Eckpunkte
  ENDC
; ** Entfernung zur Lichtquelle berechnen **
  move.w  (a0),d7            ;Farbnummer
  sub.w   variables+bv_variable_light_z_coordinate(pc),d0 ;D = zm-zl
; ** Farbintensit�t der Fl�che ermitteln **
  sub.w   #bv_D0,d0          ;D-D0
  bgt.s   bv_draw_lines_no_underflow_distance ;Wenn > Null -> verzweige
  moveq   #1,d0              ;D = 1
bv_draw_lines_no_underflow_distance
  divu.w  d0,d1              ;RtdRGB = (kdRGB*EpRGB)/(D-D0)
  IFEQ bv_EpRGB_check_max
    cmp.w   #bv_EpRGB,d1     ;Wenn <= Maximalwert -> verzweige
    ble.s   bv_draw_lines_EpRGB_max_ok
    MOVEF.W bv_EpRGB_max,d1  ;Maximalwert setzen
bv_draw_lines_EpRGB_max_ok
  ENDC
; ** Farbwert in Copperliste eintragen **
  move.l  (a7,d1.w*4),d0
  move.w  d0,(cl1_COLOR12_low5-cl1_COLOR12_high5,a4,d7.w*4) ;Low-Bits COLORxx
  swap    d0                 ;High
  move.w  d0,(a4,d7.w*4)     ;High-Bits COLORxx
  move.w  bv_object_info_lines_number-bv_object_info_face_color(a0),d6 ;Anzahl der Linien
bv_draw_lines_loop2
  move.w  (a5)+,d0           ;Startwerte der Punkte P1,P2
  move.w  (a5),d2
  movem.w (a1,d0.w*2),d0-d1  ;P1(x,y)
  movem.w (a1,d2.w*2),d2-d3  ;P2(x,y)
  GET_LINE_PARAMETERS bv,AREAFILL,,extra_pf1_plane_width*extra_pf1_depth
  add.l   a2,d1              ;+ Bildadresse
  add.l   a3,d0              ;restliche BLTCON0 & BLTCON1-Bits setzen
bv_draw_lines_check_bitplane1
  btst    #0,d7              ;Bitplane 1 ?
  beq.s   bv_draw_lines_check_bitplane2 ;Nein -> verzweige
  WAITBLITTER
  move.l  d0,BLTCON0-DMACONR(a6) ;Bits 31-16: BLTCON0, Bits 15-0: BLTCON1
  move.w  d3,BLTAPTL-DMACONR(a6) ;(dy)-(2*dx)
  move.l  d1,BLTCPT-DMACONR(a6) ;Playfield lesen
  move.l  d1,BLTDPT-DMACONR(a6) ;Bild schreiben
  move.l  d4,BLTBMOD-DMACONR(a6) ;Bits 31-16: 4*dy, Bits 15-0: 4*(dy-dx)
  move.w  d2,BLTSIZE-DMACONR(a6) ;Blitter starten
bv_draw_lines_check_bitplane2
  btst    #1,d7              ;Bitplane 2 ?
  beq.s   bv_draw_lines_no_line ;Nein -> verzweige
  moveq   #extra_pf1_plane_width,d5
  add.l   d5,d1              ;n�chste Plane
  WAITBLITTER
  move.l  d0,BLTCON0-DMACONR(a6) ;Bits 31-16: BLTCON0, Bits 15-0: BLTCON1
  move.w  d3,BLTAPTL-DMACONR(a6) ;(dy)-(2*dx)
  move.l  d1,BLTCPT-DMACONR(a6) ;Playfield lesen
  move.l  d1,BLTDPT-DMACONR(a6) ;Bild schreiben
  move.l  d4,BLTBMOD-DMACONR(a6) ;Bits 31-16: 4*dy, Bits 15-0: 4*(dy-dx)
  move.w  d2,BLTSIZE-DMACONR(a6) ;Blitter starten
bv_draw_lines_no_line
  dbf     d6,bv_draw_lines_loop2
bv_draw_lines_no_face
  swap    d7                 ;Fl�chenz�hler 
  addq.w  #4,a0              ;Farbnummer und Anzahl der Linien �berspringen
  dbf     d7,bv_draw_lines_loop1
  move.l  variables+save_a7(pc),a7 ;Alten Stackpointer 
  movem.l (a7)+,a3-a5
  move.w  #DMAF_BLITHOG,DMACON-DMACONR(a6) ;BLTPRI aus
bv_no_draw_lines
  rts
  CNOP 0,4
bv_draw_lines_init
  move.w  #DMAF_BLITHOG+DMAF_SETCLR,DMACON-DMACONR(a6) ;BLTPRI an
  WAITBLITTER
  move.l  #$ffff8000,BLTBDAT-DMACONR(a6) ;Bits 31-16: Linientextur, Bits 0-15: Linientextur mit MSB beginnen
  moveq   #FALSE,d0
  move.l  d0,BLTAFWM-DMACONR(a6) ;Keine Ausmaskierung
  moveq   #extra_pf1_plane_width*extra_pf1_depth,d0 ;Moduli f�r Interleaved-Bitmaps
  move.w  d0,BLTCMOD-DMACONR(a6)
  move.w  d0,BLTDMOD-DMACONR(a6)
  rts

; ** Bild f�llen **
; -----------------
  CNOP 0,4
bv_fill_image
  move.l  extra_pf2(a3),a0
  WAITBLITTER
  move.l  (a0),a0
  move.l  #((BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC)<<16)+(BLTCON1F_DESC+BLTCON1F_EFE),BLTCON0-DMACONR(a6) ;Minterm D=A, F�ll-Modus, R�ckw�rts
  add.l   #(extra_pf1_plane_width*extra_pf1_y_size*extra_pf1_depth)-2,a0 ;Ende des Bildes
  move.l  a0,BLTAPT-DMACONR(a6) ;Quelle
  move.l  a0,BLTDPT-DMACONR(a6) ;Ziel
  moveq   #0,d0
  move.l  d0,BLTAMOD-DMACONR(a6) ;A+D-Mod
  move.w  #(bv_fill_blit_y_size*bv_fill_blit_depth*64)+(bv_fill_blit_x_size/16),BLTSIZE-DMACONR(a6)
  rts

; ** Puffer in Sprite-Strukturen kopieren **
; ------------------------------------------
  CNOP 0,4
bv_copy_image
  move.l  a4,-(a7)
  move.l  extra_pf3(a3),a0
  move.l  (a0),a0            ;Puffer
  lea     spr_pointers_construction+(6*4)(pc),a2 ;Aufbau-Sprites
  move.l  (a2)+,a1           ;Sprite6
  ADDF.W  (spr_pixel_per_datafetch/4),a1 ;Header �berspringen
  move.l  (a2),a2            ;Sprite7
  ADDF.W  (spr_pixel_per_datafetch/4),a2 ;Header �berspringen
  moveq   #bv_image_y_size-1,d7 ;Anzahl der Zeilen zum Kopieren
bv_copy_image_loop
  movem.l (a0)+,d0-d6/a4     ;Bitplane 1&2 mit jeweils 128 Pixel lesen
  move.l  d0,(a1)+           ;Sprite0 Bitplane1 64 Pixel
  move.l  d1,(a1)+
  move.l  d2,(a2)+           ;Sprite1 Bitplane1 64 Pixel
  move.l  d3,(a2)+
  move.l  d4,(a1)+           ;Sprite0 Bitplane2 64 Pixel
  move.l  d5,(a1)+
  move.l  d6,(a2)+           ;Sprite1 Bitplane2 64 Pixel
  move.l  a4,(a2)+
  dbf     d7,bv_copy_image_loop
  move.l  (a7)+,a4
  rts

; ** Sprites bewegen **
; ---------------------
  CNOP 0,4
bv_move_sprites
  movem.l a3-a6,-(a7)
  move.w  bv_sprite_x_coordinate(a3),d3 ;X-Koord
  move.w  bv_sprite_y_coordinate(a3),d4 ;Y-Koord
  move.w  bv_sprite_x_direction(a3),d5 ;X-Richtung
  moveq   #bv_sprite_y_center,d6
  lea     spr_pointers_construction+(6*4)(pc),a1 ;Zeiger auf Sprites
  move.w  #bv_sprite_x_max,a2
  move.w  #bv_sprite_y_max,a4
  move.w  #bv_sprite_x_center,a5
  add.w   d5,d3              ;X-Pos. erh�hen/verringern
bv_check_x_min
  IFNE bv_sprite_x_min
    cmp.w   #bv_sprite_x_min,d3 ;X >= X-Min ?
  ENDC
  bge.s   bv_check_x_max     ;Ja  -> verzweige
  moveq   #bv_sprite_x_min,d3 ;X zur�cksetzen
  neg.w   d5                 ;X-Richtung umkehren
bv_check_x_max
  cmp.w   a2,d3              ;X < X-Max ?
  blt.s   bv_set_x_movement_values ;Ja -> verzweige
  move.w  a2,d3              ;X zur�cksetzen
  neg.w   d5                 ;X-Richtung umkehren
bv_set_x_movement_values
  move.w  d3,bv_sprite_x_coordinate(a3) ;X-Pos. retten
  add.w   a5,d3              ;+ X-Mittelpunkt
  move.w  d5,bv_sprite_x_direction(a3) ;X-Richtung retten

  move.w  bv_sprite_y_direction(a3),d5 ;Y-Richtung
  add.w   d5,d4              ;Y-Pos. erh�hen/verringern
bv_check_y_min
  IFNE bv_sprite_y_min
    cmp.w   #bv_sprite_y_min,d4 ;Y >= Y-Min ?
  ENDC
  bge.s   bv_check_y_max     ;Ja -> verzweige
  moveq   #bv_sprite_y_min,d4 ;Y zur�cksetzen
  neg.w   d5                 ;Y-Richtung �ndern
bv_check_y_max
  cmp.w   a4,d4              ;Y < Y-Max ?
  blt.s   bv_set_y_movement_values ;Ja -> verzweige
  move.w  a4,d4              ;Y zur�cksetzen
  neg.w   d5                 ;Y-Richtung �ndern
bv_set_y_movement_values
  move.w  d4,bv_sprite_y_coordinate(a3) ;Y-Position retten
  add.w   d6,d4              ;+ Y-Mittelpunkt
  move.w  d5,bv_sprite_y_direction(a3) ;Y-Richtung retten

bv_set_sprites_positions
  move.w  #spr_x_size2*4,a2  ;X-Offset n�chstes Sprite
  moveq   #bv_used_sprites_number-1,d7 ;Anzahl der Objekte
bv_move_sprites_loop
  move.l  (a1)+,a0           ;Sprite-Struktur
  move.w  d3,d0              ;X-Pos. 
  move.w  d4,d1              ;Y-Pos. 
  MOVEF.W bv_image_y_size,d2 ;H�he
  add.w   d1,d2              ;H�he zu Y addieren
  SET_SPRITE_POSITION d0,d1,d2
  move.w  d1,(a0)            ;SPRxPOS
  add.w   a2,d3              ;X-Position des n�chsten Sprites
  move.w  d2,spr_pixel_per_datafetch/8(a0) ;SPRxCTL
  dbf     d7,bv_move_sprites_loop
  movem.l (a7)+,a3-a6
  rts

; ** 2xCos-Schwabbel-Effekt **
; ----------------------------
  CNOP 0,4
bv_wobble_sprites
  movem.l a4-a6,-(a7)
  move.w  bv_wobble_x_radius_3),d1 ;X-Winkel
  move.w  d1,d0              ;retten
  MOVEF.W sine_table_length-1,d5
  addq.w  #bv_wobble_x_radius_angle_speed,d0 ;n�chster X-Radius-Winkel
  move.w  bv_wobble_x_angle(a3),d2 ;X-Winkel
  and.w   d5,d0              ;�berlauf entfernen
  move.w  d0,bv_wobble_x_radie(a3) ;Startwert retten
  move.w  d2,d0              ;retten
  addq.w  #bv_wobble_x_angle_speed,d0 ;n�chster X-Winkel
  move.w  d5,d0              ;�berlauf entfernen
  move.w  d0,bv_wobble_x_angle(a3) ;Startwert retten
  lea     spr_pointers_construction+(6*4)(pc),a0 ;Zeiger auf Sprites
  move.l  (a0)+,a2           ;Sprite6-Struktur
  move.w  (a2),a5            ;SPR6POS
  move.l  (a0),a2            ;Sprite7-Struktur
  move.w  (a2),a6            
  lea     sine_table(pc),a0
  move.l  cl1_construction2(a3),a1
  ADDF.W  cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subext1_SPR6POS+2,a1 ;CL
  move.w  #bv_wobble_x_center,a2
  move.w  #cl1_subextension1_SIZE,a4
  MOVEF.W cl2_display_y_size-1,d7 ;Anzahl der Zeilen
bv_wobble_sprites_loop1
  moveq   #rz_display_y_scale_factor-1,d6 ;Anzahl der Abschnitte f�r Y-Skalierung
bv_wobble_sprites_loop2
  move.l  (a0,d1.w*4),d0     ;cos(w)
  MULUF.L bv_wobble_x_radius*4,d0,d3 ;xr'=(xr*cos(w))/2*^15
  swap    d0
  muls.w  2(a0,d2.w*4),d0    ;x'=(xr'*cos(w))/2*^15
  swap    d0
  add.w   a2,d0              -Mittelpunkt
  move.w  d0,d3              ;retten
  add.w   a5,d0              ;x' + vertikaler/horizontaler Startwert des Sprites6
  move.w  d0,(a1)            ;Neue SPR6POS in CL Schreiben
  addq.w  #bv_wobble_x_radius_angle_step,d1 ;n�chster X-Radius-Winkel
  addq.w  #bv_wobble_x_angle_step,d2 ;n�chster X-Winkel
  and.w   d5,d1              ;�berlauf entfernen
  and.w   d5,d2              ;�berlauf entfernen
  add.w   a6,d3              ;x' + vertikaler/horizontaler Startwert des Sprites7
  move.w  d3,4(a1)           ;Neue SPR7POS in CL schreiben
  add.l   a4,a1              ;n�chste Zeile in CL
  dbf     d6,bv_wobble_sprites_loop2
  addq.w  #8,a1              ;COP2LCH + COP2LCL �berspringen
  dbf     d7,bv_wobble_sprites_loop1
  movem.l (a7)+,a4-a6
  rts

; ** Bild rotieren/zoomen **
; --------------------------
  CNOP 0,4
rotation_zoomer
  tst.w   rz_active(a3)
  bne     no_rotation_zoomer
  movem.l a3-a6,-(a7)
  lea     sine_table(pc),a0
  move.w  rz_z_rotation_angle(a3),d4 ;Rotations-Winkel 
  move.w  d4,d3              ;Rotations-Winkel retten
  move.w  rz_zoom_angle(a3),d5 ;Zoom-Winkel 
  IFNE rz_table_length_256
    MOVEF.W sine_table_length-1,d6 ;�berlauf
  ENDC
  move.w  2(a0,d4.w*4),d1     ;sin(w)
  IFEQ rz_table_length_256
    add.b   #sine_table_length/4,d4 ;+ 90 Grad
  ELSE
    add.w   #sine_table_length/4,d4 ;+ 90 Grad
  ENDC
  move.w  2(a0,d5.w*4),d2     ;sin(w) f�r Zoom
  IFEQ rz_table_length_256
    addq.b  #rz_z_rotation_angle_speed,d3 ;n�chster Rotations-Winkel
  ELSE
    and.w   d6,d4            ;�berlauf entfernen
    addq.w  #rz_z_rotation_angle_speed,d3 ;n�chster Rotations-Winkel
  ENDC
  move.w  2(a0,d4.w*4),d0     ;cos(w)
  IFEQ rz_table_length_256
    tst.w   rz_zoomer_active(a3) ;Zoomer an?
    bne.s   rz_no_zoomer     ;Nein -> verzweige
    addq.b  #rz_zoom_angle_speed,d5 ;n�chster Zoom-Winkel
rz_no_zoomer
  ELSE
    tst.w   rz_zoomer_active(a3) ;Zoomer an?
    bne.s   rz_no_zoomer    ;Nein -> verzweige
    addq.w  #rz_zoom_angle_speed,d5 ;n�chster Zoom-Winkel
    and.w   d6,d5            ;�berlauf entfernen
rz_no_zoomer
    and.w   d6,d3            ;�berlauf entfernen
  ENDC

; ** Zoomfaktor berechnen **
; --------------------------
  IFEQ rz_zoom_radius-4096
    asr.w   #3,d2            ;zoom'=(zoomr*sin(w))/2^15
  ELSE
    IFEQ rz_zoom_radius-2048
      asr.w   #4,d2          ;zoom'=(zoomr*sin(w))/2^15
    ELSE
      IFEQ rz_zoom_radius-1024
        asr.w   #5,d2        ;zoom'=(zoomr*sin(w))/2^15
      ELSE
        MULSF.W rz_zoom_radius*2,d2,d6 ;zoom=(zoomr*sin(w))/2^15
        swap    d2
      ENDC
    ENDC
  ENDC
  move.w  d3,rz_z_rotation_angle(a3) ;Rotations-Winkel retten
  add.w   #rz_zoom_center,d2 ;+ Zoom-Mittelpunkt
  move.w  d5,rz_zoom_angle(a3) ;Zoom-Winkel retten
  muls.w  d2,d0              ;x'=(zoom'*cos(w))/2^15
  muls.w  d2,d1              ;y'=(zoom'*sin(w))/2^15
  swap    d0
  swap    d1

; ** Rotation um die Z-Achse **
; -----------------------------
  moveq   #rz_Ax,d2         ;X links oben
  muls.w  d0,d2              ;Ax*cos(w)
  moveq   #rz_Ay,d3         ;Y links oben
  muls.w  d1,d3              ;Ay*sin(w)
  move.l  extra_memory(a3),a0 ;Zeiger auf Tabelle mit Switchwerten
  add.l   d3,d2              ;Ax'=Ax*cos(w)+Ay*sin(w)
  moveq   #rz_Bx,d3         ;X rechts oben
  muls.w  d1,d3              ;Bx*sin(w)
  moveq   #rz_By,d4         ;Y rechts oben
  muls.w  d0,d4              ;By*cos(w)
  add.w   #rz_z_rotation_x_center<<8,d2 ;x' + X-Mittelpunkt
  add.l   d4,d3              ;By'=Bx*sin(w)+By*cos(w)

; ** Translation **
; -----------------
  move.w  d2,a4              ;X-Mittelpunkt retten
  add.w   #rz_z_rotation_y_center<<8,d3 ;y' + Y-Mittelpunkt
  move.l  cl2_construction2(a3),a1
  move.w  d3,a5              ;Y-Mittelpunkt retten

; ** Farbwerte in Copperliste kopieren **
; ---------------------------------------
  move.l  a7,save_a7(a3)     
  move.w  #cl2_extension1_SIZE,a2
  move.w  d0,a3              ;cos(w) retten
  move.w  d1,a7              ;sin(w)
  add.w   a3,a3              ;*2 ist notwendig, um die 2:1 Pixelverzerrung auszugleichen
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPLCON4_1+2,a1 ;CL
  move.w  #(cl2_extension1_SIZE*cl2_display_y_size)-4,a6
  add.w   a7,a7              ;*2 ist notwendig, um die 2:1 Pixelverzerrung auszugleichen
  moveq   #TRUE,d2           ;Langwortzugriff
  moveq   #cl2_display_width-1,d7 ;Anzahl der Spalten
rotation_zoomer_loop1
  move.w  a4,d4              ;X Linke obere Ecke in Bild
  move.w  a5,d5              ;Y Linke obere Ecke in Bild
  moveq   #cl2_display_y_size-1,d6 ;Anzahl der Zeilen
rotation_zoomer_loop2
  move.w  d4,d3              ;X-Pos in Bild 
  move.w  d5,d2              ;Y-Pos in Bild 
  lsr.w   #8,d3              ;Bits in richtige Postion bringen
  move.b  d3,d2              ;Bits 15-8 = Y-Offset, Bits 7-0 = X-Offset
  move.b  (a0,d2.l),(a1)     ;Switchwert setzen
  add.w   d1,d4              ;n�chste Pixel-Spalte in Bild
  add.w   d0,d5              ;n�chste Pixel-Zeile in Bild
  add.l   a2,a1              ;n�chste Zeile in CL
  dbf     d6,rotation_zoomer_loop2
  add.w   a3,a4              ;n�chste X-Pos in Bild
  sub.w   a7,a5              ;n�chste Y-Pos in Bild
  sub.l   a6,a1              ;n�chste Spalte in CL
  dbf     d7,rotation_zoomer_loop1
  move.l  variables+save_a7(pc),a7 ;Alter Stackpointer
  movem.l (a7)+,a3-a6
no_rotation_zoomer
  rts


; ** Grafik einblenden **
; -----------------------
  CNOP 0,4
image_fader_in
  tst.w   ifi_active(a3)     ;Image-Fader-In an ?
  bne.s   no_image_fader_in  ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  ifi_fader_angle(a3),d2 ;Fader-Winkel 
  move.w  d2,d0
  ADDF.W  ifi_fader_angle_speed,d0 ;n�chster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   ifi_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
ifi_no_restart_fader_angle
  move.w  d0,ifi_fader_angle(a3) 
  MOVEF.W if_colors_number*3,d6 ;Z�hler
  lea     sine_table(pc),a0
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L ifi_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  ifi_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     pf1_color_table(pc),a0 ;Puffer f�r Farbwerte
  lea     ifi_color_table(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert f�r Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 l�schen
  move.l  d0,a2              ;Additions-/Subtraktionswert f�r Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert f�r Gr�n
  MOVEF.W if_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,if_colors_counter(a3) ;Image-Fader-In fertig ?
  bne.s   no_image_fader_in  ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,ifi_active(a3)  ;Image-Fader-In aus
no_image_fader_in
  rts

; ** Grafik ausblenden **
; -----------------------
  CNOP 0,4
image_fader_out
  tst.w   ifo_active(a3)     ;Image-Fader-Out an ?
  bne.s   no_image_fader_out ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  ifo_fader_angle(a3),d2 ;Fader-Winkel 
  move.w  d2,d0
  ADDF.W  ifo_fader_angle_speed,d0 ;n�chster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   ifo_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
ifo_no_restart_fader_angle
  move.w  d0,ifo_fader_angle(a3) 
  MOVEF.W if_colors_number*3,d6 ;Z�hler
  lea     sine_table(pc),a0
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L ifo_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  ifo_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     pf1_color_table(pc),a0 ;Puffer f�r Farbwerte
  lea     ifo_color_table(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert f�r Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 l�schen
  move.l  d0,a2              ;Additions-/Subtraktionswert f�r Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert f�r Gr�n
  MOVEF.W if_colors_number-1,d7 ;Anzahl der Farben
  bsr.s   if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,if_colors_counter(a3) ;Image-Fader-Out fertig ?
  bne.s   no_image_fader_out ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,ifo_active(a3)  ;Image-Fader-Out aus
  move.w  d0,part_title_active(a3) ;Title-Part deaktivieren
no_image_fader_out
  rts

  COLOR_FADER if

; ** Farbwerte in Copperliste kopieren **
; ---------------------------------------
  CNOP 0,4
if_copy_color_table
  IFNE cl1_size2
    move.l  a4,-(a7)
  ENDC
  tst.w   if_copy_colors_active(a3) ;Kopieren der Farbwerte beendet ?
  bne.s   if_no_copy_color_table ;Ja -> verzweige
  move.w  #$0f0f,d3          ;Maske f�r RGB-Nibbles
  IFGT if_colors_number-32
    moveq   #TRUE,d4         ;Color-Bank Farbregisterz�hler
  ENDC
  lea     pf1_color_table(pc),a0 ;Puffer f�r Farbwerte
  move.l  cl1_display(a3),a1 ;CL
  ADDF.W  cl1_COLOR00_high1+2,a1
  IFNE cl1_size1
    move.l  cl1_construction1(a3),a2 ;CL
    ADDF.W  cl1_COLOR00_high1+2,a2
  ENDC
  IFNE cl1_size2
    move.l  cl1_construction2(a3),a4 ;CL
    ADDF.W  cl1_COLOR00_high1+2,a4
  ENDC
  MOVEF.W if_colors_number-1,d7 ;Anzahl der Farben
if_copy_color_table_loop
  move.l  (a0)+,d0           arbwert
  move.l  d0,d2              ;retten
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a1)            ;COLORxx High-Bits
  IFNE cl1_size1
    move.w  d0,(a2)          ;COLORxx High-Bits
  ENDC
  IFNE cl1_size2
    move.w  d0,(a4)          ;COLORxx High-Bits
  ENDC
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a1) ;Low-Bits COLORxx
  addq.w  #4,a1              ;n�chstes Farbregister
  IFNE cl1_size1
    move.w  d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a2) ;Low-Bits COLORxx
    addq.w  #4,a2            ;n�chstes Farbregister
  ENDC
  IFNE cl1_size2
    move.w  d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a4) ;Low-Bits COLORxx
    addq.w  #4,a4            ;n�chstes Farbregister
  ENDC
  IFGT if_colors_number-32
    addq.b  #1*8,d4          ;Farbregister-Z�hler erh�hen
    bne.s   if_no_restart_color_bank ;Nein -> verzweige
    addq.w  #4,a1            ;CMOVE �berspringen
    IFNE cl1_size1
      addq.w  #4,a2          ;CMOVE �berspringen
    ENDC
    IFNE cl1_size2
      addq.w  #4,a4          ;CMOVE �berspringen
    ENDC
if_no_restart_color_bank
  ENDC
  dbf     d7,if_copy_color_table_loop
  tst.w   if_colors_counter(a3) ;Fading beendet ?
  bne.s   if_no_copy_color_table ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,if_copy_colors_active(a3) ;Kopieren beendet
if_no_copy_color_table
  IFNE cl1_size2
    move.l  (a7)+,a4
  ENDC
  rts

; ** Blind-Fader-In **
; --------------------
  CNOP 0,4
blind_fader_in
  tst.w   bfi_active(a3)    ;Blind-Fader-In an ?
  bne.s   bfi_no_blind_fader_in ;Nein -> verzweige
  move.l  a4,-(a7)
  move.w  bf_address_offsets_table_start(a3),d2 ;Startwert 
  MOVEF.W bf_table_length-1,d
  move.w  d2,d0              ;retten
  MOVEF.L cl2_extension1_SIZE,d4
  addq.w  #bf_speed,d0       ;Startwert erh�hen
  moveq   #bf_step2,d5
  cmp.w   #(bf_table_length/2)+1,d0 ;Ende der Tabelle erreicht ?
  ble.s   bfi_not_finished   ;Nein -> verzweige
bfi_finished
  move.l  (a7)+,a4
  moveq   #FALSE,d0
  move.w  d0,bfi_active(a3)  ;Blind-Fader-In aus
  bra.s   bfi_no_blind_fader_in
  CNOP 0,4
bfi_not_finished
  move.w  d0,bf_address_offsets_table_start(a3) ;retten
  lea     bf_address_offsets_table(pc),a0 ;Tabelle mit Registeroffsets
  IFNE cl2_size1
    move.l  cl2_construction1(a3),a1 ;1. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a1
    ENDC
  ENDC
  IFNE cl2_size2
    move.l  cl2_construction2(a3),a2 ;2. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a2
    ENDC
  ENDC
  IFNE cl2_size3
    move.l  cl2_display(a3),a4 ;3. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a4
    ENDC
  ENDC
  moveq   #bf_lamellas_number-1,d7 ;Anzahl der Lamellen
blind_fader_in_loop1
  move.w  d2,d1              ;Startwert 
  moveq   #bf_lamella_height-1,d6 ;H�he der Lamelle
blind_fader_in_loop2
  move.w  (a0,d1.w*2),d0     ;Registeroffset aus Tabelle 
  addq.w  #bf_step1,d1       ;n�chster Wert aus Tabelle
  IFNE cl2_size1
    move.w  d0,(a1)          ;Registeroffset in 1. CL schreiben
    add.l   d4,a1            ;n�chste Zeile in 1. CL
  ENDC
  IFNE cl2_size2
    move.w  d0,(a2)          ;Registeroffset in 2. CL schreiben
  add.l   d4,a2              ;n�chste Zeile in 2. CL
  ENDC
  IFNE cl2_size3
    move.w  d0,(a4)          ;Registeroffset in 3. CL schreiben
    add.l   d4,a4            ;n�chste Zeile in 3. CL
  ENDC
  and.w   d3,d1              ;�berlauf entfernen
  dbf     d6,blind_fader_in_loop2
  add.w   d5,d2              ;Startwert erh�hen
  and.w   d3,d2              ;�berlauf entfernen
  dbf     d7,blind_fader_in_loop1
  move.l  (a7)+,a4
bfi_no_blind_fader_in
  rts

; ** Blind-Fader-Out **
; ---------------------
  CNOP 0,4
blind_fader_out
  tst.w   bfo_active(a3)     ;Blind-Fader-Out an ?
  bne     bfo_no_blind_fader_out ;Nein -> verzweige
  move.l  a4,-(a7)
  move.w  bf_address_offsets_table_start(a3),d2 ;Startwert 
  MOVEF.W bf_table_length-1,d
  move.w  d2,d0              ;retten
  MOVEF.L cl2_extension1_SIZE,d4
  subq.w  #bf_speed,d0       ;Startwert verringern
  bpl.s   bfo_not_finished   ;Wenn positiv -> verzweige
bfo_finished
  move.l  (a7)+,a4
  moveq   #FALSE,d0
  move.w  d0,bfo_active(a3)  ;Blind-Fader-Out aus
  move.w  d0,part_main_active(a3) ;Main-Part deaktivieren
  tst.w   pt_fade_out_music_active(a3) ;Wird die Musik ausgeblendet ?
  beq.s   bfo_no_blind_fader_out ;Ja -> verzweige
bfo_restart_intro
  bsr     init_own_variables2
  bsr     wst_init_characters_x_positions
  bsr     init_color_registers2
  bsr     set_noop_screen
  bsr     cl1_set_branches_pointers
  move.w  #DMAF_RASTER+DMAF_SETCLR,DMACON-DMACONR(a6) ;Bitplane-DMA an
  moveq   #0,d0
  move.w  d0,COPJMP1-DMACONR(a6) ;1. Copperliste neu starten, damit die ge�nderte Palette dargestellt wird
  bra.s   bfo_no_blind_fader_out
  CNOP 0,4
bfo_not_finished
  move.w  d0,bf_address_offsets_table_start(a3) ;retten
  moveq   #bf_step2,d5
  lea     bf_address_offsets_table(pc),a0 ;Tabelle mit Registeroffsets
  IFNE cl2_size1
    move.l  cl2_construction1(a3),a1 ;1. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a1
    ENDC
  ENDC
  IFNE cl2_size2
    move.l  cl2_construction2(a3),a2 ;2. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a2
    ENDC
  ENDC
  IFNE cl2_size3
    move.l  cl2_display(a3),a4 ;3. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a4
    ENDC
  ENDC
  moveq   #bf_lamellas_number-1,d7 ;Anzahl der Lamellen
blind_fader_out_loop1
  move.w  d2,d1              ;Startwert 
  moveq   #bf_lamella_height-1,d6 ;H�he der Lamelle
blind_fader_out_loop2
  move.w  (a0,d1.w*2),d0     ;Registeradresse aus Tabelle 
  addq.w  #bf_step1,d1       ;n�chster Wert aus Tabelle
  IFNE cl2_size1
    move.w  d0,(a1)          ;Registeroffset in 1. CL schreiben
    add.l   d4,a1            ;n�chste Zeile in 1. CL
  ENDC
  IFNE cl2_size2
    move.w  d0,(a2)          ;Registeroffset in 2. CL schreiben
  add.l   d4,a2              ;n�chste Zeile in 2. CL
  ENDC
  IFNE cl2_size3
    move.w  d0,(a4)          ;Registeroffset in 3. CL schreiben
    add.l   d4,a4            ;n�chste Zeile in 3. CL
  ENDC
  and.w   d3,d1              ;�berlauf entfernen
  dbf     d6,blind_fader_out_loop2
  add.w   d5,d2              ;Startwert erh�hen
  and.w   d3,d2              ;�berlauf entfernen
  dbf     d7,blind_fader_out_loop1
  move.l  (a7)+,a4
bfo_no_blind_fader_out
  rts

  CNOP 0,4
init_color_registers2
; ***** Bild *****
  lea     ifo_color_table(pc),a0 ;Farbwerte
  move.l  cl1_construction2(a3),a1 ;CL
  ADDF.W  cl1_COLOR00_high1+2,a1
  move.l  cl1_display(a3),a2 ;CL
  ADDF.W  cl1_COLOR00_high1+2,a2
  move.w  #$f0f,d3           ;Maske f�r gb/GB-Bits
  IFGT pf1_colors_number-32
    moveq   #TRUE,d4         ;Farbregisterz�hler
  ENDC
  moveq   #pf1_colors_number-1,d7 ;Anzahl der Farben
init_color_registers2_loop
  move.l  (a0)+,d0           -Farbwert 
  move.l  d0,d1              ;retten
  RGB8_TO_RGB4HI d0,d2,d3
  move.w  d0,(a1)            ;High-Bits COLORxx
  addq.w  #4,a1
  move.w  d0,(a2)            ;High-Bits COLORxx
  RGB8_TO_RGB4LO d1,d2,d3
  move.w  d2,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a1) ;Low-Bits COLORxx
  addq.w  #4,a2
  move.w  d2,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a2) ;Low-Bits COLORxx
  IFGT pf1_colors_number-32
    addq.b  #1*8,d4          ;Farbregister-Z�hler erh�hen
    bne.s   no_restart_color_bank ;Nein -> verzweige
    addq.w  #4,a1            ;BPLCON3 �berspringen
    addq.w  #4,a2            ;BPLCON3 �berspringen
no_restart_color_bank
  ENDC
  dbf     d7,init_color_registers2_loop
; **** Sprites ****
  lea     spr_color_table(pc),a0 ;Farbwerte
  move.l  cl1_construction2(a3),a1 ;CL
  ADDF.W  cl1_COLOR00_high5+2,a1
  move.l  cl1_display(a3),a2 ;CL
  ADDF.W  cl1_COLOR00_high5+2,a2
  move.w  #$f0f,d3           ;Maske f�r gb/GB-Bits
  IFGT spr_colors_number-32
    moveq   #TRUE,d4         ;Farbregisterz�hler
  ENDC
  moveq   #spr_colors_number-1,d7 ;Anzahl der Farben
init_color_registers2_loop2
  move.l  (a0)+,d0           -Farbwert 
  move.l  d0,d1              ;retten
  RGB8_TO_RGB4HI d0,d2,d3
  move.w  d0,(a1)            ;High-Bits COLORxx
  addq.w  #4,a1
  move.w  d0,(a2)            ;High-Bits COLORxx
  RGB8_TO_RGB4LO d1,d2,d3
  move.w  d2,cl1_COLOR00_low5-cl1_COLOR00_high5-4(a1) ;Low-Bits COLORxx
  addq.w  #4,a2
  move.w  d2,cl1_COLOR00_low5-cl1_COLOR00_high5-4(a2) ;Low-Bits COLORxx
  IFGT spr_colors_number-32
    addq.b  #1*8,d4          ;Farbregister-Z�hler erh�hen
    bne.s   no_restart_color_bank2 ;Nein -> verzweige
    addq.w  #4,a1            ;BPLCON3 �berspringen
    addq.w  #4,a2            ;BPLCON3 �berspringen
no_restart_color_bank2
  ENDC
  dbf     d7,init_color_registers2_loop2
  rts

  CNOP 0,4
set_noop_screen
  IFNE cl2_size1
    move.l  cl2_construction1(a3),a0 ;1. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a0
    ENDC
  ENDC
  IFNE cl2_size2
    move.l  cl2_construction2(a3),a1 ;2. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a1
    ENDC
  ENDC
  IFNE cl2_size3
    move.l  cl2_display(a3),a2 ;3. CL
    IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
      ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1DAT,a2
    ENDC
  ENDC
  move.w  #BPL1DAT,d0
  MOVEF.L cl2_extension1_SIZE,d1
  moveq   #cl2_display_y_size-1,d7 ;Anzahl der Zeilen
set_noop_screen_loop1
  IFNE cl2_size1
    move.w  d0,(a0)           ;Offset BPL1DAT setzen
    add.l   d1,a0
  ENDC
  IFNE cl2_size2
    move.w  d0,(a1)
    add.l   d1,a1
  ENDC
  IFNE cl2_size3
    move.w  d0,(a2)
    add.l   d1,a2
  ENDC
  dbf     d7,set_noop_screen_loop1
  rts

; ** W�rfel heranzoomen **
; ------------------------
  CNOP 0,4
cube_zoomer_in
  tst.w   czi_active(a3)     ;Cube-Zoomer-In an ?
  bne.s   no_cube_zoomer_in  
  lea     sine_table(pc),a0
  move.w  czi_zoom_angle(a3),d1 ;Zoom-In-Winkel 
  moveq   #0,d0           ;Langwort-Zugriff
  move.w  2(a0,d1.w*4),d0    ;sin(w)
  add.w   #czi_zoom_center,d0 ;+ ZMittelpunkt
  move.l  d0,bv_zoom_distance(a3) ;retten
  addq.w  #czi_zoom_angle_speed,d1 ;n�chster Zoom-In-Winkel
  cmp.w   #sine_table_length/4,d1 ;90 Grad erreicht ?
  bgt.s   czi_finished       ;Ja -> verzweige
  move.w  d1,czi_zoom_angle(a3) ;neuen Zoom-In-Winkel retten
  rts
  CNOP 0,4
czi_finished
  moveq   #FALSE,d0
  move.w  d0,czi_active(a3)  ;Cube-Zoomer-In aus
no_cube_zoomer_in
  rts


; ** Funktionstasten abfragen **
; ------------------------------
  CNOP 0,4
keyboard_handler
  tst.w   bv_active(a3)      ;W�rfel aktiv ?
  bne     kh_no_keyboard_handler ;Nein ->verzweige
  btst    #CIAICRB_SP,CIAICR(a4) ;CIA-A SP-Interrupt ?
  beq     kh_no_keyboard_handler ;Nein verzweige
  btst    #CIACRAB_SPMODE,CIACRA(a4) ;Ausgabe ?
  bne     kh_no_keyboard_handler ;Ja -> verzweige
  move.b  CIASDR(a4),d0      ;Tastencode 
  ror.b   #1,d0              ;Bits in richtige Position bringen
  not.b   d0                 ;Alle Bits umdrehen
  bmi.s   kh_handshake       ;Taste losgelassen ?
  tst.b   kh_key_flag(a3)    ;Bereits ein Code gespeichert ?
  bne.s   kh_handshake       ;Ja -> verzweige
  move.b  d0,kh_key_code(a3) ;Code speichern
  not.b   kh_key_flag(a3)    ;Key-Flag setzen
kh_handshake
  moveq   #CIACRAF_SPMODE,d0
  or.b    d0,CIACRA(a4)      ;Serieller-Port = Ausgabe, Handshake starten
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a4)      ;Wartezeit 200 �s
kh_delay_loop
  btst    #CIACRBB_START,CIACRB(a4)
  bne.s   kh_delay_loop
  moveq   #~CIACRAF_SPMODE,d0
  and.b   d0,CIACRA(a4)      ;Serieller-Port = Eingabe, Handshake beenden
kh_check_key
  clr.b   kh_key_flag(a3)    ;Key-Flag l�schen
  move.b  kh_key_code(a3),d0
  cmp.b   #keyboard_keycode_F1,d0 ;F1 gedr�ckt ?
  beq.s   kh_set_xyz_rotation_angle_speed1
  cmp.b   #keyboard_keycode_F2,d0 ;F2 gedr�ckt ?
  beq.s   kh_set_xyz_rotation_angle_speed2
  cmp.b   #keyboard_keycode_F3,d0 ;F3 gedr�ckt ?
  beq.s   kh_set_xyz_rotation_angle_speed3
  cmp.b   #keyboard_keycode_F4,d0 ;F4 gedr�ckt ?
  beq.s   kh_set_xyz_rotation_angle_speed4
  cmp.b   #keyboard_keycode_F5,d0 ;F5 gedr�ckt ?
  beq.s   kh_set_xyz_rotation_angle_speed5
  cmp.b   #keyboard_keycode_F6,d0 ;F6 gedr�ckt ?
  beq     kh_set_xyz_rotation_angle_speed6
  cmp.b   #keyboard_keycode_F7,d0 ;F7 gedr�ckt ?
  beq     kh_set_xyz_rotation_angle_speed7
  cmp.b   #keyboard_keycode_F8,d0 ;F8 gedr�ckt ?
  beq     kh_set_xyz_rotation_angle_speed8
  cmp.b   #keyboard_keycode_F9,d0 ;F9 gedr�ckt ?
  beq     kh_set_xyz_rotation_angle_speed9
  cmp.b   #keyboard_keycode_F10,d0 ;F10 gedr�ckt ?
  beq     kh_set_xyz_rotation_angle_speed10
kh_no_keyboard_handler
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed1
  moveq   #bv_rotation_x_angle_speed1,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed1,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed1,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed2
  moveq   #bv_rotation_x_angle_speed2,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed2,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed2,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed3
  moveq   #bv_rotation_x_angle_speed3,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed3,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed3,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed4
  moveq   #bv_rotation_x_angle_speed4,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed4,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed4,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed5
  moveq   #bv_rotation_x_angle_speed5,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed5,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed5,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed6
  moveq   #bv_rotation_x_angle_speed6,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed6,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed6,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed7
  moveq   #bv_rotation_x_angle_speed7,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed7,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed7,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed8
  moveq   #bv_rotation_x_angle_speed8,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed8,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed8,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed9
  moveq   #bv_rotation_x_angle_speed9,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed9,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed9,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts
  CNOP 0,4
kh_set_xyz_rotation_angle_speed10
  moveq   #bv_rotation_x_angle_speed10,d2
  move.w  d2,bv_variable_rotation_x_angle_speed(a3)
  moveq   #bv_rotation_y_angle_speed10,d2
  move.w  d2,bv_variable_rotation_y_angle_speed(a3)
  moveq   #bv_rotation_z_angle_speed10,d2
  move.w  d2,bv_variable_rotation_z_angle_speed(a3)
  rts

; ** Mouse-Handler **
; -------------------
  CNOP 0,4
mouse_handler
  btst    #CIAB_GAMEPORT0,CIAPRA(a4) ;Linke Maustaste gedr�ckt ?
  beq.s   mh_quit            ;Ja -> verzweige
  rts
  CNOP 0,4
mh_quit
  move.w  #wst_stop_text-wst_text,wst_text_table_start(a3) ;Scrolltext beenden
  moveq   #FALSE,d0
  move.w  d0,pt_effects_handler_active(a3) ;FX-Abfrage aus
  moveq   #0,d0
  move.w  d0,pt_fade_out_music_active(a3) ;Musik ausblenden
mh_check_part_title
  tst.w   part_title_active(a3) ;Titel-Part aktiv ?
  bne.s   mh_check_part_main ;Nein -> verzweige
  move.w  #if_colors_number*3,if_colors_counter(a3)
  moveq   #0,d0
  move.w  d0,ifo_active(a3)  ;Image-Fader-Out an
  move.w  d0,if_copy_colors_active(a3) ;Kopieren der Farben an
  tst.w   ifi_active(a3)     ;Image-Fader-In aktiv ?
  bne.s   mh_skip1           ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,ifi_active(a3)  ;Image-Fader-In aus
mh_skip1
  rts
  CNOP 0,4
mh_check_part_main
  tst.w   part_main_active(a3) ;Main-Part aktiv ?
  bne.s   mh_skip2           ;Nein -> verzweige
  clr.w   bfo_active(a3)     ;Blind-Fader-Out an
  tst.w   bfi_active(a3)     ;Blind-Fader-In aktiv ?
  bne.s   mh_skip2           ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,bfi_active(a3)  ;Blind-Fader-In aus
mh_skip2
  rts


; ## Interrupt-Routinen ##
; ------------------------

  INCLUDE "int-autovectors-handlers.i"

  IFEQ pt_ciatiming_enabled
; ** CIA-B timer A interrupt server **
; ------------------------------------
  CNOP 0,4
CIAB_TA_int_server
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
    PT_FADE_OUT fx_active

    CNOP 0,4
  ENDC

; ** PT-replay routine **
; -----------------------
  IFD pt_v2.3a pt_effects_handler
    PT2_REPLAY
  ENDC
  IFD pt_v3.0b
    PT3_REPLAY pt_effects_handler
  ENDC

;--> 8xy "Not used/custom" <--
  CNOP 0,4
pt_effects_handler
  tst.w   pt_effects_handler_active(a3) ;Check enabled?
  bne.s   pt_no_trigger_fx   ;No -> skip
  move.b  n_cmdlo(a2),d0     ;Get command data x = Effekt y = TRUE/FALSE
  beq.s   pt_restart_intro
  cmp.b   #$10,d0
  beq.s   pt_start_horiz_scrolltext
  cmp.b   #$20,d0
  beq.s   pt_start_fade_in_image
  cmp.b   #$30,d0
  beq.s   pt_start_fade_out_image
  cmp.b   #$40,d0
  beq.s   pt_start_fade_in_rotation_zoomer
  cmp.b   #$50,d0
  beq     pt_start_cube_zoomer_in
  cmp.b   #$60,d0
  beq     pt_start_zoomer
  cmp.b   #$61,d0
  beq     pt_stop_zoomer
pt_no_trigger_fx
  rts
  CNOP 0,4
pt_restart_intro
  clr.w   bfo_active(a3)     ;Blind-Fader-Out an
  rts
  CNOP 0,4
pt_start_horiz_scrolltext
  clr.w   wst_active(a3)     ;Wave-Scrolltext an
  rts
  CNOP 0,4
pt_start_fade_in_image
  move.l  a0,-(a7)
  move.w  #if_colors_number*3,if_colors_counter(a3)
  moveq   #0,d0
  move.w  d0,ifi_active(a3)  ;Image-Fader-In an
  move.w  d0,if_copy_colors_active(a3) ;Kopieren der Farben an
  move.w  d0,part_title_active(a3) ;Title-Part aktivieren
  move.l  cl1_construction2(a3),a0 ;CL
  move.w  #BPLCON0BITS2,cl1_BPLCON0+2(a0) ;Bitplanes darstellen
  move.l  cl1_display(a3),a0 ;CL
  move.w  #BPLCON0BITS2,cl1_BPLCON0+2(a0)
  move.l  (a7)+,a0
  rts
  CNOP 0,4
pt_start_fade_out_image
  move.w  #if_colors_number*3,if_colors_counter(a3)
  moveq   #0,d0
  move.w  d0,ifo_active(a3)  ;Image-Fader-Out an
  move.w  d0,if_copy_colors_active(a3) ;Kopieren der Farben an
  rts
  CNOP 0,4
pt_start_fade_in_rotation_zoomer
  movem.l d1-d7/a0-a2,-(a7)
  moveq   #0,d0
  move.w  d0,rz_active(a3)   ;Rotation-Zoomer an
  move.w  d0,bfi_active(a3)  ;Blind-Fader-In an
  move.w  d0,part_main_active(a3) ;Main-Part aktivieren
  bsr.s   rz_init_color_registers
  bsr     rz_set_branches_pointers
  move.l  cl1_construction2(a3),a0 ;CL
  move.w  #BPLCON0BITS,cl1_BPLCON0+2(a0) ;Keine Bitplanes darstellen
  move.l  cl1_display(a3),a0 ;CL
  move.w  #BPLCON0BITS,cl1_BPLCON0+2(a0)
  movem.l (a7)+,d1-d7/a0-a2
  rts
  CNOP 0,4
pt_start_cube_zoomer_in
  moveq   #0,d0
  move.w  d0,bv_active(a3)   ;Cube an
  move.w  d0,czi_active(a3)  ;Cube-Zoomer-In an
  rts
  CNOP 0,4
pt_start_zoomer
  clr.w  rz_zoomer_active(a3) ;Zoomer an
  rts
  CNOP 0,4
pt_stop_zoomer
  moveq  #FALSE,d0
  move.w d0,rz_zoomer_active(a3) ;Zoomer aus
  rts

  CNOP 0,4
rz_init_color_registers
  lea     pf1_color_table+(pf1_colors_number*LONGWORDSIZE),a0
  move.l  cl1_construction2(a3),a1 ;CL
  ADDF.W  cl1_COLOR00_high1+2,a1
  move.l  cl1_display(a3),a2 ;CL
  ADDF.W  cl1_COLOR00_high1+2,a2
  move.w  #$f0f,d3           ;Maske gb/GB-Bits
  IFGT if_colors_number-32
    moveq   #TRUE,d4         ;Farbregisterz�hler
  ENDC
  MOVEF.W if_colors_number-1,d7 ;Anzahl der Farben
rz_init_color_registers_loop
  move.l  (a0)+,d0           -Farbwert 
  move.l  d0,d1              ;retten
  RGB8_TO_RGB4HI d0,d2,d3
  move.w  d0,(a1)            ;High-Bits COLORxx
  addq.w  #4,a1
  move.w  d0,(a2)            ;High-Bits COLORxx
  RGB8_TO_RGB4LO d1,d2,d3
  move.w  d1,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a1) ;Low-Bits COLORxx
  addq.w  #4,a2
  move.w  d1,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a2) ;Low-Bits COLORxx
  IFGT if_colors_number-32
    addq.b  #1*8,d4          ;Farbregister-Z�hler erh�hen
    bne.s   rz_no_restart_color_bank ;Nein -> verzweige
    addq.w  #4,a1            ;BPLCON3 �berspringen
    addq.w  #4,a2            ;BPLCON3 �berspringen
rz_no_restart_color_bank
  ENDC
  dbf     d7,rz_init_color_registers_loop
  rts

  CNOP 0,4
rz_set_branches_pointers
  move.l  cl1_construction2(a3),a0 ;Aufbau-CL1
  MOVEF.L cl1_subextension1_SIZE,d2
  move.l  cl2_construction2(a3),d0 ;Einsprungadresse = Aufbau-CL2
  MOVEF.L cl2_extension1_SIZE,d3
  moveq   #cl1_extension1_SIZE,d4
  bsr.s   rz_set_jump_entry_pointers
  move.l  cl1_display(a3),a0 ;Darstellen-CL1
  move.l  cl2_display(a3),d0 ;Einsprungadresse = Darstellen-CL2

; ** Routine set-jump-entry_pointers **
; a0 ... Copperliste1
; d0 ... Einsprungadresse Copperliste2
; d2 ... cl1_subextension1_SIZE
; d3 ... cl2_extension1_SIZE
; MOVEF.cl1_extension1_SIZE
rz_set_jump_entry_pointers
  MOVEF.L cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subextension1_SIZE,d1 ;Offset R�cksprungadresse CL1
  add.l   a0,d1              ;+ R�cksprungadresse CL1
  lea     cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subext1_COP1LCH+2(a0),a1
  ADDF.W  cl1_extension1_entry+cl1_ext1_COP2LCH+2,a0
  moveq   #cl2_display_y_size-1,d7 ;Anzahl der Zeilen
rz_set_branches_loop1
  swap    d0                 ;High
  move.w  d0,(a0)            ;COP2LCH
  swap    d0                 ;Low
  move.w  d0,4(a0)           ;COP2LCL
  moveq   #rz_display_y_scale_factor-1,d6 ;Anzahl der Abschnitte f�r Y-Skalierung
rz_set_branches_loop2
  swap    d1                 ;High-Wert
  move.w  d1,(a1)            ;COP1LCH
  swap    d1                 ;Low-Wert
  move.w  d1,4(a1)           ;COP1LCL
  add.l   d2,d1              ;R�cksprungadresse CL1 erh�hen
  add.l   d2,a1              ;n�chste Zeile in Unterabschnitt der CL1
  dbf     d6,rz_set_branches_loop2
  add.l   d3,d0              ;Einsprungadresse CL2 erh�hen
  add.l   d4,a0              ;n�chste Zeile in CL1
  addq.l  #8,d1              ;CMOVE COP2LCH + CMOVE COP2LCL �berspringen
  addq.w  #8,a1              ;CMOVE COP2LCH + CMOVE COP2LCL �berspringen
  dbf     d7,rz_set_branches_loop1
  rts

; ** CIA-B Timer B interrupt server **
  CNOP 0,4
CIAB_TB_int_server
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


; ** Timer stoppen **
; -------------------

  INCLUDE "continuous-timers-stop.i"


; ## System wieder in Ausganszustand zur�cksetzen ##
; --------------------------------------------------

  INCLUDE "sys-return.i"


; ## Hilfsroutinen ##
; -------------------

  INCLUDE "help-routines.i"


; ## Speicherstellen f�r Tabellen und Strukturen ##
; -------------------------------------------------

  INCLUDE "sys-structures.i"

; ** Farben des ersten Playfields **
; ----------------------------------
  CNOP 0,4
pf1_color_table
  REPT pf1_colors_number
    DC.L COLOR00BITS
  ENDR
  INCLUDE "Daten:Asm-Sources.AGA/projects/Old'scool/colortables/256x256x128-Texture.ct"

; ** Farben der Sprites **
; ------------------------
spr_color_table
  INCLUDE "Daten:Asm-Sources.AGA/projects/Old'scool/colortables/64x56x4-Font.ct"
  INCLUDE "Daten:Asm-Sources.AGA/projects/Old'scool/colortables/64x56x4-Font.ct"
  INCLUDE "Daten:Asm-Sources.AGA/projects/Old'scool/colortables/64x56x4-Font.ct"
  REPT 4
    DC.L COLOR00BITS
  ENDR

; ** Adressen der Sprites **
; --------------------------
spr_pointers_construction
  DS.L spr_number

spr_pointers_display
  DS.L spr_number

; ** Sinus / Cosinustabelle **
; ----------------------------
sine_table
  INCLUDE "sine-table-512x32.i"

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

; **** Wave-Scrolltext ****
; ** ASCII-Buchstaben **
; ----------------------
wst_ASCII
  DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():/\*#@ "
wst_ASCII_end
  EVEN

; ** Offsets der einzelnen Chars **
; ---------------------------------
  CNOP 0,2
wst_characters_offsets
  DS.W wst_ASCII_end-wst_ASCII
  
; ** X-Koordinaten der einzelnen Chars der Laufschrift **
; -------------------------------------------------------
wst_characters_x_positions
  DS.W wst_text_characters_number

; **** Blenk-Vectors ****
; ** Farbtabelle f�r Shading **
; -----------------------------
  CNOP 0,4
bv_color_table
  INCLUDE "Daten:Asm-Sources.AGA/projects/Old'scool/colortables/64-Colorgradient-Brown.ct"

; ** Objektdaten **
; -----------------
  CNOP 0,2
bv_object_coordinates
  DC.W -(35*8),-(35*8),-(35*8) ;P0 W�rfel
  DC.W 35*8,-(35*8),-(35*8)  ;P1
  DC.W 35*8,35*8,-(35*8)     ;P2
  DC.W -(35*8),35*8,-(35*8)  ;P3
  DC.W -(35*8),-(35*8),35*8  ;P4
  DC.W 35*8,-(35*8),35*8     ;P5
  DC.W 35*8,35*8,35*8        ;P6
  DC.W -(35*8),35*8,35*8     ;P7
  
; ** Information �ber Objekt **
; -----------------------------
  CNOP 0,4
bv_object_info_table
; ** 1. Fl�che **
; ---------------
  DC.L 0                     ;Zeiger auf Koords
  DC.W bv_object_face1_color ;Farbe der Fl�che
  DC.W bv_object_face1_lines_number-1 ;Anzahl der Linien

; ** 2. Fl�che **
; ---------------
  DC.L 0                     ;Zeiger auf Koords
  DC.W bv_object_face2_color ;Farbe der Fl�che
  DC.W bv_object_face2_lines_number-1 ;Anzahl der Linien

; ** 3. Fl�che **
; ---------------  
  DC.L 0                     ;Zeiger auf Koords
  DC.W bv_object_face3_color ;Farbe der Fl�che
  DC.W bv_object_face3_lines_number-1 ;Anzahl der Linien

; ** 4. Fl�che **
; ---------------  
  DC.L 0                     ;Zeiger auf Koords
  DC.W bv_object_face4_color ;Farbe der Fl�che
  DC.W bv_object_face4_lines_number-1 ;Anzahl der Linien

; ** 5. Fl�che **
; ---------------  
  DC.L 0                     ;Zeiger auf Koords
  DC.W bv_object_face5_color ;Farbe der Fl�che
  DC.W bv_object_face5_lines_number-1 ;Anzahl der Linien

; ** 6. Fl�che **
; ---------------  
  DC.L 0                     ;Zeiger auf Koords
  DC.W bv_object_face6_color ;Farbe der Fl�che
  DC.W bv_object_face6_lines_number-1 ;Anzahl der Linien
  
; ** Eckpunkte der Fl�chen **
; ---------------------------
  CNOP 0,2
bv_object_edge_table
  DC.W 0*3,1*3,2*3,3*3,0*3   ;Fl�che vorne
  DC.W 5*3,4*3,7*3,6*3,5*3   ;Fl�che hinten
  DC.W 4*3,0*3,3*3,7*3,4*3   ;Fl�che links
  DC.W 1*3,5*3,6*3,2*3,1*3   ;Fl�che rechts
  DC.W 4*3,5*3,1*3,0*3,4*3   ;Fl�che oben
  DC.W 3*3,2*3,6*3,7*3,3*3   ;Fl�che unten

; ** Koordinaten der Linien **
; ----------------------------
bv_rotation_xyz_coordinates
  DS.W bv_object_edge_points_number*3

; **** Image-Fader ****
; ** Zielfarbwerte f�r Image-Fader-In **
; --------------------------------------
  CNOP 0,4
ifi_color_table
  INCLUDE "Daten:Asm-Sources.AGA/projects/Old'scool/colortables/320x256x128-Title.ct"

; ** Zielfarbwerte f�r Image-Fader-Out **
; ---------------------------------------
ifo_color_table
  REPT pf1_colors_number
    DC.L COLOR00BITS
  ENDR

; ** Tabelle mit Registeradressen **
; ----------------------------------
  CNOP 0,2
bf_address_offsets_table
  REPT bf_table_length/2
    DC.W NOOP
  ENDR
  REPT bf_table_length/2
    DC.W BPL1DAT
  ENDR


; ## Speicherstellen allgemein ##
; -------------------------------

  INCLUDE "sys-variables.i"


; ## Speicherstellen f�r Namen ##
; -------------------------------

  INCLUDE "sys-names.i"


; ## Speicherstellen f�r Texte ##
; -------------------------------

  INCLUDE "error-texts.i"

; **** Wave-Scrolltext ****
; ** Text f�r Laufschrift **
; --------------------------
wst_text
  DC.B "��RESISTANCE"
  REPT wst_text_characters_number/(wst_origin_character_x_size/wst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B "PRESENTS  "
  REPT wst_text_characters_number/(wst_origin_character_x_size/wst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B ""
  DC.B "
�� YES WE ARE BACK ON THE AMIGA ### "
  REPT wst_text_characters_number/(wst_origin_character_x_size/wst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B ""
  DC.B "PRESS F1-F10 FOR DIFFERENT CUBE MOVEMENTS...  "
  REPT wst_text_characters_number/(wst_origin_character_x_size/wst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B ""
  DC.B "��"
  DC.B "THE ELECRONIC KNIGHTS  "
  DC.B "DESIRE  "
  DC.B "NAH-KOLOR  "
  DC.B "ARTSTATE  "
  DC.B "FOCUS DESIGN  "
  DC.B "GHOSTOWN  "
  DC.B "PLANET JAZZ  "
  DC.B "WANTED TEAM  "
  DC.B "SOFTWARE FAILURE  "
  DC.B "EPHIDRENA  "
  REPT wst_text_characters_number/(wst_origin_character_x_size/wst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B ""
  DC.B "
��THE CREDITS      "
  DC.B "CODING AND MUSIC *DISSIDENT*     "
  DC.B "GRAPHICS *GRASS*      "
  DC.B "RELEASED @ NORDLICHT 2023"
wst_stop_text
  REPT wst_text_characters_number/(wst_origin_character_x_size/wst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B " "
  EVEN

; ** Programmversion f�r Version-Befehl **
; ----------------------------------------
prg_version DC.B "$VER: RSE-Old'scool 1.0 (31.8.23)",TRUE
  EVEN


; ## Audiodaten nachladen ##
; --------------------------

; **** PT-Replay ****Old'scool
  IFNE pt_split_module_enabled
pt_auddata SECTION pt_audio_module,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/projects/Old'scool/modules/mod.ClassicTune14remix"
  ELSE
pt_auddata SECTION pt_audio_song,DATA
    INCBIN "Daten:Asm-Sources.AGA/projects/Old'scool/modules/MOD.ClassicTune14Remix.song"

pt_audsmps SECTION pt_audio_samples,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/projects/Old'scool/modules/MOD.ClassicTune14Remix.smps"
  ENDC


; ## Grafikdaten nachladen ##
; ---------------------------
; **** Background-Image ****
bg_image_data SECTION bg_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/old'scool/graphics/320x256x128-Title.rawblit"
; **** Rotation-Zoomer ****
rz_image_data SECTION rz_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/projects/Old'scool/graphics/256x256x128-Texture.rawblit"
; **** Wave-Scrolltext ****
wst_image_data SECTION wst_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/projects/Old'scool/fonts/64x56x4-Font.rawblit"

  END


; -- Unbenutzt -------------------------------------------------------------
czo_zoom_radius      EQU 32768
czo_zoom_center      EQU 32768
czo_zoom_angle_speed EQU 1

czo_active     RS.W 1
czo_zoom_angle RS.W 1

  move.w  d1,czo_active(a3)
  move.w  #sine_table_length/4,czo_zoom_angle(a3)

; ** W�rfel wegzoomen **
; ----------------------
  CNOP 0,4
cube_zoomer_out
  tst.w   czo_active(a3)     ;Cube-Zoomer-Out an ?
  bne.s   no_cube_zoomer_out ;Nein -> verzweige
  lea     sine_table(pc),a0  
  move.w  czo_zoom_angle(a3),d1 ;Zoom-Out-Winkel 
  moveq   #0,d0           ;Langgriff
  move.w  2(a0,d1.w*4),d0    ;sin(w)
  add.w   #czo_zoom_center,d0 ;+ Zoom-Out-Mittelpunkt
  move.l  d0,bv_zoom_distance(a3) ;retten
  addq.w  #czo_zoom_angle_speed,d1 ;n�chster Zoom-Out-Winkel
  cmp.w   #sine_table_length/2,d1 ;180 Grad erreicht ?
  bge.s   czo_finished       ;Ja -> verzweige
  move.w  d1,czo_zoom_angle(a3) ;neuen Zoom-Out-Winkel retten
  rts
  CNOP 0,4
czo_finished
  not.w   czo_active(a3)     ;Cube-Zoomer-Out aus
no_cube_zoomer_out
  rts
