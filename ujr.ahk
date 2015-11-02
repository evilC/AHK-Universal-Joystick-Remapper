; UJR - Universal Joystick Remapper

/*
ToDo:

Before next release:

Known Issues:
* QuickBind may behave weirdly when running multiple copies as the same binding would trigger multiple times (once for each copy).
* Split L/H does not work together with Deadzone settings

Features:

Long-term:
* Reduce string comparisons, eg checking DDLs to see if they are "None".
* Make QuickBind settings persistent? Per-Profile?

*/

#SingleInstance Off
;#include <USkin>

; Create an instance of the library
ADHD := New ADHDLib

; Ensure running as admin
ADHD.run_as_admin()

; ============================================================================================
; CONFIG SECTION - Configure ADHD

; Authors - Edit this section to configure ADHD according to your macro.
; You should not add extra things here (except add more records to hotkey_list etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
;SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box

ADHD.config_about({name: "UJR", version: "6.10", author: "evilC", link: "<a href=""http://evilc.com/proj/ujr"">Homepage</a> / <a href=""https://github.com/evilC/AHK-Universal-Joystick-Remapper/issues"">Bug Tracker</a> / <a href=""http://ahkscript.org/boards/viewtopic.php?f=19&t=5671"">Forum Thread</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want

; GUI size
ADHD.config_size(600,500)

; Configure update notifications:
ADHD.config_updates("http://evilc.com/files/ahk/vjoy/ujr.au.txt")

; Warn user of incompatible settings file
ini_version := 2
ADHD.config_ini_version(ini_version)

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "QuickBind", subroutine: "QuickBind", tooltip: "Trigger QuickBind"})
ADHD.config_hotkey_add({uiname: "QuickBind Select", subroutine: "QuickBindSelect", tooltip: "Select Button / Axis for QuickBind"})

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("option_changed", "option_changed_hook")
ADHD.config_event("tab_changed", "tab_changed_hook")
ADHD.config_event("on_exit", "on_exit_hook")
;ADHD.config_event("program_mode_on", "program_mode_on_hook")
;ADHD.config_event("program_mode_off", "program_mode_off_hook")
;ADHD.config_event("app_active", "app_active_hook")
;ADHD.config_event("app_inactive", "app_inactive_hook")
;ADHD.config_event("disable_timers", "disable_timers_hook")
;ADHD.config_event("resolution_changed", "resolution_changed_hook")

; Add custom tabs
;ADHD.config_tabs(Array("Axes 1", "Axes 2", "Btns1", "Btns2", "Btns3", "Btns4", "Hats"))
ADHD.config_tabs(Array("Axes 1", "Axes 2", "Buttons 1", "Buttons 2", "Hats"))

; Init ADHD
ADHD.init()
if (!ADHD.is_first_run() && ADHD.get_ini_version() != ini_version){
	msgbox This version of UJR is incompatible with your settings file.`nPlease delete or rename ujr.ini and re-launch UJR.`n`nExiting...
	ADHD.config_write_version(0)
	ExitApp
}
ADHD.create_gui()

; Init the PPJoy / vJoy library
#include <VJoy_lib>

vjoy_id := 0		; The current vjoy device the app is trying to use. Also serves as a "last item selected" for the vjoy id dropdown
vjoy_ready := 0		; Whether the vjoy_id is connected and under the app's control

; Init stick vars for AHK
axis_list_ahk := Array("X","Y","Z","R","U","V")

; Init stick vars for vJoy
axis_list_vjoy := Array("X","Y","Z","RX","RY","RZ","SL0","SL1")

; The order in which the state buttons for the hat
hat_axes := Array("u","d","l","r")

vjoy_max := 32768
vjoy_mid := vjoy_max / 2
vjoy_min := 0
ahk_vjoy_factor := 327.68

quick_bind_mode := 0
; Configure virtual stick capabilities. Set to max capabilities that app supports, so all UI elements created at start
virtual_axes := 8
virtual_buttons := 32
virtual_hats := 1	; AHK currently can only read one hat per stick

; Mapping array - A multidimensional array holding Axis mappings
; The first element is the mapping for the first virtual axis, the second element for axis 2, etc, etc
; Each element is then comprise of a further array:
; [Physical Joystick #,Physical Axis #, Scale (-1 = invert)]
axis_mapping1 := Array()
axis_mapping2 := Array()
button_mapping := Array()
hat_mapping := Array()

; The "Axes 1" tab is tab 1
Gui, Tab, 1


; ============================================================================================
; GUI SECTION

gui_width := 600
w:=gui_width-10

th1 := 65
th2 := th1+5

Gui, Add, Text, x10 y35, vJoy Stick ID
ADHD.gui_add("DropDownList", "virtual_stick_id", "xp+70 yp-5 w50 h20 R9", "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16", "1")
Gui, Add, Text, xp+60 yp+5 w400 vvirtual_stick_status, 

; AXES TABS
; ---------

Loop, 2 {
	tabnum := A_Index
	Gui, Tab, %tabnum%
	
	Gui, Add, Text, x12 y%th1% w30 R2 Center, Virtual Axis
	if (A_Index == 1){
		Gui, Add, Text, x52 y%th1% w70 R2 Center, Special Operations
	} else {
		Gui, Add, Text, x70 y%th1% w50 R2 Center, Axis Merging
	}
	Gui, Add, Text, x125 y%th1% w60 R2 Center, Physical Stick ID
	Gui, Add, Text, x185 y%th1% w60 R2 Center, Physical Axis
	Gui, Add, Text, x240 y%th2% w100 h20 Center, State
	Gui, Add, Text, x335 y%th2% w40 h20 Center, Invert
	Gui, Add, Text, x375 y%th2% w50 R2 Center, % "Deadzone %"
	Gui, Add, Text, x430 y%th2% w50 R2 Center, % "Sensitivity %"
	Gui, Add, Text, x480 y%th2% w50 h20 Center, Physical
	Gui, Add, Text, x525 y%th2% w40 h20 Center, Virtual
	Gui, Add, Text, x568 y%th2% w20 h20 Center, QB

	Gui, Add, GroupBox, x5 y50 w585 h290,
	
	Loop, %virtual_axes% {
		ypos := 70 + A_Index * 30
		ypos2 := ypos + 5
		ypos3 := ypos + 3
		Gui, Add, Text, x10 y%ypos3% Center, %A_Index%
		tmp := axis_list_vjoy[A_Index]
		Gui, Add, Text, x15 y%ypos3% w35 Center, ( %tmp% )
		
		if (tabnum == 1){
			tmp := "None|Rests H|Rests L|Split H|Split L"
			axis%tabnum%_controls_special_%A_Index%_TT := "Special Operations:`nRests (Low/High) - Makes Deadzone etc treat the high/low end of the axis as neutral.`nSplit (Low/High) - Uses only the low/high end of the physical axis."
		} else {
			tmp := "None|Merge|Greatest|Trim|Linear"
			axis%tabnum%_controls_special_%A_Index%_TT := "Enables merging with axis " A_Index " on tab 'Axes 1'.`nMerge - A standard average of the two inputs.`nGreatest - whichever input is deflected the most.`nTrim - shift axis 1 center by axis 2."
		}
		ADHD.gui_add("DropDownList", "axis" tabnum "_controls_special_" A_Index, "x55 y" ypos " w65 h20 R9", tmp, "None")
		
		ADHD.gui_add("DropDownList", "axis" tabnum "_controls_physical_stick_id_" A_Index, "x130 y" ypos " w50 h20 R9", "None|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16", "None")
		axis%tabnum%_controls_physical_stick_id_%A_Index%_TT := "Selects which physical stick to use for this axis"
		
		ADHD.gui_add("DropDownList", "axis" tabnum "_controls_physical_axis_" A_Index, "x190 y" ypos " w50 h20 R9", "None|1|2|3|4|5|6|7|8", "None")
		axis%tabnum%_controls_physical_axis_%A_Index%_TT := "Selects which axis to use on the selected physical stick"
		
		Gui, Add, Slider, x240 y%ypos% w100 h20 vaxis%tabnum%_controls_state_slider_%A_Index%
		axis%tabnum%_controls_state_slider_%A_Index%_TT := "Shows the state of this axis"
		
		ADHD.gui_add("CheckBox", "axis" tabnum "_controls_invert_" A_Index, "x345 y" ypos " w20 h20", "", 0)
		axis%tabnum%_controls_invert_%A_Index%_TT := "Inverts this axis"
		
		ADHD.gui_add("Edit", "axis" tabnum "_controls_deadzone_" A_Index, "x380 y" ypos " w40 h21", "", 0)
		axis%tabnum%_controls_deadzone_%A_Index%_TT := "Applies a deadzone to this axis"
		
		ADHD.gui_add("Edit", "axis" tabnum "_controls_sensitivity_" A_Index, "x435 y" ypos " w40 h21", "", 100)
		axis%tabnum%_controls_sensitivity_%A_Index%_TT := "Adjusts sensitivity of this axis"
		
		Gui, Add, Text, x485 y%ypos% w40 h21 Center vaxis%tabnum%_controls_physical_value_%A_Index%, 0
		Gui, Add, Text, x525 y%ypos% w40 h21 Center vaxis%tabnum%_controls_virtual_value_%A_Index%, 0
	}
}
; BUTTONS TAB
; -----------

