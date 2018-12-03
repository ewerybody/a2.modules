wordCount() {
    global wordCount_tooltip_timeout
	txt := clipboard_get()
    words := StrSplit(txt, [A_Tab, A_Space, "`n", "`r"])
	StringLen, length, txt
    
    lines := StrSplit(txt, "`n")
	tt(length " characters`n" words.maxIndex() " words`n" lines.maxIndex() " lines", wordCount_tooltip_timeout)
}
