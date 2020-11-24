; getWinfo - window information tool
; gathers title, process Id, handle, class, size, positon and controls information
; in a menu that you can click to get the item in your clipboard

getWinfo() {
	tt("getting Winfo ...", 1)
	Sleep, 50
	global getWinfoID
	WinGet, getWinfoID, ID, A
	WinGetTitle, this_title, ahk_id %getWinfoID%
	WinGetClass, this_class, ahk_id %getWinfoID%
	WinGet, thisPID, PID, ahk_id %getWinfoID%
	WinGet, this_process, ProcessName, ahk_id %getWinfoID%
    WinGet, this_path, ProcessPath, ahk_id %getWinfoID%
	FileGetVersion, this_ver, %this_path%

	Menu, wInfoMenu, Add, title: %this_title%, getWinfoMenuHandler
	Menu, wInfoMenu, Add, class: %this_class%, getWinfoMenuHandler
	Menu, wInfoMenu, Add, hwnd: %getWinfoID%, getWinfoMenuHandler
	Menu, wInfoMenu, Add, pid: %thisPID%, getWinfoMenuHandler
	Menu, wInfoMenu, Add, process: %this_process%, getWinfoMenuHandler
	Menu, wInfoMenu, Add, version: %this_ver%, getWinfoMenuHandler
    Menu, wInfoMenu, Add, path: %this_path%, getWinfoMenuHandler
	Menu, wInfoMenu, Add, Explore to path, getWinfoGotoPath

	ctrlList := getWinfoCtrls()
	if (ctrlList.MaxIndex()) {
		numCtrls := ctrlList.MaxIndex()
		Menu, wInfoMenu, Add, Controls: %numCtrls% ( click to show ... ), getWinfoCtrlsHandler
        Menu, wInfoMenu, Add, Copy All Control Info, getWinfoCopyCtrlsHandler
	}
	else {
		Menu, wInfoMenu, Add, No Controls Here, getWinfoMenuHandler
		Menu, wInfoMenu, Disable, No Controls Here
	}

	window_get_rect(X, Y, Width, Height, getWinfoID)
	CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
	Menu, wInfoPosMenu, Add, x: %X%, getWinfoMenuHandler
	Menu, wInfoPosMenu, Add, y: %Y%, getWinfoMenuHandler
	Menu, wInfoPosMenu, Add, w: %Width%, getWinfoMenuHandler
	Menu, wInfoPosMenu, Add, h: %Height%, getWinfoMenuHandler
    Menu, wInfoPosMenu, Add, x|y|w|h: %x%|%y%|%Width%|%Height%, getWinfoMenuHandler
	Menu, wInfoPosMenu, Add, SetToCursor, getWinfoSetToCursor
    Menu, wInfoPosMenu, Add, MousePos: %mouseX%`,%mouseY%, getWinfoMenuHandler

	Menu, wInfoMenu, Add, Pos:  %X% x %Y%   Size:  %Width% x %Height%  ..., :wInfoPosMenu
	Menu, wInfoMenu, Add, Cancel, getWinfoMenuHandler

	CoordMode, Menu, Screen
	menu_x := mouseX + 15
	menu_y := mouseY + 47
	Menu, wInfoMenu, Show, %menu_x%, %menu_y%
	; cleanup
	Menu, wInfoMenu, DeleteAll
	Menu, wInfoPosMenu, DeleteAll
	tt()
}

; standard handler gets the menu item, cuts away the name, puts it to the clipboard
getWinfoMenuHandler:
	getWinfoID := A_ThisMenuItem
	if (getWinfoID == "Cancel")
		Return
	StringGetPos, iTmp, getWinfoID, %A_Space%
	StringTrimLeft, getWinfoID, getWinfoID, (iTmp + 1)
	Clipboard := getWinfoID
	tt( getWinfoID, 0.5 )
return

; to recover lost windows
getWinfoSetToCursor:
	CoordMode, Mouse, Screen
	MouseGetPos, mousex, mousey
	tt( getWinfoID " to " mousex "x" mousey,2)
	;position the windowtitle under the cursor so one can move it instantly:
	WinActivate, ahk_id %getWinfoID%
	WinWait, ahk_id %getWinfoID%
	WinMove, ahk_id %getWinfoID%,,(mousex - 30), (mousey - 10)
return

; returns the current windows control names in an array
getWinfoCtrls() {
	global getWinfoID
	WinGet, thisControlList, ControlList, ahk_id %getWinfoID%
	ctrlList := []
	Loop, Parse, thisControlList, `n
		ctrlList.insert(A_LoopField)
	return ctrlList
}

; displays the windows controls and details in a menu
getWinfoCtrlsHandler:
	getWinfoCtrlsHandler(getWinfoID)
Return

getWinfoCtrlsHandler(getWinfoID) {
	ctrlList := getWinfoCtrls()
	menuList := []

	startTime := A_TickCount
	for i, ctrl in ctrlList {
		tookTime := A_TickCount - startTime
		if ( tookTime > 500 )
			if ( mod(i, 10) == 10 )
				tt( "gathering controls... " tookTime "`n" ctrl )

		menuName := "getWinfoCtrlMenu" i
		menuList.insert(menuName)
		ControlGet, thisCtrlID, Hwnd,, %ctrl%, ahk_id %getWinfoID%
		ControlGetText, thisCtrlText, %ctrl%, ahk_id %getWinfoID%
		StringLeft, thisCtrlText, thisCtrlText, 250

		Menu, %menuName%, Add, name: %ctrl%, getWinfoMenuHandler
		Menu, %menuName%, Add, hwnd: %thisCtrlID%, getWinfoMenuHandler
		Menu, %menuName%, Add, text: %thisCtrlText%, getWinfoMenuHandler

		Menu, ctrlSubmenu, Add, %i%: %ctrl%, :%menuName%
	}

	; Menu, wInfoMenu, Add, controls: %numCtrls%, :ctrlSubmenu
	Menu, ctrlSubmenu, Show

	Menu, ctrlSubmenu, DeleteAll
	Loop % menuList.maxIndex() {
		thisMenu := menuList[A_Index]
		Menu, %thisMenu%, DeleteAll
	}
}

getWinfoCopyCtrlsHandler:
    getWinfoCopyCtrlsHandler(getWinfoID)
Return

getWinfoCopyCtrlsHandler(getWinfoID) {
    ctrlList := getWinfoCtrls()

    texttmp := ""
	for i, ctrl in ctrlList {
		ControlGet, thisCtrlID, Hwnd,, %ctrl%, ahk_id %getWinfoID%
		ControlGetText, thisCtrlText, %ctrl%, ahk_id %getWinfoID%
		StringLeft, thisCtrlText, thisCtrlText, 250
        texttmp = %texttmp%%ctrl% %thisCtrlID% %thisCtrlText%`n
	}
    Clipboard := texttmp
}

getWinfoGotoPath() {
    global getWinfoID
    WinGet, this_path, ProcessPath, ahk_id %getWinfoID%
    cmd = explorer.exe /select, "%this_path%"
    Run, %cmd%
}
