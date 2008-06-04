/*
------------------------------------------------------------------------

HashTable (Associative array) module
http://www.autohotkey.com

------------------------------------------------------------------------

Version: 0.0.1 2008-05
License: GNU General Public License
Author: FARKAS, Mate

A simple implementation of HashTable, using global vars

------------------------------------------------------------------------
*/

HashTable_Set( pdic, sKey, sItm )
{
	global
	[%pdic%]%sKey% := sItm
}

HashTable_Get( pdic, sKey )
{
	global
	return [%pdic%]%sKey% . ""
}

HashTable_New()
{
	static count := 0
	return ++count
}
