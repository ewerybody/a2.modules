; ComfortResize - comfort_resize_main.ahk
; Port from ac'tivAid to a2
; author: eric
; created: 2019 4 19

comfort_resize_init() {
    ; All variables for the 9 regions from the combinations of
    ; Up/Down, Left/Right and Center
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
    ; get mouse position relative to screen
    CoordMode, Mouse, Screen
    MouseGetPos, mouse_x, mouse_y, window_id

    ahk_id := "ahk_id " . window_id
    WinGetClass, cr_actClass, %ahk_id%
    ; Ignore desktop and taskbar area
    if (cr_actClass ~= "(WorkerW|Shell_TrayWnd)")
        Return

    if (cr_actClass == "Putty")
        SendMessage WM_ENTERSIZEMOVE, , , , %ahk_id%

    double_click := _comfort_resize_get_doubleclick(mouse_x, mouse_y)
    ; remember the current mouse cursor
    current_cursor := A_Cursor

    SetBatchLines, 2000
    window_get_rect(cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, window_id)

    _cr_set_region(cr_WinHor, cr_WinVer, mouse_x, mouse_y, cr_WinX1, cr_WinY1, cr_WinW, cr_WinH)

    If ( (!(window_is_resizable(window_id)) AND cr_ResizeFixedWindows = 0) OR cr_AlwaysMoveNonActive = 1 AND !WinActive(ahk_id))
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

    work_area := screen_get_work_area()

    Loop
    {
        GetKeyState, cr_Button, RButton, P
        IfInString, A_ThisHotkey, MButton
            GetKeyState, cr_Button, MButton, P
        IfInString, A_ThisHotkey, LButton
            GetKeyState, cr_Button, LButton, P

        GetKeyState, cr_LButton, LButton, P

        ; as long as button is pressed [D]own
        If (cr_Button == "D") {
            If cr_MouseKey = 9 AND cr_LButton <> D
                continue

            ; aktuelle Mausposition bestimmen
            MouseGetPos, cr_X2, cr_Y2
            cr_X3 = %cr_X2%
            cr_Y3 = %cr_Y2%
            ; aktuelle Fenstergroesse und -position bestimmen
            window_get_rect(cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, window_id)
            cr_WinX2 := cr_WinX1 + cr_WinW
            cr_WinY2 := cr_WinY1+cr_WinH

            ; Raster
            GetKeyState, cr_ShiftState, Shift, P
            GetKeyState, cr_CtrlState, Ctrl, P
            If ( (cr_ShiftState = "D" AND cr_RasterAlways = 0) OR (cr_ShiftState = "U" AND cr_RasterAlways = 1) )
            {
                cr_RasterXtmp := StrReplace(cr_RasterX, ":", "/")
                cr_RasterYtmp := StrReplace(cr_RasterY, ":", "/")
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
            If (!cr_hCurs) {
                cr_hCurs := DllCall("LoadCursor", "UInt", NULL, "Int", cr_Cur%cr_WinVer%%cr_WinHor%)
                _cr_set_cursor(cr_hCurs, current_cursor)
            }

            ; Wenn das Fenster maximiert ist
            WinGet, cr_WinMinMax, MinMax, %ahk_id%
            If (cr_WinMinMax = 1 AND double_click = 0)
            {
                If cr_ResizeFixedWindows = 1
                    WinRestore, %ahk_id%
                Else
                    Return
            }

            ; Abhaengig von der Fensterregion reagieren
            ; In der Mitte wird das Fenster verschoben
            If ( is_center OR (cr_AlwaysMoveNonActive = 1 AND !WinActive(ahk_id)) ) {
                If (double_click = 1 AND cr_Resizeable = 1) {
                    window_toggle_maximize(window_id)
                    cr_Resizeable = 0
                    cursor_reset()
                    Return
                }
                cr_WinX1 += cr_OffsetX
                cr_WinY1 += cr_OffsetY
                If ( (cr_MagneticBorders = 1 AND cr_CtrlState = "U") OR (cr_MagneticBorders = 0 AND cr_CtrlState = "D") ) {
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
                If ( cr_WinHor = "Left" AND cr_Resizeable = 1 ) {
                    If (double_click = 1) {
                        window_toggle_maximize_width(window_id)
                        cr_Resizeable = 0
                        cursor_reset()
                        Return
                    }
                    cr_WinX1 += cr_OffsetX
                    cr_WinW	-= cr_OffsetX
                }
                Else If ( cr_WinHor = "Right"	AND cr_Resizeable = 1 ) {
                    If (double_click = 1) {
                        window_toggle_maximize_width(window_id)
                        cr_Resizeable = 0
                        cursor_reset()
                        Return
                    }
                    cr_WinW	+= cr_OffsetX
                }

                If (cr_WinVer = "Up" AND cr_Resizeable = 1) {
                    If (double_click = 1) {
                        window_toggle_maximize_height(window_id)
                        cr_Resizeable = 0
                        cursor_reset()
                        Return
                    }
                    cr_WinY1 += cr_OffsetY
                    cr_WinH	-= cr_OffsetY
                }
                Else If (cr_WinVer = "Down" AND cr_Resizeable = 1) {
                    If (double_click = 1) {
                        window_toggle_maximize_height(window_id)
                        cr_Resizeable = 0
                        cursor_reset()
                        Return
                    }
                    cr_WinH	+= cr_OffsetY
                }

                If ( (cr_MagneticBorders = 1 AND cr_CtrlState = "U") OR (cr_MagneticBorders = 0 AND cr_CtrlState = "D") ) {
                    if (cr_WinX1 + cr_WinW > WorkAreaRight)
                        cr_WinW := WorkAreaRight - cr_WinX1
                    if (cr_WinX1 < WorkAreaLeft) {
                        cr_WinW := (cr_WinX1-WorkAreaLeft) + cr_WinW
                        cr_WinX1 := WorkAreaLeft
                    }
                    if (cr_WinY1 + cr_WinH > WorkAreaBottom)
                        cr_WinH := WorkAreaBottom - cr_WinY1
                    if (cr_WinY1 < WorkAreaTop) {
                        cr_WinH := (cr_WinY1-WorkAreaTop) + cr_WinH
                        cr_WinY1 := WorkAreaTop
                    }
                }
            }

            ; Raster
            If ( (cr_ShiftState = "D" AND cr_RasterAlways = 0) OR (cr_ShiftState = "U" AND cr_RasterAlways = 1) ) {
                cr_WinX1 := Round(cr_WinX1/cr_RasterXtmp)*cr_RasterXtmp
                cr_WinY1 := Round(cr_WinY1/cr_RasterYtmp)*cr_RasterYtmp
                If (cr_Resizeable = 1) {
                    cr_WinW := Round(cr_WinW/cr_RasterXtmp)*cr_RasterXtmp
                    cr_WinH := Round(cr_WinH/cr_RasterYtmp)*cr_RasterYtmp
                }
            }

            ; Bei Stillstand Fenster neu zeichen, wodurch "Schlieren" entfernt werden
            If (cr_LastX <> cr_WinX1 OR cr_LastY <> cr_WinY1 OR cr_LastW <> cr_WinW OR cr_LastH <> cr_WinH) {
                ; Zeichenverzoegerung je nach Voreinstellung
                If cr_SlowMovement = 1
                    SetWinDelay,30
                Else
                    SetWinDelay,-1
            }
            Else
                SetWindelay, 5

            ; Die gerade ermittelten Werte werden jetzt aufs Fenster angewendet
            window_set_rect(cr_WinX1, cr_WinY1, cr_WinW, cr_WinH, window_id)

            ; Mausposition fuer diese Schleife uebernehmen
            mouse_x := cr_X2
            mouse_y := cr_Y2

            ; update tooltip
            If ( !(cr_AlwaysMoveNonActive = 1 AND !WinActive(ahk_id)) AND (comfort_resize_show_tooltip_pos OR comfort_resize_show_tooltip_size)) {
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

        } Else {
            ; Wenn der Mausbutton losgelassen wurde, Tooltip loeschen und abbrechen
            cr_LastX =
            cr_LastY =
            cr_LastW =
            cr_LastH =
            Tooltip
            If (Abs(cr_DistanceX) < 4 AND Abs(cr_DistanceY) < 4) {
                If (!WinActive("ahk_id" window_id))
                    WinActivate, %ahk_id%
            }
            Break
        }
        Sleep, 10
    } ; Loop Ende

    if (cr_actClass = "Putty")
        SendMessage WM_EXITSIZEMOVE , , , , %ahk_id%

    cursor_reset()
}

_comfort_resize_get_doubleclick(mx, my) {
    global comfort_resize_pixel_threshold, comfort_resize_time_threshold
    if (!comfort_resize_pixel_threshold OR !comfort_resize_time_threshold)
        return 0

    static last_mouse_x, last_mouse_y, click_time, last_dbl_click

    If (A_Priorhotkey != A_Thishotkey)
        return 0

    if (!click_time) {
        click_time := A_TickCount
        return 0
    }

    diffx := Abs(last_mouse_x - mx), diffy := Abs(last_mouse_y - my)
    last_mouse_x := mx, last_mouse_y := my
    diff_t := A_TickCount - click_time
    click_time := A_TickCount

    If (diffx > comfort_resize_pixel_threshold OR diffy > comfort_resize_pixel_threshold)
        return 0

    ; to prevent double-doubleclicks
    diff_last := A_TickCount - last_dbl_click
    if !last_dbl_click
        late_enough := 1
    Else
        late_enough := diff_last > comfort_resize_time_threshold

    quick_enough := diff_t < comfort_resize_time_threshold
    If (quick_enough == 1 AND late_enough == 1) {
        double_click = 1
        last_dbl_click := A_TickCount
    } Else
    double_click = 0

    ; msg .= "quick_enough: " . quick_enough . "(" . diff_t . "), late_enough: " . late_enough . "(" . diff_last . ")"
    ; a2log_debug(msg, "comfort_resize")

    return double_click
}

_cr_set_cursor(to_id, current_cursor) {
    If (current_cursor == "IBeam")
        cursor_set(to_id, IDC_IBEAM)
    Else
        cursor_set(to_id, IDC_ARROW)
}

_cr_set_region(ByRef cr_WinHor, ByRef cr_WinVer, mouse_x, mouse_y, x, y, w, h) {
    ; Fensterregion ermitteln. Die neun Regionen ergeben sich als
    ; Horizontal * Vertikal = (left,center,right)*(up,center,down)
    If (mouse_x < x + w / 4)
    cr_WinHor := "Left"
    Else If (mouse_x < x + 3 * w / 4)
    cr_WinHor := "Center"
    Else
        cr_WinHor := "Right"

    If (mouse_y < y + h / 4)
    cr_WinVer := "Up"
    Else If (mouse_y < y + 3 * h / 4)
    cr_WinVer := "Center"
    Else
        cr_WinVer := "Down"
}