button_tab := 3
button_row := 1
button_column := 0

Loop, %virtual_buttons% {
	if (Mod(A_Index,8) == 1){
		button_column++
		if (button_column == 3){
			button_column := 1
			button_tab++
		}

		Gui, Tab, %button_tab%
		xpos := 5 + ((button_column - 1) * 295)
		Gui, Add, GroupBox, x5 y50 w585 h290,
		
		xbase := ((button_column - 1) * 300)
		xpos := xbase + 20
		Gui, Add, Text, x%xpos% y%th1% w20 R2 Center, Virt Btn
		xpos := xbase + 62
		Gui, Add, Text, x%xpos% y%th2% w60 h20 Center, Stick ID
		xpos := xbase + 132
		Gui, Add, Text, x%xpos% y%th2% w60 h20 Center, Button #
		xpos := xbase + 205
		Gui, Add, Text, x%xpos% y%th2% w60 h20 Center, State
		xpos := xbase + 268
		Gui, Add, Text, x%xpos% y%th2% w20 h20 Center, QB

		button_row = 1
	}
	ypos := 70 + button_row * 30
	ypos2 := ypos + 5
	xpos := xbase + 25
	Gui, Add, Text, x%xpos% y%ypos2% w40 h20 , %A_Index%
	
	xpos := xbase + 62
	ADHD.gui_add("DropDownList", "button_physical_stick_id_" A_Index, "x" xpos " y" ypos " w60 h10 R9", "None|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16", "None")
	button_physical_stick_id_%A_Index%_TT := "Select the physical stick for this button"
	
	xpos := xbase + 132
	ADHD.gui_add("DropDownList", "button_id_" A_Index, "x" xpos " y" ypos " w60 h10 R15", "None|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|POV U|POV D|POV L|POV R", "None")
	button_id_%A_Index%_TT := "Select the button to use from the selected physical stick for this button"
	
	xpos := xbase + 220
	Gui, Add, Text, x%xpos% y%ypos% w30 h20 vbutton_state_%A_Index% cred Center, Off
	button_row++
}

; HATS TAB
; --------

Gui, Tab, 5

Gui, Add, Text, x20 y%th1% w50 R2 Center, Hat Number
Gui, Add, Text, x75 y%th1% w60 R2 Center, Physical Stick ID
;Gui, Add, Text, x135 y%th1% w60 R2 Center, Hat ID

button_row := 1
ypos := 70 + button_row * 30
ypos2 := ypos -3

