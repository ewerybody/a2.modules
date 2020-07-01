; ComfortResize - comfort_resize_main.ahk
; Port from ac'tivAid to a2
; author: eric
; created: 2019 4 19

comfort_resize_init() {
	global cr_CurDownCenter := IDC_SIZENS
	global cr_CurUpCenter := IDC_SIZENS
	global cr_CurCenterLeft := IDC_SIZEWE
	global cr_CurCenterRight := IDC_SIZEWE
	global cr_CurUpRight := IDC_SIZENESW
	global cr_CurDownLeft := IDC_SIZENESW
	global cr_CurDownRight := IDC_SIZENWSE
	global cr_CurUpLeft := IDC_SIZENWSE
	global cr_CurCenterCenter := IDC_SIZEALL
}

comfort_resize_main() {
    static cr_ClickTime

	; get mouse position relative to screen
	CoordMode, Mouse, Screen
	MouseGetPos, mouse_x, mouse_y, window_id
	WinGetClass, cr_actClass, ahk_id %window_id%

    double_click := _comfort_resize_get_doubleclick(mouse_x, mouse_y)
    ; remember the current mouse cursor
	current_cursor := A_Cursor

	if (cr_actClass = "Putty")
		SendMessage WM_ENTERSIZEMOVE, , , , ahk_id %window_id%

	SetBatchLines, 2000
	; Postion und Groesse des Fensters ermitteln
	WinGetPos, cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, ahk_id %window_id%
	; Fensterregion ermitteln. Die neun Regionen ergeben sich als
	; Horizontal x Vertikal = (left,center,right)x(up,center,down)
	If (mouse_x < cr_WinX1 + cr_WinW / 4)
        cr_WinHor := "Left"
	Else If (mouse_x < cr_WinX1 + 3 * cr_WinW / 4)
        cr_WinHor := "Center"
	Else
        cr_WinHor := "Right"

	If (mouse_y < cr_WinY1 + cr_WinH / 4)
		cr_WinVer := "Up"
	Else If (mouse_y < cr_WinY1 + 3 * cr_WinH / 4)
		cr_WinVer := "Center"
	Else
		cr_WinVer := "Down"

	If ( (!(window_is_resizable(window_id)) AND cr_ResizeFixedWindows = 0) OR cr_AlwaysMoveNonActive = 1 AND !WinActive("ahk_id " window_id))
	{
		cr_Resizeable = 0
		cr_WinHor := "Center"
		cr_WinVer := "Center"
	}
	Else
		cr_Resizeable = 1

    if (cr_WinHor = "Center" and cr_WinVer = "Center")
        is_center := true
    else
        is_center := false

	cr_DistanceX := 0
	cr_DistanceY := 0

    work_area := new screen_workarea(screen_get_index("A"))

	Loop
	{
		GetKeyState, cr_Button, RButton, P
		IfInString, A_ThisHotkey, MButton
			GetKeyState, cr_Button, MButton, P
		IfInString, A_ThisHotkey, LButton
			GetKeyState, cr_Button, LButton, P

		GetKeyState, cr_LButton, LButton, P

		; as long as button is pressed [D]own
		If cr_Button = D
		{
			If cr_MouseKey = 9 AND cr_LButton <> D
                continue

            ; aktuelle Mausposition bestimmen
            MouseGetPos, cr_X2, cr_Y2
            cr_X3 = %cr_X2%
            cr_Y3 = %cr_Y2%
            ; aktuelle Fenstergroesse und -position bestimmen
            WinGetPos, cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, ahk_id %window_id%
            cr_WinX2 := cr_WinX1 + cr_WinW
            cr_WinY2 := cr_WinY1+cr_WinH

            ; Raster
            GetKeyState, cr_ShiftState, Shift, P
            GetKeyState, cr_CtrlState, Ctrl, P
            If ( (cr_ShiftState = "D" AND cr_RasterAlways = 0) OR (cr_ShiftState = "U" AND cr_RasterAlways = 1) )
            {
                cr_RasterXtmp = %cr_RasterX%
                cr_RasterYtmp = %cr_RasterY%
                StringReplace, cr_RasterXtmp, cr_RasterXtmp, `:, /
                StringReplace, cr_RasterYtmp, cr_RasterYtmp, `:, /
                IfInString cr_RasterXtmp, /
                {
                    StringSplit, cr_RasterXtmp, cr_RasterXtmp, /
                    cr_RasterXtmp := Round(work_area.width * cr_RasterXtmp1 / cr_RasterXtmp2)
                }
                IfInString cr_RasterYtmp, /
                {
                    StringSplit, cr_RasterYtmp, cr_RasterYtmp, /
                    cr_RasterYtmp := Round(work_area.height * cr_RasterYtmp1 / cr_RasterYtmp2)
                }

                cr_X2 := Round(cr_X2 / cr_RasterXtmp) * cr_RasterXtmp
                cr_Y2 := Round(cr_Y2 / cr_RasterYtmp) * cr_RasterYtmp
            }

            ; Verschiebung der Maus innerhalb dieser Schleife ermitteln
            cr_OffsetX := cr_X3 - mouse_x
            cr_OffsetY := cr_Y3 - mouse_y

            cr_DistanceX := cr_DistanceX + cr_OffsetX
            cr_DistanceY := cr_DistanceY + cr_OffsetY

            If (Abs(cr_DistanceX) < 4 AND Abs(cr_DistanceY) < 4 AND double_click = 0)
            {
                mouse_x := cr_X3
                mouse_y := cr_Y3
                continue
            }

            ; Mauspfeil anpassen
            If cr_hCurs =
            {
                cr_hCurs := DllCall("LoadCursor", "UInt", NULL, "Int", cr_Cur%cr_WinVer%%cr_WinHor%)
                If current_cursor = IBEAM
                    DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_IBEAM)
                Else
                    DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_ARROW)
            }

            ; Wenn das Fenster maximiert ist
            WinGet, cr_WinMinMax, MinMax, ahk_id %window_id%
            If (cr_WinMinMax = 1 AND double_click = 0)
            {
                If cr_ResizeFixedWindows = 1
                    WinRestore, ahk_id %window_id%
                Else
                    Return
            }

            ; Abhaengig von der Fensterregion reagieren
            ; In der Mitte wird das Fenster verschoben
            If ( is_center OR (cr_AlwaysMoveNonActive = 1 AND !WinActive("ahk_id " window_id)) )
            {
                If (double_click = 1 AND cr_Resizeable = 1 AND Enable_WindowsControl = 1)
                {
                    Gosub, wc_sub_Max%A_EmptyVar%
                    cr_Resizeable = 0
                    Return
                }
                cr_WinX1 += cr_OffsetX
                cr_WinY1 += cr_OffsetY
                If ( (cr_MagneticBorders = 1 AND cr_CtrlState = "U") OR (cr_MagneticBorders = 0 AND cr_CtrlState = "D") )
                {
                    if (cr_WinX1 + cr_WinW > WorkAreaRight)
                        cr_WinX1 := WorkAreaRight-cr_WinW
                    if (cr_WinX1 < WorkAreaLeft)
                        cr_WinX1 := WorkAreaLeft
                    if (cr_WinY1 + cr_WinH > WorkAreaBottom)
                        cr_WinY1 := WorkAreaBottom-cr_WinH
                    if (cr_WinY1 < WorkAreaTop)
                        cr_WinY1 := WorkAreaTop
                }
            }
            ; Ansonsten wird die Groesse veraendert
            Else
            {
  			    If ( cr_WinHor = "Left" AND cr_Resizeable = 1 )
                {
			    If (double_click = 1 AND Enable_WindowsControl = 1)
                    {
                        window_toggle_maximize_width(window_id)
                        cr_Resizeable = 0
                        Return
                    }
                    cr_WinX1 += cr_OffsetX
                    cr_WinW	-= cr_OffsetX
                }
			    Else If ( cr_WinHor = "Right"	AND cr_Resizeable = 1 )
                {
                    If (double_click = 1 AND Enable_WindowsControl = 1)
                    {
                        window_toggle_maximize_width(window_id)
                        cr_Resizeable = 0
                        Return
                    }
                    cr_WinW	+= cr_OffsetX
                }

                If ( cr_WinVer = "Up" AND cr_Resizeable = 1 )
                {
                    If (double_click = 1 AND Enable_WindowsControl = 1)
                    {
                        Gosub, wc_sub_MaxHeight%A_EmptyVar%
                        cr_Resizeable = 0
                        Return
                    }
                    cr_WinY1 += cr_OffsetY
                    cr_WinH	-= cr_OffsetY
                }
                Else If ( cr_WinVer = "Down" AND cr_Resizeable = 1)
                {
			    If (double_click = 1 AND Enable_WindowsControl = 1)
                    {
                        Gosub, wc_sub_MaxHeight%A_EmptyVar%
                        cr_Resizeable = 0
                        Return
                    }
                    cr_WinH	+= cr_OffsetY
                }

                If ( (cr_MagneticBorders = 1 AND cr_CtrlState = "U") OR (cr_MagneticBorders = 0 AND cr_CtrlState = "D") )
                {
                    if (cr_WinX1 + cr_WinW > WorkAreaRight)
                        cr_WinW := WorkAreaRight - cr_WinX1
                    if (cr_WinX1 < WorkAreaLeft)
                    {
                        cr_WinW := (cr_WinX1-WorkAreaLeft) + cr_WinW
                        cr_WinX1 := WorkAreaLeft
                    }
                    if (cr_WinY1 + cr_WinH > WorkAreaBottom)
                        cr_WinH := WorkAreaBottom - cr_WinY1
                    if (cr_WinY1 < WorkAreaTop)
                    {
                        cr_WinH := (cr_WinY1-WorkAreaTop) + cr_WinH
                        cr_WinY1 := WorkAreaTop
                    }
                }
            }

            ; Raster
            If ( (cr_ShiftState = "D" AND cr_RasterAlways = 0) OR (cr_ShiftState = "U" AND cr_RasterAlways = 1) )
            {
                cr_WinX1 := Round(cr_WinX1/cr_RasterXtmp)*cr_RasterXtmp
                cr_WinY1 := Round(cr_WinY1/cr_RasterYtmp)*cr_RasterYtmp
                If cr_Resizeable = 1
                {
                    cr_WinW := Round(cr_WinW/cr_RasterXtmp)*cr_RasterXtmp
                    cr_WinH := Round(cr_WinH/cr_RasterYtmp)*cr_RasterYtmp
                }
            }

            ; Bei Stillstand Fenster neu zeichen, wodurch "Schlieren" entfernt werden
            If (cr_LastX <> cr_WinX1 OR cr_LastY <> cr_WinY1 OR cr_LastW <> cr_WinW OR cr_LastH <> cr_WinH)
            {
                ; Zeichenverzoegerung je nach Voreinstellung
                If cr_SlowMovement = 1
                    SetWinDelay,30
                Else
                    SetWinDelay,-1
            }
            Else
                SetWindelay, 5

            ; Die gerade ermittelten Werte werden jetzt aufs Fenster angewendet
            WinMove, ahk_id %window_id%, , %cr_WinX1%, %cr_WinY1%, %cr_WinW%, %cr_WinH%

            ; Mausposition fuer diese Schleife uebernehmen
            mouse_x := cr_X2
            mouse_y := cr_Y2

            ; update tooltip
            If ( !(cr_AlwaysMoveNonActive = 1 AND !WinActive("ahk_id " window_id)) AND (comfort_resize_show_tooltip_pos OR comfort_resize_show_tooltip_size))
            {
                tt_text := ""
                if (is_center AND comfort_resize_show_tooltip_pos)
                    tt_text := "Position (" cr_WinX1 "," cr_WinY1 ")`n"
                if (!is_center AND comfort_resize_show_tooltip_size)
                    tt_text := tt_text "Size (" cr_WinW "," cr_WinH ")" Style " " ExStyle
                if tt_text
                    Tooltip, %tt_text%
            }

            cr_LastX = %cr_WinX1%
            cr_LastY = %cr_WinY1%
            cr_LastW = %cr_WinW%
            cr_LastH = %cr_WinH%

         }
         ; Wenn der Mausbutton losgelassen wurde, Tooltip loeschen und abbrechen
         Else
         {
            cr_LastX =
            cr_LastY =
            cr_LastW =
            cr_LastH =
            Tooltip
            If (Abs(cr_DistanceX) < 4 AND Abs(cr_DistanceY) < 4)
            {
                IfInString, A_ThisHotkey, MButton
                    MButton_send = yes
                IfInString, A_ThisHotkey, RButton
                {
                    RButton_send = yes
                    RButton_tip = yes
                }
                If (!WinActive("ahk_id" window_id))
                    WinActivate, ahk_id %window_id%
            }
            Else
            {
                RButton_send = no
                IfInString, A_ThisHotkey, MButton
                    MButton_send = no
            }
            Break
		}
		Sleep, 10
	} ; Loop Ende

    if (cr_actClass = "Putty")
		SendMessage WM_EXITSIZEMOVE , , , , ahk_id %window_id%

	; reset mouse cursor
	If current_cursor = IBEAM
		DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_IBEAM)
	Else
    	DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_ARROW)
	cr_hCurs =
}


_comfort_resize_get_doubleclick(mx, my) {
    static _comfort_resize_lastMouseX, _comfort_resize_lastMouseY, _comfort_resize_ClickTime
    diffx := Abs(_comfort_resize_lastMouseX - mx)
	diffy := Abs(_comfort_resize_lastMouseY - my)
	If (diffx < 5 AND diffy < 5)
	{
		If (A_Priorhotkey = A_Thishotkey AND A_TickCount - _comfort_resize_ClickTime < 400)
			double_click = 1
		Else
			double_click = 0
	}
	Else
		double_click = 0

	_comfort_resize_lastMouseX = %mx%
	_comfort_resize_lastMouseY = %my%
	_comfort_resize_ClickTime = %A_TickCount%

    return double_click
}
