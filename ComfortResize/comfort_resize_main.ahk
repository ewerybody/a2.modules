; ComfortResize - comfort_resize_main.ahk
; Port from ac'tivAid to a2
; author: eric
; created: 2019 4 19

comfort_resize_main() {
    ; get mouse position relative to screen
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouse_x, &mouse_y, &window_id

    ahk_id := "ahk_id " . window_id
    win_class := WinGetClass(ahk_id)
    ; Ignore desktop and taskbar area
    if (win_class ~= "(WorkerW|Shell_TrayWnd)")
        return

    if (win_class == "Putty")
        SendMessage "WM_ENTERSIZEMOVE", , , , ahk_id

    double_click := _comfort_resize_get_doubleclick(mouse_x, mouse_y)
    ; remember the current mouse cursor
    current_cursor := A_Cursor

    window_get_rect(&win_x1, &win_y1, &win_w, &win_h, window_id)
    _cr_set_region(&zone_horizontal, &zone_vertical, mouse_x, mouse_y, win_x1, win_y1, win_w, win_h)

    if ((!(window_is_resizable(window_id)) AND cr_ResizeFixedWindows = 0) OR cr_AlwaysMoveNonActive AND !WinActive(
        ahk_id)) {
        is_resizable := 0
        zone_horizontal := "Center", zone_vertical := "Center"
    }
    else
        is_resizable := 1

    if (zone_horizontal = "Center" and zone_vertical = "Center")
        is_center := true
    else
        is_center := false

    distance_x := 0, distance_y := 0
    ; TODO: can we deprecate these?
    cr_SlowMovement := 0

    work_area := screen_get_work_area()
    cursor_handle := 0
    last_x := 0, last_y := 0, last_w := 0, last_h := 0

    cursor_DownCenter := IDC_SIZENS, cursor_UpCenter := IDC_SIZENS
    cursor_CenterLeft := IDC_SIZEWE, cursor_CenterRight := IDC_SIZEWE
    cursor_UpRight := IDC_SIZENESW, cursor_DownLeft := IDC_SIZENESW
    cursor_DownRight := IDC_SIZENWSE, cursor_UpLeft := IDC_SIZENWSE
    cursor_CenterCenter := IDC_SIZEALL

    loop {
        init_button := GetKeyState("RButton", "P")
        if InStr(A_ThisHotkey, "MButton")
            init_button := GetKeyState("MButton", "P")
        if InStr(A_ThisHotkey, "LButton")
            init_button := GetKeyState("LButton", "P")

        ; If mouse key was released, remove tooltip and break already
        if (!init_button) {
            last_x := 0, last_y := 0, last_w := 0, last_h := 0
            Tooltip()
            if (Abs(distance_x) < 4 AND Abs(distance_y) < 4) {
                if (!WinActive("ahk_id" window_id))
                    WinActivate(ahk_id)
            }
            break
        }

        MouseGetPos &x2, &y2
        x3 := x2, y3 := y2
        window_get_rect(&win_x1, &win_y1, &win_w, &win_h, window_id)

        ; Precompute Raster
        shift_state := GetKeyState("Shift", "P")
        do_raster := (shift_state AND cr_RasterAlways = 0) OR (!shift_state AND cr_RasterAlways = 1)
        if (do_raster) {
            raster_x := StrReplace(cr_RasterX, ":", "/")
            raster_y := StrReplace(cr_RasterY, ":", "/")
            if InStr(raster_x, "/") {
                raster_x := StrSplit(raster_x, "/")
                raster_x := Round(work_area.width * raster_x[1] / raster_x[2])
            }
            if InStr(raster_y, "/") {
                raster_y := StrSplit(raster_y, "/")
                raster_y := Round(work_area.height * raster_y[1] / raster_y[2])
            }

            x2 := Round(x2 / raster_x) * raster_x
            y2 := Round(y2 / raster_y) * raster_y
        }

        offset_x := x3 - mouse_x, offset_y := y3 - mouse_y
        distance_x := distance_x + offset_x
        distance_y := distance_y + offset_y

        if (Abs(distance_x) < 4 AND Abs(distance_y) < 4 AND !double_click) {
            mouse_x := x3, mouse_y := y3
            continue
        }

        if (!cursor_handle) {
            cursor_handle := DllCall("LoadCursor", "UInt", 0, "Int", cursor_%zone_vertical%%zone_horizontal%)
            _cr_set_cursor(cursor_handle, current_cursor)
        }

        win_min_max := WinGetMinMax(ahk_id)
        if (win_min_max = 1 AND !double_click) {
            if cr_ResizeFixedWindows
                WinRestore(ahk_id)
            else
                return
        }

        if (double_click AND is_resizable) {
            if (is_center)
                window_toggle_maximize(window_id)
            else if (zone_horizontal != "Center")
                window_toggle_maximize_width(window_id)
            else
                window_toggle_maximize_height(window_id)
            is_resizable := 0
            cursor_reset()
            return
        }

        ctrl_state := GetKeyState("Ctrl", "P")
        do_clamp := (IsSet(cr_allow_outside) AND ((!cr_allow_outside AND !ctrl_state) OR (cr_allow_outside AND
            ctrl_state))) OR ctrl_state
        ; Act upon window zone
        ; MOVE in the center
        if (is_center OR (cr_AlwaysMoveNonActive AND !WinActive(ahk_id))) {
            win_x1 += offset_x, win_y1 += offset_y
            win_x2 := win_x1 + win_w, win_y2 := win_y1 + win_h

            if (do_clamp) {
                if (win_x2 > work_area.right)
                    win_x1 := work_area.right - win_w
                if (win_x1 < work_area.left)
                    win_x1 := work_area.left
                if (win_y2 > work_area.bottom)
                    win_y1 := work_area.bottom - win_h
                if (win_y1 < work_area.top)
                    win_y1 := work_area.top
            }

            win_x1 := _cr_snap(win_x1, work_area.left)
            win_x1 := _cr_snap(win_x1, work_area.right, win_w)
            win_y1 := _cr_snap(win_y1, work_area.top)
            win_y1 := _cr_snap(win_y1, work_area.bottom, win_h)
        }

        ; RESIZE in other zones
        else {
            if (zone_horizontal = "Left" AND is_resizable = 1) {
                new_x1 := _cr_snap(win_x1 + offset_x, work_area.left)
                win_w += win_x1 - new_x1
                win_x1 := new_x1
            }
            else if (zone_horizontal = "Right" AND is_resizable = 1) {
                win_w := _cr_snap(win_x1 + win_w + offset_x, work_area.right) - win_x1
            }

            if (zone_vertical = "Up" AND is_resizable = 1) {
                new_y1 := _cr_snap(win_y1 + offset_y, work_area.top)
                win_h += win_y1 - new_y1
                win_y1 := new_y1
            }
            else if (zone_vertical = "Down" AND is_resizable = 1) {
                win_h := _cr_snap(win_y1 + win_h + offset_y, work_area.bottom) - win_y1
            }

            if (do_clamp) {
                if (win_x1 + win_w > work_area.right)
                    win_w := work_area.right - win_x1
                if (win_x1 < work_area.left) {
                    win_w := (win_x1 - work_area.left) + win_w
                    win_x1 := work_area.left
                }
                if (win_y1 + win_h > work_area.bottom)
                    win_h := work_area.bottom - win_y1
                if (win_y1 < work_area.top) {
                    win_h := (win_y1 - work_area.top) + win_h
                    win_y1 := work_area.top
                }
            }
        }

        ; Apply Raster
        if (do_raster) {
            win_x1 := Round(win_x1 / raster_x) * raster_x
            win_y1 := Round(win_y1 / raster_y) * raster_y
            if (is_resizable = 1) {
                win_w := Round(win_w / raster_x) * raster_x
                win_h := Round(win_h / raster_y) * raster_y
            }
        }

        ; Redraw when standing still to avoid ghosting
        if (last_x != win_x1 OR last_y != win_y1 OR last_w != win_w OR last_h != win_h) {
            if cr_SlowMovement == 1
                SetWinDelay 30
            else
                SetWinDelay -1
        }
        else
            SetWinDelay 5

        ; Apply calculated values to the window
        window_set_rect(win_x1, win_y1, win_w, win_h, window_id)

        ; Set mouse position for next loop
        mouse_x := x2, mouse_y := y2

        ; update tooltip
        if (!(cr_AlwaysMoveNonActive AND !WinActive(ahk_id)) AND (cr_show_tooltip_pos OR
            cr_show_tooltip_size)) {
            tt_text := ""
            if (is_center AND cr_show_tooltip_pos)
                tt_text := "Position (" win_x1 "," win_y1 ")`n"
            if (!is_center AND cr_show_tooltip_size)
                tt_text := tt_text "Size (" win_w "," win_h ")"
            if tt_text
                Tooltip(tt_text)
        }

        last_x := win_x1, last_y := win_y1
        last_w := win_w, last_h := win_h

        Sleep 10
    } ; loop end

    if (win_class = "Putty")
        SendMessage "WM_EXITSIZEMOVE", , , , ahk_id

    cursor_reset()
}