Loop, % virtual_hats {
	Gui, Add, Text, x30 y%ypos% w40 h20 , Hat %A_Index%
	ADHD.gui_add("DropDownList", "hat_physical_stick_id_" A_Index, "x80 y" ypos " w50 h10 R9", "None|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16", "None")

	Gui, Add, Text, x150 y%th2% w40 Center, Direction
	Gui, Add, Text, x205 yp Center, State
	Gui, Add, Text, x248 yp Center, QB
	
	Gui, Add, Text, x150 y100 w40 Center, Up
	Gui, Add, Text, x205 yp w30 h20 vhat_state_1 cred Center, Off

	Gui, Add, Text, x150 y120 w40 Center, Down
	Gui, Add, Text, x205 yp w30 h20 vhat_state_2 cred Center, Off

	Gui, Add, Text, x150 y140 w40 Center, Left
	Gui, Add, Text, x205 yp w30 h20 vhat_state_3 cred Center, Off

	Gui, Add, Text, x150 y160 w40 Center, Right
	Gui, Add, Text, x205 yp w30 h20 vhat_state_4 cred Center, Off
	
	button_row++
}

; QUICKBIND RADIOS
; ---------------------
; AHK cannot group radios if they are interspersed with other controls, so add them all in one go here.

Gui, Tab, 1

xpos := 560
Loop, %virtual_axes% {
	ypos := 70 + A_Index * 30
	ypos2 := ypos + 5
	tmp := "x" xpos " y" ypos " w25 Right gQuickBindOptionChanged hwndQB_A_" A_Index
	if (A_Index == 1){
		tmp := tmp " vQuickBindAxes Checked"
	}
	Gui, Add, Radio, %tmp%
}

button_tab := 3
button_row := 1
button_column := 0

Loop, %virtual_buttons% {
	if (Mod(A_Index,8) == 1){
		button_column++
		if (button_column == 3){
			button_column := 1
			button_tab++
		}
		Gui, Tab, %button_tab%
		xbase := ((button_column - 1) * 300)
		button_row := 1
	}
	ypos := 70 + button_row * 30
	ypos2 := ypos + 5
	xpos := xbase + 260
	
	;tmp := "x" xpos " y" ypos " w25 Right gQuickBindOptionChanged"
	tmp := "x" xpos " y" ypos " w25 Right gQuickBindOptionChanged hwndQB_B_" A_Index
	if (A_Index == 1 || A_Index == 17){
		tmp := tmp " vQuickBindButtons" button_tab-2 " Checked"
	}
	Gui, Add, Radio, %tmp%
	button_row++
}

Gui, Tab, 5

Loop, %virtual_hats% {
	; Create QuickBind menu for U/D/L/R
	grp := " vQuickBindHats Checked"
	
	Gui, Add, Radio, x250 y100 gQuickBindOptionChanged hwndQB_H_1 %grp%
	Gui, Add, Radio, x250 y120 gQuickBindOptionChanged hwndQB_H_2
	Gui, Add, Radio, x250 y140 gQuickBindOptionChanged hwndQB_H_3
	Gui, Add, Radio, x250 y160 gQuickBindOptionChanged hwndQB_H_4
}

; AUTO CONFIGURE
; ---------------------
Gui, Tab

Gui, Add, Button, x430 y339 vAutoConfigureButton gAutoConfigurePressed, Auto Configure Stick ID
Gui, Add, DropDownList, x560 yp+1 w30 vAutoConfigureID, 1||2|3|4|5|6|7|8|9|10|11|12|13|14|15|16

; QUICKBIND FOOTER
; ---------------------

Gui, Add, GroupBox, x5 y355 w585 h105 vQuickBindLabelGroup, QuickBind
		
Gui, Add, Text, x10 y375 vQuickBindLabelDelay, Delay (seconds)
Gui, Add, Edit, xp+100 yp-2 w70 vQuickBindDelay  gQuickBindOptionChanged, 1
QuickBindDelay_TT := "The amount of time between you hitting the QuickBind key,`nand QuickBind starting to manipulate the axis or button"

Gui, Add, Text, x10 y400 vQuickBindLabelDuration, Duration (seconds)
Gui, Add, Edit, xp+100 yp-2 w70 vQuickBindDuration  gQuickBindOptionChanged, 1
QuickBindDuration_TT := "The amount of time that QuickBind moves the axis or holds the button"

Gui, Add, Text, x10 y425 vQuickBindLabelAxisType, Axis movement type
Gui, Add, DropDownList, xp+100 yp-2 w70 vQuickBindAxisType gQuickBindOptionChanged, High-Low||Mid-High|Mid-Low
QuickBindAxisType_TT := "How QuickBind moves the axis.`n`nMid-High just moves up.`nMid-Low just moves down.`nHigh-Low moves to both ends"

tmp := "QuickBind Instructions:`n"
tmp .= "Lets you bind the virtual stick in a game without having to move the physical stick.`n"
tmp .= "1) Ensure you have bound 'QuickBind' and 'QuickBind Select' in the Bindings tab.`n"
tmp .= "2) Map the physical stick to the virtual stick as required, then enter the game.`n"
tmp .= "3) Hit 'QuickBind Select' and move the axis or press the button you wish to bind.`n"
tmp .= "4) Hit 'QuickBind', quickly activate the Game's bind function, then wait for the beep`n"
tmp .= "    UJR will operate the axis or button, and the game should bind to the virtual stick."
Gui, Add, Text, x190 y365 vQuickBindLabelInstructions, %tmp%

tmp := "Axis Merging Instructions:`n`n"
tmp .= "This tab is used to configure Axis Merging - a feature that allows you to merge two physical axes into one virtual axis`n"
tmp .= "Each row on this tab corresponds to a row on the Axes 1 tab. Row 1 on this tab will be merged with row 1 on the Axes 1 tab.`n"
tmp .= "Intended for use with axes that sit at one end when resting - for example to merge two pedal axes into one rudder axis.`n"
tmp .= "On the 'Axes 1' tab: Configure the left pedal to move the slider left (use 'Invert' if needed), and set 'Special Ops' to 'Rest H'.`n"
tmp .= "On the 'Axes 2' tab: Configure the right pedal to move the slider right, and set 'Axis Merging' to 'Merge', 'Greatest' or 'Trim' .`n"
tmp .= "Merge averages the two axes, Greatest uses whichever axis is pressed the most, Trim shifts axis 1 using axis 2."
Gui, Add, Text, x10 y345 vAxisMergingInstructions, %tmp%

