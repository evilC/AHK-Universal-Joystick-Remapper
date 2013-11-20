AHK-Universal-Joystick-Remapper
===============================

UJR - evilC's Universal Joystick Remapper
evilc@evilc.com

An AutoHotKey GUI script to remap one or more physical joysticks to a virtual joystick.
For more information, see the home page: http://evilc.com/joomla/index.php/articles/9-code/autohotkey/1-ujr-universal-joystick-remapper

===================================== 8< =====================================

Installation Instructions:

1) Install vJoy 2.x
http://sourceforge.net/projects/vjoystick/files/Beta%202.x/
Note, if you had UJR 1.x installed, you will need to remove vJoy 1.x and install vJoy 2.x
You will need to reboot to enter Test Mode, then vJoy will install before windows comes back up fully.

2) Configure the vJoy stick through the "Configure vJoy" program in your start menu. Enable all the axes and as many buttons as you require.
UJR cannot add axes / buttons to the vjoy stick - you must do this using the vjoy app, then use UJR to assign functions to those axes / buttons.

3) Extract the contents of the UJR ZIP and double-click ujr.exe
Note: UJR needs the contents of the "vJoyLib" folder, so do not separate ujr.exe and the vJoyLib folder!
You can always drag a shortcut to ujr.exe anywhere you like though.

===================================== 8< =====================================

Usage Instructions:

Stage 1 - Initial testing
-------------------------
1) Make sure a joystick is plugged in and Double click ujr.exe - you should see a GUI.
2) Go into the Bindings tab and bind something to QuickBind. In this example I sall assume you used F2
   eg to bind to F2: Tick "Program Mode", click the mouse in the box on the "QuickBind" row in the "Keyboard" column
   Hit F2, untick "Program Mode"
3) Go to the "Axes" tab.
   There are 8 rows in this tab, each representing an axis on the virtual controller.
   On the first row, set "Virtual Axis" to 1, set "Phystical Stick ID" to 1 and "Physical Axis" to 1.
   Now move axis 1 on your stick.
   If the "State" slider does not move, change the "Physical Stick ID" dropdown to the next option and try again
   ie if 1 does not work, try 2, then 3 etc...
   When you find one that moves the slider, you have found the physical ID of the stick that you were moving.
4) On the right is a "QB" column - this sets which axis to use for the QuickBind function. Make sure the 1st row is selected.
   Open the joystick control panel (Start -> joy.cpl)
   Double click the "vJoy Device" entry.
   Hit F2 and wait. When you hear a beep, the stick should move. If it does, UJR has proper control of the virtual stick.

You have now set up your first axis mapping - repeat the process used in steps 3 and 4 for the remaining axes and buttons.

The QuickBind function can also be used to map the virtual joystick to functions in games without the game detecting your physical stick.
In UJR, make sure the QB indicator is on the row you wish to bind.
To make the binding, tab into game and hit the QuickBind button, THEN activate the game's bind function.
Once the game's bind function is waiting for input, leave everything alone and QuickBind will operate the virtual stick to make the binding.
The Delay option for QuickBind will let you adjust how long it waits before manipulating the virtual stick.


Advanced
--------

Source code - The ujr.ahk file in the zip is the source code. In order to use this, you will also need my ADHD library.

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
use the "QuickBind" option, Double click bind option in game, ALT+Tab into UJR, move slider, tab back into game.

The button tab should be self explanatory - to use more than 8 buttons, run the "Configure vJoy" option in your start menu and set buttons to 32.
Note that to remap a POV (Hat) switch on your stick, you should set a virtual button to map to a physical POV.
UJR currently only supports one POV, this is a limitation of AHK.
