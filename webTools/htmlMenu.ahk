; HtmlMenu
; selecting links "a" creates html-links in the style: <a href="http://safdsadf">text</a>
; if there is already a URL in Clipboard it's immediately written to the href!
; nothing selected: puts the cursor between the >< otherwise the selected is put inbetween
; when a link is selected: it goes to the href and cursor goes between the ><

HtmlMenu() {
    ; add menu entries on demand...
    Menu, MyMenu, Add, a, HtmlMenuHandler
    Menu, MyMenu, Add, b, HtmlMenuHandler
    Menu, MyMenu, Add, i, HtmlMenuHandler
    Menu, MyMenu, Add, li, HtmlMenuHandler
    Menu, MyMenu, Add, img, HtmlMenuHandler
    Menu, MyMenu, Add, video, HtmlMenuHandler
    Menu, MyMenu, Add, testHTML, HtmlMenuHandler
    Menu, MyMenu, Add, encodeURL, HtmlMenuHandler
    Menu, MyMenu, Show
	Menu, MyMenu, DeleteAll
}


HtmlMenuHandler() {
    textClip := Clipboard
	sel := clipboard_get()

    if (A_ThisMenuItem == "a") {
        ; if selection contains http* put that into the href, point cursor between >< then
        If SubStr(sel,1,4) = "http" ;
        {
			tt("HtmlMenu handling link...",1)
			clipboard_paste( "<a href=" sel "></a>" )
			SendInput, {Left 4}
        }
        ; if clipboard already contains http* put that in the href and the selection into the ><
        Else If SubStr(textClip,1,4) = "http"
        {
            clipboard_paste("<a href=" textClip ">" sel "</a>")
        }
        ; otherwise just put the selected into the ><
        Else
        {
            clipboard_paste("<a href=`"`">" sel "</a>")
            StringLen, hLen, sel
            hLen += 6
            SendInput, {Left %hLen%}
        }
    }
    Else If (A_ThisMenuItem == "img") {
        clipboard_paste("<img src=" sel " />")
    }
    Else If (A_ThisMenuItem == "testHTML") {
        fileName = %A_Temp%\testHTML.html
        FileDelete %fileName%
        FileAppend, %sel%, %fileName%
        Run, %fileName%,,Hide
    }
    Else If (A_ThisMenuItem == "video") {
        code = <video width="960" height="540" controls>`n<source src="%sel%" type="video/mp4">`n</video>
        clipboard_paste(code)
    }
    Else If (A_ThisMenuItem == "encodeURL") {
        clipboard_paste(uri_encode(sel))
    }
    Else {
        ; handle simple surrounding with the tags:
        clipboard_paste("<" A_ThisMenuItem ">" sel "</" A_ThisMenuItem ">")
    }
}
