; UJR - Universal Joystick Remapper

; ToDo:
; =====
; Allow selection of vjoy id

; Cater for case where non-existant vjoy id is selected on load.
; Should gracefully load and allow user to change ID

; Check presence of features (Hat settings always showing even if virt stick has no hat)

; Replace / Add axis splitting? Move to right of Physical Axis?

; Make QuickBind settings persistent? Per-Profile?

; Optimize main loop
; Less conversion of scales, ?set all axes at same time?

#SingleInstance On

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
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box

ADHD.config_about({name: "UJR", version: "5.4", author: "evilC", link: "<a href=""http://evilc.com/proj/ujr"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
;ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(600,500)

; Configure update notifications:
ADHD.config_updates("http://evilc.com/files/ahk/vjoy/ujr.au.txt")

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "QuickBind", subroutine: "QuickBind"})
adhd_hk_k_1_TT := "Trigger QuickBind"
ADHD.config_hotkey_add({uiname: "QuickBind Select", subroutine: "QuickBindSelect"})
adhd_hk_k_2_TT := "Select Button / Axis for QuickBind"

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
ADHD.tab_list := Array("Axes 1", "Axes 2", "Buttons 1", "Buttons 2", "Hats")

; Init ADHD
ADHD.init()
ADHD.create_gui()

; Init the PPJoy / vJoy library
#include VJoyLib\VJoy_lib.ahk

LoadPackagedLibrary()

vjoy_id := 1
VJoy_Init(vjoy_id)
if (!VJoy_Ready(vjoy_id)){
	msgbox The vJoy virtual joystick is already being controlled by something else.`n`nExiting...
	ExitApp
}

; Init stick vars for AHK
axis_list_ahk := Array("X","Y","Z","R","U","V")

; Init stick vars for vJoy
axis_list_vjoy := Array("X","Y","Z","RX","RY","RZ","SL0","SL1")

; The order in which the state buttons for the hat
hat_axes := Array("u","d","l","r")

quick_bind_mode := 0
virtual_axes := 8
;virtual_buttons := VJoy_GetVJDButtonNumber(vjoy_id)
virtual_buttons := 32
;virtual_hats := VJoy_GetContPovNumber(vjoy_id)
virtual_hats := 1	; AHK currently can only read one hat per stick