; End GUI creation section
; ============================================================================================

ADHD.finish_startup()

; Fire tab changed at startup to init common portion
tab_changed_hook()

; =============================================================================================================================
; MAIN LOOP - controls the virtual stick
Loop{
	; Detect vjoy config change and force reload of stick
	if (DllCall("vJoyInterface\GetVJDStatus", "UInt", vjoy_id)){
		VJoy_RelinquishVJD(vjoy_id)
		VJoy_Close()
		vjoy_id := 0
		option_changed_hook()
	}
	if (ADHD.private.functionality_enabled && !quick_bind_mode){
		; Cycle through rows. MAY NOT BE IN ORDER OF VIRTUAL AXES!
		For index, value in axis_mapping1 {
			if (value.exists && vjoy_ready){
				if (axis_mapping1[index].id == "None"){
					; Do not update axis if Physical Stick ID is set to "None"
					continue
				}
				
				; Main section for active axes
				; Get input value
				axis_one := GetKeyState(value.id . "Joy" . axis_list_ahk[value.axis])
				
				axis2_configured := axis_mapping2[index].id != "None" && axis_mapping2[index].axis != "None"
				if (axis_mapping2[index].special != "None"){
					if (axis_mapping2[index].special == "Merge"){
						merge := 1
					} else if (axis_mapping2[index].special == "Greatest"){
						merge := 2
					} else if (axis_mapping2[index].special == "Trim"){
						merge := 3
					} else if (axis_mapping2[index].special == "Linear"){
						merge := 4
					}
				} else {
					merge := 0
				}
				if (axis2_configured){
					axis_two := GetKeyState(axis_mapping2[index].id . "Joy" . axis_list_ahk[axis_mapping2[index].axis])
				}

				; Display input value in AHK format, rounded
				GuiControl,, axis1_controls_physical_value_%index%, % round(axis_one,2)
				if (axis2_configured){
					GuiControl,, axis2_controls_physical_value_%index%, % round(axis_two,2)
				}
				
				; Adjust axis according to invert / deadzone options etc
				tmp := instr(value.special, "Rests ")
				if (tmp){
					tmp := substr(value.special, 7)
					if (tmp == "H"){
						rests := 1
					} else {
						rests := -1
					}
				} else {
					rests := 0
				}
				axis_one := AdjustAxis(axis_one,value,rests)
				if (axis2_configured){
					; Pass opposite of rests to second (merged) axis
					rests := rests * -1
					axis_two := AdjustAxis(axis_two,axis_mapping2[index],rests)
				}
				
				; Display output value in AHK format
				GuiControl,, axis1_controls_virtual_value_%index%, % round(axis_one,2)
				if (axis2_configured){
					GuiControl,, axis2_controls_virtual_value_%index%, % round(axis_two,2)
				}
				; Move slider to show input value
				GuiControl,, axis1_controls_state_slider_%index%, % axis_one
				if (axis2_configured){
					GuiControl,, axis2_controls_state_slider_%index%, % axis_two
				}
				; Get the value for this axis on the virtual stick
				axismap := axis_list_vjoy[index]

				; ToDo: This code SUCKS!
				; re-write!!
				; risky assumptions (low/high "no deflection" setting, when could be implied from "Rests" setting)

				; rescale to vJoy style 0->32768
				axis_one := AHKToVjoy(axis_one)
				axis_two := AHKToVjoy(axis_two)
				
				ax := value.axis
				if (merge){
					; Merge mode
					out := axis_one 	; default output to 1st axis
					if (merge == 1){
						; Standard merge
						out := (axis_one + axis_two) / 2
					} else if (merge == 2){
						; "Greatest" merge
						/*
						if (axis1_controls_special_%index% == "None"){
							; Rests Middle
							if ( axis_two > axis_one ){
								; If the 1st axis is deflected by more than the 2nd axis
								out := axis_two
							}
						} else {
							; Axis does not rest at middle position
							if (value.invert == -1){
								; low value is no deflection
								def1 := axis_one
							} else {
								; high value is no deflection
								def1 := vjoy_max - axis_one
							}
							if (axis_mapping2[index].invert == -1){
								; low value is no deflection
								def2 := axis_two
							} else {
								; high value is no deflection
								def2 := vjoy_max - axis_two
							}
							; Which axis is deflected more?
							if (def1 > def2){
								out := axis_one / 2
							} else {
								out := vjoy_mid + (axis_two / 2)
							}
						}
						*/
						tmp := (vjoy_max - axis_one)
						if (tmp > axis_two){
							; Axis 1 is more deflected
							;ToolTip % "* " tmp " | " axis_two
							out := vjoy_mid - ( (vjoy_max - axis_one) / 2)
						} else {
							; Axis 2 is more deflected
							;ToolTip % tmp " | * " axis_two
							out := vjoy_mid + (axis_two / 2)
						}
					} else if (merge == 3){
						; "Trim" merge
						axis_one  :=  axis_one / vjoy_max
						axis_two := axis_two / vjoy_max
						axis_two := axis_two *.5 + .25
						a := 2 - 4*axis_two
						b := 4*axis_two - 1
						out := vjoy_max * (a*axis_one*axis_one + b*axis_one)
					} else if (merge == 4){
						if (axis_two > axis_one){
							out := axis_two
						}
					}
					VJoy_SetAxis(out, vjoy_id, HID_USAGE_%axismap%)
				} else {
					VJoy_SetAxis(axis_one, vjoy_id, HID_USAGE_%axismap%)
				}

			} else {
				; Blank out unused axes
				DisableAxis(index)
			}
			
		}
		
		For index, value in button_mapping {
			if (button_mapping[index].id != "None" && button_mapping[index].button != "None" && vjoy_ready && value.exists){
				if (value.pov){
					; get current state of pov in val
					val := PovToAngle(GetKeyState(value.id . "Joy" . "POV"))
					; Does it match the current mapping?
					val := PovMatchesAngle(val,value.pov)
					SetButtonState(index,val)
				} else {
					val := GetKeyState(value.id . "Joy" . value.button)
					SetButtonState(index,val)
				}
				VJoy_SetBtn(val, vjoy_id, index)
			}		
		}
		
		For index, value in hat_mapping {
			if (hat_mapping[index].id != "None" && vjoy_ready && value.exists){
				val := GetKeyState(value.id . "Joy" . "POV")
				Loop, 4 {
					if (PovMatchesAngle(PovToAngle(val), hat_axes[A_Index])){
						SetHatState(A_Index,1)
					} else {
						SetHatState(A_Index,0)
					}
				}
				VJoy_SetContPov(val, vjoy_id, A_Index)
			}
		}
	}
	Sleep, 10
}
return

