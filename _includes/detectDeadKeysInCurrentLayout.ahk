/*
------------------------------------------------------------------------

SendU module for detecting the deadkeys in current keyboard layout
http://www.autohotkey.com

------------------------------------------------------------------------

Version: 0.0.2 2008-01-24
License: GNU General Public License
Author: FARKAS Máté <http://fmate14.try.hu> (My given name is Máté)

Tested Platform:  Windows XP/Vista
Tested AutoHotkey Version: 1.0.47.04
Lastest version: http://autohotkey.try.hu/detectDeadKeysInCurrentLayout/detectDeadKeysInCurrentLayout.ahk

------------------------------------------------------------------------

If you would like help to me...
Please correct my english misspellings...

------------------------------------------------------------------------

TODO: A better version without Send/Clipboard (I don't have idea)

------------------------------------------------------------------------

Why? In hungarian keyboard layout ~ is a dead key: 
	Send ~o ; is o with ~ accent
	Send ~ ; is nothing
	Send ~{Space} ; is space
So... If I would like send ~, I must send ~{Space}. This script detect these characters

------------------------------------------------------------------------
*/

if not DeadKeysInCurrentLayout
	DeadKeysInCurrentLayout = ;


detectDeadKeysInCurrentLayout()
{
	global detectDeadKeys_locale_MSGBOX_TITLE
	global detectDeadKeys_locale_MSGBOX
	global detectDeadKeys_locale_EDITOR
	global DeadKeysInCurrentLayout
	possibleDeadKeys = ~ ^ ` *
	DeadKeysInCurrentLayout = ;
	
	if ( detectDeadKeys_locale_MSGBOX_TITLE == "" ) {
		detectDeadKeys_locale_MSGBOX_TITLE = Open Notepad?
		detectDeadKeys_locale_MSGBOX = To detect the deadkeys in your current keyboard layout,`nI need an editor.`n`nClick Yes to open the Notepad`nClick No if you already in an editor`nClick Cancel if you KNOW, your system doesn't have dead keys
		detectDeadKeys_locale_EDITOR = Detecting deadkeys... Do not interrupt!
	}
	
	notepadMode = 0
	MsgBox 51, %detectDeadKeys_locale_MSGBOX_TITLE%, %detectDeadKeys_locale_MSGBOX%
	IfMsgBox Cancel
		return
	IfMsgBox Yes
	{
		notepadMode = 1
		Run Notepad
		Sleep 2000
		SendInput {RAW}%detectDeadKeys_locale_EDITOR%
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
	if (notepadMode)
		Send !{F4}
}