; Mapping array - A multidimensional array holding Axis mappings
; The first element is the mapping for the first virtual axis, the second element for axis 2, etc, etc
; Each element is then comprise of a further array:
; [Physical Joystick #,Physical Axis #, Scale (-1 = invert)]
axis_mapping := Array()
button_mapping := Array()
hat_mapping := Array()

; When axes are to be merged - the first axis to be processed stores it's value in this array
; The second axis can then use the value in here to merge with the first axis
merged_axes := Array()

; The "Axes" tab is tab 1
Gui, Tab, 1


; ============================================================================================
; GUI SECTION

gui_width := 600
w:=gui_width-10

th1 := 65
th2 := th1+5

; AXES TAB
; --------

Gui, Add, Text, x10 y35, vJoy Stick ID
ADHD.gui_add("DropDownList", "virtual_stick_id", "xp+70 yp-5 w50 h20 R9", "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16", "1")

Gui, Add, Text, x20 y%th1% w30 R2 Center, Virtual Axis
Gui, Add, Text, x70 y%th1% w50 R2 Center, Axis Merging
Gui, Add, Text, x125 y%th1% w60 R2 Center, Physical Stick ID
Gui, Add, Text, x185 y%th1% w60 R2 Center, Physical Axis
Gui, Add, Text, x240 y%th2% w100 h20 Center, State
Gui, Add, Text, x335 y%th2% w40 h20 Center, Invert
Gui, Add, Text, x380 y%th2% w50 R2 Center, % "Deadzone %"
Gui, Add, Text, x435 y%th2% w50 R2 Center, % "Sensitivity %"
Gui, Add, Text, x485 y%th2% w50 h20 Center, Physical
Gui, Add, Text, x530 y%th2% w40 h20 Center, Virtual
Gui, Add, Text, x568 y%th2% w20 h20 Center, QB

tmp := 0

Gui, Add, GroupBox, x5 y50 w585 h290,
Loop, %virtual_axes% {
	ypos := 70 + A_Index * 30
	ypos2 := ypos + 5
	ADHD.gui_add("DropDownList", "virtual_axis_id_" A_Index, "x10 y" ypos " w50 h20 R9", "None|1|2|3|4|5|6|7|8", "None")
	virtual_axis_id_%A_Index%_TT := "Makes this row map to the selected virtual axis"
	
	ADHD.gui_add("DropDownList", "virtual_axis_merge_" A_Index, "x70 y" ypos " w50 h20 R9", "None||On", "None")
	
	ADHD.gui_add("DropDownList", "axis_physical_stick_id_" A_Index, "x130 y" ypos " w50 h20 R9", "None|1|2|3|4|5|6|7|8", "None")
	axis_physical_stick_id_%A_Index%_TT := "Selects which physical stick to use for this axis"
	
	ADHD.gui_add("DropDownList", "physical_axis_id_" A_Index, "x190 y" ypos " w50 h20 R9", "None|1|2|3|4|5|6|7|8", "None")
	physical_axis_id_%A_Index%_TT := "Selects which axis to use on the selected physical stick"
	
	Gui, Add, Slider, x240 y%ypos% w100 h20 vaxis_state_slider_%A_Index%
	axis_state_slider_%A_Index%_TT := "Shows the state of this axis"
	
	ADHD.gui_add("CheckBox", "virtual_axis_invert_" A_Index, "x345 y" ypos " w20 h20", "", 0)
	virtual_axis_invert_%A_Index%_TT := "Inverts this axis"
	
	ADHD.gui_add("Edit", "virtual_axis_deadzone_" A_Index, "x385 y" ypos " w40 h21", "", 0)
	virtual_axis_deadzone_%A_Index%_TT := "Applies a deadzone to this axis"
	
	ADHD.gui_add("Edit", "virtual_axis_sensitivity_" A_Index, "x440 y" ypos " w40 h21", "", 100)
	virtual_axis_sensitivity_%A_Index%_TT := "Adjusts sensitivity of this axis"
	
	Gui, Add, Text, x490 y%ypos% w40 h21 Center vphysical_value_%A_Index%, 0
	Gui, Add, Text, x530 y%ypos% w40 h21 Center vvirtual_value_%A_Index%, 0
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
	ADHD.gui_add("DropDownList", "button_physical_stick_id_" A_Index, "x" xpos " y" ypos " w60 h10 R9", "None|1|2|3|4|5|6|7|8", "None")
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
	ADHD.gui_add("DropDownList", "hat_physical_stick_id_" A_Index, "x80 y" ypos " w50 h10 R9", "None|1|2|3|4|5|6|7|8", "None")

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
		tmp := tmp " vQuickBindButtons" button_tab-1 " Checked"
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
Gui, Add, DropDownList, x560 yp+1 w30 vAutoConfigureID, 1||2|3|4|5|6|7|8

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

; End GUI creation section
; ============================================================================================

ADHD.finish_startup()

; Fire tab changed at startup to init common portion
tab_changed_hook()

; =============================================================================================================================
; MAIN LOOP - controls the virtual stick
Loop{
	; Clear axes - for axis merging, we need each axis to start at -1 so we know if we have altered it yet
	Loop, %virtual_axes% {
		merged_axes[%A_Index%] := -1
	}
	
	if (!quick_bind_mode){
		; Cycle through rows. MAY NOT BE IN ORDER OF VIRTUAL AXES!
		For index, value in axis_mapping {
			;if (virtual_axis_id_%index% != "None" && axis_mapping[index].id != "None" && axis_mapping[index].axis != "None"){
			if (virtual_axis_id_%index% != "None"){
				; Main section for active axes
				; Get input value
				val := GetKeyState(value.id . "Joy" . axis_list_ahk[value.axis])

				; Display input value, rescale to -100 to +100
				GuiControl,, physical_value_%index%, % round((val-50)*2,2)
				
				; Adjust axis according to invert / deadzone options etc
				val := AdjustAxis(val,value)
				
				; Display output value, rescale to -100 to +100
				GuiControl,, virtual_value_%index%, % round((val-50)*2,2)
				; Move slider to show input value
				GuiControl,, axis_state_slider_%index%, % val
				
				; Set the value for this axis on the virtual stick
				axismap := axis_list_vjoy[value.virt_axis]

				; rescale to vJoy style 0->32767
				val := val * 327.67
				
				ax := value.axis
				if (value.merge != "None"){
					if (merged_axes[%ax%] == -1){
						merged_axes[%ax%] := val
					} else {
						;val := ((val/2)+50) + ((merged_axes[%ax%]/2) * -1)
						val := (val + merged_axes[%ax%]) / 2
						VJoy_SetAxis(val, vjoy_id, HID_USAGE_%axismap%)
					}
				} else {
					VJoy_SetAxis(val, vjoy_id, HID_USAGE_%axismap%)
				}

			} else {
				; Blank out unused axes
				GuiControl,, physical_value_%index%, 
				GuiControl,, virtual_value_%index%, 
				GuiControl,, axis_state_slider_%index%, 50
			}
			
		}
		
		For index, value in button_mapping {
			if (button_mapping[index].id != "None" && button_mapping[index].button != "None"){
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
			if (hat_mapping[index].id != "None"){
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

; Make adjustments to axis based upon settings
AdjustAxis(input,settings){
	; Shift from 0 -> 100 scale to -50 -> +50 scale
	output := input - 50
	
	; invert if needed
	output := output * settings.invert
	
	; impose deadzone if set
	dz := settings.deadzone
	
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
	output := output + 50
	
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
	; pov = 0-7 or -1
	; angle = u,d,l,r or -1
	if (angle == "u"){
		if (pov == 7 || pov == 0 || pov == 1){
			return 1
		}
	} else if (angle == "d"){
		if (pov >= 3 && pov <= 5){
			return 1
		}	
	} else if (angle == "l"){
		if (pov >= 5 && pov <= 7){
			return 1
		}
	} else if (angle == "r"){
		if (pov >= 1 && pov <= 3){
			return 1
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
	Global adhd_current_tab
	
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

	if (adhd_current_tab == "Axes 1" || adhd_current_tab == "Buttons 1" || adhd_current_tab == "Buttons 2" || adhd_current_tab == "Hats"){
		GuiControl, -Hidden, QuickBindLabelGroup
		GuiControl, -Hidden, QuickBindLabelDelay
		GuiControl, -Hidden, QuickBindDelay
		GuiControl, -Hidden, QuickBindLabelDuration
		GuiControl, -Hidden, QuickBindDuration
		GuiControl, -Hidden, QuickBindLabelInstructions
		if (adhd_current_tab == "Axes 1"){
			GuiControl, -Hidden, QuickBindLabelAxisType
			GuiControl, -Hidden, QuickBindAxisType
			GuiControl, -Hidden, AutoConfigureButton
			GuiControl, -Hidden, AutoConfigureID
		} else if (adhd_current_tab == "Buttons 1" || adhd_current_tab == "Buttons 2"){
			GuiControl, -Hidden, AutoConfigureButton
			GuiControl, -Hidden, AutoConfigureID
		} else if (adhd_current_tab == "Hats"){
		
		}
	}
}

; This is fired when settings change (including on load). Use it to pre-calculate values etc.
option_changed_hook(){
	Global virtual_axes
	Global virtual_buttons
	Global virtual_hats
	
	Global axis_mapping
	Global button_mapping
	Global hat_mapping
	
	Global axis_list_vjoy
	Global virtual_stick_id
	
	; Build arrays for main loop
	Loop, %virtual_axes% {
		axis_mapping[A_Index] := Object()
		
		tmp := axis_list_vjoy[A_Index]

		; Detect if this axis is present on the virtual stick
		axis_mapping[A_Index].exist := VJoy_GetAxisExist_%tmp%(virtual_stick_id)
		
		axis_mapping[A_Index].virt_axis := virtual_axis_id_%A_Index%

		axis_mapping[A_Index].merge := virtual_axis_merge_%A_Index%

		axis_mapping[A_Index].id := axis_physical_stick_id_%A_Index%

		axis_mapping[A_Index].axis := physical_axis_id_%A_Index%
		
		if(virtual_axis_invert_%A_Index% == 0){
			axis_mapping[A_Index].invert := 1
		} else {
			axis_mapping[A_Index].invert := -1
		}
		
		if (virtual_axis_deadzone_%A_Index% is not number){
			GuiControl,,virtual_axis_deadzone_%A_Index%,0
		} else {
			axis_mapping[A_Index].deadzone := virtual_axis_deadzone_%A_Index%
		}
		
		if (virtual_axis_sensitivity_%A_Index% is not number){
			GuiControl,,virtual_axis_sensitivity_%A_Index%,100
		} else {
			axis_mapping[A_Index].sensitivity := virtual_axis_sensitivity_%A_Index%
		}
	}

	Loop, %virtual_buttons% {
		button_mapping[A_Index] := Object()
		
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
	
	Loop, %virtual_hats% {
		hat_mapping[A_Index] := Object()
		
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
	; Work out what control we need to manipulate
	if (adhd_current_tab == "Axes 1" || adhd_current_tab == "Buttons 1" || adhd_current_tab == "Buttons 2" || adhd_current_tab == "Hats"){
		quick_bind_mode := 1

		; set all configured axes to neutral position
		For index, value in axis_mapping {
			axismap := axis_list_vjoy[value.virt_axis]
			if (axismap != ""){
				GuiControl,,axis_state_slider_%index%,50
				VJoy_SetAxis(16383.5, vjoy_id, HID_USAGE_%axismap%)
			}
		}
		
		; Set all configured buttons to off
		Loop, % virtual_buttons {
			SetButtonState(A_Index,0)
			VJoy_SetBtn(0, vjoy_id, A_Index)
		}
		
		; Set all configured hats to neutral position
		Loop, 4 {
			SetHatState(A_Index,0)
		}
		VJoy_SetContPov(-1, vjoy_id, 1)

		; Find which tab we are on and which control is selected, then move it after a delay
		if (adhd_current_tab == "Axes 1"){
			; Check axis is mapped
			value := axis_mapping[QuickBindAxes]
			axismap := axis_list_vjoy[value.virt_axis]
			if (axismap == ""){
				return
			}
			
			play_quickbind_delay()
			
			if (QuickBindAxisType == "High-Low"){
				GuiControl,,axis_state_slider_%QuickBindAxes%,100
				VJoy_SetAxis(32767, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
				
				GuiControl,,axis_state_slider_%QuickBindAxes%,0
				VJoy_SetAxis(0, vjoy_id, HID_USAGE_%axismap%)
				;Sleep, % (QuickBindDuration * 1000 ) / 2
			} else if (QuickBindAxisType == "Mid-High"){
				GuiControl,,axis_state_slider_%QuickBindAxes%,50
				VJoy_SetAxis(16383.5, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
				
				GuiControl,,axis_state_slider_%QuickBindAxes%,100
				VJoy_SetAxis(32767, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
			} else {
				GuiControl,,axis_state_slider_%QuickBindAxes%,50
				VJoy_SetAxis(16383.5, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
				
				GuiControl,,axis_state_slider_%QuickBindAxes%,0
				VJoy_SetAxis(0, vjoy_id, HID_USAGE_%axismap%)
				Sleep, % (QuickBindDuration * 1000 ) / 2
			}
		} else if (adhd_current_tab == "Buttons 1" || adhd_current_tab == "Buttons 2"){
			if (adhd_current_tab == "Buttons 1"){
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
		} else if (adhd_current_tab == "Hats"){
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
	Global axis_mapping
	Global button_mapping
	Global hat_mapping
	Global hat_axes
	Global vjoy_id
	Global axis_list_ahk
	Global adhd_current_tab
	
	quickbind_start := A_TickCount
	last_beep := 0

	joystate := Array()
	
	; Store starting state of axes for later comparison.
	; If user has a throttle, it may be set at full...
	For index, value in axis_mapping {
		joystate[index] := GetKeyState(value.id . "Joy" . axis_list_ahk[value.axis])
		;msgbox % joystate[value.id]
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
				GuiControl, Choose,adhd_current_tab, %tab%
				
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
						GuiControl, Choose,adhd_current_tab, 5
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

		For index, value in axis_mapping {
			if (virtual_axis_id_%index% != "None"){
				; Main section for active axes
				; Get input value
				val := GetKeyState(value.id . "Joy" . axis_list_ahk[value.axis])
				
				if (abs(val - joystate[index]) > 37.5){
					; Switch to tab and select QB radio for this button
					GuiControl, Choose,adhd_current_tab, 1
					
					ax := value.axis
					control, check,,,% "ahk_id " QB_A_%ax%
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

quickbind_selected()(){
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
	if (adhd_current_tab == "Axes 1"){
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
			GuiControl, choosestring,virtual_axis_id_%A_Index%, %A_Index%
			GuiControl, choosestring,axis_physical_stick_id_%A_Index%, %AutoConfigureID%
			GuiControl, choosestring,physical_axis_id_%A_Index%, %A_Index%
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

; Loads the vJoy DLL
LoadPackagedLibrary() {
    if (A_PtrSize < 8) {
        dllpath = VJoyLib\x86\vJoyInterface.dll
    } else {
        dllpath = VJoyLib\x64\vJoyInterface.dll
    }
    hDLL := DLLCall("LoadLibrary", "Str", dllpath)
    if (!hDLL) {
        MsgBox, [%A_ThisFunc%] LoadLibrary %dllpath% fail
    }
    return hDLL
} 

; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