; ============================================================================================
; FUNCTIONS

DisableAxis(index){
	global
	GuiControl,, axis1_controls_physical_value_%index%, 
	GuiControl,, axis1_controls_virtual_value_%index%, 
	GuiControl,, axis1_controls_state_slider_%index%, 50
}

; Takes an AHK joystick range (0 -> 100) and zero-centers it (-50 -> +50)
AHKToZeroCentered(val){
	return val - 50
}

ZeroCenteredToAHK(val){
	return val + 50
}

; Takes an AHK joystick range (0 -> 100) and converts it to a vjoy range (0 -> 32768)
AHKToVjoy(val){
	global ahk_vjoy_factor

	return val * ahk_vjoy_factor
}

VjoyToAHK(val){
	global ahk_vjoy_factor

	return val / ahk_vjoy_factor
}

; Make adjustments to axis based upon settings
AdjustAxis(input,settings,rests){
	if (rests == 0){
		; Scale rests in middle

		; Axis Splitting
		if (settings.special == "Split H"){
			; rests low: 50-100 -> 0-100
			if (input < 50){
				output := 0
			} else {
				output := (input - 50) * 2
			}
		} else if (settings.special == "Split L"){
			; rests high: 50-0 -> 0-100
			if (input > 50){
				output := 0
			} else {
				output := (50 - input) * 2
			}
		} else {		
			output := input
		}
		; Shift from 0 -> 100 scale to -50 -> +50 scale
		output := AHKToZeroCentered(output)
		
		; invert if needed
		output := output * settings.invert
		
		; impose deadzone if set
		if (abs(output) <= settings.deadzone/2){
			output := 0
		} else {
			output := sign(output)*50*(abs(output)-(settings.deadzone/2))/(50-settings.deadzone/2)
		}
		
		; Adjust for sensitivity
		if (settings.sensitivity != 100){
			sens := settings.sensitivity/100 ; Shift sensitivity to 0 -> 1 scale
			output := output/50	; Shift input value to -1 -> +1 scale
			output := (sens*output)+((1-sens)*output**3)	; Perform sensitivity calc
			output := output*50	; Shift back to -50 -> 50 scale
		}
		
		; Shift back to proper scale
		output := ZeroCenteredToAHK(output)
	} else {
		; scale rests at one end
		output := input

		; invert if needed
		if (settings.invert == -1){
			output := 100 - output
		}

		; invert according to rests, so we are always operating on a low->high scale
		if (rests == 1){
			; rests high - invert before applying deadzone
			output := 100 - output
		}
			
		; impose deadzone if set
		if (settings.deadzone != 0){
			if (output < settings.deadzone){
				output := 0
			} else {
				;rescale
				output := (output - settings.deadzone) * (100 / (100 - settings.deadzone))
			}
		}
		
		; Adjust for sensitivity
		if (settings.sensitivity != 100){
			sens := settings.sensitivity/100 ; Shift sensitivity to 0 -> 1 scale
			output := output/100	; Shift input value to -1 -> +1 scale
			output := (sens*output)+((1-sens)*output**3)	; Perform sensitivity calc
			output := output*100	; Shift back to -50 -> 50 scale
		}

		if (rests == 1){
			; rests high - de-invert after applying deadzone and sensitivity
			output := 100 - output
		}
		
	}
	
	return output
}

; Detects the sign (+ or -) of a number and returns a multiplier for that sign
sign(input){
	if (input < 0){
		return -1
	} else {
		return 1
	}
}

; Converts an AHK POV (degrees style) value to 0-7 (0 being up, going clockwise)
PovToAngle(pov){
	if (pov == -1){
		return -1
	} else {
		return round(pov/4500)
	}
}

; Calculates whether a u/d/l/r value matches a pov (0-7) value
; eg Up ("u") is pov angle 0, but pov 7 (up left) and 1 (up right) also mean "up" is held
PovMatchesAngle(pov,angle){
	static angles := ["u","d","l","r"]
	static matches := [[7,0,1],[3,4,5],[5,6,7],[1,2,3]]

	Loop % angles.MaxIndex() {
		a := A_Index
		if (angle = angles[a]){
			Loop % matches[a].MaxIndex() {
				if (pov == matches[a][A_Index]){
					return 1
				}
			}
		}
	}
	return 0
}

; Converts a hat index (1,2,3,4 - representing u,d,l,r) to a POV (9000 per 90 degrees going clockwise from up)
HatIndexToPov(angle){
	if (angle == 1){
		return 0
	} else if (angle == 2) {
		return 18000
	} else if (angle == 3){
		return 27000
	} else if (angle == 4){
		return 9000
	} else {
		return -1
	}
}

; Changes display to reflect the state of a button
SetButtonState(but,state){
	if (state == 1){
		GuiControl, +cgreen, button_state_%but%
		GuiControl,, button_state_%but%, On
	} else {
		GuiControl, +cred, button_state_%but%
		GuiControl,,button_state_%but%, Off
	}
}

