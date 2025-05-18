; Requirements
; 68020+
; AGA PAL
; 3.0+


; History/Changes

; V.1.0 beta
; - Erstes Release

; V.1.1 beta
; - Mit aktueller Greetings-List

; V.1.2 beta
; - Optimierung der Copperlist2. Wenn kein Rotator/Zoomer dargestellt wird, dann
; wird kein BPLCON4-Chunky-Screen dargestellt und die CPU entlastet, da der
; Copper weniger Memory-Slots bei nur 2 CMOVEs ben�tigt
; - Die Credits werden jetzt durch das Modul getriggert
; - Umstellung auf VERTB main loop
; - Mit Grass' Titelbild in 64 Farben

; V.1.3 beta
; - Mit Grass' Zoomer/Rotator-Textur
; - W�rfelfarbe and Textur angepasst und Maximalwertpr�fung bei Helligkeit des
; W�rfels
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
; von der Tastatur benutzt wird. Jetzt ist auch vom Freezer eine R�ckkehr
; ohne Fehler m�glich

; V.1.7 beta
; - Keyboard-Handler: Handshake-Delay auf 200 �s hochgesetzt und es wird keine
; Tastaturleitung mehr manuell gesetzt. Die passiert automatisch beim Wechsel
; von SP input -> SP output -> SP input laut Toni Wilen

; V.1.8 beta
; - Code optimiert
; - Bugfix: Nach dem Einblenden wurde f�lschlicherweise der Title-Part
; deaktiviert und bei einem vozeitigen User-Abbruch das Titelbild
; nicht mehr ausgeblendet
; V.1.0
; - Endversion
; - Code optimiert
; - Mit �berarbeitetem Tracker-Modul
; - Bugfix: Bitplane-DMA wird nur f�r das Intro und den Title-Screen aktiviert,
; um die Anzeige von Datenm�ll im Hauptteil zu Brginn zu vermeiden
; - Image-Fader: Abfrage der RGB-Werte beim Vergleich verfeinert. ble -> bls
; - Rotationen 1-10 ge�ndert damit die Unterschiede offensichtlicher sind
; - Modul leicht ge�ndert


; PT 8xy-Befehl
; 800	Restart intro
; 810	Enable horizontal scrolltext
; 820	Fade title in
; 830	Fade title out
; 840	Fade in rotation zoomer
; 850	Zoom cube in
; 860	Enable zoomer
; 861	Disable zoomer


; Ausf�hrungszeit 68020: 220 Rasterzeilen


	MC68040


	INCDIR "include3.5:"

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


PROTRACKER_VERSION_3		SET 1


	INCDIR "custom-includes-aga:"


	INCLUDE "macros.i"


	INCLUDE "equals.i"

requires_030_cpu		EQU FALSE
requires_040_cpu		EQU FALSE
requires_060_cpu		EQU FALSE
requires_fast_memory		EQU FALSE
requires_multiscan_monitor	EQU FALSE

workbench_start_enabled		EQU FALSE
screen_fader_enabled		EQU TRUE
text_output_enabled		EQU FALSE

; PT-Replay
pt_ciatiming_enabled		EQU TRUE
pt_usedfx			EQU %1111010101011001
pt_usedefx			EQU %0000100000000000
pt_mute_enabled			EQU FALSE
pt_music_fader_enabled		EQU TRUE
pt_fade_out_delay		EQU 2 ; ticks
pt_split_module_enabled		EQU TRUE
pt_track_notes_played_enabled	EQU FALSE
pt_track_volumes_enabled	EQU FALSE
pt_track_periods_enabled	EQU FALSE
pt_track_data_enabled		EQU FALSE
pt_metronome_enabled		EQU FALSE
pt_metrochanbits		EQU pt_metrochan1
pt_metrospeedbits		EQU pt_metrospeed4th

open_border_enabled		EQU TRUE

; Rotation-Zoomer
rz_table_length_256		EQU FALSE
rz_display_y_scale_factor	EQU 4

; Blenk-Vectors
bv_EpRGB_check_max_enabled	EQU TRUE

dma_bits			EQU DMAF_BLITTER|DMAF_SPRITE|DMAF_COPPER|DMAF_RASTER|DMAF_MASTER|DMAF_SETCLR

	IFEQ pt_ciatiming_enabled
intena_bits			EQU INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ELSE					
intena_bits			EQU INTF_VERTB|INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ENDC

ciaa_icr_bits EQU CIAICRF_SETCLR
	IFEQ pt_ciatiming_enabled
ciab_icr_bits			EQU CIAICRF_TA|CIAICRF_TB|CIAICRF_SETCLR
	ELSE
ciab_icr_bits			EQU CIAICRF_TB|CIAICRF_SETCLR
	ENDC

copcon_bits			EQU 0

pf1_x_size1			EQU 0
pf1_y_size1			EQU 0
pf1_depth1			EQU 0
pf1_x_size2			EQU 0
pf1_y_size2			EQU 0
pf1_depth2			EQU 0
pf1_x_size3			EQU 320
pf1_y_size3			EQU 256
pf1_depth3			EQU 7
pf1_colors_number		EQU 128

pf2_x_size1			EQU 0
pf2_y_size1			EQU 0
pf2_depth1			EQU 0
pf2_x_size2			EQU 0
pf2_y_size2			EQU 0
pf2_depth2			EQU 0
pf2_x_size3			EQU 0
pf2_y_size3			EQU 0
pf2_depth3			EQU 0
pf2_colors_number		EQU 0
pf_colors_number		EQU pf1_colors_number+pf2_colors_number
pf_depth			EQU pf1_depth3+pf2_depth3

pf_extra_number			EQU 3
extra_pf1_x_size		EQU 128
extra_pf1_y_size		EQU 128
extra_pf1_depth			EQU 2
extra_pf2_x_size		EQU 128
extra_pf2_y_size		EQU 128
extra_pf2_depth			EQU 2
extra_pf3_x_size		EQU 128
extra_pf3_y_size		EQU 128
extra_pf3_depth			EQU 2

spr_number			EQU 8
spr_x_size1			EQU 64
spr_x_size2			EQU 64
spr_depth			EQU 2
spr_colors_number		EQU 16
spr_odd_color_table_select	EQU 8
spr_even_color_table_select	EQU 8
spr_used_number			EQU 6
spr_swap_number			EQU 2

	IFD PROTRACKER_VERSION_2 
audio_memory_size		EQU 0
	ENDC
	IFD PROTRACKER_VERSION_3
audio_memory_size		EQU 1*WORD_SIZE
	ENDC

disk_memory_size		EQU 0

chip_memory_size		EQU 0
ciaa_crb_bits			EQU CIACRBF_LOAD|CIACRBF_RUNMODE ; oneshot mode
	IFEQ pt_ciatiming_enabled
ciab_cra_bits			EQU CIACRBF_LOAD
	ENDC
ciab_crb_bits			EQU CIACRBF_LOAD|CIACRBF_RUNMODE ; oneshot mode
ciaa_ta_time			EQU 0
ciaa_tb_time			EQU 142 ;0.709379 MHz * 200 �s
	IFEQ pt_ciatiming_enabled
ciab_ta_time			EQU 14187 ;= 0.709379 MHz * [20000 �s = 50 Hz duration for one frame on a PAL machine]
;ciab_ta_time			EQU 14318 ;= 0.715909 MHz * [20000 �s = 50 Hz duration for one frame on a NTSC machine]
	ELSE
ciab_ta_time			EQU 0
	ENDC
