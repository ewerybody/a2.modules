ftpExplorerCopy() {
	WinGet, this_id, ID, A
	;legacy: Win 7: ;ControlGetText, path, ToolbarWindow322, ahk_id %this_id%
    ;Win 8 ;ControlGetText, path, ToolbarWindow323, ahk_id %this_id%

    selection := explorer_get_selected(this_id)
    if !(selection.Length()) {
        a2tip("Nothing selected!")
        Return
    }

	result := []
    for i, pth in selection
    {
        if (Substr(pth, 1, 6) == "ftp://")
            result.Push("http://" SubStr(pth, InStr(pth, "@") + 1))
    }

	Clipboard := string_join(result, "`n")
	a2tip(Clipboard)
}