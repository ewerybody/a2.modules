wordCount() {
	txt := clipboard_get()
    if (!txt) {
        a2tip("wordCount: Nothing selected!")
        Return
    }

    words := StrSplit(txt, [A_Tab, A_Space, "`n", "`r"])
	length := StrLen(txt)
    lines := StrSplit(txt, "`n")

    msg := "wordCount: " words.MaxIndex() "`n"
    msg .= "characters: " length "`n"
    msg .= "lines: " lines.MaxIndex() "`n"
	a2tip(msg, wordCount_tooltip_timeout)
}