ciab_tb_time			EQU 362 ;= 0.709379 MHz * [511.43 �s = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
					;= 0.715909 MHz * [506.76 �s = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled	EQU FALSE
ciaa_tb_continuous_enabled	EQU FALSE
	IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled	EQU TRUE
	ELSE
ciab_ta_continuous_enabled	EQU FALSE
	ENDC
ciab_tb_continuous_enabled	EQU FALSE

beam_position			EQU VSTOP_256_LINES

pixel_per_line			EQU 320
visible_pixels_number		EQU 320
visible_lines_number		EQU 256
MINROW				EQU VSTART_256_LINES

pf_pixel_per_datafetch		EQU 64	; 4x
spr_pixel_per_datafetch		EQU 64	; 4x

display_window_hstart		EQU HSTART_320_PIXEL
display_window_vstart		EQU MINROW
display_window_hstop		EQU HSTOP_320_PIXEL
display_window_vstop		EQU VSTOP_256_LINES

pf1_plane_width			EQU pf1_x_size3/8
data_fetch_width		EQU pixel_per_line/8
pf1_plane_moduli		EQU (pf1_plane_width*(pf1_depth3-1))+pf1_plane_width-data_fetch_width
extra_pf1_plane_width		EQU extra_pf1_x_size/8
extra_pf2_plane_width		EQU extra_pf2_x_size/8
extra_pf3_plane_width		EQU extra_pf3_x_size/8

diwstrt_bits			EQU ((display_window_vstart&$ff)*DIWSTRTF_V0)|(display_window_hstart&$ff)
diwstop_bits			EQU ((display_window_vstop&$ff)*DIWSTOPF_V0)|(display_window_hstop&$ff)
ddfstrt_bits			EQU DDFSTART_320_PIXEL
ddfstop_bits			EQU DDFSTOP_320_PIXEL_4X
bplcon0_bits			EQU BPLCON0F_ECSENA|BPLCON0F_COLOR
bplcon0_bits2			EQU BPLCON0F_ECSENA|((pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|((pf_depth&$07)*BPLCON0F_BPU0)
bplcon1_bits			EQU 0
bplcon2_bits			EQU 0
bplcon3_bits1			EQU BPLCON3F_SPRES0
bplcon3_bits2			EQU bplcon3_bits1|BPLCON3F_LOCT
bplcon4_bits			EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)|(BPLCON4F_ESPRM4*spr_even_color_table_select)
diwhigh_bits			EQU DIWHIGHF_HSTOP1|(((display_window_hstop&$100)>>8)*DIWHIGHF_HSTOP8)|(((display_window_vstop&$700)>>8)*DIWHIGHF_VSTOP8)+DIWHIGHF_hstart1+(((display_window_hstart&$100)>>8)*DIWHIGHF_HSTART8)+((display_window_vstart&$700)>>8)
fmode_bits			EQU FMODEF_BPL32|FMODEF_BPAGEM|FMODEF_SPR32|FMODEF_SPAGEM
color00_bits			EQU $090909

cl2_display_x_size		EQU visible_pixels_number+8
cl2_display_width		EQU cl2_display_x_size/8
cl2_display_y_size		EQU visible_lines_number/rz_display_y_scale_factor
	IFNE open_border_enabled
cl1_hstart1			EQU display_window_hstart-(7*CMOVE_SLOT_PERIOD)
	ELSE
cl1_hstart1			EQU display_window_hstart-(8*CMOVE_SLOT_PERIOD)
	ENDC
cl1_vstart1			EQU MINROW
cl1_hstart2			EQU $00
cl1_vstart2			EQU beam_position&$ff

sine_table_length		EQU 512

; Background-Image
bg_image_x_size			EQU 320
bg_image_plane_width		EQU bg_image_x_size/8
bg_image_y_size			EQU 256
bg_image_depth			EQU 7
bg_image_colors_number		EQU 128

; Rotation-Zoomer
rz_image_x_size			EQU 256
rz_image_plane_width		EQU rz_image_x_size/8
rz_image_y_size			EQU 256
rz_image_depth			EQU 7

rz_Ax				EQU -40
rz_Ay				EQU -32
rz_Bx				EQU 40
rz_By				EQU -32

rz_z_rotation_x_center		EQU rz_image_x_size/2
rz_z_rotation_y_center		EQU rz_image_y_size/2
rz_z_rotation_angle_speed	EQU 3

rz_d				EQU 220
rz_zoom_radius			EQU 1024
rz_zoom_center			EQU 1024+rz_d
rz_zoom_angle_speed		EQU 1

; Wave-Scrolltext
wst_used_sprites_number		EQU 6

wst_image_x_size		EQU 640
wst_image_plane_width		EQU wst_image_x_size/8
wst_image_depth			EQU 2

wst_origin_char_x_size		EQU 64
wst_origin_char_y_size		EQU 56
wst_origin_char_depth		EQU wst_image_depth

wst_text_char_x_size		EQU wst_origin_char_x_size
wst_text_char_width		EQU wst_text_char_x_size/8
wst_text_char_y_size		EQU wst_origin_char_y_size
wst_text_char_depth		EQU wst_image_depth

wst_horiz_scroll_window_x_size	EQU visible_pixels_number+wst_text_char_x_size
wst_horiz_scroll_window_width	EQU wst_horiz_scroll_window_x_size/8
wst_horiz_scroll_window_y_size	EQU wst_text_char_y_size
wst_horiz_scroll_window_depth	EQU wst_text_char_depth
wst_horiz_scroll_speed1		EQU 10
wst_horiz_scroll_speed2		EQU 12
wst_horiz_scroll_speed3		EQU 17

wst_text_char_x_restart		EQU wst_horiz_scroll_window_x_size*4 ;*4 da superhires Pixel
wst_text_chars_number		EQU wst_horiz_scroll_window_x_size/wst_text_char_x_size

wst_y_radius			EQU (visible_lines_number-wst_text_char_y_size)/2
wst_y_center			EQU ((visible_lines_number-wst_text_char_y_size)/2)+display_window_vstart
wst_y_angle_speed1		EQU 5
wst_y_angle_step1		EQU sine_table_length/wst_text_chars_number

; Blenk-Vectors
bv_rotation_d			EQU 256
bv_rotation_xy_center		EQU extra_pf2_x_size/2
bv_rotation_x_angle_speed1	EQU 4
bv_rotation_y_angle_speed1	EQU 2
bv_rotation_z_angle_speed1	EQU 6

bv_rotation_x_angle_speed2	EQU -2
bv_rotation_y_angle_speed2	EQU -3
bv_rotation_z_angle_speed2	EQU -1

bv_rotation_x_angle_speed3	EQU 0
bv_rotation_y_angle_speed3	EQU 1
bv_rotation_z_angle_speed3	EQU 4

bv_rotation_x_angle_speed4	EQU -7
bv_rotation_y_angle_speed4	EQU -4
bv_rotation_z_angle_speed4	EQU -2

bv_rotation_x_angle_speed5	EQU 2
bv_rotation_y_angle_speed5	EQU 0
bv_rotation_z_angle_speed5	EQU 5

bv_rotation_x_angle_speed6	EQU 0
bv_rotation_y_angle_speed6	EQU -6
bv_rotation_z_angle_speed6	EQU -4

bv_rotation_x_angle_speed7	EQU 4
bv_rotation_y_angle_speed7	EQU 0
bv_rotation_z_angle_speed7	EQU 0

bv_rotation_x_angle_speed8	EQU -5
bv_rotation_y_angle_speed8	EQU 0
bv_rotation_z_angle_speed8	EQU -3

bv_rotation_x_angle_speed9	EQU 3
bv_rotation_y_angle_speed9	EQU 5
bv_rotation_z_angle_speed9	EQU 1

bv_rotation_x_angle_speed10	EQU 0
bv_rotation_y_angle_speed10	EQU -5
bv_rotation_z_angle_speed10	EQU 0

bv_object_edge_points_number	EQU 8
bv_object_edge_points_per_face	EQU 4
bv_object_faces_number		EQU 6

bv_object_face1_color		EQU 1
bv_object_face1_lines_number	EQU 4
bv_object_face2_color		EQU 1
bv_object_face2_lines_number	EQU 4
bv_object_face3_color		EQU 2
bv_object_face3_lines_number	EQU 4
bv_object_face4_color		EQU 2
bv_object_face4_lines_number	EQU 4
bv_object_face5_color		EQU 3
bv_object_face5_lines_number	EQU 4
bv_object_face6_color		EQU 3
bv_object_face6_lines_number	EQU 4

bv_light_z_coordinate1		EQU -56
bv_EpRGB			EQU $3f	; Intensit�t der Lichtquelle
bv_kdRGB			EQU 6	; Reflexion der Fl�che = Helligkeit des Objekts
bv_D0				EQU 15	; Helligkeitsverlust, Schutz vor Division durch Null
bv_EpRGB_max			EQU 63	; L�nge der Farbtabelle - 1

bv_light_z_radius		EQU 16
bv_light_z_center		EQU 16

bv_image_x_size			EQU 128
bv_image_y_size			EQU 128
bv_image_depth			EQU 2

bv_used_sprites_number		EQU 2
bv_used_first_sprite		EQU 6

bv_sprite_x_direction_speed	EQU 3
bv_sprite_y_direction_speed	EQU 2
bv_sprite_x_center		EQU display_window_hstart*4
bv_sprite_y_center		EQU display_window_vstart
bv_sprite_x_min			EQU 0
bv_sprite_x_max			EQU (visible_pixels_number-(bv_image_x_size+80+60))*4
bv_sprite_y_min			EQU 0
bv_sprite_y_max			EQU visible_lines_number-bv_image_y_size

bv_wobble_x_radius		EQU 80/2
bv_wobble_x_center		EQU 80/2
bv_wobble_x_radius_angle_speed	EQU 1
bv_wobble_x_radius_angle_step	EQU 2
bv_wobble_x_angle_speed		EQU 2
bv_wobble_x_angle_step		EQU 1

bv_clear_blit_x_size		EQU extra_pf1_x_size
bv_clear_blit_y_size		EQU extra_pf1_y_size
bv_clear_blit_depth		EQU extra_pf1_depth

bv_fill_blit_x_size		EQU extra_pf1_x_size
bv_fill_blit_y_size		EQU extra_pf1_y_size
bv_fill_blit_depth		EQU extra_pf1_depth

; Image-Fader
if_rgb8_start_color		EQU 0
if_rgb8_color_table_offset	EQU 0
if_rgb8_colors_number		EQU pf1_colors_number

; Image-Fader-In
ifi_rgb8_fader_speed_max	EQU 4
ifi_rgb8_fader_radius		EQU ifi_rgb8_fader_speed_max
ifi_rgb8_fader_center		EQU ifi_rgb8_fader_speed_max+1
ifi_rgb8_fader_angle_speed	EQU 1

; Image-Fader-Out
ifo_rgb8_fader_speed_max	EQU 8
ifo_rgb8_fader_radius		EQU ifo_rgb8_fader_speed_max
ifo_rgb8_fader_center		EQU ifo_rgb8_fader_speed_max+1
ifo_rgb8_fader_angle_speed	EQU 1

; Blind-Fader
bf_lamellas_number		EQU 8
bf_lamella_height		EQU 8
bf_step1			EQU 1
bf_step2			EQU 1
bf_speed			EQU 1
bf_table_length			EQU bf_lamella_height*4

; Cube-Zoomer-In
czi_zoom_radius			EQU 32768
czi_zoom_center			EQU 32768
czi_zoom_angle_speed		EQU 1

color_values_number1		EQU 64
segments_number1		EQU 1

extra_memory_size		EQU rz_image_x_size*rz_image_y_size*BYTE_SIZE


	INCLUDE "except-vectors.i"


	INCLUDE "extra-pf-attributes.i"


	INCLUDE "sprite-attributes.i"


; PT-Replay
	INCLUDE "music-tracker/pt-song.i"

	INCLUDE "music-tracker/pt-temp-channel.i"


; Blenk-Vectors
	RSRESET

object_info			RS.B 0

object_info_edges_table		RS.L 1
object_info_face_color		RS.W 1
object_info_lines_number	RS.W 1

object_info_size		RS.B 0


	RSRESET

cl1_subextension1		RS.B 0
cl1_subext1_WAIT		RS.L 1
cl1_subext1_SPR6POS		RS.L 1
cl1_subext1_SPR7POS		RS.L 1
cl1_subext1_COP1LCH		RS.L 1
cl1_subext1_COP1LCL		RS.L 1
cl1_subext1_COPJMP2		RS.L 1
cl1_subextension1_size		RS.B 0


	RSRESET

cl1_extension1			RS.B 0
cl1_ext1_COP2LCH		RS.L 1
cl1_ext1_COP2LCL		RS.L 1
cl1_ext1_subextension1_entry	RS.B cl1_subextension1_size*rz_display_y_scale_factor
cl1_extension1_size		RS.B 0


	RSRESET

cl1_begin			RS.B 0

	INCLUDE "copperlist1.i"

cl1_extension1_entry		RS.B cl1_extension1_size*cl2_display_y_size
cl1_WAIT1			RS.L 1
cl1_WAIT2			RS.L 1
cl1_INTENA			RS.L 1

cl1_end				RS.L 1

copperlist1_size		RS.B 0


	RSRESET

cl2_extension1			RS.B 0

	IFEQ open_border_enabled 
cl2_ext1_BPL1DAT		RS.L 1
	ENDC
cl2_ext1_BPLCON4_1		RS.L 1
cl2_ext1_BPLCON4_2		RS.L 1
cl2_ext1_BPLCON4_3		RS.L 1
cl2_ext1_BPLCON4_4		RS.L 1
cl2_ext1_BPLCON4_5		RS.L 1
cl2_ext1_BPLCON4_6		RS.L 1
cl2_ext1_BPLCON4_7		RS.L 1
cl2_ext1_BPLCON4_8		RS.L 1
cl2_ext1_BPLCON4_9		RS.L 1
cl2_ext1_BPLCON4_10		RS.L 1
cl2_ext1_BPLCON4_11		RS.L 1
cl2_ext1_BPLCON4_12		RS.L 1
cl2_ext1_BPLCON4_13		RS.L 1
cl2_ext1_BPLCON4_14		RS.L 1
cl2_ext1_BPLCON4_15		RS.L 1
cl2_ext1_BPLCON4_16		RS.L 1
cl2_ext1_BPLCON4_17		RS.L 1
cl2_ext1_BPLCON4_18		RS.L 1
cl2_ext1_BPLCON4_19		RS.L 1
cl2_ext1_BPLCON4_20		RS.L 1
cl2_ext1_BPLCON4_21		RS.L 1
cl2_ext1_BPLCON4_22		RS.L 1
cl2_ext1_BPLCON4_23		RS.L 1
cl2_ext1_BPLCON4_24		RS.L 1
cl2_ext1_BPLCON4_25		RS.L 1
cl2_ext1_BPLCON4_26		RS.L 1
cl2_ext1_BPLCON4_27		RS.L 1
cl2_ext1_BPLCON4_28		RS.L 1
cl2_ext1_BPLCON4_29		RS.L 1
cl2_ext1_BPLCON4_30		RS.L 1
cl2_ext1_BPLCON4_31		RS.L 1
cl2_ext1_BPLCON4_32		RS.L 1
cl2_ext1_BPLCON4_33		RS.L 1
cl2_ext1_BPLCON4_34		RS.L 1
cl2_ext1_BPLCON4_35		RS.L 1
cl2_ext1_BPLCON4_36		RS.L 1
cl2_ext1_BPLCON4_37		RS.L 1
cl2_ext1_BPLCON4_38		RS.L 1
cl2_ext1_BPLCON4_39		RS.L 1
cl2_ext1_BPLCON4_40		RS.L 1
cl2_ext1_BPLCON4_41		RS.L 1
cl2_ext1_COPJMP1		RS.L 1

cl2_extension1_size		RS.B 0


	RSRESET

cl2_extension2			RS.B 0

	IFEQ open_border_enabled 
cl2_ext2_BPL1DAT		RS.L 1
	ENDC
cl2_ext2_COPJMP1		RS.L 1

cl2_extension2_size		RS.B 0


	RSRESET

cl2_begin			RS.B 0

cl2_extension1_entry		RS.B cl2_extension1_size*cl2_display_y_size
cl2_extension2_entry		RS.B cl2_extension2_size

copperlist2_size		RS.B 0


cl1_size1			EQU 0
cl1_size2			EQU copperlist1_size
cl1_size3			EQU copperlist1_size
cl2_size1			EQU 0
cl2_size2			EQU copperlist2_size
cl2_size3			EQU copperlist2_size


; Sprite0 additional structure
	RSRESET

spr0_extension1			RS.B 0

spr0_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr0_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*wst_text_char_y_size

spr0_extension1_size		RS.B 0

; Sprite0 main structure
	RSRESET

spr0_begin			RS.B 0

spr0_extension1_entry RS.B spr0_extension1_size

spr0_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite0_size			RS.B 0

; Sprite1 additional structure
	RSRESET

spr1_extension1	RS.B 0

spr1_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr1_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*wst_text_char_y_size

spr1_extension1_size		RS.B 0

; Sprite1 main structure
	RSRESET

spr1_begin			RS.B 0

spr1_extension1_entry		RS.B spr1_extension1_size

spr1_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite1_size			RS.B 0

; Sprite2 additional structure
	RSRESET

spr2_extension1			RS.B 0

spr2_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr2_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*wst_text_char_y_size

spr2_extension1_size		RS.B 0

; Sprite2 main structure
	RSRESET

spr2_begin			RS.B 0

spr2_extension1_entry		RS.B spr2_extension1_size

spr2_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite2_size			RS.B 0

; Sprite3 additional structure
	RSRESET

spr3_extension1			RS.B 0

spr3_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr3_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*wst_text_char_y_size

spr3_extension1_size		RS.B 0

; Sprite3 main structure
	RSRESET

spr3_begin			RS.B 0

spr3_extension1_entry		RS.B spr3_extension1_size

spr3_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite3_size			RS.B 0

; Sprite4 additional structure
	RSRESET

spr4_extension1			RS.B 0

spr4_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr4_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*wst_text_char_y_size

spr4_extension1_size		RS.B 0

; Sprite4 main structure
	RSRESET

spr4_begin			RS.B 0

spr4_extension1_entry		RS.B spr4_extension1_size

spr4_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite4_size			RS.B 0

; Sprite5 additional structure
	RSRESET

spr5_extension1	RS.B 0

spr5_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr5_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*wst_text_char_y_size

spr5_extension1_size		RS.B 0

; Sprite5 main structure
	RSRESET

spr5_begin			RS.B 0

spr5_extension1_entry		RS.B spr5_extension1_size

spr5_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite5_size			RS.B 0

; Sprite6 additional structure
	RSRESET

spr6_extension1	RS.B 0

spr6_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr6_ext1_planedata		RS.L bv_image_y_size*(spr_pixel_per_datafetch/WORD_BITS)

spr6_extension1_size		RS.B 0

; Sprite6 main structure
	RSRESET

spr6_begin			RS.B 0

spr6_extension1_entry		RS.B spr6_extension1_size

spr6_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite6_size			RS.B 0

; Sprite7 additional structure
	RSRESET

spr7_extension1	RS.B 0

spr7_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr7_ext1_planedata		RS.L bv_image_y_size*(spr_pixel_per_datafetch/WORD_BITS)

spr7_extension1_size		RS.B 0

; Sprite7 main structure
	RSRESET

spr7_begin			RS.B 0

spr7_extension1_entry		RS.B spr7_extension1_size

spr7_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite7_size			RS.B 0


spr0_x_size1			EQU spr_x_size1
spr0_y_size1			EQU sprite0_size/(spr_pixel_per_datafetch/4)
spr1_x_size1			EQU spr_x_size1
spr1_y_size1			EQU sprite1_size/(spr_pixel_per_datafetch/4)
spr2_x_size1			EQU spr_x_size1
spr2_y_size1			EQU sprite2_size/(spr_pixel_per_datafetch/4)
spr3_x_size1			EQU spr_x_size1
spr3_y_size1			EQU sprite3_size/(spr_pixel_per_datafetch/4)
spr4_x_size1			EQU spr_x_size1
spr4_y_size1			EQU sprite4_size/(spr_pixel_per_datafetch/4)
spr5_x_size1			EQU spr_x_size1
spr5_y_size1			EQU sprite5_size/(spr_pixel_per_datafetch/4)
spr6_x_size1			EQU spr_x_size1
spr6_y_size1			EQU sprite6_size/(spr_pixel_per_datafetch/4)
spr7_x_size1			EQU spr_x_size1
spr7_y_size1			EQU sprite7_size/(spr_pixel_per_datafetch/4)

spr0_x_size2			EQU spr_x_size2
spr0_y_size2			EQU sprite0_size/(spr_pixel_per_datafetch/4)
spr1_x_size2			EQU spr_x_size2
spr1_y_size2			EQU sprite1_size/(spr_pixel_per_datafetch/4)
spr2_x_size2			EQU spr_x_size2
spr2_y_size2			EQU sprite2_size/(spr_pixel_per_datafetch/4)
spr3_x_size2			EQU spr_x_size2
spr3_y_size2			EQU sprite3_size/(spr_pixel_per_datafetch/4)
spr4_x_size2			EQU spr_x_size2
spr4_y_size2			EQU sprite4_size/(spr_pixel_per_datafetch/4)
spr5_x_size2			EQU spr_x_size2
spr5_y_size2			EQU sprite5_size/(spr_pixel_per_datafetch/4)
spr6_x_size2			EQU spr_x_size2
spr6_y_size2			EQU sprite6_size/(spr_pixel_per_datafetch/4)
spr7_x_size2			EQU spr_x_size2
spr7_y_size2			EQU sprite7_size/(spr_pixel_per_datafetch/4)


	RSRESET

	INCLUDE "main-variables.i"

save_a7				RS.L 1

; PT-Replay
	IFD PROTRACKER_VERSION_2 
		INCLUDE "music-tracker/pt2-variables.i"
	ENDC
	IFD PROTRACKER_VERSION_3
		INCLUDE "music-tracker/pt3-variables.i"
	ENDC

pt_effects_handler_active	RS.W 1

; Rotation-Zoomer
rz_active			RS.W 1
rz_zoomer_active		RS.W 1
rz_z_rotation_angle		RS.W 1
rz_zoom_angle			RS.W 1

; Wave-Scrolltext
	RS_ALIGN_LONGWORD
wst_image			RS.L 1
wst_enabled			RS.W 1
wst_text_table_start		RS.W 1
wst_y_angle			RS.W 1
wst_y_angle_speed		RS.W 1
wst_y_angle_step		RS.W 1
wst_horiz_scroll_speed		RS.W 1

; Blenk-Vectors
bv_active			RS.W 1
bv_rotation_x_angle		RS.W 1
bv_rotation_y_angle		RS.W 1
bv_rotation_z_angle		RS.W 1
bv_rotation_x_angle_speed	RS.W 1
bv_rotation_y_angle_speed	RS.W 1
bv_rotation_z_angle_speed	RS.W 1

bv_light_z_coordinate		RS.W 1

bv_sprite_x_coordinate		RS.W 1
bv_sprite_y_coordinate		RS.W 1
bv_sprite_x_direction		RS.W 1
bv_sprite_y_direction		RS.W 1

bv_wobble_x_radius_angle	RS.W 1
bv_wobble_x_angle		RS.W 1

	RS_ALIGN_LONGWORD
bv_zoom_distance		RS.L 1

; Image-Fader
if_rgb8_colors_counter		RS.W 1
if_rgb8_copy_colors_active	RS.W 1

; Image-Fader-In
ifi_rgb8_active			RS.W 1
ifi_rgb8_fader_angle		RS.W 1

; Image-Fader-Out
ifo_rgb8_active			RS.W 1
ifo_rgb8_fader_angle		RS.W 1

; Blind-Fader
bf_address_offsets_table_start	RS.W 1

; Blind-Fader-In
bfi_active			RS.W 1

; Blind-Fader-Out
bfo_active			RS.W 1

; Cube-Zoomer-In
czi_active			RS.W 1
czi_zoom_angle			RS.W 1

; Keyboard-Handler
kh_key_code			RS.B 1
kh_key_flag			RS.B 1

; Main
stop_fx_active			RS.W 1
part_title_active		RS.W 1
part_main_active		RS.W 1

variables_size			RS.B 0


	SECTION code,CODE


	INCLUDE "sys-wrapper.i"


	CNOP 0,4
init_main_variables
	bsr.s	init_pt_variables
	bra.s	init_main_variables2


	CNOP 0,4
init_pt_variables

; PT-Replay
	IFD PROTRACKER_VERSION_2
		PT2_INIT_VARIABLES
	ENDC
	IFD PROTRACKER_VERSION_3
		PT3_INIT_VARIABLES
	ENDC

	clr.w	pt_effects_handler_active(a3)
	rts


	CNOP 0,4
init_main_variables2
; Rotation-Zoomer
	moveq	#FALSE,d1
	move.w	d1,rz_active(a3)
	move.w	d1,rz_zoomer_active(a3)
	moveq	#TRUE,d0
	move.w	d0,rz_z_rotation_angle(a3) ; 0�
	move.w	#(sine_table_length/4)*3,rz_zoom_angle(a3) ; 270�

; Wave-Scrolltext
	move.w	d1,wst_enabled(a3)
	lea	wst_image_data,a0
	move.l	a0,wst_image(a3)
	move.w	d0,wst_text_table_start(a3)
	move.w	d0,wst_y_angle(a3)	; 0�
	move.w	#wst_y_angle_speed1,wst_y_angle_speed(a3)
	move.w	#wst_y_angle_step1,wst_y_angle_step(a3)
	move.w	#wst_horiz_scroll_speed1,wst_horiz_scroll_speed(a3)

; Blenk-Vectors
	move.w	d1,bv_active(a3)
	move.w	d0,bv_rotation_x_angle(a3) ; 0�
	move.w	d0,bv_rotation_y_angle(a3) ; 0�
	move.w	d0,bv_rotation_z_angle(a3) ; 0�
	move.w	#bv_rotation_x_angle_speed1,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed1,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed1,bv_rotation_z_angle_speed(a3)

	move.w	#bv_light_z_coordinate1,bv_light_z_coordinate(a3)

	move.w	d0,bv_sprite_x_coordinate(a3)
	move.w	d0,bv_sprite_y_coordinate(a3)
	move.w	#bv_sprite_x_direction_speed,bv_sprite_x_direction(a3)
	move.w	#bv_sprite_y_direction_speed,bv_sprite_y_direction(a3)

	move.w	#sine_table_length/4,bv_wobble_x_radius_angle(a3) ; 90�
	move.w	d0,bv_wobble_x_angle(a3) ; 0�

	move.l	#czi_zoom_radius,bv_zoom_distance(a3)

; Image-Fader
	move.w	d0,if_rgb8_colors_counter(a3)
	move.w	d1,if_rgb8_copy_colors_active(a3)

	move.w	d1,ifi_rgb8_active(a3)
	move.w	#sine_table_length/4,ifi_rgb8_fader_angle(a3) ; 90�

	move.w	d1,ifo_rgb8_active(a3)
	move.w	#sine_table_length/4,ifo_rgb8_fader_angle(a3) ; 90�

; Blind-Fader
	move.w	d0,bf_address_offsets_table_start(a3)

; Blind-Fader-In
	move.w	d1,bfi_active(a3)

; Blind-Fader-Out
	move.w	d1,bfo_active(a3)

; Cube-Zoomer-In
	move.w	d1,czi_active(a3)
	move.w	d0,czi_zoom_angle(a3)	; 90�

; Keyboard-Handler
	move.b	d0,kh_key_code(a3)
	move.b	d0,kh_key_flag(a3)

; Main
	move.w	d1,stop_fx_active(a3)
	move.w	d1,part_title_active(a3)
	move.w	d1,part_main_active(a3)
	rts


	CNOP 0,4
init_main
	bsr.s	pt_DetectSysFrequ
	bsr.s	pt_InitRegisters
	bsr	pt_InitAudTempStrucs
	bsr	pt_ExamineSongStruc
	bsr	pt_InitFtuPeriodTableStarts
	bsr	rz_convert_image_data
	bsr	wst_init_chars_offsets
	bsr	wst_init_chars_x_positions
	bsr	bv_convert_color_table
	bsr	bv_init_object_info
	bsr	bg_copy_image_to_plane
	bsr	init_sprites
	bsr	init_CIA_timers
	bsr	init_first_copperlist
	bra	init_second_copperlist


; PT-Replay
	PT_DETECT_SYS_FREQUENCY

	PT_INIT_REGISTERS

	PT_INIT_AUDIO_TEMP_STRUCTURES

	PT_EXAMINE_SONG_STRUCTURE

	PT_INIT_FINETUNE_TABLE_STARTS


; Rotation-Zoomer
	CONVERT_IMAGE_TO_BPLCON4_CHUNKY.B rz,extra_memory,a3


; Wave-Scrolltext
	INIT_CHARS_OFFSETS.W wst

	INIT_CHARS_X_POSITIONS wst,SHIRES


; Blenk-Vectors
	RGB8_TO_RGB8_HIGH_LOW bv,segments_number1*color_values_number1

	CNOP 0,4
bv_init_object_info
	lea	bv_object_info+object_info_edges_table(pc),a0
	lea	bv_object_edges(pc),a1
	move.w	#object_info_size,a2
	moveq	#bv_object_faces_number-1,d7
bv_init_object_info_loop
	move.w	object_info_lines_number(a0),d0
	addq.w	#2,d0			; Anzahl der Linien + 1 = Anzahl der Eckpunkte
	move.l	a1,(a0)			; Zeiger auf Tabelle mit Eckpunkten eintragen
	lea	(a1,d0.w*2),a1		; Zeiger auf Eckpunkte-Tabelle erh�hen
	add.l	a2,a0			; Object-Info-Struktur der n�chsten Fl�che
	dbf	d7,bv_init_object_info_loop
	rts


; Background-Image
	COPY_IMAGE_TO_BITPLANE bg


	CNOP 0,4
init_sprites
	bsr.s	spr_init_ptrs_table
	bra	spr_copy_structures

	INIT_SPRITE_POINTERS_TABLE

	COPY_SPRITE_STRUCTURES


	CNOP 0,4
init_CIA_timers
	MOVEF.W ciaa_tb_time&$ff,d0
	move.b	d0,CIATBLO(a4)		; Timer-B Low-Bits
	moveq	#ciaa_tb_time>>8,d0
	move.b	d0,CIATBHI(a4)		; Timer-B High-Bits
	moveq	#ciaa_crb_bits,d0
	move.b	d0,CIACRB(a4)

; PT-Replay
	PT_INIT_TIMERS
	rts


	CNOP 0,4
init_first_copperlist
	move.l	cl1_construction2(a3),a0 
	bsr.s	cl1_init_playfield_props
	bsr.s	cl1_init_sprite_ptrs
	bsr	cl1_init_colors
	bsr	cl1_init_plane_ptrs
	bsr	cl1_init_branches_ptrs
	bsr	cl1_init_copper_interrupt
	COP_LISTEND
	bsr	cl1_set_sprite_ptrs
	bsr	cl1_set_plane_ptrs
	bsr	copy_first_copperlist
	bra	cl1_set_branches_ptrs


	COP_INIT_PLAYFIELD_REGISTERS cl1


	COP_INIT_SPRITE_POINTERS cl1


	CNOP 0,4
cl1_init_colors
	COP_INIT_COLOR_HIGH COLOR00,32,pf1_rgb8_color_table
	COP_SELECT_COLOR_HIGH_BANK 1
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 2
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 3
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 4
	COP_INIT_COLOR_HIGH COLOR00,16,spr_rgb8_color_table

	COP_SELECT_COLOR_LOW_BANK 0
	COP_INIT_COLOR_LOW COLOR00,32,pf1_rgb8_color_table
	COP_SELECT_COLOR_LOW_BANK 1
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 2
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 3
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 4
	COP_INIT_COLOR_LOW COLOR00,16,spr_rgb8_color_table
	rts


	COP_INIT_BITPLANE_POINTERS cl1


	CNOP 0,4
cl1_init_branches_ptrs
	move.l	#(((cl1_vstart1<<24)|(((cl1_hstart1/4)*2)<<16))|$10000)|$fffe,d0 ; CWAIT
	moveq	#2,d1			; X-Verschiebung $00020000
	swap	d1
	moveq	#1,d2
	ror.l	#8,d2			; Y-Additionswert $01000000
	moveq	#cl2_display_y_size-1,d7
cl1_init_branches_ptrs_loop1
	COP_MOVEQ 0,COP2LCH
	COP_MOVEQ 0,COP2LCL
	moveq	#rz_display_y_scale_factor-1,d6 ; Anzahl der Abschnitte f�r Y-Skalierung
cl1_init_branches_ptrs_loop2
	move.l	d0,(a0)+		; CWAIT x,y
	COP_MOVEQ 0,SPR6POS
	COP_MOVEQ 0,SPR7POS
	COP_MOVEQ 0,COP1LCH
	eor.l	d1,d0			; X-Shift
	COP_MOVEQ 0,COP1LCL
	add.l	d2,d0			; n�chste Zeile
	COP_MOVEQ 0,COPJMP2
	dbf	d6,cl1_init_branches_ptrs_loop2
	dbf	d7,cl1_init_branches_ptrs_loop1
	rts


	COP_INIT_COPINT cl1,cl1_hstart2,cl1_vstart2


	COP_SET_SPRITE_POINTERS cl1,construction2,spr_number


	COP_SET_BITPLANE_POINTERS cl1,construction2,pf1_depth3


	COPY_COPPERLIST cl1,2


	CNOP 0,4
cl1_set_branches_ptrs
	move.l	cl1_construction2(a3),a0 1
	moveq	#cl1_subextension1_size,d2
	move.l	cl2_construction2(a3),d0 ; Einsprungadresse
	add.l	#cl2_extension2_entry,d0
	moveq	#cl1_extension1_size,d4
	bsr.s	cl1_set_jump_entry_ptrs
	move.l	cl1_display(a3),a0 1
	move.l	cl2_display(a3),d0	; Einsprungadresse
	add.l	#cl2_extension2_entry,d0
	bsr.s	cl1_set_jump_entry_ptrs
	rts


; Input
; d0.l	Einsprungadresse Copperliste2
; d2.l	cl1_subextension1_size
; d4.l	cl1_extension1_size
; a0.l	Copperliste1
; Result
; d0.l	Kein R�ckgabewert
	CNOP 0,4
cl1_set_jump_entry_ptrs
	MOVEF.L cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subextension1_size,d1 ; Offset R�cksprungadresse CL1
	add.l	a0,d1			; + R�cksprungadresse CL1
	lea	cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subext1_COP1LCH+WORD_SIZE(a0),a1
	ADDF.W	cl1_extension1_entry+cl1_ext1_COP2LCH+WORD_SIZE,a0
	moveq	#cl2_display_y_size-1,d7
cl1_set_branches_loop1
	swap	d0			; High
	move.w	d0,(a0)			; COP2LCH
	swap	d0			; Low
	move.w	d0,4(a0)		; COP2LCL
	moveq	#rz_display_y_scale_factor-1,d6 ; Anzahl der Abschnitte f�r Y-Skalierung
cl1_set_branches_loop2
	swap	d1			; High
	move.w	d1,(a1)			; COP1LCH
	swap	d1			; Low
	move.w	d1,4(a1)		; COP1LCL
	add.l	d2,d1			; R�cksprungadresse CL1 erh�hen
	add.l	d2,a1			; n�chste Zeile in Unterabschnitt der CL1
	dbf	d6,cl1_set_branches_loop2
	add.l	d4,a0			; n�chste Zeile in CL1
	addq.l	#8,d1			; CMOVE COP2LCH + CMOVE COP2LCL �berspringen
	addq.w	#8,a1			; CMOVE COP2LCH + CMOVE COP2LCL �berspringen
	dbf	d7,cl1_set_branches_loop1
	rts


	CNOP 0,4
init_second_copperlist
	move.l	cl2_construction2(a3),a0 
	bsr	cl2_init_bplcon4
	bsr	cl2_init_noop
	bra	copy_second_copperlist


	CNOP 0,4
cl2_init_bplcon4
	move.l	#(BPLCON4<<16)+bplcon4_bits,d0
	IFEQ open_border_enabled 
		move.l	#BPL1DAT<<16,d1
	ENDC
	moveq	#cl2_display_y_size-1,d7
cl2_init_bplcon4_loop1
	IFEQ open_border_enabled 
		move.l	d1,(a0)+	; BPL1DAT
	ENDC
	moveq	#cl2_display_width-1,d6	; number of columns
cl2_init_bplcon4_loop2
	move.l	d0,(a0)+		; BPLCON4
	dbf	d6,cl2_init_bplcon4_loop2
	COP_MOVEQ 0,COPJMP1
	dbf	d7,cl2_init_bplcon4_loop1
	rts


	CNOP 0,4
cl2_init_noop
	IFEQ open_border_enabled 
		COP_MOVEQ 0,BPL1DAT
	ENDC
	COP_MOVEQ 0,COPJMP1
	rts

	COPY_COPPERLIST cl2,2


	CNOP 0,4
main
	bsr.s	no_sync_routines
	bra.s	beam_routines


	CNOP 0,4
no_sync_routines
	rts


	CNOP 0,4
beam_routines
	bsr	wait_vbi
	bsr	wave_scrolltext
	bsr	bv_draw_lines
	bsr	bv_fill_image
	bsr	rotation_zoomer
	bsr	cube_zoomer_in
	bsr	bv_move_lightsource
	bsr	bv_clear_image
	bsr	bv_rotation
	bsr	bv_move_sprites
	bsr	bv_wobble_sprites
	bsr	bv_copy_image
	bsr	image_fader_in
	bsr	image_fader_out
	bsr	keyboard_handler
	bsr	mouse_handler
	bsr	wait_copint
	bsr	swap_first_copperlist
	bsr	swap_second_copperlist
	bsr	spr_swap_structures
	bsr	spr_set_sprite_ptrs
	bsr	swap_images
	bsr	blind_fader_in
	bsr	blind_fader_out
	bsr	if_rgb8_copy_color_table
	tst.w	stop_fx_active(a3)
	bne.s	beam_routines
	rts


	SWAP_COPPERLIST cl1,2


	SWAP_COPPERLIST cl2,2,NOSET


	SWAP_SPRITES spr,spr_swap_number,6


	SET_SPRITES spr,spr_swap_number,6


	CNOP 0,4
swap_images
	move.l	extra_pf1(a3),a0
	move.l	extra_pf3(a3),extra_pf1(a3)
	move.l	extra_pf2(a3),a1
	move.l	a0,extra_pf2(a3)
	move.l	a1,extra_pf3(a3)
	rts


	CNOP 0,4
wave_scrolltext
	movem.l a4-a6,-(a7)
	tst.w	wst_enabled(a3)
	bne	wave_scrolltext_quit
	move.w	wst_y_angle(a3),d4
	move.w	d4,d0		
	add.w	wst_y_angle_speed(a3),d0
	and.w	#sine_table_length-1,d0	; remove overflow
	move.w	d0,wst_y_angle(a3) 
	moveq	#wst_image_plane_width-4,d3
	lea	wst_chars_x_positions(pc),a2
	lea	spr_ptrs_display(pc),a4
	lea	sine_table(pc),a5
	move.w	wst_horiz_scroll_speed(a3),a6
	moveq	#wst_text_chars_number-1,d7
wave_scrolltext_loop1
	move.l	(a4)+,a1		; Zeiger auf Sprite-Struktur
	move.w	(a2),d5			; X-Position
	move.w	d5,d0		
	move.l	(a5,d4.w*4),d1		; sin(w)
	MULUF.L wst_y_radius*2,d1,d2	; y'=(yr*sin(w))/2^15
	add.w	#(display_window_hstart-wst_text_char_x_size)*SHIRES_PIXEL_FACTOR,d0 ; X-Zentrierung
	swap	d1
	sub.w	wst_y_angle_step(a3),d4 ; n�chster Buchstabe
	add.w	#wst_y_center,d1	; Y-Zentrierung
	moveq	#wst_text_char_y_size,d2
	add.w	d1,d2			; VSTOP
	SET_SPRITE_POSITION d0,d1,d2
	move.w	d1,(a1)			; SPRxPOS
	and.w	#sine_table_length-1,d4 ; remove overflow
	move.w	d2,spr_pixel_per_datafetch/8(a1) ; SPRxCTL
	sub.w	a6,d5			; X-Position verringern
	bpl.s   wave_scrolltext_skip
	add.w	#wst_text_char_x_restart,d5 ; X-Pos zur�cksetzen
	bsr.s	wst_get_new_char_image
	move.l	d0,a0			; Bild f�r Character
	add.l	#(spr_pixel_per_datafetch/8)*2,a1 ; Sprite-Header �berpsringen
	moveq	#wst_text_char_y_size-1,d6
wave_scrolltext_loop2
	move.l	(a0)+,(a1)+		; quadword bitplane 1
	move.l	(a0),(a1)+
	add.l	d3,a0			; n�chste Zeile in Quelle
	move.l	(a0)+,(a1)+		; quadword bitplane 2
	move.l	(a0),(a1)+
	add.l	d3,a0			; n�chste Zeile in Quelle
	dbf	d6,wave_scrolltext_loop2
wave_scrolltext_skip
	move.w	d5,(a2)+		; X-Position
	dbf	d7,wave_scrolltext_loop1
wave_scrolltext_quit
	movem.l (a7)+,a4-a6
	rts


	GET_NEW_char_IMAGE.W wst,wst_check_control_codes,NORESTART


	CNOP 0,4
wst_check_control_codes
; Input
; d0.b	ASCII-Code
; Result
; d0.l	R�ckgabewert: Return-Code
	cmp.b	#"�",d0
	beq.s	wst_set_standard_scroll
	cmp.b	#"�",d0
	beq.s	wst_clear_y_angle_step
	cmp.b	#"�",d0
	beq.s	wst_set_y_angle_step
	cmp.b	#"�",d0
	beq.s	wst_set_y_angle_speed
	cmp.b	#ASCII_CTRL_S,d0
	beq.s	wst_set_horiz_scroll_speed_slow
	cmp.b	#ASCII_CTRL_M,d0
	beq.s	wst_set_horiz_scroll_speed_medium
	cmp.b	#ASCII_CTRL_F,d0
	beq.s	wst_set_horiz_scroll_speed_fast
	cmp.b	#ASCII_CTRL_W,d0
	beq.s	wst_stop_scrolltext
	rts
	CNOP 0,4
wst_set_standard_scroll
	move.w	#sine_table_length/2,wst_y_angle(a3) ; Y-Winkel = 180�
	clr.w	wst_y_angle_speed(a3) ; Y-Winkel-Geschwindigkeit = 0
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_clear_y_angle_step
	clr.w	wst_y_angle_step(a3) ; Y-Winkel-Schrittweite = 0
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_set_y_angle_step
	move.w	#wst_y_angle_step1,wst_y_angle_step(a3) ; Y-Winkel-Schrittweite setzen
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_set_y_angle_speed
	move.w	#wst_y_angle_speed1,wst_y_angle_speed(a3) ; Y-Winkel-Geschwindigkeit setzen
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_set_horiz_scroll_speed_slow
	move.w	#wst_horiz_scroll_speed1,wst_horiz_scroll_speed(a3)
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_set_horiz_scroll_speed_medium
	move.w	#wst_horiz_scroll_speed2,wst_horiz_scroll_speed(a3)
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_set_horiz_scroll_speed_fast
	move.w	#wst_horiz_scroll_speed3,wst_horiz_scroll_speed(a3)
	moveq	#RETURN_OK,d0
	rts
	CNOP 0,4
wst_stop_scrolltext
	move.w	#FALSE,wst_enabled(a3)
	moveq	#RETURN_OK,d0
	rts


	CNOP 0,4
bv_clear_image
	move.l	extra_pf1(a3),a0
	WAITBLIT
	move.l	#BC0F_DEST<<16,BLTCON0-DMACONR(a6) ; Minterm L�schen
	move.l	(a0),BLTDPT-DMACONR(a6)
	moveq	#0,d0
	move.w	d0,BLTDMOD-DMACONR(a6) ; D-Mod
	move.w	#(bv_clear_blit_y_size*bv_clear_blit_depth<<6)+(bv_clear_blit_x_size/WORD_BITS),BLTSIZE-DMACONR(a6) ; Blitter starten
	rts


	CNOP 0,4
bv_move_lightsource
	move.w	rz_zoom_angle(a3),d0
	lea	sine_table(pc),a0	
	move.l	(a0,d0.w*4),d0		; -sin(w)
	neg.l	d0
	MULUF.L bv_light_z_radius*2,d0,d1 ; z'=(zr*(-sin(w)))/2^15
	swap	d0
	add.w	#bv_light_z_center,d0	; z' + Z-Mittelpunkt
	moveq	#bv_light_z_coordinate1,d1
	sub.w	d0,d1			; + Z-Koodinate der Lichtquelle
	move.w	d1,bv_light_z_coordinate(a3)
	rts


	CNOP 0,4
bv_rotation
	movem.l a4-a5,-(a7)
	move.w	bv_rotation_x_angle(a3),d1
	move.w	d1,d0		
	lea	sine_table(pc),a2
	move.w	2(a2,d0.w*4),d4		; sin(a)
	move.w	#sine_table_length/4,a4
	MOVEF.W sine_table_length-1,d3
	add.w	a4,d0			; + 90�
	swap	d4 			; high word: sin(a)
	and.w	d3,d0			; �bertrag entfernen
	move.w	2(a2,d0.w*4),d4		; low word: cos(a)
	add.w	bv_rotation_x_angle_speed(a3),d1 ; n�chster X-Winkel
	and.w	d3,d1			; �bertrag entfernen
	move.w	d1,bv_rotation_x_angle(a3) 
	move.w	bv_rotation_y_angle(a3),d1
	move.w	d1,d0		
	move.w	2(a2,d0.w*4),d5		; sin(b)
	add.w	a4,d0			; + 90�
	swap	d5 			; high word: sin(b)
	and.w	d3,d0			; �bertrag entfernen
	move.w	2(a2,d0.w*4),d5		; low word: cos(b)
	add.w	bv_rotation_y_angle_speed(a3),d1 ; n�chster Y-Winkel
	and.w	d3,d1			; �bertrag entfernen
	move.w	d1,bv_rotation_y_angle(a3) 
	move.w	bv_rotation_z_angle(a3),d1
	move.w	d1,d0		
	move.w	2(a2,d0.w*4),d6	;sin(c)
	add.w	a4,d0			; + 90�
	swap	d6 			; high word: sin(c)
	and.w	d3,d0			; �bertrag entfernen
	move.w	2(a2,d0.w*4),d6	 	; low word: cos(c)
	add.w	bv_rotation_z_angle_speed(a3),d1 ; n�chster Z-Winkel
	and.w	d3,d1			; �bertrag entfernen
	move.w	d1,bv_rotation_z_angle(a3) 
	lea	bv_object_coords(pc),a0
	lea	bv_rotation_xyz_coords(pc),a1
	move.w	#bv_rotation_d*8,a4	; d
	add.l	bv_zoom_distance(a3),a4
	move.w	#bv_rotation_xy_center,a5
	moveq	#bv_object_edge_points_number-1,d7
bv_rotation_loop
	move.w	(a0)+,d0		; X-Koord.
	move.l	d7,a2		
	move.w	(a0)+,d1		; Y-Koord.
	move.w	(a0)+,d2		; Z-Koord.
	ROTATE_X_AXIS
	ROTATE_Y_AXIS
	ROTATE_Z_AXIS
; Zentralprojektion und Translation
	move.w	d2,d3			; z -> d3
	ext.l	d0
	add.w	a4,d3			; z+d
	MULUF.L bv_rotation_d,d0,d7	; x*d X-Projektion
	ext.l	d1
	divs.w	d3,d0			; x' = (x*d)/(z+d)
	MULUF.L bv_rotation_d,d1,d7	; y*d Y-Projektion
	add.w	a5,d0			; x' + X-Mittelpunkt
	move.w	d0,(a1)+		; X-Pos.
	divs.w	d3,d1			; y' = (y*d)/(z+d)
	add.w	a5,d1			; y' + Y-Mittelpunkt
	move.w	d1,(a1)+		; Y-Pos.
	asr.w	#3,d2			; Z/8
	move.l	a2,d7			; Schleifenz�hler
	move.w	d2,(a1)+		; Z-Pos.
	dbf	d7,bv_rotation_loop
	movem.l (a7)+,a4-a5
	rts


	CNOP 0,4
bv_draw_lines
	movem.l a3-a5,-(a7)
	move.l	a7,save_a7(a3)
	tst.w	bv_active(a3)
	bne	bv_draw_lines_quit
	bsr	bv_draw_lines_init
	lea	bv_object_info(pc),a0
	lea	bv_rotation_xyz_coords(pc),a1
	move.l	extra_pf2(a3),a2
	move.l	(a2),a2			; Bild
	move.l	cl1_construction2(a3),a4
	move.l	#((BC0F_SRCA|BC0F_SRCC|BC0F_DEST+NANBC|NABC|ABNC)<<16)+(BLTCON1F_LINE+BLTCON1F_SING),a3 ; Minterm Linien
	ADDF.W	cl1_COLOR12_high5+WORD_SIZE,a4
	lea	bv_color_table(pc),a7	; Zeiger auf Tabelle mit Farbverlaufwerten
	moveq	#bv_object_faces_number-1,d7
bv_draw_lines_loop1
; Z-Koordinate des Vektors N durch das Kreuzprodukt u x v berechnen
	move.l	(a0)+,a5		; Zeiger auf Startwerte der Punkte
	swap	d7			; Fl�chenz�hler retten
	move.w	(a5),d4			; P1-Startwert
	move.w	2(a5),d5		; P2-Startwert
	move.w	4(a5),d6		; P3-Startwert
	movem.w (a1,d5.w*2),d0-d1	; P2(x,y)
	movem.w (a1,d6.w*2),d2-d3	; P3(x,y)
	sub.w	d0,d2			; xv = xp3-xp2
	sub.w	(a1,d4.w*2),d0		; xu = xp2-xp1
	sub.w	d1,d3			; yv = yp3-yp2
	sub.w	2(a1,d4.w*2),d1		; yu = yp2-yp1
	muls.w	d3,d0			; xu*yv
	muls.w	d2,d1			; yu*xv
	sub.l	d0,d1			; zn = (yu*xv)-(xu*yv)
	bpl	bv_draw_lines_skip5
; Mittlere Z-Koordinate der Fl�che berechnen
	move.w	6(a5),d7		; P4-Startwert
	move.w	4(a1,d4.w*2),d0		; zm = zp1+zp2+zp3+zp4
	add.w	4(a1,d5.w*2),d0
	add.w	4(a1,d6.w*2),d0
	move.l	#bv_kdRGB*bv_EpRGB,d1	; (kdRGB*EpRGB)
	add.w	4(a1,d7.w*2),d0
	IFEQ bv_object_edge_points_per_face-4
		asr.w	#2,d0		; zm / Anzahl der Eckpunkte
	ELSE
		ext.l	d0
		divs.w	#bv_object_edge_points_per_face,d0 ; zm / Anzahl der Eckpunkte
	ENDC
; Entfernung zur Lichtquelle berechnen
	move.w	(a0),d7			; Farbnummer
	sub.w	variables+bv_light_z_coordinate(pc),d0 ; D = zm-zl
; Farbintensit�t der Fl�che ermitteln
	sub.w	#bv_D0,d0		; D-D0
	bgt.s	bv_draw_lines_skip1
	moveq	#1,d0			; D = 1
bv_draw_lines_skip1
	divu.w	d0,d1			; RtdRGB = (kdRGB*EpRGB)/(D-D0)
	IFEQ bv_EpRGB_check_max_enabled
		cmp.w	#bv_EpRGB_max,d1
		ble.s	bv_draw_lines_skip2
		MOVEF.W bv_EpRGB_max,d1
bv_draw_lines_skip2
	ENDC
; Farbwert in Copperliste eintragen
	move.l	(a7,d1.w*4),d0
	move.w	d0,(cl1_COLOR12_low5-cl1_COLOR12_high5,a4,d7.w*4) ; Color low
	swap	d0			; High
	move.w	d0,(a4,d7.w*4)		; High-Bits COLORxx
	move.w	object_info_lines_number-object_info_face_color(a0),d6 ; Anzahl der Linien
bv_draw_lines_loop2
	move.w	(a5)+,d0		; Startwerte der Punkte P1,P2
	move.w	(a5),d2
	movem.w (a1,d0.w*2),d0-d1	; P1(x,y)
	movem.w (a1,d2.w*2),d2-d3	; P2(x,y)
	GET_LINE_PARAMETERS bv,AREAFILL,,extra_pf1_plane_width*extra_pf1_depth,bv_draw_lines_skip4
	add.l	a2,d1			; + Bitplanes-Adresse
	add.l	a3,d0			; restliche BLTCON0 & BLTCON1-Bits setzen
	btst	#0,d7			; Bitplane1 ?
	beq.s	bv_draw_lines_skip3
	WAITBLIT
	move.l	d0,BLTCON0-DMACONR(a6) 	; low word: BLTCON1, high word: BLTCON0
	move.w	d3,BLTAPTL-DMACONR(a6)	; (dy)-(2*dx)
	move.l	d1,BLTCPT-DMACONR(a6)	; Bitplanes lesen
	move.l	d1,BLTDPT-DMACONR(a6)	; Bitplanes schreiben
	move.l	d4,BLTBMOD-DMACONR(a6) 	; low word: 4*(dy-dx), high word: 4*dy
	move.w	d2,BLTSIZE-DMACONR(a6)
bv_draw_lines_skip3
	btst	#1,d7			; Bitplane2 ?
	beq.s	bv_draw_lines_skip4
	moveq	#extra_pf1_plane_width,d5
	add.l	d5,d1			; n�chste Bitplane
	WAITBLIT
	move.l	d0,BLTCON0-DMACONR(a6) 	; low word: BLTCON1, high word: BLTCON0
	move.w	d3,BLTAPTL-DMACONR(a6)	; (dy)-(2*dx)
	move.l	d1,BLTCPT-DMACONR(a6)	; Bitplanes lesen
	move.l	d1,BLTDPT-DMACONR(a6)	; Bitplanes schreiben
	move.l	d4,BLTBMOD-DMACONR(a6) 	; low word: 4*(dy-dx), high word: 4*dy
	move.w	d2,BLTSIZE-DMACONR(a6)
bv_draw_lines_skip4
	dbf	d6,bv_draw_lines_loop2
bv_draw_lines_skip5
	swap	d7			; Fl�chenz�hler
	addq.w	#LONGWORD_SIZE,a0	; Farbnummer und Anzahl der Linien �berspringen
	dbf	d7,bv_draw_lines_loop1
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
bv_draw_lines_quit
	move.l	variables+save_a7(pc),a7
	movem.l (a7)+,a3-a5
	rts
	CNOP 0,4
bv_draw_lines_init
	move.w	#DMAF_BLITHOG|DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.l	#$ffff8000,BLTBDAT-DMACONR(a6) ; low word: Linientextur mit MSB beginnen, high word: Linientextur
	moveq	#-1,d0
	move.l	d0,BLTAFWM-DMACONR(a6)
	moveq	#extra_pf1_plane_width*extra_pf1_depth,d0 ; Moduli f�r Interleaved-Bitmaps
	move.w	d0,BLTCMOD-DMACONR(a6)
	move.w	d0,BLTDMOD-DMACONR(a6)
	rts


	CNOP 0,4
bv_fill_image
	move.l	extra_pf2(a3),a0
	move.l	(a0),a0
	add.l	#(extra_pf1_plane_width*extra_pf1_y_size*extra_pf1_depth)-2,a0 ; Ende des Bildes
	WAITBLIT
	move.l	#((BC0F_SRCA|BC0F_DEST|ANBNC|ANBC|ABNC|ABC)<<16)+(BLTCON1F_DESC+BLTCON1F_EFE),BLTCON0-DMACONR(a6) ; Minterm D=A, F�ll-Modus, R�ckw�rts
	move.l	a0,BLTAPT-DMACONR(a6)	; Quelle
	move.l	a0,BLTDPT-DMACONR(a6)	; Ziel
	moveq	#0,d0
	move.l	d0,BLTAMOD-DMACONR(a6)	; A+D-Mod
	move.w	#(bv_fill_blit_y_size*bv_fill_blit_depth<<6)+(bv_fill_blit_x_size/WORD_BITS),BLTSIZE-DMACONR(a6) ; Blitter starten
	rts


	CNOP 0,4
bv_copy_image
	move.l	a4,-(a7)
	move.l	extra_pf3(a3),a0
	move.l	(a0),a0			; Image
	lea	spr_ptrs_construction+(bv_used_first_sprite*LONGWORD_SIZE)(pc),a2
	move.l	(a2)+,a1		; Sprite6
	ADDF.W	(spr_pixel_per_datafetch/4),a1 ; Header �berspringen
	move.l	(a2),a2			; Sprite7
	ADDF.W	(spr_pixel_per_datafetch/4),a2 ; Header �berspringen
	moveq	#bv_image_y_size-1,d7
bv_copy_image_loop
	movem.l (a0)+,d0-d6/a4		; Bitplane1&2 mit jeweils 128 Pixel lesen
	move.l	d0,(a1)+		; Sprite0 Bitplane1 64 Pixel
	move.l	d1,(a1)+
	move.l	d2,(a2)+		; Sprite1 Bitplane1 64 Pixel
	move.l	d3,(a2)+
	move.l	d4,(a1)+		; Sprite0 Bitplane2 64 Pixel
	move.l	d5,(a1)+
	move.l	d6,(a2)+		; Sprite1 Bitplane2 64 Pixel
	move.l	a4,(a2)+
	dbf	d7,bv_copy_image_loop
	move.l	(a7)+,a4
	rts


	CNOP 0,4
bv_move_sprites
	movem.l a3-a6,-(a7)
	move.w	bv_sprite_x_coordinate(a3),d3
	move.w	bv_sprite_y_coordinate(a3),d4
	move.w	bv_sprite_x_direction(a3),d5
	moveq	#bv_sprite_y_center,d6
	lea	spr_ptrs_construction+(bv_used_first_sprite*LONGWORD_SIZE)(pc),a1
	move.w	#bv_sprite_x_max,a2
	move.w	#bv_sprite_y_max,a4
	move.w	#bv_sprite_x_center,a5
	add.w	d5,d3			; X-Pos. erh�hen/verringern
	IFNE bv_sprite_x_min
		cmp.w	#bv_sprite_x_min,d3 ; X >= X-Min ?
	ENDC
	bge.s	bv_move_sprites_skip1
	moveq	#bv_sprite_x_min,d3	; X zur�cksetzen
	neg.w	d5			; X-Richtung umkehren
bv_move_sprites_skip1
	cmp.w	a2,d3			; X-Max ?
	blt.s	bv_move_sprites_skip2
	move.w	a2,d3			; X zur�cksetzen
	neg.w	d5			; X-Richtung umkehren
bv_move_sprites_skip2
	move.w	d3,bv_sprite_x_coordinate(a3)
	add.w	a5,d3			; + X-Mittelpunkt
	move.w	d5,bv_sprite_x_direction(a3)

	move.w	bv_sprite_y_direction(a3),d5
	add.w	d5,d4			; Y-Pos. erh�hen/verringern
	IFNE bv_sprite_y_min
		cmp.w	#bv_sprite_y_min,d4
	ENDC
	bge.s	bv_move_sprites_skip3
	moveq	#bv_sprite_y_min,d4	; Y zur�cksetzen
	neg.w	d5			; Y-Richtung �ndern
bv_move_sprites_skip3
	cmp.w	a4,d4			; Y-Max ?
	blt.s	bv_move_sprites_skip4
	move.w	a4,d4			; Y zur�cksetzen
	neg.w	d5			; Y-Richtung �ndern
bv_move_sprites_skip4
	move.w	d4,bv_sprite_y_coordinate(a3)
	add.w	d6,d4			; + Y-Mittelpunkt
	move.w	d5,bv_sprite_y_direction(a3)
	move.w	#spr_x_size2*SHIRES_PIXEL_FACTOR,a2 ; X-Offset n�chstes Sprite
	moveq	#bv_used_sprites_number-1,d7
bv_move_sprites_loop
	move.l	(a1)+,a0		; Sprite-Struktur
	move.w	d3,d0			; X-Pos.
	move.w	d4,d1			; Y-Pos.
	MOVEF.W bv_image_y_size,d2
	add.w	d1,d2			; VSTOP
	SET_SPRITE_POSITION d0,d1,d2
	move.w	d1,(a0)			; SPRxPOS
	add.w	a2,d3			; X-Position des n�chsten Sprites
	move.w	d2,spr_pixel_per_datafetch/8(a0) ; SPRxCTL
	dbf	d7,bv_move_sprites_loop
	movem.l (a7)+,a3-a6
	rts

	CNOP 0,4
bv_wobble_sprites
	movem.l a4-a6,-(a7)
	move.w	bv_wobble_x_radius_angle(a3),d1
	move.w	d1,d0		
	MOVEF.W sine_table_length-1,d5
	addq.w	#bv_wobble_x_radius_angle_speed,d0 ; n�chster X-Radius-Winkel
	move.w	bv_wobble_x_angle(a3),d2
	and.w	d5,d0			; remove overflow
	move.w	d0,bv_wobble_x_radius_angle(a3)
	move.w	d2,d0		
	addq.w	#bv_wobble_x_angle_speed,d0 ; n�chster X-Winkel
	move.w	d5,d0			; remove overflow
	move.w	d0,bv_wobble_x_angle(a3)
	lea	spr_ptrs_construction+(bv_used_first_sprite*LONGWORD_SIZE)(pc),a0
	move.l	cl1_construction2(a3),a1
	ADDF.W	cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subext1_SPR6POS+WORD_SIZE,a1
	move.l	(a0)+,a2		; Sprite6-Struktur
	move.w	(a2),a5			; SPR6POS
	move.l	(a0),a2			; Sprite7-Struktur
	move.w	(a2),a6			; SPR7POS
	lea	sine_table(pc),a0
	move.w	#bv_wobble_x_center,a2
	move.w	#cl1_subextension1_size,a4
	MOVEF.W cl2_display_y_size-1,d7
bv_wobble_sprites_loop1
	moveq	#rz_display_y_scale_factor-1,d6 ; Anzahl der Abschnitte f�r Y-Skalierung
bv_wobble_sprites_loop2
	move.l	(a0,d1.w*4),d0		; cos(w)
	MULUF.L bv_wobble_x_radius*2*2,d0,d3 ; xr'=(xr*cos(w))/2*^15
	swap	d0
	muls.w	2(a0,d2.w*4),d0		; x'=(xr'*cos(w))/2*^15
	swap	d0
	add.w	a2,d0			; x' + X-Mittelpunkt
	move.w	d0,d3		
	add.w	a5,d0			; x' + vertikaler/horizontaler table start des Sprites6
	move.w	d0,(a1)			; SPR6POS
	addq.w	#bv_wobble_x_radius_angle_step,d1 ; n�chster X-Radius-Winkel
	addq.w	#bv_wobble_x_angle_step,d2 ; n�chster X-Winkel
	and.w	d5,d1			; remove overflow
	and.w	d5,d2			; remove overflow
	add.w	a6,d3			; x' + vertikaler/horizontaler table start des Sprites7
	move.w	d3,4(a1)		; SPR7POS
	add.l	a4,a1			; next line in cl
	dbf	d6,bv_wobble_sprites_loop2
	addq.w	#QUADWORD_SIZE,a1	; COP2LCH + COP2LCL �berspringen
	dbf	d7,bv_wobble_sprites_loop1
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
rotation_zoomer
	movem.l a3-a6,-(a7)
	tst.w	rz_active(a3)
	bne	rotation_zoomer_quit
	lea	sine_table(pc),a0
	move.w	rz_z_rotation_angle(a3),d4
	move.w	d4,d3
	move.w	rz_zoom_angle(a3),d5
	IFNE rz_table_length_256
		MOVEF.W sine_table_length-1,d6 ; �berlauf
	ENDC
	move.w	2(a0,d4.w*4),d1		; sin(w)
	IFEQ rz_table_length_256
		add.b	#sine_table_length/4,d4 ; + 90�
	ELSE
		add.w	#sine_table_length/4,d4 ; + 90�
	ENDC
	move.w	2(a0,d5.w*4),d2		; sin(w) f�r Zoom
	IFEQ rz_table_length_256
		addq.b	#rz_z_rotation_angle_speed,d3 ; n�chster Rotations-Winkel
	ELSE
	and.w	d6,d4			; remove overflow
		addq.w	#rz_z_rotation_angle_speed,d3 ; n�chster Rotations-Winkel
		and.w	d6,d3		; remove overflow
	ENDC
	move.w	2(a0,d4.w*4),d0	;cos(w)
	tst.w	rz_zoomer_active(a3)
	bne.s	rotation_zoomer_skip
	IFEQ rz_table_length_256
		addq.b	#rz_zoom_angle_speed,d5 ; n�chster Zoom-Winkel
rotation_zoomer_skip
	ELSE
		addq.w	#rz_zoom_angle_speed,d5 ; n�chster Zoom-Winkel
		and.w	d6,d5		; remove overflow
	ENDC
rotation_zoomer_skip
; Zoomfaktor berechnen
	IFEQ rz_zoom_radius-4096
		asr.w	#3,d2		; zoom'=(zoomr*sin(w))/2^15
	ELSE
		IFEQ rz_zoom_radius-2048
			asr.w	#4,d2	; zoom'=(zoomr*sin(w))/2^15
		ELSE
			IFEQ rz_zoom_radius-1024
				asr.w	#5,d2 ; zoom'=(zoomr*sin(w))/2^15
			ELSE
				MULSF.W rz_zoom_radius*2,d2,d6 ; zoom=(zoomr*sin(w))/2^15
				swap	d2
			ENDC
		ENDC
	ENDC
	move.w	d3,rz_z_rotation_angle(a3)
	add.w	#rz_zoom_center,d2
	move.w	d5,rz_zoom_angle(a3)
	muls.w	d2,d0			; x'=(zoom'*cos(w))/2^15
	muls.w	d2,d1			; y'=(zoom'*sin(w))/2^15
	swap	d0
	swap	d1
