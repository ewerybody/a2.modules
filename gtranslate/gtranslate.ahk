; direct to user website
; https://translate.google.com/#en/de/hallo
; translate website
; https://translate.google.com/translate?sl=de&tl=en&js=y&prev=_t&hl=en&ie=UTF-8&u=&edit-text=&act=url
; translate api call
; https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=de&dt=t&q=File%20not%20visible
; other translate api call
; http://translate.google.de/translate_a/t?client=x&text=File%20not%20visible&sl=auto&tl=de

__gtranslation := ""
__gtranslate_search := ""


gtranslate() {
    icon_path := A_ScriptDir "\..\modules\a2.modules\gtranslate\a2icon.png"
    
    WriteDebug("triggered", "", "debug", "gtranslate")
    global __gtranslate_search
    sel := getSelection() ; get selected text
    __gtranslate_search := Trim(sel, " `n`t`r")
    if (__gtranslate_search == "")
    {
        InputBox, UserInput, gtranslate, Enter something to translate..., , 640, 150
        if ErrorLevel
            return
        else
            __gtranslate_search := Trim(UserInput)
    }
    else if is_web_adress(__gtranslate_search) {
        global gtranslate_ask_website_translate
        if gtranslate_ask_website_translate {
            MsgBox, 1, Translate the web adress with translate.google.com?
            IfMsgBox No
                return
        }
        url := "https://translate.google.com/translate?sl=de&tl=en&js=y&prev=_t&hl=en&ie=UTF-8&u="
        url .= LC_UrlEncode(__gtranslate_search)
        url .= "&edit-text=&act=url"
        Run, %url%
        return
    }

    global __gtranslation
    __gtranslation := gtranslate_fetch(__gtranslate_search, "auto", "de") ; translate

    if (__gtranslation == "")
        MsgBox No tranlation found for "%__gtranslate_search%".
    else {
        Menu, gtranslate_menu, Add, %__gtranslation%, gtranslate_insert
        Menu, gtranslate_menu, Icon, %__gtranslation%, %icon_path%
        Menu, gtranslate_menu, Add, Show in web browser, gtranslate_open_webpage
        Menu, gtranslate_menu, Icon, Show in web browser, %icon_path%
        Menu, gtranslate_menu, Show
        Menu, gtranslate_menu, DeleteAll
    }
}


gtranslate_fetch(srcTxt, srcLng, transLng) {
    global gtranslate_use_proxy

    WriteDebug("Text to translate:", srcTxt, "debug", gtranslate)

    encoded := LC_UriEncode(srcTxt)
    
    ApiURi := "https://translate.googleapis.com/translate_a/single?client=gtx"
    ApiURi .= "&sl=" srcLng
    ApiURi .= "&tl=" transLng
    ApiURi .= "&dt=t"
    ApiURi .= "&q=" encoded ;srcTxt
    WriteDebug("Calling URL:", ApiURi, "debug", gtranslate)

    Headers := "Content-Type: application/json`n"
    Headers .= "user-agent: Mozilla/5.0`n"

    Options := "Method: GET`n"
    Options .= "Charset: UTF-8`n"

    if gtranslate_use_proxy
    {
        Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " Base64Encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""
    }

    WriteDebug("HTTPRequest request HEADER:", Headers, "debug", "gtranslate")
    WriteDebug("HTTPRequest request Options:", Options, "debug", "gtranslate")

    tt("gtranslate looking up '" srcTxt "' ...")
    HTTPRequest(ApiURi , response, Headers, Options)
    tt()

    WriteDebug("HTTPRequest response HEADER:", Headers, "debug", "gtranslate")
    WriteDebug("HTTPRequest response BODY:", response, "debug", "gtranslate")

    RegExMatch(response, "\[\""(.+?)\""", match)
    ;tranlation := LC_UriDecode(match1)
    ;return tranlation
    return match1
}


gtranslate_insert(ItemName, ItemPos, MenuName) {
    global __gtranslation
    paste(__gtranslation)
}


gtranslate_open_webpage(ItemName, ItemPos, MenuName) {
    global __gtranslate_search
    url := "https://translate.google.com/#en/de/" __gtranslate_search
    Run, %url%
}
