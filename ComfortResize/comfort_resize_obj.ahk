; ComfortResize - comfort_resize_main.ahk
; author: eric
; created: 2019 4 19
;
; WIP! Still way toooo slow. Don't use! yet! ;)
;
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

class ComfortResizeObject
{
    dist_threshold := 3
    double_click_threshold := 500

    mouse := {}
    window := {}

    horizontal := ""
    vertical := ""
    double_click := 0
    resizeable := 1

    dist_x := 0
    dist_y := 0
    offset_x := 0
    offset_y := 0

    init_mouse_pos() {
        ; get mouse position relative to screen
        CoordMode, Mouse, Screen
        MouseGetPos, mouse_x, mouse_y, window_id
        this.mouse["x"] := mouse_x
        this.mouse["y"] := mouse_y
        this.window["id"] := window_id
        this.window["idstr"] := "ahk_id " window_id
        WinGetClass, window_class, ahk_id %window_id%
        this.window["class"] := window_class
    }

    get_new_mouse_pos() {
        CoordMode, Mouse, Screen
        MouseGetPos, cr_X2, cr_Y2
        this.mouse["x2"] := cr_X2
        this.mouse["y2"] := cr_Y2
        this.mouse["x3"] := cr_X2
        this.mouse["y3"] := cr_Y2
    }

