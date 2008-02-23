#NoEnv
#Persistent
#NoTrayIcon
#InstallKeybdHook
#SingleInstance force
#MaxHotkeysPerInterval 300

pkl_version = 0.2
pkl_compiled = 2008.02.23.

SendMode Event
SetBatchLines, -1
Process, Priority, , R
SetWorkingDir, %A_ScriptDir%

layoutDir   = ; The directory of the layout
hasAltGr    = 0 ; Did work Right alt as altGr in the layout?
extendKey = "" ; With this you can use ijkl as arrows, etc.
CurrentDeadKeys = 0 ; How many dead key were pressed
CurrentBaseKey  = 0 ; Current base key :)

pkl_init() ; I would like use local variables
return



; ##################################### functions #####################################

pkl_init()
{

	if ( !FileExist("pkl.ini") ) {
		msgBox, pkl.ini file NOT FOUND`nSorry. The program will exit.
		ExitApp
	}
	
	IniRead, t, pkl.ini, pkl, compactMode, 0
	if ( t == 1 || t == "true" || t == "yes" )
		compact_mode = 1
	else
		compact_mode = 0
	
	IniRead, t, pkl.ini, pkl, language, auto
	if ( t == "auto" )
		t := getLanguageStringFromDigits( A_Language )
	pkl_locale_load( t, compact_mode )

	IniRead, t, pkl.ini, pkl, exitApp, %A_Space%
	if ( t <> "" )
		Hotkey, %t%, ExitApp
	
	IniRead, t, pkl.ini, pkl, systemsdeadkeys, %A_Space%
	setGlobal("DeadKeysInCurrentLayout", t)

	SendU_Init()
	IniRead, t, pkl.ini, pkl, changeDynamicMode, 0
	if ( t )
		Hotkey, %t%, _SendU_Change_Dynamic_Mode
	IniRead, t, pkl.ini, pkl, SendUClipboardRestoreMode, 1
		SendU_Clipboard_Restore_Mode( t )

	IniRead, Layout, pkl.ini, pkl, layout, %A_Space%
	if ( Layout == "" ) {
		pkl_MsgBox( 1 )
		ExitApp
	} 
	if ( compact_mode ) {
		LayoutFile = layout.ini
		setGlobal( "layoutDir", "." )
	} else {
		LayoutFile := "layouts\" . Layout . "\layout.ini"
		if (not FileExist(LayoutFile)) {
			pkl_MsgBox( 2, LayoutFile )
			ExitApp
		}
		setGlobal( "layoutDir", "layouts\" . Layout )
	}
	IniRead, ShiftStates, %LayoutFile%, global, shiftstates, 0:1
	ShiftStates = %ShiftStates%:8:9 ; SgCap, SgCap + Shift
	StringSplit, ShiftStates, ShiftStates, :
	IfInString, ShiftStates, 6
		setGlobal( "hasAltGr", 1)
	else
		setGlobal( "hasAltGr", 0)
	IniRead, extendKey, %LayoutFile%, global, extend_key, %A_Space%
	if ( extendKey <> "" ) {
		setGlobal( "extendKey", extendKey )
	}

	remap := Ini_LoadSection( LayoutFile, "layout" )
	Loop, parse, remap, `r`n
	{
		pos := InStr( A_LoopField, "=" )
		key := subStr( A_LoopField, 1, pos-1 )
		parts := subStr(A_LoopField, pos+1 )
		StringSplit, parts, parts, %A_Tab%
		StringLower, parts2, parts2
		if ( parts2 == "virtualkey" || parts2 == "vk")
			parts2 = -1
		else if ( parts2 == "modifier" )
			parts2 = -2
		setGlobal( key . "v", virtualKeyCodeFromName(parts1) ) ; virtual key
		setGlobal( key . "c", parts2 ) ; caps state
		if ( parts2 == -2 ) {
			Hotkeys_Add( "*" . key, "modifierDown" )
			Hotkeys_Add( "*" . key " Up", "modifierUp" )
			setGlobal( key . "v", parts1 )
		} else if ( key == extendKey ) {
			Hotkeys_Add( "*" . key " Up", "upToDownKeyPress" )
		} else {
			Hotkeys_Add( "*" . key, "keyPressed" )
		}
		Loop, % parts0 - 3 {
			k = ShiftStates%A_Index%
			k := %k%
			
			v := A_Index + 2
			v = parts%v%
			v := %v%
			if ( StrLen( v ) == 0 ) {
				v = -- ; Disabled
			} else if ( StrLen( v ) == 1 ) {
				v := asc( v )
			} else {
				if ( SubStr(v,1,1) == "*" ) { ; Special chars
					setGlobal( key . k . "s", SubStr(v,2) )
					v := "*"
				} else if ( SubStr(v,1,1) == "=" ) { ; Special chars with {Blind}
					setGlobal( key . k . "s", SubStr(v,2) )
					v := "="
				} else if ( SubStr(v,1,1) == "%" ) { ; Ligature (with unicode chars, too)
					setGlobal( key . k . "s", SubStr(v,2) )
					v := "%"
				} else if ( v == "--" ) {
					v = -- ;) Disabled
				} else if ( substr(v,1,2) == "dk" ) {
					v := "-" . substr(v,3)
					v += 0
				} else {
					Loop, parse, v
					{
						if ( A_Index == 1 ) {
							ligature = 0
						} else if ( asc( A_LoopField ) < 128 ) {
							ligature = 1
							break
						}
					}
					if ( ligature ) { ; Ligature
						setGlobal( key . k . "s", v )
						v := "%"
					} else { ; One character
						v := "0x" . HexUC( v )
						v += 0
					}
				}
			}
			if ( v != "--" )
				setGlobal( key . k , v )
		}
	}

	if ( extendKey )
	{
		remap := Ini_LoadSection( "pkl.ini", "extend" )
		Loop, parse, remap, `r`n
		{
			pos := InStr( A_LoopField, "=" )
			key := subStr( A_LoopField, 1, pos-1 )
			parts := subStr(A_LoopField, pos+1 )
			setGlobal( key . "e", parts )
		}
		remap := Ini_LoadSection( LayoutFile, "extend" )
		Loop, parse, remap, `r`n
		{
			pos := InStr( A_LoopField, "=" )
			key := subStr( A_LoopField, 1, pos-1 )
			parts := subStr(A_LoopField, pos+1 )
			setGlobal( key . "e", parts )
		}
	}
	Hotkeys_Set_All()
	if ( getGlobal( "LAltc" ) <> "" || getGlobal( "SC038c" ) <> "" ) {
		Hotkey, LAlt & RCtrl, Off
		setGlobal("pkl_SuspendHotkey", pkl_locale_string(17) )
	} else {
		setGlobal("pkl_SuspendHotkey", pkl_locale_string(16) )
	}


	pkl_set_tray_menu()
	IniRead, t, pkl.ini, pkl, displayHelpImage, 1
	if ( t )
		pkl_displayHelpImage( 1 )

}

pkl_set_tray_menu()
{
	about := pkl_locale_string(9)
	susp := pkl_locale_string(10) . " (" . getGlobal("pkl_SuspendHotkey") . ")"
	exit := pkl_locale_string(11)
	deadk := pkl_locale_string(12)
	helpimage := pkl_locale_string(15)

	if ( A_IsCompiled )
		Menu, tray, NoStandard
	else
		Menu, tray, add, 
	Menu, Tray, Icon,,, 1 ; Freeze the icon
	Menu, tray, add, %about%, ShowAbout
	Menu, tray, add, %susp%, toggleSuspend
	Menu, tray, add, %deadk%, detectDeadKeysInCurrentLayout
	Menu, tray, add, %helpimage%, displayHelpImageToggle
	Menu, tray, add, %exit%, exitApp
	Menu, tray, Default , %susp%
	Menu, Tray, Click, 1 
	
	if ( A_IsCompiled )
		Menu, tray, Icon, %A_ScriptName%, 6
	else
		Menu, tray, Icon, on.ico
}

pkl_about()
{
	lfile := getGlobal( "layoutDir" ) . "\layout.ini"
	pklVersion := getGlobal( "pkl_version" )
	compiledAt := getGlobal( "pkl_compiled" )

	unknown := pkl_locale_string(3)
	active_layout := pkl_locale_string(4)
	version := pkl_locale_string(5)
	language := pkl_locale_string(6)
	copyright := pkl_locale_string(7)
	company := pkl_locale_string(8)
	license := pkl_locale_string(13)
	infos := pkl_locale_string(14)
	
	IniRead, lname, %lfile%, informations, layoutname, %unknown%
	IniRead, lver, %lfile%, informations, version, %unknown%
	IniRead, lcode, %lfile%, informations, layoutcode, %unknown%
	IniRead, lcopy, %lfile%, informations, copyright, %unknown%
	IniRead, lcomp, %lfile%, informations, company, %unknown%
	IniRead, llocale, %lfile%, informations, localeid, 0409
	IniRead, lwebsite, %lfile%, informations, homepage, %A_Space%
	llang := getLanguageStringFromDigits( llocale )

	Gui, Add, Text, , Portable Keyboard Layout v%pklVersion% (%compiledAt%)
	Gui, Add, Edit, , http://pkl.soureforde.net/
	Gui, Add, Text, , ......................................................................
	Gui, Add, Text, , (c) FARKAS, Mate, 2007-2008
	Gui, Add, Text, , %license%
	Gui, Add, Text, , %infos%
	Gui, Add, Edit, , http://www.gnu.org/licenses/gpl-3.0.txt
	Gui, Add, Text, , ......................................................................
	Gui, Add, Text, , %ACTIVE_LAYOUT%:
	Gui, Add, Text, , %lname%
	Gui, Add, Text, , %version%: %lver%
	Gui, Add, Text, , %language%: %llang%
	Gui, Add, Text, , %copyright%: %lcopy%
	Gui, Add, Text, , %company%: %lcomp%
	Gui, Add, Edit, , %lwebsite%
	Gui, Add, Text, , ......................................................................
	Gui, Show
}

keyPressed( HK )
{
	Critical, Off
	static extendKeyStroke := 0
	static extendKey := "--"
	modif = ; modifiers to send
	state = 0
	if ( extendKey == "--" )
		extendKey := getGlobal( "extendKey" )
	cap := getGlobal( HK . "c" )
	
	if ( extendKey && getKeyState( extendKey, "P" ) ) {
		extendKeyStroke = 1
		extendKeyPressed( HK )
		return
	} else if ( HK == extendKey && extendKeyStroke ) {
		extendKeyStroke = 0
		Send {RShift Up}{LCtrl Up}{LAlt Up}{LWin Up}
		return
	} else if ( cap == -1 ) {
		t := getGlobal( HK . "v" )
		t = {VK%t%}
		Send {Blind}%t%
		return
	}
	extendKeyStroke = 0
	if ( getGlobal("hasAltGr") ) {
		if ( getKeyState("RAlt") ) {  ; AltGr
			sh := getKeyState("Shift")
			if ( (cap & 4) && getKeyState("CapsLock", "T") )
				sh := 1 - sh
			state := 6 + sh
		} else { ; Not AltGr
			if ( getKeyState("LAlt")) {
				modif .= "!"
				if ( getKeyState("RCtrl"))
					modif .= "^"
				state := pkl_ShiftState( cap )
			} else { ; not Alt
				pkl_CtrlState( HK, cap, state, modif )
			}
		}
	} else {
		if ( getKeyState("Alt")) {
			modif .= "!"
			if ( getKeyState("RCtrl") || ( getKeyState("LCtrl") && !getKeyState("RAlt") ) )
				modif .= "^"
			state := pkl_ShiftState( cap )
		} else { ; not Alt
			pkl_CtrlState( HK, cap, state, modif )
		}
	}
	if ( getKeyState("LWin") || getKeyState("RWin") )
		modif .= "#"


	ch := getGlobal( HK . state )
	if ( ch == 32 && HK == "SC039" ) {
		Send, {Blind}{Space}
	} else if ( ( ch + 0 ) > 0 ) {
		pkl_Send( ch, modif )
	} else if ( ch == "*" || ch == "="  ) {
		; Special
		if ( ch == "=" )
			modif = {Blind}
		else
			modif := ""
		
		ch := getGlobal( HK . state . "s" )
		if ( ch == "{CapsLock}" ) {
			toggleCapsLock()
		} else {
			toSend = ;
			if ( ch != "" ) {
				toSend = %modif%%ch%
			} else {
				ch := getGlobal( HK . "0s" )
				if ( ch != "" )
					ToSend = %modif%%ch%
			}
			if ( getGlobal("ModifierRAltIsDown") )
				toSend = {RAlt Up}%toSend%{RAlt Down}
			Send, %toSend%
		}
	} else if ( ch == "%" ) {
		SendU_utf8_string( getGlobal( HK . state . "s" ) )
	} else if ( ch < 0 ) {
		DeadKey( -1 * ch )
	}
}

extendKeyPressed( HK )
{
	static shiftPressed := ""
	static ctrlPressed := ""
	static altPressed := ""
	static winPressed := ""

	ch := getGlobal( HK . "e" )
	if ( ch == "") {
		return
	} else if ( ch == "Shift" ) {
		shiftPressed := HK
		Send {RShift Down}
		return
	} else if ( ch == "Ctrl" ) {
		ctrlPressed := HK
		Send {LCtrl Down}
		return
	} else if ( ch == "Alt" ) {
		altPressed := HK
		Send {LAlt Down}
		return
	} else if ( ch == "Win" ) {
		winPressed := HK
		Send {LWin Down}
		return
	}
	
	
	if ( SubStr( ch, 1, 1 ) == "!" ) {
		ch := SubStr( ch, 2 )
		SendInput, {RAW}%ch%
		return
	} else if ( SubStr( ch, 1, 1 ) == "*" ) {
		ch := SubStr( ch, 2 )
		SendInput, %ch%
		return
	}
	if ( ShiftPressed && !getKeyState( ShiftPressed, "P" ) ) {
		Send {RShift Up}
		ShiftPressed := ""
	}
	if ( CtrlPressed && !getKeyState( CtrlPressed, "P" ) ) {
		Send {LCtrl Up}
		CtrlPressed := ""
	}
	if ( AltPressed && !getKeyState( AltPressed, "P" ) ) {
		Send {LAlt Up}
		AltPressed := ""
	}
	if ( WinPressed && !getKeyState( WinPressed, "P" ) ) {
		Send {LWin Up}
		WinPressed := ""
	}
	if ( !altPressed && getKeyState( "RAlt", "P" ) ) {
		Send {LAlt Down}
		altPressed = RAlt
	}
	
	if ( ch == "WheelLeft" ) {
		ControlGetFocus, control, A
		Loop 5  ; Scroll Speed
			SendMessage, 0x114, 0, 0,  %control%, A ; 0x114 is WM_HSCROLL
		return
	} else if ( ch == "WheelRight" ) {
		ControlGetFocus, control, A
		Loop 5  ; Scroll Speed
			SendMessage, 0x114, 1, 0,  %control%, A ; 0x114 is WM_HSCROLL
		return
	} else {
		if ( ch == "Cut" ) {
			ch = +{Del}
		} else if ( ch == "Copy" ) {
			ch = ^{Ins}
		} else if ( ch == "Paste" ) {
			ch = +{Ins}
		} else {
			ch = {Blind}{%ch%}
		}
		Send %ch%
	}
}

toggleCapsLock()
{
	if ( getKeyState("CapsLock", "T") )
	{
		SetCapsLockState, off
	} else {
		SetCapsLockState, on
	}
}

DeadKeyValue( dk, base )
{
	static file := ""
	if ( file == "" )
		file := getGlobal( "layoutDir" ) . "\layout.ini"
	res := getGlobal( "DK" . dk . "_" . base )
	if ( res ) {
		if ( res == -1 ) 
			res = 0
		return res
	}
	IniRead, res, %file%, deadkey%dk%, %base%, -1`t;
	t := InStr( res, A_Tab )
	res := subStr( res, 1, t - 1 )
	setGlobal( "DK" . dk . "_" . base, res)
	if ( res == -1 ) 
		res = 0
	return res
}

DeadKey(DK)
{
	global CurrentDeadKeys 
	global CurrentBaseKey  
	global CurrentDeadKeyNum
	static PVDK := "" ; Pressed dead keys
	DeadKeyChar := DeadKeyValue( DK, 0)

	CurrentDeadKeyNum := DK
	CurrentDeadKeys++
	Input, nk, L1, {F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}
	IfInString, ErrorLevel, EndKey
	{
		endk := "{" . Substr(ErrorLevel,8) . "}" 
		CurrentDeadKeys = 0
		CurrentBaseKey = 0
		pkl_Send( DeadKeyChar )
		Send %endk%
		return
	}

	if ( CurrentDeadKeys == 0 ) {
		pkl_Send( DeadKeyChar )
		return
	}
	if ( CurrentBaseKey != 0 ) {
		hx := CurrentBaseKey
		nk := chr(hx)
	} else {
		hx := asc(nk)
	}
	CurrentDeadKeys--
	CurrentBaseKey = 0
	newkey := DeadKeyValue( DK, hx)

	if ( newkey && (newkey + 0) == "" ) {
		; New key (value) is a special string, like {Home}+{End}
		if ( PVDK ) {
			PVDK := ""
			CurrentDeadKeys = 0
		}
		SendInput %newkey%
	} else if ( newkey && PVDK == "" ) {
		pkl_Send( newkey )
	} else {
		if ( CurrentDeadKeys == 0 ) {
			pkl_Send( DeadKeyChar )
			if ( PVDK ) {
				StringTrimRight, PVDK, PVDK, 1
				StringSplit, DKS, PVDK, " "
				Loop %DKS0% {
					pkl_Send( DKS%A_Index% )
				}
				PVDK := ""
			}
		} else {
			PVDK := DeadKeyChar  . " " . PVDK
		}
		pkl_Send( hx )
	}
}

pkl_Send( ch, modif = "" )
{
	if ( getGlobal( "CurrentDeadKeys" ) > 0 ) {
		setGlobal( "CurrentBaseKey", ch )
		Send {Space}
		return
	} else if ( 32 < ch && ch < 128 ) {
		char := "{" . chr(ch) . "}"
		if ( inStr( getGlobal("DeadKeysInCurrentLayout"), chr(ch) ) )
			char .= "{Space}"
	} else if ( ch == 32 ) {
		char = {Space}
	} else if ( ch == 9 ) {
		char = {Tab}
	} else if ( ch > 0 && ch <= 26 ) {
		; http://en.wikipedia.org/wiki/Control_character#How_control_characters_map_to_keyboards
		char := "^" . chr( ch + 64 )
	} else if ( ch == 27 ) {
		char = ^{VKDB}
	} else if ( ch == 28 ) {
		char = ^{VKDC}
	} else if ( ch == 29 ) {
		char = ^{VKDD}
	} else {
		; Unicode
		sendU(ch)
		return
	}
	toSend = %modif%%char%
	if ( getGlobal("ModifierRAltIsDown") )
		toSend = {RAlt Up}%toSend%{RAlt Down}
	Send %toSend%
}

pkl_CtrlState( HK, capState, ByRef state, ByRef modif )
{
	if ( getKeyState("Ctrl")) {
		state = 2
		if ( getKeyState("Shift") ) {
			state++
			if ( !getGlobal( HK . state ) ) {
				state--
				modif .= "+"
				if ( !getGlobal( HK . state ) ) {
					state = 0
					modif .= "^"
				}
			}
		} else if ( !getGlobal( HK . state ) ) {
			state = 0
			modif .= "^"
		}
	} else {
		state := pkl_ShiftState( capState )
	}
}

pkl_ShiftState( capState )
{
	res = 0
	if ( capState == 8 ) {
		if ( getKeyState("CapsLock", "T") )
			res = 8
		if ( getKeyState("Shift") )
			res++
	} else {
		res := getKeyState("Shift")
		if ( (capState & 1) && getKeyState("CapsLock", "T") )
			res := 1 - res
	}
	return res
}


pkl_locale_default()
{
	m1 = You must set the layout file in pkl.ini!
	m2 = #s# file NOT FOUND`nSorry. The program will exit.
	m3 = unknown
	m4 = ACTIVE LAYOUT
	m5 = Version
	m6 = Language
	m7 = Copyright
	m8 = Company
	m9 = About...
	m10 = Suspend
	m11 = Exit
	m12 = Detect deadkeys
	m13 = License: GPL v3
	m14 = This program comes with`nABSOLUTELY NO WARRANTY`nThis is free software, and you`nare welcome to redistribute it`nunder certain conditions.
	m15 = Display help image
	m16 = Left Alt + Right Ctrl
	m17 = Scroll Lock + F12
	Loop, 17
	{
		setGlobal( "pkl_Locale_" . A_Index, m%A_Index% )
	}
}

pkl_locale_load( lang, compact = 0 )
{
	pkl_locale_default()
	if ( compact )
		file = %lang%.ini
	else 
		file = languages\%lang%.ini
	line := Ini_LoadSection( file, "pkl" )
	Loop, parse, line, `r`n
	{
		pos := InStr( A_LoopField, "=" )
		key := subStr( A_LoopField, 1, pos-1 )
		val := subStr(A_LoopField, pos+1 )
		StringReplace, val, val, \n, `n, A
		StringReplace, val, val, \\, \, A
		setGlobal( "pkl_Locale_" . key, val )
	}
	line := Ini_LoadSection( file, "SendU" )
	Loop, parse, line, `r`n
	{
		pos := InStr( A_LoopField, "=" )
		key := subStr( A_LoopField, 1, pos-1 )
		val := subStr(A_LoopField, pos+1 )
		StringReplace, val, val, \n, `n, A
		StringReplace, val, val, \\, \, A
		setGlobal( "_SendU_" . key, val )
	}
	line := Ini_LoadSection( file, "detectDeadKeys" )
	Loop, parse, line, `r`n
	{
		pos := InStr( A_LoopField, "=" )
		key := subStr( A_LoopField, 1, pos-1 )
		val := subStr(A_LoopField, pos+1 )
		StringReplace, val, val, \n, `n, A
		StringReplace, val, val, \\, \,
		setGlobal( "detectDeadKeys_locale_" . key, val )
	}
}

pkl_locale_string( msg, s = "", p = "", q = "", r = "" )
{
	m := getGlobal( "pkl_Locale_" . msg )
	if ( s <> "" )
		StringReplace, m, m, #s#, %s%, A
	if ( p <> "" )
		StringReplace, m, m, #p#, %p%, A
	if ( q <> "" )
		StringReplace, m, m, #q#, %q%, A
	if ( r <> "" )
		StringReplace, m, m, #r#, %r%, A
	return m
}

pkl_MsgBox( msg, s = "", p = "", q = "", r = "" )
{
	message := pkl_locale_string( msg, s, p, q, r )
	msgbox %message%
}

pkl_displayHelpImage( activate = 0 )
{
	static guiActive := 0
	static prevFile
	static HelperImage
	static displayOnTop := 1
	static yPosition := -1
	static layoutDir := "#"
	static hasAltGr
	static extendKey
	static imgWidth
	static imgHeight
	global CurrentDeadKeys 
	global CurrentDeadKeyNum

	
	if ( activate == 2 )
		activate := 1 - 2 * guiActive
	if ( activate == 1 ) {
		if ( layoutDir == "#" ) {
			layoutDir := getGlobal("layoutDir")
			hasAltGr := getGlobal("hasAltGr")
			extendKey  := getGlobal("extendKey")
			yPosition := A_ScreenHeight - 160
			IniRead, imgWidth, %LayoutDir%\layout.ini, global, img_width, 291
			IniRead, imgHeight, %LayoutDir%\layout.ini, global, img_height, 99
		}
		guiActive = 1
		Gui, 2:+AlwaysOnTop -Border +ToolWindow
		Gui, 2:margin, 0, 0
		Gui, 2:Add, Pic, xm vHelperImage
		GuiControl,2:, HelperImage, *w%width% *h%height% %layoutDir%\state0.png
		Gui, 2:Show, xCenter y%yPosition% AutoSize NA, pklHelperImage
		setTimer, displayHelpImage, 200
	} else if ( activate == -1 ) {
		setTimer, displayHelpImage, off
		guiActive = 0
		Gui, 2:Destroy
		return
	}
	if ( guiActive == 0 )
		return

	MouseGetPos, , , id
	WinGetTitle, title, ahk_id %id%
	if ( title == "pklHelperImage" ) {
		displayOnTop := 1 - displayOnTop
		if ( displayOnTop )
			yPosition := 5
		else
			yPosition := A_ScreenHeight - imgHeight - 60
		Gui, 2:Show, xCenter y%yPosition% AutoSize NA, pklHelperImage
	}
	
	fileName = state0
	if ( CurrentDeadKeys ) {
		fileName = deadkey%CurrentDeadKeyNum%
	} else if ( extendKey && getKeyState( extendKey, "P" ) ) {
		fileName = extend
	} else {
		state = 0
		state += 1 * getKeyState( "Shift" )
		state += 6 * ( hasAltGr * getKeyState( "RAlt" ) )
		fileName = state%state%
	}
	
	if ( prevFile == fileName )
		return
	prevFile := fileName 
	GuiControl,2:, HelperImage, *w%imgWidth% *h%imgHeight% %layoutDir%\%fileName%.png
}


; ##################################### labels #####################################

ShowAbout:
	pkl_about()
return

exitApp:
	exitApp
return

detectDeadKeysInCurrentLayout:
	detectDeadKeysInCurrentLayout()
return

keyPressedwoStar: ; SC025
	Critical
	ThisHotkey := A_ThisHotkey
	keyPressed( ThisHotkey )
return

keyPressed: ; *SC025
	Critical
	ThisHotkey := substr( A_ThisHotkey, 2 )
	keyPressed( ThisHotkey )
return

modifierDown:  ; *SC025
	Critical
	ThisHotkey := substr( A_ThisHotkey, 2 )
	t = % %ThisHotkey%v
	modifier%t%IsDown = 1
	Send {%t% Down}
return

modifierUp: ; *SC025 UP
	Critical
	ThisHotkey := A_ThisHotkey
	ThisHotkey := substr( ThisHotkey, 2 )
	ThisHotkey := substr( ThisHotkey, 1, -3 )
	t = % %ThisHotkey%v
	modifier%t%IsDown = 0
	Send {%t% Up}
return

upToDownKeyPress: ; *SC025 UP
	Critical
	ThisHotkey := A_ThisHotkey
	ThisHotkey := substr( ThisHotkey, 2 )
	ThisHotkey := substr( ThisHotkey, 1, -3 )
	keyPressed( ThisHotkey )
return

displayHelpImage:
	pkl_displayHelpImage()
return

displayHelpImageToggle:
	pkl_displayHelpImage(2)
return

; ##################################### END #####################################

LAlt & RCtrl::
ScrollLock & F12::
ToggleSuspend:
	Suspend
	if ( A_IsCompiled ) {
		if ( A_IsSuspended )
			Menu, tray, Icon, %A_ScriptName%, 3
		else
			Menu, tray, Icon, %A_ScriptName%, 6
	} else {
		if ( A_IsSuspended )
			Menu, tray, Icon, off.ico
		else
			Menu, tray, Icon, on.ico
	}
return


#Include %A_ScriptDir%\_includes
#Include HexUC.ahk ; Written by Laszlo hars
#Include Ini.ahk ; http://www.autohotkey.net/~majkinetor/Ini/Ini.ahk
#Include SendU.ahk ; http://autohotkey.try.hu/SendU/SendU.ahk
#Include Hotkeys.ahk ; http://autohotkey.try.hu/Hotkeys/Hotkeys.ahk
#Include getGlobal.ahk ; http://autohotkey.try.hu/getGlobal/getGlobal.ahk
#Include detectDeadKeysInCurrentLayout.ahk ; http://autohotkey.try.hu/detectDeadKeysInCurrentLayout/detectDeadKeysInCurrentLayout.ahk
#Include virtualKeyCodeFromName.ahk ; http://autohotkey.try.hu/virtualKeyCodeFromName/virtualKeyCodeFromName.ahk
#Include getLanguageStringFromDigits.ahk ; http://autohotkey.try.hu/getLanguageStringFromDigits/getLanguageStringFromDigits.ahk
