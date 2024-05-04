; URL erzeugt links im style [URL=http://safdsadf]text[/URL]
; wenn ein URL im Clipboard ist wird dieser sofort in den href geschrieben
; nix markiert: kommt der cursor dann in die >< ansonsten kommt das markierte dazwischen
; ist ein link markiert wird der auch ins href geschrieben und der cursor zw. >< positioniert

BBCodeMenu() {
    ; add menu entries on demand...
    BBCode_Menu := Menu()
	BBCode_Menu.Add("IMG", BBCodeMenuHandler)
	BBCode_Menu.Add("URL", BBCodeURLHandler)
	BBCode_Menu.Add("QUOTE", BBCodeMenuHandler)
    BBCode_Menu.Add("B", BBCodeMenuHandler)
	BBCode_Menu.Add("<kbd>", BBCodeKBDHandler)
	BBCode_Menu.Show()
}

BBCodeMenuHandler(menu_item, *) {
	sel := clipboard_get()
	code := "[" menu_item "]" sel "[/" menu_item "]"
	clipboard_paste(code)
}

BBCodeURLHandler(*) {
	sel := clipboard_get()
	If (string_is_web_address(sel))
	{
		a2tip("selection is URL",1)
		clipboard_paste( "[URL=" sel "][/URL]" )
		SendInput "{Left 6}"
	}
	; if clipboard already contains a URL put that in the [URL= and the selection between ][/URL]
	Else If (string_is_web_address(A_Clipboard))
	{
		a2tip("Clipboard is URL",1)
		code := "[URL=" A_Clipboard "]" sel "[/URL]"
		clipboard_paste(code)
		SendInput "{Left 6}"
	}
	; otherwise just put the selected into the ><
	Else
	{
		a2tip("otherwise...",1)
		code := "[URL=]" sel "[/URL]"
		clipboard_paste(code)
		hLen := StrLen(sel)
		hLen += 7
		SendInput "{Left " . hLen . "}"
	}
}

BBCodeKBDHandler(*) {
	sel := clipboard_get()
	code := "<kbd>" . sel . "</kbd>"
	clipboard_paste(code)
	sel_len := StrLen(sel)
	; hLen += 7
	SendInput "{Left 6}+{Left " . sel_len . "}"
}
