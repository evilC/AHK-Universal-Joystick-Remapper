AHK-Universal-Joystick-Remapper
===============================

UJR - evilC's Universal Joystick Remapper
evilc@evilc.com
Trim mode by PhoenixBvo

An AutoHotKey GUI script to remap one or more physical joysticks to a virtual joystick.
For more information, see the home page: http://evilc.com/joomla/index.php/articles/9-code/autohotkey/1-ujr-universal-joystick-remapper

===================================== 8< =====================================

Installation Instructions:

1) Install vJoy
http://vjoystick.sourceforge.net/

2) Configure the vJoy stick through the "Configure vJoy" program in your start menu. Enable all the axes and as many buttons as you require.
UJR cannot add axes / buttons to the vjoy stick - you must do this using the vjoy app, then use UJR to assign functions to those axes / buttons.

3) Extract the contents of the UJR ZIP and double-click ujr.exe

===================================== 8< =====================================

Usage Instructions:

Stage 1 - Initial setup
-------------------------
1) Make sure a joystick is plugged in and Double click ujr.exe - you should see a GUI.
2) Go into the Bindings tab and bind something to QuickBind. In this example I sall assume you used F2
   eg to bind to F2: Tick "Program Mode", click the mouse in the box on the "QuickBind" row in the "Keyboard" column, then Hit F2
   IMPORTANT!! When done changing bindings, ALWAYS be sure to untick "Program Mode"
3) Go to the "Axes 1" tab.
   There are 8 rows in this tab, each representing an axis on the virtual controller.
   On the first row (X), set "Physical Stick ID" to 1 and "Physical Axis" to 1.
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

If rows appear greyed out, that is because the virtual joystick is not configured to support that function.
For example, if you only configured the virtual joystick to be 16 buttons, buttons 17-32 will be greyed out.
To configure the virtual stick, use the configuration utility that came with vJoy.

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

Source code:
The ujr.ahk file in the zip is the source code. In order to use this, you will also need my ADHD library and the vJoy library.

"Rest" settings:
On the Axis 1 tab in the "Special Operations" column, the "Rest H/L" settings do the following:
Rest H - Tells UJR that this axis Rests at a high value (ie a pedal that sits at max value when the pedal is not pressed)
Rest L - Tells UJR that this axis Rests at a low value (ie a pedal that sits at min value when the pedal is not pressed)
Setting these will affect how the deadzone / sensitivity settings are applied.

Axis Merging:
Use this to merge two axes on to one, for example to merge two pedals into one rudder.
It is NOT recommended for input axes that rest in a neutral position, it is intended for axes that rest at one end (eg pedals).
The Axes 2 tab is for configuring the second axis to merge.
For example, if your left pedal is stick 1, axis 1 and your right pedal is stick 1, axis 2
On the "Axes 1" tab, you would set row 1 to stick 1, axis 1 and make sure that pressing the pedal moves the slider left (use invert if needed)
On the "Axes 1" tab, set the "Special Operations" option for row 1 to "Rest H" to let UJR know to apply the deadzone and sensitivity settings.
On the "Axes 2" tab, you would set row 1 to stick 1, axis 2 and make sure that pressing the pedal moves the slider left (use invert if needed)
On the "Axes 2" tab, set "Axis Merging" to either "Merge" or "Greatest"
"Merge" averages the two pedals.
"Greatest" uses whichever pedal is pressed the most.
Bear in mind this is intended for merging axes that normally sit at one end of the scale (like a pedal) rather than in the middle (like a stick)
Merging two sticks will have strange results.

Axis Splitting:
Use this to use half of a physical axis to control a virtual axis.
The two settings - "Low" and "High" select which end of the axis is used for the virtual axis
Bear in mind that this is intended to be used for axes that normally sit in the middle of the axis (like a stick),
not axes that normally sit at one end of the scale (like pedals)

General notes:
UJR currently does not mask the Physical Joystick from games etc - it will still see both.
As long as the physical joystick is not bound to anything, it shouldn't make a difference.
If you need to bind the virtual axis but cannot because the game bind routine recognises the physical stick instead,
use the "QuickBind" option, Double click bind option in game, ALT+Tab into UJR, move slider, tab back into game.

The button tab should be self explanatory - to use more than 8 buttons, run the "Configure vJoy" option in your start menu and set buttons to 32.
Note that to remap a POV (Hat) switch on your stick, you should set a virtual button to map to a physical POV.
UJR currently only supports one POV, this is a limitation of AHK.