; Rotation um die Z-Achse
	moveq	#rz_Ax,d2		; X links oben
	muls.w	d0,d2			; Ax*cos(w)
	moveq	#rz_Ay,d3		; Y links oben
	muls.w	d1,d3			; Ay*sin(w)
	move.l	extra_memory(a3),a0	; Zeiger auf BPLAM-Tabelle
	add.l	d3,d2			; Ax'=Ax*cos(w)+Ay*sin(w)
	moveq	#rz_Bx,d3		; X rechts oben
	muls.w	d1,d3			; Bx*sin(w)
	moveq	#rz_By,d4		; Y rechts oben
	muls.w	d0,d4			; By*cos(w)
	add.w	#rz_z_rotation_x_center<<8,d2 ; x' + X-Mittelpunkt
	add.l	d4,d3			; By'=Bx*sin(w)+By*cos(w)
; Translation
	move.w	d2,a4			; X-Mittelpunkt retten
	add.w	#rz_z_rotation_y_center<<8,d3 ; y' + Y-Mittelpunkt
	move.l	cl2_construction2(a3),a1
	move.w	d3,a5			; Y-Mittelpunkt retten
; BPLAM-werte in Copperliste kopieren
	move.l	a7,save_a7(a3)	
	move.w	#cl2_extension1_size,a2
	move.w	d0,a3			; cos(w) retten
	move.w	d1,a7			; sin(w)
	add.w	a3,a3			; notwendig, um die 2:1 Pixelverzerrung auszugleichen
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPLCON4_1+WORD_SIZE,a1
	move.w	#(cl2_extension1_size*cl2_display_y_size)-4,a6
	add.w	a7,a7			; notwendig, um die 2:1 Pixelverzerrung auszugleichen
	moveq	#0,d2
	moveq	#cl2_display_width-1,d7 ; number of columns
