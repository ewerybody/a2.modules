wordCount() {
	txt := clipboard_get()
    if (!txt) {
        a2tip("wordCount: Nothing selected!")
        Return
    }

    words := StrSplit(txt, [A_Tab, A_Space, "`n", "`r"])
	StringLen, length, txt
    lines := StrSplit(txt, "`n")

    msg := "wordCount: " words.MaxIndex() "`n"
    msg .= "characters: " length "`n"
    msg .= "lines: " lines.MaxIndex() "`n"
	a2tip(msg, wordCount_tooltip_timeout)
}
