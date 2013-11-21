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

Stage 1 - Initial setup
-------------------------
1) Make sure a joystick is plugged in and Double click ujr.exe - you should see a GUI.
2) Go into the Bindings tab and bind something to QuickBind. In this example I sall assume you used F2
   eg to bind to F2: Tick "Program Mode", click the mouse in the box on the "QuickBind" row in the "Keyboard" column, then Hit F2
   IMPORTANT!! When done changing bindings, ALWAYS be sure to untick "Program Mode"
3) Go to the "Axes" tab.
   There are 8 rows in this tab, each representing an axis on the virtual controller.
   On the first row, set "Virtual Axis" to 1, set "Phystical Stick ID" to 1 and "Physical Axis" to 1.
   Now move axis 1 on your stick.
   If the "State" slider does not move, change the "Physical Stick ID" dropdown to the next option and try again
   ie if 1 does not work, try 2, then 3 etc...
   When you find one that moves the slider, you have found the physical ID of the stick that you were moving.
4) Go to the Axes tab, and in the bottom right, set the "Auto Configure Stick ID" dropdown to the value of the physical stick you just found.
   Click the "Auto Configure Stick ID" button to quickly configure the rest of the axes for you.
   Change to the "Buttons 1" tab and click the button again to quickly configure the buttons.
5) If your stick has a hat switch, go to the "Hats" tab and select the same stick ID from the dropdown.

Congratulations, your stick is now configured!

Open the joystick control panel (Start -> joy.cpl) and double click the "vJoy Device" entry.
You should see the virtual stick mimicking the actions of your physical stick.

The profiles menu can be used to create additional profiles - this allows you quickly change the configuration of UJR.

Also bear in mind that the virtual joystick is always "plugged in". Always mapping games to the virtual stick gives you a nice benefit:
If you start a game and forgot to plug your stick in, you only need to tab out and start up UJR and the stick will start working!


Stage 2 - Binding to a game
---------------------------
Because of the fact that UJR does not hide your physical stick from games, they may pick up the physical stick when trying to bind the virtual stick.
Before starting, you should bind something to "QuickBind Select" in the bindings tab.
(Example assumes you used F3)

1) Make sure that all the buttons you want to use are fully mapped to the virtual stick.
2) Enter the game, open it's bindings menu and choose which input you wish to bind first.
3) You want to bind the up axis first, so hit 'QuickBind Select' (F3) - a beeping will start.
   You have until the beeping stops to hit up on your stick.
4) Once you hit up, you should hear a high pitched confirmation beep - UJR is now ready to bind "up".
5) Hit 'QuickBind' (F2) and you will hear a series of beeps getting higher. You have until these beeps ends to activate the game's bind function.
   Before the beeps stop getting higher, double click the entry in the game's bind options that you wish to bind your up axis to.
6) When the beeps stop rising, you will hear a single tone and UJR will move the stick up, which the game should see and make the binding.

Repeat steps 3-6 for other axes or buttons.

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