rotation_zoomer_loop1
	move.w	a4,d4			; X Linke obere Ecke in BPLAM-Tabelle
	move.w	a5,d5			; Y Linke obere Ecke in BPLAM-Tabelle
	moveq	#cl2_display_y_size-1,d6
rotation_zoomer_loop2
	move.w	d4,d3			; X-Pos in BPLAM-Tabelle
	move.w	d5,d2			; Y-Pos in BPLAM-Tabelle
	lsr.w	#8,d3			; Bits in richtige Postion bringen
	move.b	d3,d2			; Bits 0-7: X-Offset, Bits 8-15: Y-Offset
	move.b	(a0,d2.l),(a1)		; BPLCON4 high
	add.w	d1,d4			; n�chste Pixel-Spalte in BPLAM-Tabelle
	add.w	d0,d5			; n�chste Pixel-Zeile in BPLAM-Tabelle
	add.l	a2,a1			; next line in cl
	dbf	d6,rotation_zoomer_loop2
	add.w	a3,a4			; n�chste X-Pos in BPLAM--Tabelle
	sub.w	a7,a5			; n�chste Y-Pos in BPLAM-Tabelle
	sub.l	a6,a1			; next column in CL
	dbf	d7,rotation_zoomer_loop1
	move.l	variables+save_a7(pc),a7