; Changes display to reflect the state of a hat
SetHatState(hat,state){
	if (state == 1){
		GuiControl, +cgreen, hat_state_%hat%
		GuiControl,, hat_state_%hat%, On
	} else {
		GuiControl, +cred, hat_state_%hat%
		GuiControl,,hat_state_%hat%, Off
	}
}

; ============================================================================================
; LABELS

QuickBindOptionChanged:
	Gui, Submit, Nohide
	return

; ============================================================================================
; EVENT HOOKS

tab_changed_hook(){
	Global ADHD
	current_tab := ADHD.get_current_tab()
	
	GuiControl, +Hidden, QuickBindLabelGroup
	GuiControl, +Hidden, QuickBindLabelDelay
	GuiControl, +Hidden, QuickBindDelay
	GuiControl, +Hidden, QuickBindDelay
	GuiControl, +Hidden, QuickBindLabelDuration
	GuiControl, +Hidden, QuickBindDuration
	GuiControl, +Hidden, QuickBindLabelAxisType
	GuiControl, +Hidden, QuickBindAxisType
	GuiControl, +Hidden, QuickBindLabelInstructions
	GuiControl, +Hidden, AutoConfigureID
	GuiControl, +Hidden, AutoConfigureButton
	GuiControl, +Hidden, AxisMergingInstructions

	if (current_tab == "Axes 1" || current_tab == "Buttons 1" || current_tab == "Buttons 2" || current_tab == "Hats"){
		GuiControl, -Hidden, QuickBindLabelGroup
		GuiControl, -Hidden, QuickBindLabelDelay
		GuiControl, -Hidden, QuickBindDelay
		GuiControl, -Hidden, QuickBindLabelDuration
		GuiControl, -Hidden, QuickBindDuration
		GuiControl, -Hidden, QuickBindLabelInstructions
		if (current_tab == "Axes 1"){
			GuiControl, -Hidden, QuickBindLabelAxisType
			GuiControl, -Hidden, QuickBindAxisType
			GuiControl, -Hidden, AutoConfigureButton
			GuiControl, -Hidden, AutoConfigureID
		} else if (current_tab == "Buttons 1" || current_tab == "Buttons 2"){
			GuiControl, -Hidden, AutoConfigureButton
			GuiControl, -Hidden, AutoConfigureID
		} else if (current_tab == "Hats"){
		
		}
	} else if (current_tab == "Axes 2"){
		GuiControl, -Hidden, AxisMergingInstructions
	}
}

