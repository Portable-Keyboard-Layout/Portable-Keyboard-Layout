toggleCapsLock()
{
	if ( getKeyState("CapsLock", "T") )
	{
		SetCapsLockState, Off
	} else {
		SetCapsLockState, on
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
		if ( inStr( getDeadKeysInCurrentLayout(), chr(ch) ) )
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
	pkl_SendThis( modif . char )
}

pkl_SendThis( toSend )
{
	if ( getAltGrState() ) {
		setAltGrState( 0 )
		Send, %toSend%
		setAltGrState( 1 )
	} else {
		Send, %toSend%
	}
}