rotation_zoomer_quit
	movem.l (a7)+,a3-a6
	rts


	CNOP 0,4
image_fader_in
	movem.l a4-a6,-(a7)
	tst.w	ifi_rgb8_active(a3)
	bne.s	image_fader_in_quit
	move.w	ifi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	ifi_rgb8_fader_angle_speed,d0 ; n�chster Winkel
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	image_fader_in_skip
	MOVEF.W sine_table_length/2,d0
image_fader_in_skip
	move.w	d0,ifi_rgb8_fader_angle(a3) 
	MOVEF.W if_rgb8_colors_number*3,d6 ; RGB-Z�hler
	lea	sine_table(pc),a0
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L ifi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	ifi_rgb8_fader_center,d0
	lea	pf1_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer f�r Farbwerte
	lea	ifi_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W if_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,if_rgb8_colors_counter(a3) ; Fading-In beendet ?
	bne.s	image_fader_in_quit
	move.w	#FALSE,ifi_rgb8_active(a3)
image_fader_in_quit
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
image_fader_out
	movem.l a4-a6,-(a7)
	tst.w	ifo_rgb8_active(a3)
	bne.s	image_fader_out_quit
	move.w	ifo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	ifo_rgb8_fader_angle_speed,d0 ; n�chster Winkel
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	image_fader_out_skip
	MOVEF.W sine_table_length/2,d0
