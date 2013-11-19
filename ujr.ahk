; UJR - Universal Joystick Remapper

#SingleInstance Off

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

ADHD.config_about({name: "UJR", version: 5.0, author: "evilC", link: "<a href=""http://evilc.com/proj/ujr"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
;ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(600,500)

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "Fire", subroutine: "Fire"})

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("option_changed", "option_changed_hook")
ADHD.config_event("program_mode_on", "program_mode_on_hook")
ADHD.config_event("program_mode_off", "program_mode_off_hook")
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("disable_timers", "disable_timers_hook")
ADHD.config_event("resolution_changed", "resolution_changed_hook")

; Add custom tabs
ADHD.tab_list := Array("Axes", "Buttons 1", "Buttons 2", "Hats")

; Init ADHD
ADHD.init()
ADHD.create_gui()

; The "Axes" tab is tab 1
Gui, Tab, 1


; ============================================================================================
; GUI SECTION

; End GUI creation section
; ============================================================================================

ADHD.finish_startup()
return

; ============================================================================================
; FUNCTIONS



; ============================================================================================
; EVENT HOOKS


; ============================================================================================
; ACTIONS


; Macro is trying to fire - timer label
Fire:
	return

; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
