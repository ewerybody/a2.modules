; URL erzeugt links im style [URL=http://safdsadf]text[/URL]
; wenn ein URL im Clipboard ist wird dieser sofort in den href geschrieben
; nix markiert: kommt der cursor dann in die >< ansonsten kommt das markierte dazwischen
; ist ein link markiert wird der auch ins href geschrieben und der cursor zw. >< positioniert

BBCodeMenu(){
    ; add menu entries on demand...
	Menu, BBCodeMenu, Add, IMG, BBCodeMenuHandler
	Menu, BBCodeMenu, Add, URL, BBCodeURLHandler
	Menu, BBCodeMenu, Add, QUOTE, BBCodeMenuHandler
    Menu, BBCodeMenu, Add, B, BBCodeMenuHandler
	Menu, BBCodeMenu, Add, <kbd>, BBCodeKBDHandler
	Menu, BBCodeMenu, Show
	Menu, BBCodeMenu, DeleteAll
}


BBCodeMenuHandler() {
	sel := clipboard_get()
	code := "[" A_ThisMenuItem "]" sel "[/" A_ThisMenuItem "]"
	clipboard_paste(code)
}


BBCodeURLHandler() {
	sel := clipboard_get()
	If (string_is_web_address(sel))
	{
		tt("selection is URL",1)
		clipboard_paste( "[URL=" sel "][/URL]" )
		SendInput, {Left 6}
	}
	; if clipboard already contains a URL put that in the [URL= and the selection between ][/URL]
	Else If (string_is_web_address(Clipboard))
	{
		tt("Clipboard is URL",1)
		code := "[URL=" Clipboard "]" sel "[/URL]"
		clipboard_paste(code)
		SendInput, {Left 6}
	}
	; otherwise just put the selected into the ><
	Else
	{
		tt("otherwise...",1)
		code := "[URL=]" sel "[/URL]"
		clipboard_paste(code)
		StringLen, hLen, sel
		hLen += 7
		SendInput, {Left %hLen%}
	}
}


BBCodeKBDHandler() {
	sel := clipboard_get()
	code := "<kbd>" sel "</kbd>"
	clipboard_paste(code)
	StringLen, sel_len, sel
	; hLen += 7
	SendInput, {Left 6}+{Left %sel_len%}
}