image_fader_out_skip
	move.w	d0,ifo_rgb8_fader_angle(a3) 
	MOVEF.W if_rgb8_colors_number*3,d6 ; RGB-Z�hler
	lea	sine_table(pc),a0
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L ifo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	ifo_rgb8_fader_center,d0
	lea	pf1_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer f�r Farbwerte
	lea	ifo_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W if_rgb8_colors_number-1,d7
	bsr.s	if_rgb8_fader_loop
	move.w	d6,if_rgb8_colors_counter(a3) ; Fading-Out beendet ?
	bne.s	image_fader_out_quit
	moveq	#FALSE,d0
	move.w	d0,ifo_rgb8_active(a3)
	move.w	d0,part_title_active(a3)
image_fader_out_quit
	movem.l (a7)+,a4-a6
	rts


	RGB8_COLOR_FADER if


	COPY_RGB8_COLORS_TO_COPPERLIST if,pf1,cl1,cl1_COLOR00_high1,cl1_COLOR00_low1


	CNOP 0,4
blind_fader_in
	move.l	a4,-(a7)
	tst.w	bfi_active(a3)
	bne.s	blind_fader_in_quit
	move.w	bf_address_offsets_table_start(a3),d2
	MOVEF.W bf_table_length-1,d3
	move.w	d2,d0		
	MOVEF.L cl2_extension1_size,d4
	addq.w	#bf_speed,d0		; increase table start
	moveq	#bf_step2,d5
	cmp.w	#(bf_table_length/2)+1,d0 ; end of table ?
	ble.s	blind_fader_in_skip
	move.w	#FALSE,bfi_active(a3)
	bra.s	blind_fader_in_quit
	CNOP 0,4
blind_fader_in_skip
	move.w	d0,bf_address_offsets_table_start(a3) 
	lea	bf_address_offsets_table(pc),a0 ; Tabelle mit Registeroffsets
	IFNE cl2_size1
		move.l	cl2_construction1(a3),a1
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a1
		ENDC
	ENDC
	IFNE cl2_size2
		move.l	cl2_construction2(a3),a2
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a2
		ENDC
	ENDC
	IFNE cl2_size3
		move.l	cl2_display(a3),a4
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a4
		ENDC
	ENDC
	moveq	#bf_lamellas_number-1,d7
blind_fader_in_loop1
	move.w	d2,d1			; Startwert
	moveq	#bf_lamella_height-1,d6
blind_fader_in_loop2
	move.w	(a0,d1.w*2),d0		; Registeroffset aus Tabelle
	addq.w	#bf_step1,d1		; next entry
	IFNE cl2_size1
		move.w	d0,(a1)		; Registeroffset in CL schreiben
		add.l	d4,a1		; next line in cl
	ENDC
	IFNE cl2_size2
		move.w	d0,(a2)		; Registeroffset in CL schreiben
		add.l	d4,a2		; next line in cl
	ENDC
	IFNE cl2_size3
		move.w	d0,(a4)		; Registeroffset in CL schreiben
		add.l	d4,a4		; next line in cl
	ENDC
	and.w	d3,d1			; remove overflow
	dbf	d6,blind_fader_in_loop2
	add.w	d5,d2			; increase table start
	and.w	d3,d2			; remove overflow
	dbf	d7,blind_fader_in_loop1
blind_fader_in_quit
	move.l	(a7)+,a4
	rts


	CNOP 0,4
blind_fader_out
	move.l	a4,-(a7)
	tst.w	bfo_active(a3)
	bne.s	blind_fader_out_quit
	move.w	bf_address_offsets_table_start(a3),d2
	MOVEF.W bf_table_length-1,d3
	move.w	d2,d0		
	MOVEF.L cl2_extension1_size,d4
	subq.w	#bf_speed,d0		; decrease table start
	bpl.s	blind_fader_out_skip
	moveq	#FALSE,d0
	move.w	d0,bfo_active(a3)
	move.w	d0,part_main_active(a3)
	tst.w	pt_music_fader_active(a3)
	beq.s	blind_fader_out_quit
	bsr	init_main_variables2
	bsr	wst_init_chars_x_positions
	bsr	init_colors2
	bsr	set_noop_screen
	bsr	cl1_set_branches_ptrs
	move.w	#DMAF_RASTER|DMAF_SETCLR,DMACON-DMACONR(a6)
	moveq	#0,d0
	move.w	d0,COPJMP1-DMACONR(a6)	; 1. Copperliste neu starten, damit die ge�nderte Palette dargestellt wird
	bra.s	blind_fader_out_quit
	CNOP 0,4
blind_fader_out_skip
	move.w	d0,bf_address_offsets_table_start(a3) 
	moveq	#bf_step2,d5
	lea	bf_address_offsets_table(pc),a0
	IFNE cl2_size1
		move.l	cl2_construction1(a3),a1
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a1
		ENDC
	ENDC
	IFNE cl2_size2
		move.l	cl2_construction2(a3),a2
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a2
		ENDC
	ENDC
	IFNE cl2_size3
		move.l	cl2_display(a3),a4
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a4
		ENDC
	ENDC
	moveq	#bf_lamellas_number-1,d7
blind_fader_out_loop1
	move.w	d2,d1			; Startwert
	moveq	#bf_lamella_height-1,d6
