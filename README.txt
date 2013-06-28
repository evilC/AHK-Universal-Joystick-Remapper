AHK-Universal-Joystick-Remapper
===============================

UJR - evilC's Universal Joystick Remapper
evilc@evilc.com

===================================== 8< =====================================

Installation Instructions:

1) Make sure Autohotkey_L is installed
http://l.autohotkey.net/AutoHotkey_L_Install.exe
You may use any option during the install (eg 32 bit/64 bit/ANSI/Unicode)

2) Install vJoy 2.x
http://sourceforge.net/projects/vjoystick/files/Beta%202.x/
Note, if you had UJR 1.x installed, you will need to remove vJoy 1.x and install vJoy 2.x
You will need to reboot to enter Test Mode, then vJoy will install before windows comes back up fully.

3) Extract the contents of the UJR ZIP and double-click ujr.ahk
Note: ujr.ahk needs the contents of the "vJoyLib" folder, so do not separate ujr.ahk and the vJoyLib folder!
You can always drag a shortcut to ujr.ahk anywhere you like though.

4) Configure the vJoy stick through the "Configure vJoy" program in your start menu. Enable all the axes and as many buttons as you require.
UJR cannot add axes / buttons to the vjoy stick - you must do this using the vjoy app, then use UJR to assign functions to those axes / buttons.

===================================== 8< =====================================

Usage Instructions:

Each Row (1-8) represents an axis on the virtual controller.

Stage 1 - Initial testing
-------------------------
1) Make sure a joystick is plugged in and Double click ujr.ahk - you should see a GUI.
2) On the first row of settings, set "Virtual Axis" to 1
3) Tick the "Manual Control" box at the bottom and then drag the "State" slider in the first row all the way right
4) Control Panel > Devices and Printers, right click your joystick, and select "Game Controller Settings".
5) You should see two devices - "vJoy Device" and your actual stick.
6) Double click vJoy device - the stick should be all the way right
7) Go back to the UJR window and drag the slider left
8) Go back to the vJoy device properties window and the axis should be all the way left.

If this works, vJoy is working and you can move on to the next stage


Stage 2 - Finding your Joystick ID (You need to find out the ID of your physical Joystick)
------------------------------------------------------------------------------------------
1) In UJR, Untick the "Manual control" box
2) Click the "Detect Axis" button, then move an axis on your stick around (As big movements as possible) until a dialog pops up
3) This will either say it could not detect the stick, or tell you which ID and which axis you moved


Stage 3 - Testing physical to virtual stick mapping
---------------------------------------------------
Now you know your stick ID and axis number, you can configure the rest of the first row.
1) Set the "Physical Stick ID" column to the ID of the stick and the "Physical Axis" column to the Axis # you got from the detect tool
2) Move the stick around like you did before, and you should see the slider in that row moving to indicate input
3) If you get nothing, try repeating the detect process and see if it detects a different stick, or try all stick IDs manually
4) If you see the slider move, that shows UJR is detecting your stick.
Go back to the vJoy device properties in windows and verify physical stick input is controlling the virtual stick
It should move left and right as vJoy axis 1 is the X axis
5) Move on to the next row, select a different virtual axis, it should be pretty obvious by now.


Advanced
--------
Axis Merging - Use this to merge two axes on to one.
eg You have racing pedals where each pedal is a seperate axis and you want to simulate one axis (like a rudder)
To use, set TWO rows to the SAME "Virtual Axis" and set the "Axis Merging" column to "On" in both rows
DO NOT enable deadzone for any merged row
If you need to invert the merged axis, invert BOTH rows
Bear in mind this is intended for merging axes that normally sit at one end of the scale (like a pedal) rather than in the middle (like a stick)
Merging two sticks will have strange results.


UJR currently does not mask the Physical Joystick from games etc - it will still see both.
As long as the physical joystick is not bound to anything, it shouldn't make a difference.
If you need to bind the virtual axis but cannot because the game bind routine recognises the physical stick instead,
use the "Manual Control" option, Double click bind option in game, ALT+Tab into UJR, move slider, tab back into game.

The button tab should be self explanatory - to use more than 8 buttons, run the "Configure vJoy" option in your start menu and set buttons to 32.
Note that to remap a POV (Hat) switch on your stick, you should set a virtual button to map to a physical POV.
UJR currently only supports one POV, this is a limitation of AHK.


===================================== 8< =====================================
Changelog

Key:
! : Warning
* : Comment
= : Change / Fix
+ : Added feature

4.2
= Duplicate in profiles was always duplicating the Default profile, no matter what you had selected - fixed.
+ Added Delete Profile button

4.1
+ Duplicate profile added.

4.0
+ Profile support added.
INI file format changed, there are now two INI files - one for misc settings, one for profiles
Existing mappings are kept and moved to the default profile
Manual profile switching only for now...

3.2
+ The first physical POV Hat can now be mapped to virtual buttons. AHK only supports reading one POV :(

3.1
+ Sensitivity option for each axis.

3.0
! Please note that the format of the config file has changed, the program will back your old one up
= Fixed bug stopping button mappings not saving
= Improved UI layout, labels etc
= Major cleanup of code - now much more understandable
+ GUI position now saved in config file - when you close the app, next time you reopen it, it will be in the same place on your desktop
+ Only settings changed from their default setting are stored in the config file
+ Detect axis button! Use this to try and find out the stick ID of a physical stick.
Instructions now simplified
+ Experimental - Merging of axes
eg Merge two pedal axes into a rudder axis


2.3
+ Much improved deadzone code
  So with a 50% deadzone, if you move to 50 on an axis, it will be dead, but moving to 51 now outputs 1 rather than 51
+ Deadzone is now a text input field, so you can use any value you like
+ Input / Output slider renamed to "State"
+ Input and Output values for axes now displayed
+ Much more commented code

2.2
+ Added per-axis deadzone settings. Just 5,10,20,30,40,50,60,70 or 80 percent at the moment but I intend to allow any figure in a future version

2.1
= Fixed bug stopping UJR from working on 64-bit AHK installs.
= Fixed bug stopping mapping of virtual axis 4 or greater
+ 32 Buttons listed for physical joystick

2.0
+ Now uses Axlar's vJoy library (http://www.autohotkey.com/board/topic/87690-using-ahk-to-control-vjoy)
+ Now uses vJoy 2.x - Support for up to 32 buttons
You will NEED to uninstall vJoy 1.x and install 2.x to use this version

1.1
= Code for button testing no longer has one subroutine per button
= Optimised technique for inverting axes - thanks Babba on AHK forums!

1.0
* Fully functional basic version!
= Fixed bug stopping invert working in Manual Control mode
+ Button mapping in

0.3
+ Settings now saved in an INI file

0.2
+ All 8 axes now mappable
+ Code optimisations

0.1
* Initial Proof of concept

