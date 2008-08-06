setLayoutItem( key, value )
{
	return getLayoutItem( key, value, 1 )
}

getLayoutItem( key, value = "", set = 0 )
{
	static pdic := 0
	if ( pdic == 0 )
	{
		pdic := HashTable_New()
	}
	if ( set == 1 )
		HashTable_Set( pdic, key, value )
	else
		return HashTable_Get( pdic, key )
}

setTrayIconInfo( var, val )
{
	return getTrayIconInfo( var, val, 1 )
}

getTrayIconInfo( var, val = "", set = 0 )
{
	static FileOn := "on.ico"
	static NumOn := 1
	static FileOff := "off.ico"
	static NumOff := 1
	if ( set == 1 )
		%var% := val
	return  %var% . ""
}

setLayoutInfo( var, val )
{
	return getLayoutInfo( var, val, 1 )
}

getLayoutInfo( key, value = "", set = 0 )
{
	/*
	active    := "" ; The active layout
	dir       := "" ; The directory of the active layout
	hasAltGr  := 0  ; Did work Right alt as altGr in the layout?
	extendKey := "" ; With this you can use qwerty's ijkl as arrows, etc.
	
	nextLayout := "" ; If you set multiple layouts, this is the next one.
	                 ; see the "changeTheActiveLayout:" label!
	countOfLayouts := 0 ; Array size
	; See the layout setting in the ini file
	LayoutsXcode = layout code
	LayoutsXname = layout name
	*/
	static pdic := 0
	if ( pdic == 0 )
	{
		pdic := HashTable_New()
	}
	if ( set == 1 )
		HashTable_Set( pdic, key, value )
	else
		return HashTable_Get( pdic, key )
}

setPklInfo( key, value )
{
	getPklInfo( key, value, 1 )
}

getPklInfo( key, value = "", set = 0 )
{
	static pdic := 0
	if ( pdic == 0 )
	{
		pdic := HashTable_New()
	}
	if ( set == 1 )
		HashTable_Set( pdic, key, value )
	else
		return HashTable_Get( pdic, key )
}

setDeadKeysInCurrentLayout( deadkeys )
{
	getDeadKeysInCurrentLayout( deadkeys, 1 )
}

getDeadKeysInCurrentLayout( newDeadkeys = "", set = 0 )
{
	static deadkeys := 0
	if ( set == 1 ) {
		if ( newDeadkeys == "auto" )
			deadkeys := getDeadKeysOfSystemsActiveLayout()
		else if ( newDeadkeys == "dynamic" )
			deadkeys := 0
		else
			deadkeys := newDeadkeys
		return
	}
	if ( deadkeys == 0 ) 
		return getDeadKeysOfSystemsActiveLayout()
	else
		return deadkeys
}

