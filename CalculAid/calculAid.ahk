; CalculAid - Calculato opener/helper
;
; nice :/ on win10 although you call calc.exe the calculator process executable will be:
; "ApplicationFrameHost.exe" and the class: "ApplicationFrameWindow". Thanks MS! This can be
; ANYTHING!!! OK the title is still "Calculator" but only on an english system.
; So basically we need logic for all of that because nothing
; is for sure. Furthermore that also means that the Close-hotkeys we wanna setup in a2ui will need
; win-version and language specific scope identifyers. In the end such a function will be quite
; nice to have in a2 anyway.

calculAid_open() {
    ; TODO fix the selected number to calculator-thing:
    ; sel := clipboard_get()
    ; RegExMatch(sel, "[0-9.,+-]+", numbers)
    ; RegExMatch(sel, "[0-9.,+/*=-]+", number_ops)

    WinGet, current_id, ID, A
    found_ids := calculAid_get_current()
    calc_is_active := string_is_in_array(current_id, found_ids)

    if (calculAid_ReuseOpenOne and found_ids.MaxIndex() and !calc_is_active)
    {
        a2tip("CalculAid: found one activating ...")
        this := found_ids[1]
        WinActivate, ahk_id %this%
        Return
    }

    ; This calls to open a Calculator, but the PID is useless.
    ; Windows will now use ApplicationFrameHost.exe to host a Calculator
    a2tip("CalculAid: Calling new ...")
    Run, calc.exe,, UseErrorLevel, calcPID

    ; We'll have to wait a moment for it to be available
    new_id := calculAid_wait_for_new(found_ids)
    ; txt := string_join(found_ids, "`n")
    ; MsgBox, calc_is_active: %calc_is_active%`nCalculAid_ReuseOpenOne:%CalculAid_ReuseOpenOne%`nnew_id:%new_id%`n`n%txt%

	If calculAid_openAtCursor {
		CoordMode, Mouse, Screen
		MouseGetPos, mx, my
        WinMove, ahk_id %new_id%,, (mx - 30), (my - 10)
	}

	If calculAid_AlwaysOnTop
        WinSet, AlwaysOnTop, On, ahk_id %new_id%
}


calculAid_get_current() {
    this_lng := SubStr(A_Language, -1)
    names := {09: "Calculator", 07: "Rechner"}
    this_name := names[this_lng]

    calc_ids := []
    WinGet, found_ids, List, %this_name% ahk_class ApplicationFrameWindow ahk_exe ApplicationFrameHost.exe
    Loop, %found_ids% {
        this := found_ids%A_Index%
        calc_ids.Push(this)
    }
    Return calc_ids
}


calculAid_wait_for_new(found_ids) {
    t0 := A_TickCount
    tries := 0
    Loop,
    {
        for _, id in calculAid_get_current() {
            if string_is_in_array(id, found_ids)
                Continue
            Return id
        }
        tries++
        t1 := A_TickCount - t0
        Sleep, 20
        if (t1 > 1000)
            Break
    }
    ; MsgBox, nothing found!`ntries: %tries%
}