    check_double_click() {
        static click_time
        diffx := Abs(this.mouse["lastx"] - this.mouse["x"])
        diffx := Abs(this.mouse["lasty"] - this.mouse["y"])
        If (diffx < this.dist_threshold AND diffy < this.dist_threshold)
        {
            If (A_Priorhotkey = A_Thishotkey AND A_TickCount - click_time < this.double_click_threshold)
                this.double_click := 1
            Else
                this.double_click := 0
            tdiff := A_TickCount - click_time
            double_click := this.double_click
            ToolTip, A_Priorhotkey:%A_Priorhotkey% A_Thishotkey:%A_Thishotkey%`ntdiff:%tdiff% double_click:%double_click%
        }
        Else
            this.double_click := 0

        this.mouse["lastx"] := this.mouse["x"]
        this.mouse["lasty"] := this.mouse["y"]
        click_time := A_TickCount
    }

    init_window() {
        index := screen_get_index("A")
        this.workarea := new Screen_Workarea(index)
        this.current_cursor := A_Cursor
        this.changed_cursor :=

        this.dist_x := 0
        this.dist_y := 0
        ; Get the active region within the window
        ; Horizontal x Vertikal = (left,center,right)x(up,center,down)
        this.check_win_geometry()
        If (this.mouse["x"] < this.window["x"] + this.window["w"] / 4)
            this.horizontal := "Left"
        Else If (this.mouse["x"] < this.window["x"] + 3 * this.window["w"] / 4)
            this.horizontal := "Center"
        Else
            this.horizontal := "Right"

        If (this.mouse["y"] < this.window["y"] + this.window["h"] / 4)
            this.vertical := "Up"
        Else If (this.mouse["y"] < this.window["y"] + 3 * this.window["h"] / 4)
            this.vertical := "Center"
        Else
            this.vertical := "Down"

        If ( (!(window_is_resizable(this.window["id"])) AND cr_ResizeFixedWindows = 0) OR cr_AlwaysMoveNonActive = 1 AND !WinActive(this.window["idstr"]))
        {
            this.resizeable := 0
            this.horizontal := "Center"
            this.vertical := "Center"
        }
        Else
            this.resizeable := 1

        ; if (this.horizontal == "Center" AND this.vertical == "Center")
        ; this.is_center := 1
        this.is_center := (this.horizontal == "Center" AND this.vertical == "Center")
    }

    check_win_geometry() {
        ; gets position and size of the window
        idstr := this.window["idstr"]
        WinGetPos, x, y, w, h, %idstr%
        this.window["x"] := x
        this.window["y"] := y
        this.window["w"] := w
        this.window["h"] := h
        this.window["x2"] := x + w
        this.window["y2"] := y + h
    }

    is_mouse_pressed() {
        GetKeyState, button_state, RButton, P
		IfInString, A_ThisHotkey, MButton
			GetKeyState, button_state, MButton, P
		IfInString, A_ThisHotkey, LButton
			GetKeyState, button_state, LButton, P

		;GetKeyState, cr_LButton, LButton, P
        if (button_state == "D")
            return 1
        else
            return 0
    }

    check_raster() {
        GetKeyState, shift_state, Shift, P
        If ( (shift_state = "D" AND cr_RasterAlways = 0) OR (shift_state = "U" AND cr_RasterAlways = 1) )
        {
            tmp_x := StrReplace(cr_RasterX, ":", "/")
            tmp_y := StrReplace(cr_RasterY, ":", "/")
            IfInString tmp_x, /
            {
                StringSplit, tmp_x, tmp_x, /
                tmp_x := Round(this.workarea.width * tmp_x1 / tmp_x2)
            }
            IfInString tmp_y, /
            {
                StringSplit, tmp_y, tmp_y, /
                tmp_y := Round(this.workarea.height * tmp_y1 / tmp_y2)
            }

            this.mouse["x2"] := Round(this.mouse["x2"] / tmp_x) * tmp_x
            this.mouse["y2"] := Round(this.mouse["y2"] / tmp_y) * tmp_y
        }
    }

    get_offsets() {
        this.offset_x := this.mouse["x3"] - this.mouse["x"]
        this.offset_y := this.mouse["y3"] - this.mouse["y"]
        this.dist_x := this.dist_x + this.offset_x
        this.dist_y := this.dist_y + this.offset_y

        offset_x := this.offset_x
        offset_y := this.offset_y
    }

    is_low_distance() {
        If (Abs(this.dist_x) < this.dist_threshold AND Abs(this.dist_y) < this.dist_threshold AND this.double_click := 0)
        {
            this.mouse["x"] := this.mouse["x3"]
            this.mouse["y"] := this.mouse["y3"]
            return 1
        }
        else
            return 0
    }

    change_cursor() {
        ; If !this.changed_cursor
        ; {
            cursor_var := "cr_Cur" this.vertical this.horizontal
            this.changed_cursor := DllCall("LoadCursor", "UInt", NULL, "Int", %cursor_var%)
            If this.current_cursor = IBEAM
                DllCall("SetSystemCursor", "Uint", this.changed_cursor, "Int", IDC_IBEAM)
            Else
                DllCall("SetSystemCursor", "Uint", this.changed_cursor, "Int", IDC_ARROW)
        ; }
    }

    restore_cursor() {
        If this.current_cursor = IBEAM
            DllCall("SetSystemCursor", "Uint", this.changed_cursor, "Int", IDC_IBEAM)
        Else
            DllCall("SetSystemCursor", "Uint", this.changed_cursor, "Int", IDC_ARROW)
        this.changed_cursor :=
    }

    maximized_win_restore(minmax_state) {
        If (minmax_state = 1 AND this.double_click = 0)
        {
            If cr_ResizeFixedWindows = 1
            {
                WinRestore(this.window["idstr"])
                return 0
            }
            else
                return 1
        }
    }

    calculate_move() {
        this.window["x"] := this.window["x"] + this.offset_x
        this.window["y"] := this.window["y"] + this.offset_y
    }

    check_magnetic_borders() {
        ; WIP
        GetKeyState, cr_CtrlState, Ctrl, P
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

    calculate_resize() {
        If (this.horizontal = "Left" AND this.resizeable = 1)
        {
            if this.maximize_width_on_double_click()
                Return
            this.window["x"] := this.window["x"] + this.offset_x
            this.window["w"] := this.window["w"] - this.offset_x
        }
        Else If (this.horizontal = "Right" AND this.resizeable = 1)
        {
            if this.maximize_width_on_double_click()
                Return
            this.window["w"] := this.window["w"] + this.offset_x
        }

        If (this.vertical = "Up" AND this.resizeable = 1)
        {
            if this.maximize_height_on_double_click()
                Return
            this.window["y"] := this.window["y"] + this.offset_y
            this.window["h"] := this.window["h"] - this.offset_y
        }
        Else If (this.vertical = "Down" AND this.resizeable = 1)
        {
            if this.maximize_height_on_double_click()
                Return
            this.window["h"] := this.window["h"] + this.offset_y
        }
    }

    maximize_width_on_double_click() {
        If (this.double_click = 1)
            {
                window_toggle_maximize_width(this.window["id"])
                this.resizeable := 0
                Return 1
            }
        Return 0
    }

    maximize_height_on_double_click() {
        If (this.double_click = 1)
            {
                window_toggle_maximize_height(this.window["id"])
                this.resizeable := 0
                Return 1
            }
        Return 0
    }

    putty_enter() {
        win_id := this.window["idstr"]
        if (this.window["class"] = "Putty")
		    SendMessage, WM_ENTERSIZEMOVE, , , , %win_id%
    }

    putty_exit() {
        win_id := this.window["idstr"]
        if (this.window["class"] = "Putty")
		    SendMessage, WM_EXITSIZEMOVE, , , , %win_id%
    }

    check_raster2() {
        ; WIP
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
    }

    apply_changes() {
        idstr := this.window["idstr"]
        winx := this.window["x"]
        winy := this.window["y"]
        winw := this.window["w"]
        winh := this.window["h"]
        WinMove, %idstr%, , %winx%, %WinY%, %WinW%, %WinH%

        this.mouse["x"] := this.mouse["x2"]
        this.mouse["y"] := this.mouse["y2"]
    }

    update_tooltip() {
        If (!(cr_AlwaysMoveNonActive = 1 AND !WinActive(this.window["idstr"])) AND (comfort_resize_show_tooltip_pos OR comfort_resize_show_tooltip_size))
        {
            tt_text := ""
            if comfort_resize_show_tooltip_pos
                tt_text := "Position (" this.window["x"] "," this.window["y"] ")`n"
            if comfort_resize_show_tooltip_size
                tt_text := tt_text "Size (" this.window["w"] "," this.window["h"] ")" Style " " ExStyle
            tt_text := tt_text "`nh: " this.horizontal " v: " this.vertical
            tt_text := tt_text "`ndoubleclickh: " this.double_click
            tt_text := tt_text "`noffsets: " this.offset_x " " this.offset_y
            Tooltip, %tt_text%
        }
    }
}

comfort_resize_main() {
    cr := New ComfortResizeObject
    cr.init_mouse_pos()
    cr.check_double_click()

    SetBatchLines, 2000
    cr.putty_enter()

    cr.init_window()
    cr.change_cursor()
    Loop
    {
        if cr.is_mouse_pressed()
        {
            cr.get_new_mouse_pos()
            cr.check_win_geometry()
            cr.check_raster()
            cr.get_offsets()
            if (cr.is_low_distance())
                continue

            minmax_state := WinGetMinMax(cr.window["idstr"])
            if (cr.maximized_win_restore(minmax_state))
                return

            If (cr.is_center OR (cr_AlwaysMoveNonActive = 1 AND !WinActive(cr.window["idstr"])) )
            {
                If (cr.double_click = 1)
                {
                    window_toggle_maximize(cr.window["id"])
                    Return
                }
                cr.calculate_move()
                ; cr.check_magnetic_borders()
            } else
            {
                cr.calculate_resize()
                ; cr.check_magnetic_borders()
            }
            cr.apply_changes()
            cr.update_tooltip()
        }
        Else
        {
            Tooltip
            Break
		}
		; Sleep, 10
	} ; Loop End

    cr.putty_exit()
	cr.restore_cursor()
}