blind_fader_out_loop2
	move.w	(a0,d1.w*2),d0		; Registeradresse aus Tabelle
	addq.w	#bf_step1,d1		; next entry
	IFNE cl2_size1
		move.w	d0,(a1)		; Registeroffset in CL schreiben
		add.l	d4,a1		; next line in cl
	ENDC
	IFNE cl2_size2
		move.w	d0,(a2)		; Registeroffset in CL schreiben
		add.l	d4,a2		; next line in cl
	ENDC
	IFNE cl2_size3
		move.w	d0,(a4)		; Registeroffset in CL schreiben
		add.l	d4,a4		; next line in cl
	ENDC
	and.w	d3,d1			; remove overflow
	dbf	d6,blind_fader_out_loop2
	add.w	d5,d2			; increase table start
	and.w	d3,d2			; remove overflow
	dbf	d7,blind_fader_out_loop1
blind_fader_out_quit
	move.l	(a7)+,a4
	rts


	CNOP 0,4
init_colors2
; Bild
	lea	ifo_rgb8_color_table(pc),a0
	move.l	cl1_construction2(a3),a1 
	ADDF.W	cl1_COLOR00_high1+WORD_SIZE,a1
	move.l	cl1_display(a3),a2 
	ADDF.W	cl1_COLOR00_high1+WORD_SIZE,a2
	move.w	#RB_NIBBLES_MASK,d3
	IFGT pf1_colors_number-32
		moveq	#0,d4		; Farbregisterz�hler
	ENDC
	moveq	#pf1_colors_number-1,d7
init_colors2_loop
	move.l	(a0)+,d0		; RGB8
	move.l	d0,d1		
	RGB8_TO_RGB4_HIGH d0,d2,d3
	move.w	d0,(a1)			; Color high
	addq.w	#4,a1
	move.w	d0,(a2)			; Color high
	RGB8_TO_RGB4_LOW d1,d2,d3
	move.w	d2,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a1) ; Color low
	addq.w	#4,a2
	move.w	d2,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a2) ; Color low
	IFGT pf1_colors_number-32
	addq.b	#1<<3,d4		; Farbregister-Z�hler erh�hen
	bne.s	init_colors2_skip
	addq.w	#LONGWORD_SIZE,a1	; CMOVE BPLCON3 �berspringen
	addq.w	#LONGWORD_SIZE,a2	; CMOVE BPLCON3 �berspringen
init_colors2_skip
	ENDC
	dbf	d7,init_colors2_loop
; Sprites
	lea	spr_rgb8_color_table(pc),a0
	move.l	cl1_construction2(a3),a1 
	ADDF.W	cl1_COLOR00_high5+WORD_SIZE,a1
	move.l	cl1_display(a3),a2 
	ADDF.W	cl1_COLOR00_high5+WORD_SIZE,a2
	move.w	#RB_NIBBLES_MASK,d3
	IFGT spr_colors_number-32
		moveq	#0,d4		; Farbregisterz�hler
	ENDC
	moveq	#spr_colors_number-1,d7
init_colors2_loop2
	move.l	(a0)+,d0		; RGB8
	move.l	d0,d1		
	RGB8_TO_RGB4_HIGH d0,d2,d3
	move.w	d0,(a1)			; Color high
	addq.w	#4,a1
	move.w	d0,(a2)			; Color high
	RGB8_TO_RGB4_LOW d1,d2,d3
	move.w	d2,cl1_COLOR00_low5-cl1_COLOR00_high5-4(a1) ; Color low
	addq.w	#4,a2
	move.w	d2,cl1_COLOR00_low5-cl1_COLOR00_high5-4(a2) ; Color low
	IFGT spr_colors_number-32
		addq.b	1<<3,d4		; Farbregister-Z�hler erh�hen
		bne.s	init_colors2_skip
		addq.w	#LONGWORD_SIZE,a1 ; CMOVE BPLCON3 �berspringen
		addq.w	#LONGWORD_SIZE,a2 ; CMOVE BPLCON3 �berspringen
init_colors2_skip
	ENDC
	dbf	d7,init_colors2_loop2
	rts


	CNOP 0,4
set_noop_screen
	IFNE cl2_size1
		move.l	cl2_construction1(a3),a0
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a0
		ENDC
	ENDC
	IFNE cl2_size2
		move.l	cl2_construction2(a3),a1
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a1
		ENDC
	ENDC
	IFNE cl2_size3
		move.l	cl2_display(a3),a2
		IFNE cl2_extension1_entry+cl2_ext1_BPL1DAT
			ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1DAT,a2
		ENDC
	ENDC
	move.w	#BPL1DAT,d0
	MOVEF.L cl2_extension1_size,d1
	moveq	#cl2_display_y_size-1,d7
set_noop_screen_loop1
	IFNE cl2_size1
		move.w	d0,(a0)		; Offset BPL1DAT setzen
		add.l	d1,a0
	ENDC
	IFNE cl2_size2
		move.w	d0,(a1)
		add.l	d1,a1
	ENDC
	IFNE cl2_size3
		move.w	d0,(a2)
		add.l	d1,a2
	ENDC
	dbf	d7,set_noop_screen_loop1
	rts


	CNOP 0,4
cube_zoomer_in
	tst.w	czi_active(a3)
	bne.s	cube_zoomer_in_quit
	lea	sine_table(pc),a0
	move.w	czi_zoom_angle(a3),d1
	cmp.w	#sine_table_length/4,d1	; 90� ?
	blt.s   cube_zoomer_in_skip
	move.w	#FALSE,czi_active(a3)
	bra.s	cube_zoomer_in_quit
	CNOP 0,4
cube_zoomer_in_skip
	moveq	#0,d0
	move.w	2(a0,d1.w*4),d0		; sin(w)
	add.w	#czi_zoom_center,d0
	move.l	d0,bv_zoom_distance(a3) 
	addq.w	#czi_zoom_angle_speed,d1
	move.w	d1,czi_zoom_angle(a3)
cube_zoomer_in_quit
	rts


	CNOP 0,4
keyboard_handler
	tst.w	bv_active(a3)
	bne	keyboard_handler_quit
	btst	#CIAICRB_SP,CIAICR(a4)
	beq	keyboard_handler_quit
	btst	#CIACRAB_SPMODE,CIACRA(a4) ; Ausgabe ?
	bne	keyboard_handler_quit
	move.b	CIASDR(a4),d0		; Tastencode
	ror.b	#1,d0			; Bits in richtige Position bringen
	not.b	d0
	bmi.s	keyboard_handler_skip
	tst.b	kh_key_flag(a3)		; Bereits ein Tastencode gespeichert ?
	bne.s	keyboard_handler_skip
	move.b	d0,kh_key_code(a3)
	not.b	kh_key_flag(a3)
keyboard_handler_skip
	moveq	#CIACRAF_SPMODE,d0
	or.b	d0,CIACRA(a4)		; Serieller-Port = Ausgabe, Handshake starten
	moveq	#CIACRBF_START,d0
	or.b	d0,CIACRB(a4)		; Wartezeit 200 �s
keyboard_handler_loop
	btst	#CIACRBB_START,CIACRB(a4)
	bne.s	keyboard_handler_loop
	moveq	#~CIACRAF_SPMODE,d0
	and.b	d0,CIACRA(a4)		; Serieller-Port = Eingabe, Handshake beenden
	clr.b	kh_key_flag(a3)
	move.b	kh_key_code(a3),d0
	cmp.b	#KEYBOARD_KEYCODE_F1,d0
	beq.s	kh_set_xyz_rotation_angle_speed1
	cmp.b	#KEYBOARD_KEYCODE_F2,d0
	beq.s	kh_set_xyz_rotation_angle_speed2
	cmp.b	#KEYBOARD_KEYCODE_F3,d0
	beq.s	kh_set_xyz_rotation_angle_speed3
	cmp.b	#KEYBOARD_KEYCODE_F4,d0
	beq.s	kh_set_xyz_rotation_angle_speed4
	cmp.b	#KEYBOARD_KEYCODE_F5,d0
	beq.s	kh_set_xyz_rotation_angle_speed5
	cmp.b	#KEYBOARD_KEYCODE_F6,d0
	beq	kh_set_xyz_rotation_angle_speed6
	cmp.b	#KEYBOARD_KEYCODE_F7,d0
	beq	kh_set_xyz_rotation_angle_speed7
	cmp.b	#KEYBOARD_KEYCODE_F8,d0
	beq	kh_set_xyz_rotation_angle_speed8
	cmp.b	#KEYBOARD_KEYCODE_F9,d0
	beq	kh_set_xyz_rotation_angle_speed9
	cmp.b	#KEYBOARD_KEYCODE_F10,d0
	beq	kh_set_xyz_rotation_angle_speed10
keyboard_handler_quit
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed1
	move.w	#bv_rotation_x_angle_speed1,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed1,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed1,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed2
	move.w	#bv_rotation_x_angle_speed2,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed2,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed2,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed3
	move.w	#bv_rotation_x_angle_speed3,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed3,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed3,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed4
	move.w	#bv_rotation_x_angle_speed4,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed4,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed4,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed5
	move.w	#bv_rotation_x_angle_speed5,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed5,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed5,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed6
	move.w	#bv_rotation_x_angle_speed6,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed6,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed6,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed7
	move.w	#bv_rotation_x_angle_speed7,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed7,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed7,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed8
	move.w	#bv_rotation_x_angle_speed8,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed8,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed8,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed9
	move.w	#bv_rotation_x_angle_speed9,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed9,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed9,bv_rotation_z_angle_speed(a3)
	rts
	CNOP 0,4
kh_set_xyz_rotation_angle_speed10
	move.w	#bv_rotation_x_angle_speed10,bv_rotation_x_angle_speed(a3)
	move.w	#bv_rotation_y_angle_speed10,bv_rotation_y_angle_speed(a3)
	move.w	#bv_rotation_z_angle_speed10,bv_rotation_z_angle_speed(a3)
	rts

	CNOP 0,4
mouse_handler
	btst	#CIAB_GAMEPORT0,CIAPRA(a4) ; LMB gedr�ckt ?
	beq.s	mh_exit_demo
	rts
	CNOP 0,4
mh_exit_demo
	move.w	#wst_stop_text-wst_text,wst_text_table_start(a3)
	move.w	#FALSE,pt_effects_handler_active(a3)
	clr.w	pt_music_fader_active(a3)
	tst.w	part_title_active(a3)
	bne.s	mh_exit_demo_skip2
	clr.w	ifo_rgb8_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	clr.w	if_rgb8_copy_colors_active(a3)
	tst.w	ifi_rgb8_active(a3)
	bne.s	mh_exit_demo_skip1
	move.w	#FALSE,ifi_rgb8_active(a3)
mh_exit_demo_skip1
	bra.s	mh_exit_demo_quit
	CNOP 0,4
mh_exit_demo_skip2
	tst.w	part_main_active(a3)
	bne.s	mh_exit_demo_quit
	clr.w	bfo_active(a3)
	tst.w	bfi_active(a3)
	bne.s   mh_exit_demo_quit
	move.w	#FALSE,bfi_active(a3)
mh_exit_demo_quit
	rts


	INCLUDE "int-autovectors-handlers.i"

	IFEQ pt_ciatiming_enabled
		CNOP 0,4
ciab_ta_int_server
	ENDC

	IFNE pt_ciatiming_enabled
		CNOP 0,4
VERTB_int_server
	ENDC


; PT-Replay
	IFEQ pt_music_fader_enabled
		bsr.s	pt_music_fader
		bra.s	pt_PlayMusic

		PT_FADE_OUT_VOLUME stop_fx_active
		CNOP 0,4
	ENDC

	IFD PROTRACKER_VERSION_2 
		PT2_REPLAY pt_effects_handler
	ENDC

	IFD PROTRACKER_VERSION_3
		PT3_REPLAY pt_effects_handler
	ENDC

	CNOP 0,4
pt_effects_handler
	tst.w	pt_effects_handler_active(a3)
	bne.s	pt_effects_handler_quit
	move.b	n_cmdlo(a2),d0
	beq.s	pt_restart_intro
	cmp.b	#$10,d0
	beq.s	pt_start_horiz_scrolltext
	cmp.b	#$20,d0
	beq.s	pt_start_fade_in_image
	cmp.b	#$30,d0
	beq.s	pt_start_fade_out_image
	cmp.b	#$40,d0
	beq.s	pt_start_fade_in_rotation_zoomer
	cmp.b	#$50,d0
	beq	pt_start_cube_zoomer_in
	cmp.b	#$60,d0
	beq	pt_start_zoomer
	cmp.b	#$61,d0
	beq	pt_stop_zoomer
pt_effects_handler_quit
	rts
	CNOP 0,4
pt_restart_intro
	clr.w	bfo_active(a3)
	rts
	CNOP 0,4
pt_start_horiz_scrolltext
	clr.w	wst_enabled(a3)
	rts
	CNOP 0,4
pt_start_fade_in_image
	move.l	a0,-(a7)
	clr.w	ifi_rgb8_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	clr.w	if_rgb8_copy_colors_active(a3)
	clr.w	part_title_active(a3)
	move.l	cl1_construction2(a3),a0 
	move.w	#bplcon0_bits2,cl1_BPLCON0+WORD_SIZE(a0) ; Bitplanes an
	move.l	cl1_display(a3),a0 
	move.w	#bplcon0_bits2,cl1_BPLCON0+WORD_SIZE(a0) ; Bitplanes an
	move.l	(a7)+,a0
	rts
	CNOP 0,4
pt_start_fade_out_image
	clr.w	ifo_rgb8_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	clr.w	if_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
pt_start_fade_in_rotation_zoomer
	movem.l d1-d7/a0-a2,-(a7)
	clr.w	rz_active(a3)
	clr.w	bfi_active(a3)
	clr.w	part_main_active(a3)
	bsr.s	rz_init_colors
	bsr	rz_set_branches_ptrs
	move.l	cl1_construction2(a3),a0 
	move.w	#bplcon0_bits,cl1_BPLCON0+WORD_SIZE(a0) ; Bitplanes aus
	move.l	cl1_display(a3),a0 
	move.w	#bplcon0_bits,cl1_BPLCON0+WORD_SIZE(a0) ; Bitplanes aus
	movem.l (a7)+,d1-d7/a0-a2
	rts
	CNOP 0,4