; This is fired when settings change (including on load). Use it to pre-calculate values etc.
option_changed_hook(){
	Global virtual_axes
	Global virtual_buttons
	Global virtual_hats
	
	Global axis_mapping1
	Global axis_mapping2
	Global button_mapping
	Global hat_mapping
	
	Global axis_list_vjoy
	Global virtual_stick_id
	
	Global vjoy_id
	Global vjoy_ready

	; Connect to virtual stick
	if (vjoy_id != virtual_stick_id){
		if (VJoy_Ready(vjoy_id)){
			VJoy_RelinquishVJD(vjoy_id)
			VJoy_Close()
		}
		vjoy_id := virtual_stick_id
		vjoy_status := DllCall("vJoyInterface\GetVJDStatus", "UInt", vjoy_id)
		if (vjoy_status == 2){
			GuiControl, +Cred, virtual_stick_status
			GuiControl, , virtual_stick_status, Busy - Other app controlling this device?
		}  else if (vjoy_status >= 3){
			; 3-4 not available
			GuiControl, +Cred, virtual_stick_status
			GuiControl, , virtual_stick_status, Not Available - Add more virtual sticks using the vJoy config app
		} else if (vjoy_status == 0){
			; already owned by this app - should not come here as we want to release non used sticks
			GuiControl, +Cred, virtual_stick_status
			GuiControl, , virtual_stick_status, Already Owned by this app (Should not see this!)
		}
		if (vjoy_status <= 1){
			VJoy_Init(vjoy_id)
			
			; Seem to need this to allow reconnecting to sticks (ie you selected id 1 then 2 then 1 again. Else control of stick does not resume
			VJoy_AcquireVJD(vjoy_id)
			VJoy_ResetVJD(vjoy_id)
			if (VJoy_Ready(vjoy_id)){
				vjoy_ready := 1
				GuiControl, +Cgreen, virtual_stick_status
				GuiControl, , virtual_stick_status, Connected
			} else {
				GuiControl, +Cred, virtual_stick_status
				GuiControl, , virtual_stick_status, Problem Connecting
				vjoy_ready := 0
			}
		} else {
			vjoy_ready := 0
		}
	}

	; Build arrays for main loop
	Loop, 2 {
		map := A_Index
		axis_mapping%map% := Array()
		Loop, %virtual_axes% {
			axis_mapping%map%[A_Index] := Object()
			
			tmp := axis_list_vjoy[A_Index]

			; Detect if this axis is present on the virtual stick
			if (vjoy_ready && VJoy_GetAxisExist_%tmp%(virtual_stick_id)){
				axis_mapping%map%[A_Index].exists := true
				tmp := "enable"
			} else {
				axis_mapping%map%[A_Index].exists := false
				tmp := "disable"
			}
			
			GuiControl, %tmp%, axis%map%_controls_special_%A_Index%
			GuiControl, %tmp%, axis%map%_controls_physical_stick_id_%A_Index%
			GuiControl, %tmp%, axis%map%_controls_physical_axis_%A_Index%
			GuiControl, %tmp%, axis%map%_controls_invert_%A_Index%
			GuiControl, %tmp%, axis%map%_controls_deadzone_%A_Index%
			GuiControl, %tmp%, axis%map%_controls_sensitivity_%A_Index%

			axis_mapping%map%[A_Index].special := axis%map%_controls_special_%A_Index%

			axis_mapping%map%[A_Index].id := axis%map%_controls_physical_stick_id_%A_Index%
			if (map == 1 && axis_mapping%map%[A_Index].id == "None"){
				DisableAxis(A_Index)
			}

			axis_mapping%map%[A_Index].axis := axis%map%_controls_physical_axis_%A_Index%
			
			if(axis%map%_controls_invert_%A_Index% == 0){
				axis_mapping%map%[A_Index].invert := 1
			} else {
				axis_mapping%map%[A_Index].invert := -1
			}
			
			if (axis%map%_controls_deadzone_%A_Index% is not number){
				GuiControl,,axis%map%_controls_deadzone_%A_Index%,0
			} else {
				axis_mapping%map%[A_Index].deadzone := axis%map%_controls_deadzone_%A_Index%
			}
			
			if (axis%map%_controls_sensitivity_%A_Index% is not number){
				GuiControl,,axis%map%_controls_sensitivity_%A_Index%,100
			} else {
				axis_mapping%map%[A_Index].sensitivity := axis%map%_controls_sensitivity_%A_Index%
			}
		}
	}

	button_mapping := Array()
	
	; Detect how many buttons are present on the virtual stick
	if (vjoy_ready){
		btns := VJoy_GetVJDButtonNumber(vjoy_id)
	} else {
		btns := 0
	}

	Loop, %virtual_buttons% {
		button_mapping[A_Index] := Object()
		
		if (btns >= A_Index){
			button_mapping[A_Index].exists := true
			tmp := "enable"
		} else {
			button_mapping[A_Index].exists := false
			tmp := "disable"
		}
		
		; Enable / Disable controls
		GuiControl, %tmp%, button_physical_stick_id_%A_Index%
		GuiControl, %tmp%, button_id_%A_Index%

		
		button_mapping[A_Index].id := button_physical_stick_id_%A_Index%
		
		tmp := instr(button_id_%A_Index%,"POV ")
		if (tmp > 0){
			tmp := SubStr(button_id_%A_Index%, 5) 
			StringLower, tmp, tmp
			button_mapping[A_Index].pov := tmp
		} else {
			button_mapping[A_Index].pov := 0			
		}
		button_mapping[A_Index].button := button_id_%A_Index%
	}

	if (vjoy_ready){
		hats := VJoy_GetContPovNumber(vjoy_id)
	} else {
		hats := 0
	}
	
	hat_mapping := Array()
	Loop, %virtual_hats% {
		hat_mapping[A_Index] := Object()
		
		if (hats >= A_Index){
			hat_mapping[A_Index].exists := true
			tmp := "enable"
		} else {
			hat_mapping[A_Index].exists := false
			tmp := "disable"
		}
		GuiControl, %tmp%, hat_physical_stick_id_%A_Index%
		hat_mapping[A_Index].id := hat_physical_stick_id_%A_Index%
	}
	
	return
}

on_exit_hook(){
	; Disconnect the joystick on exit
	VJoy_Close()
	return
}

; ============================================================================================
; ACTIONS


; QuickBind triggered
QuickBind:
	current_tab := ADHD.get_current_tab()
	; Work out what control we need to manipulate
	if (current_tab == "Axes 1" || current_tab == "Buttons 1" || current_tab == "Buttons 2" || current_tab == "Hats"){
		quick_bind_mode := 1

		; set all configured axes to neutral position
		For index, value in axis_mapping1 {
			axismap := axis_list_vjoy[index]
			if (VJoy_GetAxisExist_%axismap%(vjoy_id)){
				GuiControl,,axis1_controls_state_slider_%index%,50
				VJoy_SetAxis(vjoy_mid, vjoy_id, HID_USAGE_%axismap%)
			}
		}
		
		; Set all configured buttons to off
		Loop, % virtual_buttons {
			if (VJoy_GetVJDButtonNumber(vjoy_id) >= A_Index){
				SetButtonState(A_Index,0)
				VJoy_SetBtn(0, vjoy_id, A_Index)
			}
		}
		
		; Set all configured hats to neutral position
		Loop, 4 {
			if (VJoy_GetContPovNumber(vjoy_id) >= A_Index){
				SetHatState(A_Index,0)
			}
		}
		VJoy_SetContPov(-1, vjoy_id, 1)

		; Find which tab we are on and which control is selected, then move it after a delay
		if (current_tab == "Axes 1"){
			play_quickbind_delay()
			
			axismap := axis_list_vjoy[QuickBindAxes]
			if (QuickBindAxisType == "High-Low"){
				GuiControl,,axis1_controls_state_slider_%QuickBindAxes%,100
				VJoy_SetAxis(vjoy_max, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
				
				GuiControl,,axis1_controls_state_slider_%QuickBindAxes%,0
				VJoy_SetAxis(0, vjoy_id, HID_USAGE_%axismap%)
				;Sleep, % (QuickBindDuration * 1000 ) / 2
			} else if (QuickBindAxisType == "Mid-High"){
				GuiControl,,axis1_controls_state_slider_%QuickBindAxes%,50
				VJoy_SetAxis(vjoy_mid, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
				
				GuiControl,,axis1_controls_state_slider_%QuickBindAxes%,100
				VJoy_SetAxis(vjoy_max, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
			} else {
				GuiControl,,axis1_controls_state_slider_%QuickBindAxes%,50
				VJoy_SetAxis(vjoy_mid, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
				
				GuiControl,,axis1_controls_state_slider_%QuickBindAxes%,0
				VJoy_SetAxis(0, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
			}
		} else if (current_tab == "Buttons 1" || current_tab == "Buttons 2"){
			if (current_tab == "Buttons 1"){
				btn_id := 0
				btn_group := 1
			} else {
				btn_id := 16
				btn_group := 2
			}
			btn_id += QuickBindButtons%btn_group%
			
			play_quickbind_delay()

			SetButtonState(btn_id,1)
			VJoy_SetBtn(1, vjoy_id, btn_id)
			
			Sleep, % QuickBindDuration * 1000
			
			SetButtonState(btn_id,0)
			VJoy_SetBtn(0, vjoy_id, btn_id)
		} else if (current_tab == "Hats"){
			play_quickbind_delay()

			SetHatState(QuickBindHats,1)
			VJoy_SetContPov(HatIndexToPov(QuickBindHats), vjoy_id, 1)
			Sleep, % QuickBindDuration * 1000
		}
		
		quick_bind_mode := 0
		soundbeep, 750
	}
	return

QuickBindSelect:
	quickbind_select()
	return

; Selects a button / axis for quickbind by detecting what the user presses / moves	
quickbind_select(){
	global ADHD
	Global axis_mapping1
	Global axis_mapping2
	Global button_mapping
	Global hat_mapping
	Global hat_axes
	Global vjoy_id
	Global axis_list_ahk

	current_tab := ADHD.get_current_tab()
	
	quickbind_start := A_TickCount
	last_beep := 0

	joystate := Array()
	altstate := Array()
	
	; Store starting state of axes for later comparison.
	; If user has a throttle, it may be set at full...
	For index, value in axis_mapping1 {
		joystate[index] := GetKeyState(value.id . "Joy" . axis_list_ahk[value.axis])
		; Store state of alt (merge) axis too, so we can select using that
		if (ts != "None" && axis_mapping2[A_Index].id != "None"){
			altstate[index] := GetKeyState(axis_mapping2[A_Index].id . "Joy" . axis_list_ahk[axis_mapping2[A_Index].axis])
		} else {
			alstate[index] := -1
		}
	}

	Loop, {
		if (A_TickCount >= (quickbind_start + 5000)){
			return
		}
		if (A_TickCount >= (last_beep + 750)){
			soundbeep, 500, 100
			last_beep := A_TickCount
		}
		
		For index, value in button_mapping {
			if (button_mapping[index].id != "None" && button_mapping[index].button != "None"){
				if (instr(button_mapping[index].button,"POV ")){
					; Hat switch mapped to button
					tmp := SubStr(button_mapping[index].button, 5) 
					StringLower, tmp, tmp
					val := GetKeyState(button_mapping[index].id . "Joy" . "POV")
					val := PovToAngle(val)
					if (!PovMatchesAngle(val,tmp)){
						continue
					}
				} else {
					; Regular button mapping
					val := GetKeyState(value.id . "Joy" . value.button)
					if (!val){
						continue
					}
				}
				; A mapped button (or hat mapped to button) was pressed
				; Switch to tab and select QB radio for this button
				if (A_Index > 16){
					arr := 2
					tmp := QuickBindButtons2
				} else {
					arr := 1
					tmp := QuickBindButtons1
				}
				tab := 2 + arr
				ADHD.set_current_tab(tab)
				
				control, check,,,% "ahk_id " QB_B_%A_Index%%tmp%
				Gui, Submit, NoHide
				
				tab_changed_hook()
				
				quickbind_selected()
				return
			}
		}
		
		For index, value in hat_mapping {
			if (hat_mapping[index].id != "None"){
				val := GetKeyState(value.id . "Joy" . "POV")
				Loop, 4 {
					if (PovMatchesAngle(PovToAngle(val), hat_axes[A_Index])){
						; Reject diagonal - ambiguous mapping
						if (HatIndexToPov(A_Index) != val){
							continue
						}
						; Switch to tab and select QB radio for this button
						ADHD.set_current_tab(5)
						tab_changed_hook()
						
						control, check,,,% "ahk_id " QB_H_%A_Index%
						Gui, Submit, NoHide
						
						tab_changed_hook()
						
						quickbind_selected()
						return
					}
				}
			}
		}

		For index, value in axis_mapping1 {
			if (value.exists){
				; Main section for active axes
				; Get input value
				val := GetKeyState(value.id . "Joy" . axis_list_ahk[value.axis])
				if (altstate[A_Index] != -1){
					val2 := GetKeyState(axis_mapping2[A_Index].id . "Joy" . axis_list_ahk[axis_mapping2[A_Index].axis])
				} else {
					val2 := -1
				}
				
				if (abs(val - joystate[index]) > 37.5 || abs(val2 - altstate[index]) > 37.5){
					; Switch to tab and select QB radio for this button
					ADHD.set_current_tab(1)
					
					ax := value.axis
					control, check,,,% "ahk_id " QB_A_%A_Index%
					Gui, Submit, NoHide
					
					tab_changed_hook()
					
					quickbind_selected()
					return
				}
			}
		}
		Sleep, 10
	}
}

quickbind_selected(){
	soundbeep, 750
	return
}

play_quickbind_delay(){
	Global QuickBindDelay
	
	tick := ((QuickBindDelay * 1000) / 3) - 150
	soundbeep, 400, 75
	Sleep, % tick
	soundbeep, 500, 75
	Sleep, % tick
	soundbeep, 750, 75
	Sleep, % tick
	return
}

AutoConfigurePressed:
	if (ADHD.get_current_tab() == "Axes 1"){
		auto_configure_axes()
	} else {
		auto_configure_buttons()
	}
	return
	
auto_configure_axes(){
	Global ADHD
	Global AutoConfigureID
	Global axis_list_ahk
	
	Gui, Submit, NoHide
	; ToDo: Detect how many axes the physical stick has, and only map those
	; AHK only supports 6 axes per stick, so just populate lines 1-6
	Loop, 6 {
		if (GetKeyState(AutoConfigureID . "Joy" . axis_list_ahk[A_Index]) != ""){
			GuiControl, choosestring,axis1_controls_physical_stick_id_%A_Index%, %AutoConfigureID%
			GuiControl, choosestring,axis1_controls_physical_axis_%A_Index%, %A_Index%
		}
	}
	ADHD.option_changed()
	return
}

auto_configure_buttons(){
	Global ADHD
	Global AutoConfigureID
	Global virtual_buttons

	Loop, %virtual_buttons% {
		Gui, Submit, NoHide
		GuiControl, choosestring,button_physical_stick_id_%A_Index%, %AutoConfigureID%
		GuiControl, choosestring,button_id_%A_Index%, %A_Index%
	}
	ADHD.option_changed()
	return
}

; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
