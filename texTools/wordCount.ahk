#Include <a2tip>

wordCount() {
	txt := clipboard_get()
    if (!txt) {
        a2tip("wordCount: Nothing selected!")
        Return
    }

    words := StrSplit(txt, [A_Tab, A_Space, "`n", "`r"])
	length := StrLen(txt)
    n_lines := string_count_lines(txt)

    msg := "wordCount: " words.Length "`n"
    msg .= "characters: " length "`n"
    msg .= "lines: " n_lines "`n"
	a2tip(msg, wordCount_tooltip_timeout)
}