_comfort_resize_get_doubleclick(mx, my) {
    if (!IsSet(cr_pixel_threshold) OR !cr_pixel_threshold OR !IsSet(cr_time_threshold) OR !cr_time_threshold)
        return 0

    static last_mouse_x := 0
    static last_mouse_y := 0
    static click_time := 0
    static last_dbl_click := 0

    if (A_Priorhotkey != A_Thishotkey)
        return 0

    if (!click_time) {
        click_time := A_TickCount
        return 0
    }

    diff_x := Abs(last_mouse_x - mx), diff_y := Abs(last_mouse_y - my)
    last_mouse_x := mx, last_mouse_y := my
    diff_t := A_TickCount - click_time
    click_time := A_TickCount

    if (diff_x > cr_pixel_threshold OR diff_y > cr_pixel_threshold)
        return 0

    ; to prevent double-double-clicks
    diff_last := A_TickCount - last_dbl_click
    if !last_dbl_click
        late_enough := 1
    else
        late_enough := diff_last > cr_time_threshold

    quick_enough := diff_t < cr_time_threshold
    if (quick_enough == 1 AND late_enough == 1) {
        double_click := 1
        last_dbl_click := A_TickCount
    } else
        double_click := 0
    return double_click
}

_cr_set_cursor(to_id, current_cursor) {
    if (current_cursor == "IBeam")
        cursor_set(to_id, IDC_IBEAM)
    else
        cursor_set(to_id, IDC_ARROW)
}

; Get window zones. The nine areas are 3x3:
; horizontal * vertikal = (left,center,right)*(up,center,down)
_cr_set_region(&zone_horizontal, &zone_vertical, mouse_x, mouse_y, x, y, w, h) {
    if (mouse_x < x + w / 4)
        zone_horizontal := "Left"
    else if (mouse_x < x + 3 * w / 4)
        zone_horizontal := "Center"
    else
        zone_horizontal := "Right"

    if (mouse_y < y + h / 4)
        zone_vertical := "Up"
    else if (mouse_y < y + 3 * h / 4)
        zone_vertical := "Center"
    else
        zone_vertical := "Down"
}

; Magnetic border logic in one place
_cr_snap(value, border_value, width := 0) {
    if !IsSet(cr_snap_to_border) OR !cr_snap_to_border OR !IsSet(cr_border_threshold)
        return value
    if value + width > border_value - cr_border_threshold AND value + width < border_value + cr_border_threshold {
        return border_value - width
    }
    return value
}
