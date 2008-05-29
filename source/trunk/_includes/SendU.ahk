/*
------------------------------------------------------------------------

SendU module for sending Unicode characters
http://www.autohotkey.com

------------------------------------------------------------------------

Version: 0.0.11 2008-03-03
License: GNU General Public License
Author: FARKAS Máté <http://fmate14.try.hu/> (My given name is Máté)

Tested Platform:  Windows XP/Vista
Tested AutoHotkey Version: 1.0.47.04
Lastest version: http://autohotkey.try.hu/SendU/SendU.ahk
Location in AutoHotkey forum: http://www.autohotkey.com/forum/viewtopic.php?t=25566

Contributors:
	* Laszlo Hars <www.Hars.US>
		original SendU function, _SendU_UnicodeChar function
		and some bugfixes
	* Shimanov
		original SendU function
	* Piz
		Fixed goto issues
		http://www.autohotkey.com/forum/viewtopic.php?p=182218#182218

------------------------------------------------------------------------

If you would like help to me...
Please correct my english misspellings...

------------------------------------------------------------------------
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PUBLIC GLOBAL VARIABLES FOR LOCALIZE
; See the _SendU_Load_Locale() function!

; PRIVATE GLOBAL VARIABLES
; _SendU_*** : unicode number -> utf8 character

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PUBLIC FUNCTIONS

SendCh( Ch ) ; Character number code, for example 97 (or 0x61) for 'a'
{
	Ch += 0
	if ( Ch < 0 ) {
		; What do you want???
		return
	} else if ( Ch < 33 ) {
		; http://en.wikipedia.org/wiki/Control_character#How_control_characters_map_to_keyboards
		Char = ;
		if ( Ch == 32 ) {
			Char = {Space}
		} else if ( Ch == 9 ) {
			Char = {Tab}
		} else if ( Ch > 0 && Ch <= 26 ) {
			Char := "^" . Chr( Ch + 64 )
		} else if ( Ch == 27 ) {
			Char = ^{VKDB}
		} else if ( Ch == 28 ) {
			Char = ^{VKDC}
		} else if ( Ch == 29 ) {
			Char = ^{VKDD}
		} else {
			SendU( Ch )
			return
		}
		Send %Char%
	} else if ( Ch < 129 ) {
		; ASCII characters
		Char := "{" . Chr( Ch ) . "}"
		Send %Char%
	} else {
		; Unicode characters
		SendU( Ch )
	}
}


SendU( UC )
{
	UC += 0
	if ( UC <= 0 )
		return
	mode := SendU_Mode()
	if ( mode = "d" ) { ; dynamic
		WinGet, pn, ProcessName, A
		mode := _SendU_Dynamic_Mode( pn )
	}
	
	if ( mode = "i" )
		_SendU_Input(UC)
	else if ( mode = "c" ) ; clipboard
		_SendU_Clipboard(UC)
	else if ( mode = "a" ) { ; {ASC nnnn}
		if ( UC < 256 ) 
			UC := "0" . UC
		Send {ASC %UC%}
	} else { ; input
		_SendU_Input(UC)
	}
}

SendU_utf8_string( str )
{
	mode := SendU_Mode()
	if ( mode = "d" ) { ; dynamic
		WinGet, pn, ProcessName, A
		mode := _SendU_Dynamic_Mode( pn )
	}
	
	if ( mode = "c" ) ; clipboard
		_SendU_Clipboard( str, 1 )
	else if ( mode = "a" ) { ; {ASC nnnn}
		codes := _SendU_Utf_To_Codes( str, "_" )
		Loop, parse, codes, _
		{
			UC := A_LoopField
			if ( UC < 256 ) 
				UC := "0" . UC
			Send {ASC %UC%}
		}
	} else {
		codes := _SendU_Utf_To_Codes( str, "_" )
		Loop, parse, codes, _
		{
			_SendU_Input(A_LoopField)
		}
	}
}

SendU_Mode( newMode = -1 )
{
	static mode := "i"
	if ( newmode == "d" || newMode == "i" || newmode == "a" || newmode == "c" )
		mode := newMode
	return mode
}

SendU_Clipboard_Restore_Mode( newMode = -1 )
{
	static mode := 1
	if ( newMode == 1 || newMode == 0 ) ; Enable, disable
		mode := newMode
	else if ( newMode == 2 ) ; Toggle
		mode := 1 - mode
	return mode
}

SendU_Try_Dynamic_Mode()
{
	WinGet, processName, ProcessName, A
	mode := _SendU_GetMode( processName )
	if ( mode == "i" )
		mode = a
	else if ( mode == "a" )
		mode = c
	else 
		mode = i
	_SendU_Dynamic_Mode_Tooltip( processName, mode )
	_SendU_SetMode( processName, mode )
	_SendU_Dynamic_Mode( "", 1 ) ; Clears the PrevProcess variable
}

SendU_Init( mode = "d" )
{
	SendU_Mode( mode )
	_SendU_Load_Locale()
	_SendU_Load_Dynamic_Modes()
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PRIVATE FUNCTIONS


_SendU_Input( UC )
{
	; Original SendU function written by Shimanov and Laszlo
	; http://www.autohotkey.com/forum/topic7328.html
	static buffer := "#"
	if buffer = #
	{
		VarSetCapacity( buffer, 56, 0 )
		DllCall("RtlFillMemory", "uint",&buffer,"uint",1, "uint", 1)
		DllCall("RtlFillMemory", "uint",&buffer+28, "uint",1, "uint", 1)
	}
	DllCall("ntdll.dll\RtlFillMemoryUlong","uint",&buffer+6, "uint",4,"uint",0x40000|UC) ;KEYEVENTF_UNICODE
	DllCall("ntdll.dll\RtlFillMemoryUlong","uint",&buffer+34,"uint",4,"uint",0x60000|UC) ;KEYEVENTF_KEYUP|

	Menu, Tray, Icon,,, 1 ; Freeze the icon
	Suspend On ; SendInput conflicts with scan codes (SC)!
	DllCall("SendInput", UInt,2, UInt,&buffer, Int,28)
	Suspend Off
	Menu, Tray, Icon,,, 0 ; Unfreeze the icon

	return
}

_SendU_Utf_To_Codes( utf8, separator = "," ) {
	; Return (comma) separated Unicode numbers of UTF-8 input STRING
	; Written by Laszlo Hars and FARKAS Mate (fmate14)
	static U := "#"
	static res
	if ( U == "#" ) {
		VarSetCapacity(U,   256 * 2)
		VarSetCapacity(res, 256 * 4)
	}
	DllCall("MultiByteToWideChar", UInt,65001, UInt,0, Str,utf8, Int,-1, UInt,&U, Int,256)
	res := ""
	pointer := &U
	Loop, 256
	{
		h := (*(pointer+1)<<8) + *(pointer)
		if ( h == 0 )
			break
		if ( res )
			res .= separator
		res .= h
		pointer += 2
	}
	Return res
}

; --------------------- functions for clipboard mode ----------------------------

_SendU_Clipboard( UC, isUtfString = 0 )
{
	Critical
	restoreMode := SendU_Clipboard_Restore_Mode()
	if ( isUtfString ) {
		utf := UC
	} else {
		utf := _SendU_GetVar( UC )
		if not utf
		{
			utf := _SendU_UnicodeChar( UC )
			_SendU_SetVar( UC, utf )
		}
	}
	if restoreMode
		_SendU_SaveClipboard()
	Transform Clipboard, Unicode, %utf%
	ClipWait
	SendInput ^v
	Sleep, 50 ; see http://www.autohotkey.com/forum/viewtopic.php?p=159301#159306
	if restoreMode {
		_SendU_Last_Char_In_Clipboard( Clipboard )
		SetTimer, _SendU_restore_Clipboard, -3000
	}
	Critical, Off
}

_SendU_RestoreClipboard()
{
	_SendU_SaveClipboard(1)
}

_SendU_SaveClipboard( restore = 0 )
{
	static cb
	if ( !restore && _SendU_Last_Char_In_Clipboard() == "" )
		cb := ClipboardALL
	else
		Clipboard := cb
}

_SendU_Last_Char_In_Clipboard( newChar = -1 )
{
	static ch := ""
	if ( newChar <> -1 )
		ch := newChar
	return ch
}

_SendU_UnicodeChar( UC )  ; Return the Utf-8 char from the Unicode numeric code (UC)
{ ; Written by Laszlo Hars
	VarSetCapacity(UText, 4, 0)
	NumPut(UC, UText, 0, "UShort")
	VarSetCapacity(AText, 4, 0)
	DllCall("WideCharToMultiByte"
		, "UInt", 65001  ; CodePage: CP_ACP=0 (current Ansi), CP_UTF7=65000, CP_UTF8=65001
		, "UInt", 0      ; dwFlags
		, "Str",  UText  ; LPCWSTR lpWideCharStr
		, "Int",  -1     ; cchWideChar: size in WCHAR values: Len or -1 (= null terminated)
		, "Str",  AText  ; LPSTR lpMultiByteStr
		, "Int",  4      ; cbMultiByte: Len or 0 (= get required size / allocate!)
		, "UInt", 0      ; LPCSTR lpDefaultChar
		, "UInt", 0)     ; LPBOOL lpUsedDefaultChar
	return %AText%
}

; --------------------- functions for dynamic mode ----------------------------

_SendU_Get_Mode_Name( mode )
{
	if ( mode == "c" && SendU_Clipboard_Restore_Mode() )
		mode = r
	m := _SendU_GetVar( "Mode_Name_" . mode )
	if ( m == "" )
		m := _SendU_GetVar( "Mode_Name_0" )
	return m
}

_SendU_Get_Mode_Type( mode )
{
	if ( mode == "c" && SendU_Clipboard_Restore_Mode() )
		mode = r
	m := _SendU_GetVar( "Mode_Type_" . mode )
	if ( m == "" )
		m := _SendU_GetVar( "Mode_Type_0" )
	return m
}

_SendU_Dynamic_Mode_Tooltip( processName = -1, mode = -1 )
{
	tt := _SendU_getVar("DYNAMIC_MODE_TOOLTIP")
	if not tt
		return
	if ( processName = -1 || mode == -1 ) {
		WinGet, processName, ProcessName, A
		mode := _SendU_GetMode( processName )
	}
	WinGetTitle, title, A
	StringReplace, tt,tt, $processName$, %processName%, A
	StringReplace, tt,tt, $title$, %title%, A
	StringReplace, tt,tt, $mode$, %mode%, A
	StringReplace, tt,tt, $modeType$, % _SendU_Get_Mode_Type( mode ), A
	StringReplace, tt,tt, $modeName$, % _SendU_Get_Mode_Name( mode ), A
	ToolTip, %tt%
	SetTimer, _SendU_Remove_Tooltip, 2000
}

_SendU_Dynamic_Mode( processName, clearPrevProcess = -1 )
{
	static prevProcess := "fOyj9b4f79YmA7sZRBrnDbp75dGhiauj" ; Nothing
	static mode := ""
	if ( clearPrevProcess == 1 )
		prevProcess := "fOyj9b4f79YmA7sZRBrnDbp75dGhiauj" ; Nothing
	if ( processName == prevProcess )
		return mode
	prevProcess := processName
	mode := _SendU_GetMode( processName )
	if ( mode == "" )
		mode = i
	return mode
}

; http://www.autohotkey.com/forum/topic17838.html
_SendU_SetMode( sKey, sItm )
{
	static pdic := 0
	if ( pdic == 0 )
		_SendU_Get_Dictionary( pdic )
	pKey := SysAllocString(sKey)
	VarSetCapacity(var1, 8 * 2, 0)
	EncodeInteger(&var1 + 0, 8)
	EncodeInteger(&var1 + 8, pKey)
	pItm := SysAllocString(sItm)
	VarSetCapacity(var2, 8 * 2, 0)
	EncodeInteger(&var2 + 0, 8)
	EncodeInteger(&var2 + 8, pItm)
	DllCall(VTable(pdic, 8), "Uint", pdic, "Uint", &var1, "Uint", &var2)
	SysFreeString(pKey)
	SysFreeString(pItm)
}

; http://www.autohotkey.com/forum/topic17838.html
_SendU_GetMode( sKey )
{
	static pdic := 0
	if ( pdic == 0 )
		_SendU_Get_Dictionary( pdic )

	pKey := SysAllocString(sKey)
	VarSetCapacity(var1, 8 * 2, 0)
	EncodeInteger(&var1 + 0, 8)
	EncodeInteger(&var1 + 8, pKey)
	DllCall(VTable(pdic, 12), "Uint", pdic, "Uint", &var1, "intP", bExist)
	If bExist
	{
		VarSetCapacity(var2, 8 * 2, 0)
		DllCall(VTable(pdic, 9), "Uint", pdic, "Uint", &var1, "Uint", &var2)
		pItm := DecodeInteger(&var2 + 8)
		Unicode2Ansi(pItm, sItm)
		SysFreeString(pItm)
	}
	SysFreeString(pKey)
	Return sItm
}

_SendU_Get_Dictionary( ByRef mypdic )
{
	static pdic := 0
	if ( pdic == 0 ) {
		; http://www.autohotkey.com/forum/topic17838.html
		CoInitialize()
		CLSID_Dictionary := "{EE09B103-97E0-11CF-978F-00A02463E06F}"
		IID_IDictionary := "{42C642C1-97E1-11CF-978F-00A02463E06F}"
		pdic := CreateObject(CLSID_Dictionary, IID_IDictionary)
		DllCall(VTable(pdic, 18), "Uint", pdic, "int", 1) ; Set text mode, i.e., Case of Key is ignored. Otherwise case-sensitive defaultly.
	}
	mypdic := pdic
}

_SendU_Load_Dynamic_Modes()
{
	_SendU_SetMode( "totalcmd.exe", "c" )
	_SendU_SetMode( "skype.exe", "c" )
}

; --------------------- other functions ----------------------------

_SendU_SetVar( var, value )
{
	global
	_SendU_%var% := value
}

_SendU_GetVar( var )
{
	global
	return _SendU_%var% . ""
}

_SendU_Default_Value( var, value )
{
	global
	if ( _SendU_%var% . "" == "" )
		_SendU_%var% := value
}

_SendU_Load_Locale()
{
	stringLower, lang, A_Language
	if ( lang == "040e" ) { ; Hungarian
		_SendU_Default_Value("DYNAMIC_MODE_TOOLTIP", "Új mód a(z) $processName$ programhoz`n($title$)`n ""$mode$"" ($modeName$ - $modeType$)")
		
		_SendU_Default_Value("Mode_Name_i", "SendInput")
		_SendU_Default_Value("Mode_Name_c", "Vágólap")
		_SendU_Default_Value("Mode_Name_r", "Vágólap helyreállítással")
		_SendU_Default_Value("Mode_Name_a", "Alt+Számbillentyûzet")
		_SendU_Default_Value("Mode_Name_d", "Dinamikus")
		_SendU_Default_Value("Mode_Name_0", "Ismeretlen")
		
		_SendU_Default_Value("Mode_Type_i", "a legjobb, ha mûködik")
		_SendU_Default_Value("Mode_Type_c", "törli a vágólapot")
		_SendU_Default_Value("Mode_Type_r", "talán lassú")
		_SendU_Default_Value("Mode_Type_a", "talán nem mûködik")
		_SendU_Default_Value("Mode_Type_d", "programoktól függõ dinamikus mód")
		_SendU_Default_Value("Mode_Type_0", "ismeretlen mód")
	} else { ; English -- please, correct my mispellings!
		_SendU_Default_Value("DYNAMIC_MODE_TOOLTIP", "New mode for $processName$`n($title$)`nis ""$mode$"" ($modeName$ - $modeType$)")
		
		_SendU_Default_Value("Mode_Name_i", "SendInput")
		_SendU_Default_Value("Mode_Name_c", "Clipboard")
		_SendU_Default_Value("Mode_Name_r", "Restore Clipboard")
		_SendU_Default_Value("Mode_Name_a", "Alt+Numbers")
		_SendU_Default_Value("Mode_Name_d", "Dynamic")
		_SendU_Default_Value("Mode_Name_0", "Unknown")
		
		_SendU_Default_Value("Mode_Type_i", "the best, if works")
		_SendU_Default_Value("Mode_Type_c", "clears the clipboard")
		_SendU_Default_Value("Mode_Type_r", "maybe slow")
		_SendU_Default_Value("Mode_Type_a", "maybe not work")
		_SendU_Default_Value("Mode_Type_d", "dynamic mode for the programs")
		_SendU_Default_Value("Mode_Type_0", "unknown mode")
	}
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LABELS AND INCLUDES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

__SendU_Labels_And_Includes__This_Is_Not_A_Function()
{
	return
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; LABELS for internal use
	
	_SendU_Remove_Tooltip:
		SetTimer, _SendU_Remove_Tooltip, Off
		ToolTip
	return

	_SendU_Restore_Clipboard:
		Critical
		if ( _SendU_Last_Char_In_Clipboard() == Clipboard )
			_SendU_RestoreClipboard()
		_SendU_Last_Char_In_Clipboard( "" )
		Critical, Off
	return

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; LABELS for public use
	
	_SendU_Try_Dynamic_Mode:
	_SendU_Change_Dynamic_Mode:
		SendU_Try_Dynamic_Mode()
	return

	_SendU_Toggle_Clipboard_Restore_Mode:
		SendU_Clipboard_Restore_Mode( 2 )
		_SendU_Dynamic_Mode_Tooltip()
	return

}

#include CoHelper.ahk

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; END OF SENDU MODULE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