pt_start_cube_zoomer_in
	clr.w	czi_active(a3)
	clr.w	bv_active(a3)
	rts
	CNOP 0,4
pt_start_zoomer
	clr.w	rz_zoomer_active(a3)
	rts
	CNOP 0,4
pt_stop_zoomer
	move.w #FALSE,rz_zoomer_active(a3)
	rts

	CNOP 0,4
rz_init_colors
	lea	pf1_rgb8_color_table+(pf1_colors_number*LONGWORD_SIZE),a0
	move.l	cl1_construction2(a3),a1 
	ADDF.W	cl1_COLOR00_high1+WORD_SIZE,a1
	move.l	cl1_display(a3),a2 
	ADDF.W	cl1_COLOR00_high1+WORD_SIZE,a2
	move.w	#RB_NIBBLES_MASK,d3
	IFGT if_rgb8_colors_number-32
		moveq	#0,d4		; Farbregisterz�hler
	ENDC
	MOVEF.W if_rgb8_colors_number-1,d7
rz_init_colors_loop
	move.l	(a0)+,d0		; RGB8-Farbwert
	move.l	d0,d1		
	RGB8_TO_RGB4_HIGH d0,d2,d3
	move.w	d0,(a1)			; High-Bits COLORxx
	addq.w	#LONGWORD_SIZE,a1
	move.w	d0,(a2)			; High-Bits COLORxx
	RGB8_TO_RGB4_LOW d1,d2,d3
	move.w	d1,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a1) ; Low-Bits COLORxx
	addq.w	#4,a2
	move.w	d1,cl1_COLOR00_low1-cl1_COLOR00_high1-4(a2) ; Low-Bits COLORxx
	IFGT if_rgb8_colors_number-32
		addq.b	#1<<3,d4	; Farbregister-Z�hler erh�hen
		bne.s	rz_init_colors_skip
		addq.w	#LONGWORD_SIZE,a1 ; CMOVE BPLCON3 �berspringen
		addq.w	#LONGWORD_SIZE,a2 ; CMOVE BPLCON3 �berspringen
rz_init_colors_skip
	ENDC
	dbf	d7,rz_init_colors_loop
	rts

	CNOP 0,4
rz_set_branches_ptrs
	move.l	cl1_construction2(a3),a0
	MOVEF.L cl1_subextension1_size,d2
	move.l	cl2_construction2(a3),d0 ; Einsprungadresse
	MOVEF.L cl2_extension1_size,d3
	moveq	#cl1_extension1_size,d4
	bsr.s	rz_set_jump_entry_ptrs
	move.l	cl1_display(a3),a0
	move.l	cl2_display(a3),d0	; Einsprungadresse
	bsr.s	rz_set_jump_entry_ptrs
	rts


; Input
; a0.l	Copperliste1
; d0.l	Einsprungadresse Copperliste2
; d2.l	cl1_subextension1_size
; d3.l	cl2_extension1_size
; Result
	CNOP 0,4
rz_set_jump_entry_ptrs
	MOVEF.L cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subextension1_size,d1 ; Offset R�cksprungadresse CL1
	add.l	a0,d1			; + R�cksprungadresse CL1
	lea	cl1_extension1_entry+cl1_ext1_subextension1_entry+cl1_subext1_COP1LCH+WORD_SIZE(a0),a1
	ADDF.W	cl1_extension1_entry+cl1_ext1_COP2LCH+WORD_SIZE,a0
	moveq	#cl2_display_y_size-1,d7
rz_set_branches_loop1
	swap	d0			; High
	move.w	d0,(a0)			; COP2LCH
	swap	d0			; Low
	move.w	d0,4(a0)		; COP2LCL
	moveq	#rz_display_y_scale_factor-1,d6 ; Anzahl der Abschnitte f�r Y-Skalierung
rz_set_branches_loop2
	swap	d1			; High-Wert
	move.w	d1,(a1)			; COP1LCH
	swap	d1			; Low-Wert
	move.w	d1,4(a1)		; COP1LCL
	add.l	d2,d1			; R�cksprungadresse CL1 erh�hen
	add.l	d2,a1			; n�chste Zeile in Unterabschnitt der CL1
	dbf	d6,rz_set_branches_loop2
	add.l	d3,d0			; Einsprungadresse CL2 erh�hen
	add.l	d4,a0			; n�chste Zeile in CL1
	addq.l	#QUADWORD_SIZE,d1	; CMOVE COP2LCH + CMOVE COP2LCL �berspringen
	addq.w	#QUADWORD_SIZE,a1	; CMOVE COP2LCH + CMOVE COP2LCL �berspringen
	dbf	d7,rz_set_branches_loop1
	rts

	CNOP 0,4
ciab_tb_int_server
	PT_TIMER_INTERRUPT_SERVER

	CNOP 0,4
EXTER_int_server
	rts

	CNOP 0,4
nmi_int_server
	rts


	INCLUDE "help-routines.i"


	INCLUDE "sys-structures.i"


	CNOP 0,4
pf1_rgb8_color_table
	REPT pf1_colors_number
		DC.L color00_bits
	ENDR
	INCLUDE "Old'scool:colortables/256x256x128-Texture.ct"


	CNOP 0,4
spr_rgb8_color_table
	INCLUDE "Old'scool:colortables/64x56x4-Font.ct"
	INCLUDE "Old'scool:colortables/64x56x4-Font.ct"
	INCLUDE "Old'scool:colortables/64x56x4-Font.ct"
	REPT 4
		DC.L color00_bits
	ENDR


	CNOP 0,4
spr_ptrs_construction
	DS.L spr_number


	CNOP 0,4
spr_ptrs_display
	DS.L spr_number


	CNOP 0,4
sine_table
	INCLUDE "sine-table-512x32.i"


; PT-Replay
	INCLUDE "music-tracker/pt-invert-table.i"

	INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

	IFD PROTRACKER_VERSION_2 
		INCLUDE "music-tracker/pt2-period-table.i"
	ENDC
	IFD PROTRACKER_VERSION_3
		INCLUDE "music-tracker/pt3-period-table.i"
	ENDC

	INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

	INCLUDE "music-tracker/pt-sample-starts-table.i"

	INCLUDE "music-tracker/pt-finetune-starts-table.i"


; Wave-Scrolltext
wst_ascii
	DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():/\*#@ "
wst_ascii_end
	EVEN

	CNOP 0,2
wst_chars_offsets
	DS.W wst_ascii_end-wst_ascii

	CNOP 0,2
wst_chars_x_positions
	DS.W wst_text_chars_number


; Blenk-Vectors
	CNOP 0,4
bv_color_table
	INCLUDE "Old'scool:colortables/64-Colorgradient-Brown.ct"


; W�rfel
	CNOP 0,2
bv_object_coords
	DC.W -(35*8),-(35*8),-(35*8)	; P0
	DC.W 35*8,-(35*8),-(35*8)	; P1
	DC.W 35*8,35*8,-(35*8)		; P2
	DC.W -(35*8),35*8,-(35*8)	; P3
	DC.W -(35*8),-(35*8),35*8	; P4
	DC.W 35*8,-(35*8),35*8		; P5
	DC.W 35*8,35*8,35*8		; P6
	DC.W -(35*8),35*8,35*8		; P7

	CNOP 0,4
bv_object_info
; ** 1. Fl�che **
	DC.L 0				; Zeiger auf Koords
	DC.W bv_object_face1_color	; Farbe der Fl�che
	DC.W bv_object_face1_lines_number-1 ; Anzahl der Linien
; ** 2. Fl�che **
	DC.L 0				; Zeiger auf Koords
	DC.W bv_object_face2_color	; Farbe der Fl�che
	DC.W bv_object_face2_lines_number-1 ; Anzahl der Linien
; ** 3. Fl�che **
	DC.L 0				; Zeiger auf Koords
	DC.W bv_object_face3_color	; Farbe der Fl�che
	DC.W bv_object_face3_lines_number-1 ; Anzahl der Linien
; ** 4. Fl�che **
	DC.L 0				; Zeiger auf Koords
	DC.W bv_object_face4_color	; Farbe der Fl�che
	DC.W bv_object_face4_lines_number-1 ; Anzahl der Linien
; ** 5. Fl�che **
	DC.L 0				; Zeiger auf Koords
	DC.W bv_object_face5_color	; Farbe der Fl�che
	DC.W bv_object_face5_lines_number-1 ; Anzahl der Linien
; ** 6. Fl�che **
	DC.L 0				; Zeiger auf Koords
	DC.W bv_object_face6_color	; Farbe der Fl�che
	DC.W bv_object_face6_lines_number-1 ; Anzahl der Linien

	CNOP 0,2
bv_object_edges
	DC.W 0*3,1*3,2*3,3*3,0*3	; Fl�che vorne
	DC.W 5*3,4*3,7*3,6*3,5*3	; Fl�che hinten
	DC.W 4*3,0*3,3*3,7*3,4*3	; Fl�che links
	DC.W 1*3,5*3,6*3,2*3,1*3	; Fl�che rechts
	DC.W 4*3,5*3,1*3,0*3,4*3	; Fl�che oben
	DC.W 3*3,2*3,6*3,7*3,3*3	; Fl�che unten

	CNOP 0,2
bv_rotation_xyz_coords
	DS.W bv_object_edge_points_number*3


; Image-Fader
	CNOP 0,4
ifi_rgb8_color_table
	INCLUDE "Old'scool:colortables/320x256x128-Title.ct"

	CNOP 0,4
ifo_rgb8_color_table
	REPT pf1_colors_number
		DC.L color00_bits
	ENDR


; Blind-Fader
	CNOP 0,2
bf_address_offsets_table
	REPT bf_table_length/2
		DC.W NOOP
	ENDR
	REPT bf_table_length/2
		DC.W BPL1DAT
	ENDR


	INCLUDE "sys-variables.i"


	INCLUDE "sys-names.i"


	INCLUDE "error-texts.i"


; Wave-Scrolltext
wst_text
	DC.B ASCII_CTRL_F,"��"
	DC.B "RESISTANCE"
	REPT wst_text_chars_number/(wst_origin_char_x_size/wst_text_char_x_size)
		DC.B " "
	ENDR
	DC.B "PRESENTS  "
	REPT wst_text_chars_number/(wst_origin_char_x_size/wst_text_char_x_size)
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_W,ASCII_CTRL_M,"��"
	DC.B " YES WE ARE BACK ON THE AMIGA ### "
	REPT wst_text_chars_number/(wst_origin_char_x_size/wst_text_char_x_size)
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_W,ASCII_CTRL_S
	DC.B "PRESS F1-F10 FOR DIFFERENT CUBE MOVEMENTS...  "
	REPT wst_text_chars_number/(wst_origin_char_x_size/wst_text_char_x_size)
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_W,ASCII_CTRL_F,"��"
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
	REPT wst_text_chars_number/(wst_origin_char_x_size/wst_text_char_x_size)
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_W,ASCII_CTRL_M,"��"
	DC.B "THE CREDITS      "
	DC.B "CODING AND MUSIC *DISSIDENT*     "
	DC.B "GRAPHICS *GRASS*      "
	DC.B "RELEASED @ NORDLICHT 2023"
wst_stop_text
	REPT wst_text_chars_number/(wst_origin_char_x_size/wst_text_char_x_size)
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_W," "
	EVEN


	DC.B "$VER: "
	DC.B "RSE-Old'scool "
	DC.B "1.0 "
	DC.B "(31.8.23)",0
	EVEN


; Audiodaten nachladen

; PT-Replay
	IFNE pt_split_module_enabled
pt_auddata			SECTION pt_audio_module,DATA_C
		INCBIN "Old'scool:modules/mod.ClassicTune14remix"
	ELSE
pt_auddata			SECTION pt_audio_song,DATA
		INCBIN "Old'scool:modules/MOD.ClassicTune14Remix.song"

pt_audsmps			SECTION pt_audio_samples,DATA_C
		INCBIN "Old'scool:modules/MOD.ClassicTune14Remix.smps"
	ENDC


; Grafikdaten nachladen

; Background-Image
bg_image_data			SECTION bg_gfx,DATA
	INCBIN "Old'scool:graphics/320x256x128-Title.rawblit"

; Rotation-Zoomer
rz_image_data			SECTION rz_gfx,DATA
	INCBIN "Old'scool:graphics/256x256x128-Texture.rawblit"

; Wave-Scrolltext
wst_image_data			SECTION wst_gfx,DATA
	INCBIN "Old'scool:fonts/64x56x4-Font.rawblit"

	END


; -- Unbenutzt ---
czo_zoom_radius			EQU 32768
czo_zoom_center			EQU 32768
czo_zoom_angle_speed		EQU 1

czo_active			RS.W 1
czo_zoom_angle			RS.W 1

	move.w	d1,czo_active(a3)
	move.w	#sine_table_length/4,czo_zoom_angle(a3)

	CNOP 0,4
cube_zoomer_out
	tst.w	czo_active(a3)
	bne.s	cube_zoomer_out_quit
	lea	sine_table(pc),a0
	move.w	czo_zoom_angle(a3),d1
	cmp.w	#sine_table_length/2,d1	; 180� ?
	blt.s	cube_zoomer_out_skip
	move.w	#FALSE,czo_active(a3)	; Cube-Zoomer-Out aus
	bra.s	cube_zoomer_out_quit
	CNOP 0,4
cube_zoomer_out_skip
	move.w	d1,czo_zoom_angle(a3)
	moveq	#0,d0
	move.w	2(a0,d1.w*4),d0		; sin(w)
	add.w	#czo_zoom_center,d0
	move.l	d0,bv_zoom_distance(a3) 
	addq.w	#czo_zoom_angle_speed,d1
cube_zoomer_out_quit
	rts
