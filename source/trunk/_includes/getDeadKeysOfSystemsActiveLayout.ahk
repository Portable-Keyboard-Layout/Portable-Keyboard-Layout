/*
------------------------------------------------------------------------

Get the deadkeys of the active layout
http://www.autohotkey.com

------------------------------------------------------------------------

Version: 0.0.1 2008-05
License: GNU General Public License
Author: FARKAS Máté <http://fmate14.try.hu> (My given name is Máté)

Tested Platform:  Windows XP/Vista
Tested AutoHotkey Version: 1.0.47.04

------------------------------------------------------------------------

Why? In hungarian keyboard layout ~ is a dead key: 
	Send ~o ; is o with ~ accent
	Send ~ ; is nothing
	Send ~{Space} ; is ~ character
So... If I would like send ~, I must send ~{Space}.

------------------------------------------------------------------------
*/

getDeadKeysOfSystemsActiveLayout()
{
	l1038 = ~^` ; Hungarian
	l1036 = ~^` ; French AZERTY

	WinGet, WinID,, A
	ThreadID := DllCall("GetWindowThreadProcessId", "Int", WinID, "Int", 0)
	Layout := DllCall("GetKeyboardLayout", "Int", ThreadID) 
	Layout := ( Layout & 0xFFFFFFFF )>>16
	return l%Layout%
}
