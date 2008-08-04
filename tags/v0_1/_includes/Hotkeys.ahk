/*
------------------------------------------------------------------------

A module for managing hotkeys
http://www.autohotkey.com

------------------------------------------------------------------------

Version: 0.0.2 2008-01-15 ,,interface version'' <- very not optimized, but works
License: GNU General Public License
Author: FARKAS Máté <http://fmate14.try.hu> (My given name is Máté)

Tested Platform:  Windows XP/Vista
Tested AutoHotkey Version: 1.0.47.04
Lastest version: http://autohotkey.try.hu/Hotkeys/Hotkeys.ahk

------------------------------------------------------------------------

If you would like help to me...
Please correct my english misspellings... ;)

------------------------------------------------------------------------
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PRIVATE GLOBAL VARIABLES
_Hotkeys_Keyname0 = 0 ; Hotkey name
;_Hotkeys_Label0   = 0 ; Destination

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PUBLIC FUNCTIONS

Hotkeys_Add( HK, Label )
{
	global
	_Hotkeys_Keyname0++
	_Hotkeys_Keyname%_Hotkeys_Keyname0% := HK
	_Hotkeys_Label%_Hotkeys_Keyname0% := Label
}

Hotkeys_Remove( HK )
{
	global
	Loop, %_Hotkeys_Keyname0% {
		local HK1 := _Hotkeys_Keyname%A_Index%
		if ( HK == HK1 ) {
			_Hotkeys_Label%A_Index% := ""
			Hotkey %HK%, Off
			return
		}
	}
}

Hotkeys_Change_Or_Add( HK, Label )
{
	Hotkeys_Change( HK, Label )
}

Hotkeys_Change( HK, Label )
{
	global
	Loop, %_Hotkeys_Keyname0% {
		local HK1 := _Hotkeys_Keyname%A_Index%
		if ( HK == HK1 ) {
			_Hotkeys_Keyname%A_Index% := HK
			_Hotkeys_Label%A_Index% := Label
			return
		}
	}
	Hotkeys_Add( HK, Label )
}

Hotkeys_Set_All()
{
	global
	Loop, %_Hotkeys_Keyname0% {
		local HK := _Hotkeys_Keyname%A_Index%
		local Label := _Hotkeys_Label%A_Index%
		Hotkey %HK%, %Label%
	}
}

Hotkeys_Activate_All()
{
	global
	Loop, %_Hotkeys_Keyname0% {
		local HK := _Hotkeys_Keyname%A_Index%
		Hotkey %HK%, On
	}
}

Hotkeys_Suspend_All()
{
	global
	Loop, %_Hotkeys_Keyname0% {
		local HK := _Hotkeys_Keyname%A_Index%
		Hotkey %HK%, Off
	}
}
