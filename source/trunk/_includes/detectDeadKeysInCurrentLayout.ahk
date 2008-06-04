/*
------------------------------------------------------------------------

SendU module for detecting the deadkeys in current keyboard layout
http://www.autohotkey.com

------------------------------------------------------------------------

Version: 0.0.3 2008-05
License: GNU General Public License
Author: FARKAS Máté <http://fmate14.try.hu> (My given name is Máté)

Tested Platform:  Windows XP/Vista
Tested AutoHotkey Version: 1.0.47.04

------------------------------------------------------------------------

TODO: A better version without Send/Clipboard (I don't have idea)

------------------------------------------------------------------------

Why? In hungarian keyboard layout ~ is a dead key: 
	Send ~o ; is o with ~ accent
	Send ~ ; is nothing
	Send ~{Space} ; is ~ character
So... If I would like send ~, I must send ~{Space}. This script detect these characters

------------------------------------------------------------------------
*/

detectDeadKeysInCurrentLayout()
{
	global DeadKeysInCurrentLayout
	possibleDeadKeys = ~ ^ ` *
	DeadKeysInCurrentLayout = ;
	
	notepadMode = 0
	t := _detectDeadKeysInCurrentLayout_GetLocale( "MSGBOX_TITLE" )
	x := _detectDeadKeysInCurrentLayout_GetLocale( "MSGBOX" )
	MsgBox 51, %t%, %x%
	IfMsgBox Cancel
		return
	IfMsgBox Yes
	{
		notepadMode = 1
		Run Notepad
		Sleep 2000
		e := _detectDeadKeysInCurrentLayout_GetLocale( "EDITOR" )
		SendInput {RAW}%e%
	} else {
		Send `n{Space}+{Home}{Del}
	}
	
	loop, parse, possibleDeadKeys, %A_Space%
	{
		clipboard = ;
		Send {%A_LoopField%}{space}+{Left}^x
		ClipWait
		ifNotEqual clipboard, %A_Space%
			DeadKeysInCurrentLayout = %DeadKeysInCurrentLayout%%A_LoopField%
	}
	Send {Ctrl Up}{Shift Up}
	Send +{Home}{Del}{Backspace}
	if ( notepadMode )
		Send !{F4}
}

detectDeadKeysInCurrentLayout_SetLocale( variable, value )
{
	_detectDeadKeysInCurrentLayout_GetLocale( variable, value, 1 )
}

_detectDeadKeysInCurrentLayout_GetLocale( variable, value = "", set = 0 )
{
	static lMSGBOX_TITLE := "Open Notepad?"
	static lMSGBOX := "To detect the deadkeys in your current keyboard layout,`nI need an editor.`n`nClick Yes to open the Notepad`nClick No if you already in an editor`nClick Cancel if you KNOW, your system doesn't have dead keys"
	static lEDITOR := "Detecting deadkeys... Do not interrupt!"
	
	if ( set == 1 )
		l%variable% := value
	return l%variable%
}
