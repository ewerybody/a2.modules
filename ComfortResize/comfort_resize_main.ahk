; ComfortResize - comfort_resize_main.ahk
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
	MouseGetPos, cr_actMouseX, cr_actMouseY, cr_actWin
    global cr_ShowPosition
	WinGetClass, cr_actClass, ahk_id %cr_actWin%

	;If func_IsWindowInIgnoreList?()
	;	Return
	;WinGetTitle, cr_actWinTitle, ahk_id %cr_actWin%
	;If cr_actWinTitle in aadScreenShots
	;	Return
	;Loop, Parse, cr_DisableClasses, `,
	;{
	;	If (func_WildcardMatch( cr_actWinTitle, A_LoopField, 0) OR func_WildcardMatch( cr_actClass, A_LoopField, 0) )
	;	{
	;		Return
	;	}
	;}
    ;msgbox cr_actClass: %cr_actClass%
    
	cr_diffX := cr_lastMouseX - cr_actMouseX
	cr_diffY := cr_lastMouseY - cr_actMouseY
	Transform, cr_diffX, abs, %cr_diffX%
	Transform, cr_diffY, abs, %cr_diffY%
	If (cr_diffY < 5 AND cr_diffX < 5)
	{
		If (A_Priorhotkey = A_Thishotkey AND A_TickCount-cr_ClickTime < 400)
		{
			cr_DoubleClick = 1
		}
		Else
		{
			cr_DoubleClick = 0
		}
	}
	Else
		cr_DoubleClick = 0

	cr_ClickTime = %A_TickCount%
	cr_lastMouseX = %cr_actMouseX%
	cr_lastMouseY = %cr_actMouseY%

	cr_Cursor = %A_Cursor%
    
	WinGet, cr_WindowID, ID, A
	if (cr_actClass = "Putty")
		SendMessage WM_ENTERSIZEMOVE, , , , ahk_id %cr_WindowID%

	SetBatchLines, 2000
	; Mausposition relativ zum Bildschirm bekommen
	CoordMode, Mouse
	; Mausposition und ID des darunterliegenden Fensters ermitteln
	MouseGetPos, cr_X1, cr_Y1, cr_id
	; Postion und Groesse des Fensters ermitteln
	WinGetPos, cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, ahk_id %cr_id%
	; Fensterregion ermitteln. Die neuen Regionen ergeben sich als
	; Horizontal x Vertikal = (left,center,right)x(up,center,down)
	If (cr_X1 < cr_WinX1 + cr_WinW / 4)
        cr_WinHor := "Left"
	Else If (cr_X1 < cr_WinX1 + 3 * cr_WinW / 4)
        cr_WinHor := "Center"
	Else
        cr_WinHor := "Right"
	If (cr_Y1 < cr_WinY1 + cr_WinH / 4)
		cr_WinVer := "Up"
	Else If (cr_Y1 < cr_WinY1 + 3 * cr_WinH / 4)
		cr_WinVer := "Center"
	Else
		cr_WinVer := "Down"
	; Fenster-Style ermitteln
	WinGet, cr_Style, Style, ahk_id %cr_id%
	If ( (!(cr_Style & 0x40000) AND cr_ResizeFixedWindows = 0) OR cr_AlwaysMoveNonActive = 1 AND !WinActive("ahk_id" cr_id))
	{
		cr_Resizeable = 0
		cr_WinHor := "Center"
		cr_WinVer := "Center"
	}
	Else
		cr_Resizeable = 1

	cr_DistanceX := 0
	cr_DistanceY := 0
	; Schleife, solange Mausbutton gedrueckt
	Loop
	{
		GetKeyState, cr_Button, RButton, P
		IfInString, A_ThisHotkey, MButton
			GetKeyState, cr_Button, MButton, P
		IfInString, A_ThisHotkey, LButton
			GetKeyState, cr_Button, LButton, P

		GetKeyState, cr_LButton, LButton, P

		; Solange der Knopf gedrückt ist
		If cr_Button = D
		{
			If cr_MouseKey = 9
			{
				If cr_LButton <> D
					continue
			}
        
            ; aktuelle Mausposition bestimmen
            MouseGetPos, cr_X2, cr_Y2
            cr_X3 = %cr_X2%
            cr_Y3 = %cr_Y2%
            ; aktuelle Fenstergroesse und -position bestimmen
            WinGetPos, cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, ahk_id %cr_id%
            cr_WinX2 := cr_WinX1+cr_WinW
            cr_WinY2 := cr_WinY1+cr_WinH

            ; Raster
            GetKeyState, cr_ShiftState, Shift, P
            GetKeyState, cr_CtrlState, Ctrl, P
            If ( (cr_ShiftState = "D" AND cr_RasterAlways = 0) OR (cr_ShiftState = "U" AND cr_RasterAlways = 1) )
            {
                cr_Monitor := screen_get_index("A")

                cr_RasterXtmp = %cr_RasterX%
                cr_RasterYtmp = %cr_RasterY%
                StringReplace, cr_RasterXtmp, cr_RasterXtmp, `:, /
                StringReplace, cr_RasterYtmp, cr_RasterYtmp, `:, /
                IfInString cr_RasterXtmp, /
                {
                    StringSplit, cr_RasterXtmp, cr_RasterXtmp, /
                    cr_RasterXtmp := Round(WorkArea%cr_Monitor%Width*cr_RasterXtmp1/cr_RasterXtmp2)
                }
                IfInString cr_RasterYtmp, /
                {
                    StringSplit, cr_RasterYtmp, cr_RasterYtmp, /
                    cr_RasterYtmp := Round(WorkArea%cr_Monitor%Height*cr_RasterYtmp1/cr_RasterYtmp2)
                }

                cr_X2 := Round(cr_X2/cr_RasterXtmp)*cr_RasterXtmp
                cr_Y2 := Round(cr_Y2/cr_RasterYtmp)*cr_RasterYtmp
            }
            
            ; Verschiebung der Maus innerhalb dieser Schleife ermitteln
            cr_OffsetX := cr_X3 - cr_X1
            cr_OffsetY := cr_Y3 - cr_Y1

            cr_DistanceX := cr_DistanceX + cr_OffsetX
            cr_DistanceY := cr_DistanceY + cr_OffsetY

            If (Abs(cr_DistanceX) < 4 AND Abs(cr_DistanceY) < 4 AND cr_DoubleClick = 0)
            {
                cr_X1 := cr_X3
                cr_Y1 := cr_Y3
                continue
            }

            ; Mauspfeil anpassen
            If cr_hCurs =
            {
                cr_hCurs := DllCall("LoadCursor", "UInt", NULL, "Int", cr_Cur%cr_WinVer%%cr_WinHor%)
                If cr_Cursor = IBEAM
                    DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_IBEAM)
                Else
                    DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_ARROW)
            }

            ; Wenn das Fenster maximiert ist
            WinGet,cr_Win,MinMax,ahk_id %cr_id%
            If (cr_Win = 1 AND cr_DoubleClick = 0)
            {
                If cr_ResizeFixedWindows = 1
                    WinRestore, ahk_id %cr_id%
                Else
                    Return
            }

            ; Abhaengig von der Fensterregion reagieren
            ; In der Mitte wird das Fenster verschoben
            If ( (cr_WinHor = "Center" and cr_WinVer = "Center") OR (cr_AlwaysMoveNonActive = 1 AND !WinActive("ahk_id" cr_id)) )
            {
                If (cr_DoubleClick = 1 AND cr_Resizeable = 1 AND Enable_WindowsControl = 1)
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
                ; Wenn das Fenster maximiert ist
                WinGet,cr_Win,MinMax,ahk_id %cr_id%
                If (cr_Win = 1 AND cr_DoubleClick = 0)
                {
                    If cr_ResizeFixedWindows = 1
                        WinRestore, ahk_id %cr_id%
                    Else
                        Return
                }

			If ( cr_WinHor = "Left" AND cr_Resizeable = 1 )
                {
			 If (cr_DoubleClick = 1 AND Enable_WindowsControl = 1)
                 {
                     Gosub, wc_sub_MaxWidth%A_EmptyVar%
                     cr_Resizeable = 0
                     Return
                 }
                 cr_WinX1 += cr_OffsetX
                 cr_WinW	-= cr_OffsetX
                }
			Else If ( cr_WinHor = "Right"	AND cr_Resizeable = 1 )
                {
			 If (cr_DoubleClick = 1 AND Enable_WindowsControl = 1)
                     Goto, wc_sub_MaxWidth%A_EmptyVar%
                 cr_WinW	+= cr_OffsetX
                }
                If ( cr_WinVer = "Up" AND cr_Resizeable = 1 )
                {
                 If (cr_DoubleClick = 1 AND Enable_WindowsControl = 1)
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
			 If (cr_DoubleClick = 1 AND Enable_WindowsControl = 1)
                 {
                     Gosub, wc_sub_MaxHeight%A_EmptyVar%
                     cr_Resizeable = 0
                     Return
                 }
                 cr_WinH	+= cr_OffsetY
                }

                ; Magnetische Bildschirmränder
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
            WinMove, ahk_id %cr_id%, , %cr_WinX1%, %cr_WinY1%, %cr_WinW%, %cr_WinH%

            ; Mausposition für diese Schleife uebernehmen
            cr_X1 := cr_X2
            cr_Y1 := cr_Y2
            ; Tooltip aktualisieren
            If ( !(cr_AlwaysMoveNonActive = 1 AND !WinActive("ahk_id" cr_id)) AND cr_ShowPosition = 1 )
            {
                cr_Tooltip = %lng_cr_Position% (%cr_WinX1%, %cr_WinY1%)`n%lng_cr_Size% (%cr_WinW%, %cr_WinH%) %Style% %ExStyle%
                Tooltip, %cr_Tooltip%
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
                If (!WinActive("ahk_id" cr_id))
                    WinActivate, ahk_id %cr_id%
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
		SendMessage WM_EXITSIZEMOVE , , , , ahk_id %cr_WindowID%

	; Mauspfeil zurücksetzen
	If cr_Cursor = IBEAM
		DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_IBEAM)
	Else
    	DllCall("SetSystemCursor", "Uint", cr_hCurs, "Int", IDC_ARROW)
	cr_hCurs =
}
