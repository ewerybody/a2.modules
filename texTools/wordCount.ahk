wordCount() {
	txt := get_selection()
    words := StrSplit(txt, [A_Tab, A_Space, "`n", "`r"])
	StringLen, length, txt
    
    lines := StrSplit(txt, "`n")
	;tt(length " Zeichen`n" words.maxIndex() " Worte`n" lines.maxIndex() " Zeilen", 5)
    tt(length " characters`n" words.maxIndex() " words`n" lines.maxIndex() " lines", 5)
}
