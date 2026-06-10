; CalculAid - Calculato opener/helper
;
; nice :/ on win10 although you call calc.exe the calculator process executable will be:
; "ApplicationFrameHost.exe" and the class: "ApplicationFrameWindow". Thanks MS! This can be
; ANYTHING!!! OK the title is still "Calculator" but only on an english system.
; So basically we need logic for all of that because nothing
; is for sure. Furthermore that also means that the Close-hotkeys we wanna setup in a2ui will need
; win-version and language specific scope identifyers. In the end such a function will be quite
; nice to have in a2 anyway.
#Include <a2dlg>

calculAid_open() {
    ; TODO fix the selected number to calculator-thing:
    ; sel := clipboard_get()
    ; RegExMatch(sel, "[0-9.,+-]+", numbers)
    ; RegExMatch(sel, "[0-9.,+/*=-]+", number_ops)

    current_id := WinGetID("A")
    found_ids := calculAid_get_current()
    calc_is_active := string_is_in_array(current_id, found_ids)

    if (calculAid_ReuseOpenOne and found_ids.Length and !calc_is_active)
    {
        a2tip("CalculAid: found one activating ...")
        WinActivate("ahk_id " . found_ids[1])
        Return
    }

    ; This calls to open a Calculator, but the PID is useless.
    ; Windows will now use ApplicationFrameHost.exe to host a Calculator
    a2tip("CalculAid: Calling new ...")
    Run "calc.exe"
    if A_LastError
        a2dlg_error("Could not open up 'calc.exe'!")

    ; We'll have to wait a moment for it to be available
    new_id := calculAid_wait_for_new(found_ids)
	If calculAid_openAtCursor {
		CoordMode "Mouse", "Screen"
		MouseGetPos &mx, &my
        WinMove(mx - 30, my - 10,,, "ahk_id " . new_id)
	}

	If calculAid_AlwaysOnTop
        WinSetAlwaysOnTop(1, "ahk_id " . new_id)
}


calculAid_get_current() {
    lang_names := Map("9", "Calculator", "7", "Rechner")
    this_name := lang_names[SubStr(A_Language, -1)]
    return WinGetList(this_name . " ahk_class ApplicationFrameWindow ahk_exe ApplicationFrameHost.exe")
}


calculAid_wait_for_new(found_ids) {
    t0 := A_TickCount
    tries := 0
    Loop
    {
        for _, id in calculAid_get_current() {
            if string_is_in_array(id, found_ids)
                Continue
            Return id
        }
        tries++
        t1 := A_TickCount - t0
        Sleep 20
        if (t1 > 1000)
            Break
    }
}
