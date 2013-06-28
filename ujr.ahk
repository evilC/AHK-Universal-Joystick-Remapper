; ujr.ahk - evilC's Universal Joystick Remapper
version := 4.2

; When the script quits, disconnect the joystick
OnExit, DisconnectJoystick
SetKeyDelay, 0, 50

; Init the PPJoy / vJoy library
#include VJoyLib\VJoy_lib.ahk

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

LoadPackagedLibrary()
vjoy_id := 1
VJoy_Init(vjoy_id)

manual_control := 0
virtual_axes := 8
virtual_buttons := VJoy_GetVJDButtonNumber(vjoy_id)

; An array of names AHK uses for axes - used to we can refer to axes by axis number not name
axis_list_ahk := Array("X","Y","Z","R","U","V")
axis_list_vjoy := Array("X","Y","Z","RX","RY","RZ","SL0","SL1")

; Mapping array - A multidimensional array holding Axis mappings
; The first element is the mapping for the first virtual axis, the second element for axis 2, etc, etc
; Each element is then comprise of a further array:
; [Physical Joystick #,Physical Axis #, Scale (-1 = invert)]
axis_mapping := Array()

button_mapping := Array()

; When axes are to be merged - the first axis to be processed stores it's value in this array
; The second axis can then use the value in here to merge with the first axis
merged_axes := Array()

tmpvar := ""
IniRead, profile_list, %A_ScriptName%.ini, Settings, profile_list, unset
if (profile_list == "unset"){
	profile_list := ""
}
current_profile := "Default"

ignore_events := 1	; Setting this to 1 while we load the GUI allows us to ignore change messages generated while we build the GUI

; Detect if settings file compatible
IfExist %A_ScriptName%.ini
	IniRead, val, %A_ScriptName%.ini, Settings, config_format, unset
	if (val == "unset"){
		MsgBox, Your INI file is from a previous incompatible version. Config file will be renamed
		FileMove, %A_ScriptName%.ini, %A_ScriptName%.ini.bak
	} else if(val == "1"){
		; Pre-profile INI - split into settings and profile ini
		MsgBox, Your INI file is from a pre-profile version. Config file will be backed up, then updated.`n`nPrevious stick settings will be copied to the Default profile`n`nNo settings are lost!
		tmp := A_ScriptName ".ini"
		FileCopy, %tmp%, %tmp%.v1.bak
		Loop, %virtual_axes% {
			IniRead, val, %tmp%, Axes, virtual_axis_id_%A_Index%, None
			UpdateINI("virtual_axis_id_"A_Index, current_profile, val, "none", "profiles")
			
			IniRead, val, %tmp%, Axes, virtual_axis_merge_%A_Index%, None
			UpdateINI("virtual_axis_merge_"A_Index, current_profile, val, "none", "profiles")
			
			IniRead, val, %tmp%, Axes, axis_physical_stick_id_%A_Index%, None
			UpdateINI("axis_physical_stick_id_"A_Index, current_profile, val, "none", "profiles")
			
			IniRead, val, %tmp%, Axes, physical_axis_id_%A_Index%, None
			UpdateINI("physical_axis_id_"A_Index, current_profile, val, "none", "profiles")
			
			IniRead, val, %tmp%, Axes, virtual_axis_invert_%A_Index%, 0
			UpdateINI("virtual_axis_invert_"A_Index, current_profile, val, 0, "profiles")

			IniRead, val, %tmp%, Axes, virtual_axis_deadzone_%A_Index%, 0
			UpdateINI("virtual_axis_deadzone_"A_Index, current_profile, val, "0", "profiles")
			
			IniRead, val, %tmp%, Axes, virtual_axis_sensitivity_%A_Index%, 100
			UpdateINI("virtual_axis_sensitivity_"A_Index, current_profile, val, "100", "profiles")
		}
		IniDelete, %tmp%, Axes
		
		Loop, %virtual_buttons% {
			IniRead, val, %tmp%, Buttons, button_physical_stick_id_%A_Index%, None
			UpdateINI("button_physical_stick_id_"A_Index, current_profile, val, "none", "profiles")
			
			IniRead, val, %tmp%, Buttons, button_id_%A_Index%, None
			UpdateINI("button_id_"A_Index, current_profile, val, "none", "profiles")
		}
		IniDelete, %tmp%, Buttons
	}


; Set up the GUI
gui_width := 600
w:=gui_width-10

th1 := 65
th2 := th1+5

; PROFILE SELECTION
Gui, Add, Text, x10 y10 W80, Current Profile
Gui, Add, DropDownList, x105 y5 w100 h20 R7 vcurrent_profile gProfileChanged, Default||%profile_list%

; TAB HEADINGS
Gui, Add, Tab2, x5 y35 h390 w%w%, Axes|Buttons 1-8|Buttons 9-16|Buttons 17-24|Buttons 25-32|Profiles

; AXES TAB
Gui, Add, Text, x20 y%th1% w30 R2 Center, Virtual Axis
Gui, Add, Text, x70 y%th1% w50 R2 Center, Axis Merging
Gui, Add, Text, x125 y%th1% w60 R2 Center, Physical Stick ID
Gui, Add, Text, x185 y%th1% w60 R2 Center, Physical Axis
Gui, Add, Text, x240 y%th2% w100 h20 Center, State
Gui, Add, Text, x335 y%th2% w40 h20 Center, Invert
Gui, Add, Text, x380 y%th2% w50 R2 Center, % "Deadzone %"
Gui, Add, Text, x435 y%th2% w50 R2 Center, % "Sensitivity %"
Gui, Add, Text, x485 y%th2% w50 h20 Center, Physical
Gui, Add, Text, x540 y%th2% w50 h20 Center, Virtual

Loop, %virtual_axes% {
	ypos := 70 + A_Index * 30
	ypos2 := ypos + 5
	Gui, Add, DropDownList, x10 y%ypos% w50 h20 R7 vvirtual_axis_id_%A_Index% gConfigChanged, None||1|2|3|4|5|6|7|8
	Gui, Add, DropDownList, x70 y%ypos% w50 h20 R7 vvirtual_axis_merge_%A_Index% gConfigChanged, None||On
	Gui, Add, DropDownList, x130 y%ypos% w50 h10 R7 vaxis_physical_stick_id_%A_Index% gConfigChanged, None||1|2|3|4|5|6|7|8
	Gui, Add, DropDownList, x190 y%ypos% w50 h21 R7 vphysical_axis_id_%A_Index% gConfigChanged, None||1|2|3|4|5|6|7|8
	Gui, Add, Slider, x240 y%ypos% w100 h20 vaxis_state_slider_%A_Index%
	Gui, Add, CheckBox, x345 y%ypos% w20 h20 vvirtual_axis_invert_%A_Index% gConfigChanged
	Gui, Add, Edit, x385 y%ypos% w40 h21 vvirtual_axis_deadzone_%A_Index% gConfigChanged, 0
	Gui, Add, Edit, x440 y%ypos% w40 h21 vvirtual_axis_sensitivity_%A_Index% gConfigChanged, 100
	Gui, Add, Text, x490 y%ypos% w40 h21 Center vphysical_value_%A_Index%, 0
	Gui, Add, Text, x540 y%ypos% w40 h21 Center vvirtual_value_%A_Index%, 0
}

; BUTTONS TAB

button_tab = 1
button_row = 1

Loop, %virtual_buttons% {
	var := Mod(A_Index,16)
	if (Mod(A_Index,8) == 1){
		button_tab++
		Gui, Tab, %button_tab%
		Gui, Add, Text, x20 y%th1% w20 R2 Center, Virt Btn
		Gui, Add, Text, x62 y%th2% w60 h20 Center, Stick ID
		Gui, Add, Text, x132 y%th2% w60 h20 Center, Button #
		Gui, Add, Text, x185 y%th2% w100 h20 Center, State
		button_row = 1
	}
	ypos := 70 + button_row * 30
	ypos2 := ypos + 5
	Gui, Add, Text, x25 y%ypos2% w40 h20 , %A_Index%
	Gui, Add, DropDownList, x62 y%ypos% w60 h10 R7 vbutton_physical_stick_id_%A_Index% gConfigChanged, None||1|2|3|4|5|6|7|8
	Gui, Add, DropDownList, x132 y%ypos% w60 h21 R7 vbutton_id_%A_Index% gConfigChanged, None||POV U|POV D|POV L|POV R|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32
	Gui, Add, Text, x220 y%ypos% w30 h20 vbutton_state_%A_Index% gButtonClicked cred Center, Off
	button_row++
}

Gosub, LoadProfile

; PROFILES TAB
Gui, Tab, Profiles
Gui, Add, Text, x10 y%th2% W80, Profile to edit
Gui, Add, DropDownList, x105 y%th1% w100 h20 R7 vediting_profile gEditProfileChanged, Default||%profile_list%
Gui, add, Button, xp+120 yp gAddProfileClicked, Add
Gui, add, Button, xp+50 yp gDuplicateProfile, Duplicate
Gui, add, Button, xp+70 yp gDeleteProfile, Delete

Gui, Tab

; OUTSIDE TABS
Gui, Add, CheckBox, x12 y340 vmanual_control gToggleManualControl
Gui, Add, Text, xp+40 yp0 W300, Manual Control
Gui, Add, Text, xp yp+20 W500, When ticked, the slider in the State column above operate the virtual joystick`rUse this if the game detects your physical joystick instead of the virtual one - Enable Manual Control, tab into the game, double click the bind field, tab out of the game, operate the axis or button to bind, then tab back into the game.

w := gui_width-50
Gui, add, Button, x%w% y0 gReload, Reload
w := gui_width-120
Gui, add, Button, x%w% y0 gDetectAxis, Detect Axis

IniRead, gui_x, %A_ScriptName%.ini, Settings, gui_x, 0
IniRead, gui_y, %A_ScriptName%.ini, Settings, gui_y, 0
if (gui_x == ""){
	gui_x := 0	; in case of crash empty values can get written
}
if (gui_y == ""){
	gui_y := 0
}
Gui, Show, h430 w%gui_width% x%gui_x% y%gui_y%, Universal Joystick Remapper %version%

ignore_events := 0

; Call ConfigChanged to populate arrays
Gosub, ConfigChanged

; =============================================================================================================================

; MAIN LOOP - controls the virtual stick
Loop{
	; Clear axes - for axis merging, we need each axis to start at -1 so we know if we have altered it yet
	Loop, %virtual_axes% {
		merged_axes[%A_Index%] := -1
	}
	
	; Cycle through rows. MAY NOT BE IN ORDER OF VIRTUAL AXES!
	For index, value in axis_mapping {
		;if (virtual_axis_id_%index% != "None" && axis_mapping[index].id != "None" && axis_mapping[index].axis != "None"){
		if (virtual_axis_id_%index% != "None"){
			; Main section for active axes
			if (!manual_control){	; Normal mode
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
			} else {	; manual control mode
				GuiControlGet, val,, axis_state_slider_%index%
				val := AdjustAxis(val,value)
			}
			
			; Set the value for this axis on the virtual stick
			axismap := axis_list_vjoy[value.virt_axis]

			ax := value.axis
			if (value.merge != "None"){
				if (merged_axes[%ax%] == -1){
					merged_axes[%ax%] := val
				} else {
					val := ((val/2)+50) + ((merged_axes[%ax%]/2) * -1)
				}
			}
			; rescale to vJoy style 0->32767
			val := val * 327.67
			VJoy_SetAxis(val, vjoy_id, HID_USAGE_%axismap%)

		} else {
			; Blank out unused axes
			GuiControl,, physical_value_%index%, 
			GuiControl,, virtual_value_%index%, 
			GuiControl,, axis_state_slider_%index%, 50
		}
		
	}
	
	For index, value in button_mapping {
		if (button_mapping[index].id != "None" && button_mapping[index].button != "None"){
			if (manual_control == 0){
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
			} else {
				GuiControlGet, val,, button_state_%index%
				if (val == "On"){
					val := 1
				} else {
					val := 0
				}
			}
			VJoy_SetBtn(val, vjoy_id, index)
		}		
	}
	Sleep, 10
}

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

; Manual control ticked / unticked
ToggleManualControl:
	Gui, Submit, NoHide
	return

; Option changed - write settings to INI file and update settings arrays
ConfigChanged:
	if (!ignore_events){	; do not save settings if the change occured because we set it as the app started up
		Gui, Submit, NoHide
		
		IniWrite, 2, %A_ScriptName%.ini, Settings, config_format
		
		Loop, %virtual_axes% {
			axis_mapping[A_Index] := Object()
			
			axis_mapping[A_Index].virt_axis := virtual_axis_id_%A_Index%
			UpdateINI("virtual_axis_id_"A_Index, current_profile, virtual_axis_id_%A_Index%, "none", "profiles")

			axis_mapping[A_Index].merge := virtual_axis_merge_%A_Index%
			UpdateINI("virtual_axis_merge_"A_Index, current_profile, virtual_axis_merge_%A_Index%, "none", "profiles")

			axis_mapping[A_Index].id := axis_physical_stick_id_%A_Index%
			UpdateINI("axis_physical_stick_id_"A_Index, current_profile, axis_physical_stick_id_%A_Index%, "none", "profiles")

			axis_mapping[A_Index].axis := physical_axis_id_%A_Index%
			UpdateINI("physical_axis_id_"A_Index, current_profile, physical_axis_id_%A_Index%, "none", "profiles")
			
			if(virtual_axis_invert_%A_Index% == 0){
				axis_mapping[A_Index].invert := 1
			} else {
				axis_mapping[A_Index].invert := -1
			}
			UpdateINI("virtual_axis_invert_"A_Index, current_profile, virtual_axis_invert_%A_Index%, 0, "profiles")
			
			if virtual_axis_deadzone_%A_Index% is not number
				GuiControl,,virtual_axis_deadzone_%A_Index%,0
			else
				axis_mapping[A_Index].deadzone := virtual_axis_deadzone_%A_Index%
			
			UpdateINI("virtual_axis_deadzone_"A_Index, current_profile, virtual_axis_deadzone_%A_Index%, "0", "profiles")
			
			if virtual_axis_sensitivity_%A_Index% is not number
				GuiControl,,virtual_axis_sensitivity_%A_Index%,100
			else
				axis_mapping[A_Index].sensitivity := virtual_axis_sensitivity_%A_Index%
			
			UpdateINI("virtual_axis_sensitivity_"A_Index, current_profile, virtual_axis_sensitivity_%A_Index%, "100", "profiles")
		}
	
		Loop, %virtual_buttons% {
			button_mapping[A_Index] := Object()
			
			button_mapping[A_Index].id := button_physical_stick_id_%A_Index%
			UpdateINI("button_physical_stick_id_"A_Index, current_profile , button_physical_stick_id_%A_Index%, "none", "profiles")
			
			tmp := instr(button_id_%A_Index%,"POV ")
			if (tmp > 0){
				tmp := SubStr(button_id_%A_Index%, 5) 
				StringLower, tmp, tmp
				button_mapping[A_Index].pov := tmp

			} else {
				button_mapping[A_Index].pov := 0			
			}
			button_mapping[A_Index].button := button_id_%A_Index%
			UpdateINI("button_id_"A_Index, current_profile , button_id_%A_Index%, "none", "profiles")
		}
	}
	return
	
EditProfileChanged:
	gui, submit, nohide
	return
	
ProfileChanged:
	gui, submit, nohide
	Gosub, LoadProfile
	return
	
; Add Profile Clicked
AddProfileClicked:
	InputBox, tmp, Profile Name, Please enter a profile name
	AddProfile(tmp)
	return

AddProfile(name){
	global profile_list
	if (profile_list == ""){
		profile_list := name
	} else {
		profile_list := profile_list "|" name
	}
	Sort, profile_list, D|
	
	GuiControl,, current_profile, |Default||%profile_list%
	GuiControl,, editing_profile, |Default||%profile_list%
	
	UpdateINI("profile_list", "Settings", profile_list, "", "settings")

}
	
; Updates the settings file. If value is default, it deletes the setting to keep the file as tidy as possible
UpdateINI(key, section, value, default, type){
	if(type == "profiles"){
		tmp := A_ScriptName ".profiles.ini"
	} else {
		tmp := A_ScriptName ".ini"	
	}
	if (value != default){
		IniWrite,  %value%, %tmp%, %section%, %key%
	} else {
		IniDelete, %tmp%, %section%, %key%
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

; Detects the sign (+ or -) of a number and returns a multiplier for that sign
sign(input){
	if (input < 0){
		return -1
	} else {
		return 1
	}
}

; A button was clicked in the GUI - run ButtonClicked() with parameter for which button was clicked
ButtonClicked:
	StringTrimLeft, var, A_GuiControl, 13 ; Change if variable name for button state changes from button_state_%A_Index% !!!
	ButtonClicked(var)
	return
	
; A button was clicked in the GUI
ButtonClicked(but){
	Global manual_control
	if (manual_control == 1){
		GuiControlGet, val,, button_state_%but%
		if (val == "On"){
			SetButtonState(but,0)
		} else {
			SetButtonState(but,1)
		}
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

DuplicateProfile:
	IniRead, val, %A_ScriptName%.ini, Settings, config_format, unset
	tmp := A_ScriptName ".profiles.ini"
	InputBox, new_profile, New Profile name, Please enter a new profile name
	
	AddProfile(editing_profile)
	
	Loop, %virtual_axes% {
		IniRead, val, %tmp%, %editing_profile%, virtual_axis_id_%A_Index%, None
		UpdateINI("virtual_axis_id_"A_Index, new_profile, val, "none", "profiles")
		
		IniRead, val, %tmp%, %editing_profile%, virtual_axis_merge_%A_Index%, None
		UpdateINI("virtual_axis_merge_"A_Index, new_profile, val, "none", "profiles")
		
		IniRead, val, %tmp%, %editing_profile%, axis_physical_stick_id_%A_Index%, None
		UpdateINI("axis_physical_stick_id_"A_Index, new_profile, val, "none", "profiles")
		
		IniRead, val, %tmp%, %editing_profile%, physical_axis_id_%A_Index%, None
		UpdateINI("physical_axis_id_"A_Index, new_profile, val, "none", "profiles")
		
		IniRead, val, %tmp%, %editing_profile%, virtual_axis_invert_%A_Index%, 0
		UpdateINI("virtual_axis_invert_"A_Index, new_profile, val, 0, "profiles")

		IniRead, val, %tmp%, %editing_profile%, virtual_axis_deadzone_%A_Index%, 0
		UpdateINI("virtual_axis_deadzone_"A_Index, new_profile, val, "0", "profiles")
		
		IniRead, val, %tmp%, %editing_profile%, virtual_axis_sensitivity_%A_Index%, 100
		UpdateINI("virtual_axis_sensitivity_"A_Index, new_profile, val, "100", "profiles")
	}
	
	Loop, %virtual_buttons% {
		IniRead, val, %tmp%, %editing_profile%, button_physical_stick_id_%A_Index%, None
		UpdateINI("button_physical_stick_id_"A_Index, new_profile, val, "none", "profiles")
		
		IniRead, val, %tmp%, %editing_profile%, button_id_%A_Index%, None
		UpdateINI("button_id_"A_Index, new_profile, val, "none", "profiles")
	}
	return
	
DeleteProfile:
	if (editing_profile != "Default"){
		StringSplit, tmp, profile_list, |
		out := ""
		Loop, %tmp0%{
			if (tmp%a_index% != editing_profile){
				if (out != ""){
					out := out "|"
				}
				out := out tmp%a_index%
			}
		}
		profile_list := out
		
		tmp := A_ScriptName ".profiles.ini"
		IniDelete, %tmp%, %editing_profile%
		UpdateINI("profile_list", "Settings", profile_list, "", "settings")		
		
		GuiControl,, current_profile, |Default||%profile_list%
		GuiControl,, editing_profile, |Default||%profile_list%
		Gui, Submit, NoHide
				
		Gosub, LoadProfile
	}
	return

LoadProfile:
	ignore_events := 1
	tmp := A_ScriptName ".profiles.ini"
	Loop, %virtual_axes% {
		IniRead, val, %tmp%, %current_profile%, virtual_axis_id_%A_Index%, None
		GuiControl, ChooseString, virtual_axis_id_%A_Index%, %val%
		
		IniRead, val, %tmp%, %current_profile%, virtual_axis_merge_%A_Index%, None
		GuiControl, ChooseString, virtual_axis_merge_%A_Index%, %val%
		
		IniRead, val, %tmp%, %current_profile%, axis_physical_stick_id_%A_Index%, None
		GuiControl, ChooseString, axis_physical_stick_id_%A_Index%, %val%
		
		IniRead, val, %tmp%, %current_profile%, physical_axis_id_%A_Index%, None
		GuiControl, ChooseString, physical_axis_id_%A_Index%, %val%
		
		IniRead, val, %tmp%, %current_profile%, virtual_axis_invert_%A_Index%, 0
		GuiControl,, virtual_axis_invert_%A_Index%, %val%

		IniRead, val, %tmp%, %current_profile%, virtual_axis_deadzone_%A_Index%, 0
		GuiControl,, virtual_axis_deadzone_%A_Index%, %val%
		
		IniRead, val, %tmp%, %current_profile%, virtual_axis_sensitivity_%A_Index%, 100
		GuiControl,, virtual_axis_sensitivity_%A_Index%, %val%
	}
	
	Loop, %virtual_buttons% {
		IniRead, val, %tmp%, %current_profile%, button_physical_stick_id_%A_Index%, None
		GuiControl, ChooseString, button_physical_stick_id_%A_Index%, %val%
		
		IniRead, val, %tmp%, %current_profile%, button_id_%A_Index%, None
		GuiControl, ChooseString, button_id_%A_Index%, %val%
	}
	ignore_events := 0
	return
	
; Tries to work out which axis you are moving
DetectAxis:
	; Get idle state
	detect_array := Array()
	Loop, 8 {
		detect_array[%A_Index%] := Array()
		joy_num := A_Index
		Loop, 8 {
			detect_array[joy_num,a_index] := GetKeyState( joy_num . "Joy" . axis_list_ahk[A_Index])
		}
	}
	
	; Compare idle state to current state for 10 seconds
	joy_num := 0
	ctr := 0
	Loop {
		Loop, 8 {
			curr := GetKeyState( joy_num . "Joy" . axis_list_ahk[A_Index])
			diff := abs(detect_array[joy_num,a_index] - curr)
			if (diff >= 40){
				MsgBox, You appeared to move Joystick %joy_num%, axis %A_Index%
				return
			}
		}
		ctr++
		if (ctr >= 1000){
			MsgBox, Nothing detected for 10 seconds
			return
		}
		joy_num++
		if (joy_num == 9){
			joy_num = 1
		}
		Sleep, 10
	}
	return

; What to do when the reload button is clicked
Reload:
	Reload
	return
	
; Disconnect the joystick on exit
GuiClose:
DisconnectJoystick:
	VJoy_Close()
	Gui, +Hwndgui_id
	WinGetPos, gui_x, gui_y,,, ahk_id %gui_id%
	UpdateINI("gui_x", "Settings", gui_x, "", "settings")
	UpdateINI("gui_y", "Settings", gui_y, "", "settings")
	ExitApp
	return
