#NoEnv
#Persistent
#NoTrayIcon
#InstallKeybdHook
#SingleInstance force
#MaxThreadsBuffer
#MaxThreadsPerHotkey  3
#MaxHotkeysPerInterval 300
#MaxThreads 20

setPklInfo( "version", "0.3" )
setPklInfo( "compiled", "2008.09.01." )

SendMode Event
SetBatchLines, -1
Process, Priority, , H
Process, Priority, , R
SetWorkingDir, %A_ScriptDir%

; Global variables
CurrentDeadKeys = 0 ; How many dead key were pressed
CurrentBaseKey  = 0 ; Current base key :)

t = %1% ; Layout from command line parameter
pkl_init( t )
pkl_activate()
return

; ####################### labels #######################

exitApp:
	exitApp
return

detectDeadKeysInCurrentLayout:
	setDeadKeysInCurrentLayout( detectDeadKeysInCurrentLayout() )
return

processKeyPress0:
processKeyPress1:
processKeyPress2:
processKeyPress3:
processKeyPress4:
processKeyPress5:
processKeyPress6:
processKeyPress7:
processKeyPress8:
processKeyPress9:
processKeyPress10:
processKeyPress11:
processKeyPress12:
processKeyPress13:
processKeyPress14:
processKeyPress15:
processKeyPress16:
processKeyPress17:
processKeyPress18:
processKeyPress19:
processKeyPress20:
processKeyPress21:
processKeyPress22:
processKeyPress23:
processKeyPress24:
processKeyPress25:
processKeyPress26:
processKeyPress27:
processKeyPress28:
processKeyPress29:
	runKeyPress()
return

keyPressedwoStar: ; SC025
	activity_ping()
	Critical
	ThisHotkey := A_ThisHotkey
	processKeyPress( ThisHotkey )
return

keyPressed: ; *SC025
	activity_ping()
	Critical
	ThisHotkey := substr( A_ThisHotkey, 2 )
	processKeyPress( ThisHotkey )
return

upToDownKeyPress: ; *SC025 UP
	activity_ping()
	Critical
	ThisHotkey := A_ThisHotkey
	ThisHotkey := substr( ThisHotkey, 2 )
	ThisHotkey := substr( ThisHotkey, 1, -3 )
	processKeyPress( ThisHotkey )
return

modifierDown:  ; *SC025
	activity_ping()
	Critical
	ThisHotkey := substr( A_ThisHotkey, 2 )
	setModifierState( getLayoutItem( ThisHotkey . "v" ), 1 )
return

modifierUp: ; *SC025 UP
	activity_ping()
	Critical
	ThisHotkey := A_ThisHotkey
	ThisHotkey := substr( ThisHotkey, 2 )
	ThisHotkey := substr( ThisHotkey, 1, -3 )
	setModifierState( getLayoutItem( ThisHotkey . "v" ), 0 )
return

ShowAbout:
	pkl_about()
return

displayHelpImage:
	pkl_displayHelpImage()
return

displayHelpImageToggle:
	pkl_displayHelpImage( 2 )
return

changeTheActiveLayout:
	changeLayout( getLayoutInfo( "nextLayout" ) )
return

changeLayoutMenu:
	changeLayout( getLayoutInfo( "layout" . A_ThisMenuItemPos . "code" ) )
return

doNothing:
return

ToggleSuspend:
	Suspend
	if ( A_IsSuspended ) {
		pkl_displayHelpImage( 3 )
		Menu, tray, Icon, % getTrayIconInfo( "FileOff" ), % getTrayIconInfo( "NumOff" )
	} else {
		activity_ping( 1 )
		activity_ping( 2 )
		pkl_displayHelpImage( 4 )
		Menu, tray, Icon, % getTrayIconInfo( "FileOn" ), % getTrayIconInfo( "NumOn" )
	}
return


; ####################### functions #######################

#Include pkl_deadkey.ahk
#Include pkl_getset.ahk
#Include pkl_gui.ahk
#Include pkl_init.ahk
#Include pkl_keypress.ahk
#Include pkl_locale.ahk
#Include pkl_send.ahk
#Include pkl_activity.ahk

; ####################### (external) modules #######################

#Include HexUC.ahk ; Written by Laszlo Hars
#Include MI.ahk ; http://www.autohotkey.com/forum/viewtopic.php?t=21991
#Include Ini.ahk ; http://www.autohotkey.net/~majkinetor/Ini/Ini.ahk
#Include SendU.ahk
#Include getGlobal.ahk
#Include HashTable.ahk
#Include iniReadBoolean.ahk
#Include detectDeadKeysInCurrentLayout.ahk
#Include virtualKeyCodeFromName.ahk
#Include getDeadKeysOfSystemsActiveLayout.ahk
#Include getLanguageStringFromDigits.ahk ; http://www.autohotkey.com/docs/misc/Languages.htm
