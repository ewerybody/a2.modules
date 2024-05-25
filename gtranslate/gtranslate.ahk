; direct to user website
; https://translate.google.com/#en/de/hallo
; translate website
; https://translate.google.com/translate?sl=de&tl=en&js=y&prev=_t&hl=en&ie=UTF-8&u=&edit-text=&act=url
; translate api call
; https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=de&dt=t&q=File%20not%20visible
; other translate api call
; http://translate.google.de/translate_a/t?client=x&text=File%20not%20visible&sl=auto&tl=de
; text to speech
; https://translate.google.com/translate_tts?ie=UTF-8&q=bonjour&tl=fr&client=tw-ob
; https://stackoverflow.com/questions/32053442/google-translate-tts-api-blocked
#include <uri>

__gtranslation := ""
__gtranslate_search := ""
__gtranslate_lngs := ""

gtranslate(from:="en", to:="de") {
    global __gtranslate_search, __gtranslate_lngs
    sel := clipboard_get() ; get selected text

    __gtranslate_search := trim(sel, " `n`t`r")
    __gtranslate_lngs := from "|" to

    ; No Selection:
    if (__gtranslate_search == "")
    {
        msg := "Enter something to translate (" from " > " to ") ..."
        ibx := InputBox(msg, "gtranslate", "w640 h150")
        if ibx.Result = "Cancel"
            return
        __gtranslate_search := trim(ibx.value)
    }
    else if string_is_web_address(__gtranslate_search) {
        if gtranslate_ask_website_translate {
            msg := "Open translate.google.com with selected URL`n"
            msg .= "to have the whole page translated`n" . from . " > " . to . "?"
            if !msgbox_accepted(msg , "Translate whole webpage?")
                return
        }
        url := "https://translate.google.com/translate"
        url .= "?sl=" from
        url .= "&tl=" to
        url .= "&js=y&prev=_t&hl=en&ie=UTF-8&u="
        url .= uri_encode(__gtranslate_search)
        url .= "&edit-text=&act=url"
        Run(url)
        return
    }

    global __gtranslation
    __gtranslation := gtranslate_fetch(__gtranslate_search, from, to)

    if (__gtranslation == "") {
        msgbox_error('No tranlation found for "' . __gtranslate_search . '".`nAre you connected to the internet?')
        Return
    }

    icon_copy := path_join(a2.paths.resources, "copy.ico")
    icon_paste := path_join(a2.paths.resources, "paste.ico")
    icon_path := path_neighbor(A_LineFile, "a2icon24.png")
    icon_audio := path_join(a2.paths.resources, "volume_up.ico")

    max_menu_chars := 64
    if StrLen(__gtranslation) > max_menu_chars
        menu_label := 'Paste "' . SubStr(__gtranslation, 1, max_menu_chars) . '"...'
    else
        menu_label := 'Paste "' . __gtranslation . '"'

    gtranslate_menu := Menu()
    if (__gtranslation = __gtranslate_search) {
        if (from == "auto")
            same_label := "Auto translation resulted in identical output!"
        else
            same_label := "Translation resulted in identical output!"

        gtranslate_menu.Add(same_label, gtranslate_insert)
        gtranslate_menu.Disable(same_label)
    }

    gtranslate_menu.Add(menu_label, gtranslate_insert)
    gtranslate_menu.SetIcon(menu_label, icon_paste,, 0)
    gtranslate_menu.Add("Copy to Clipboard", gtranslate_copy)
    gtranslate_menu.SetIcon("Copy to Clipboard", icon_copy,, 0)
    audio_label := 'Play Audio "' . to . '"'
    gtranslate_menu.Add(audio_label, gtranslate_audio)
    gtranslate_menu.SetIcon(audio_label, icon_audio,, 0)

    gtranslate_menu.Add("Show in web browser", gtranslate_open_webpage)
    gtranslate_menu.SetIcon("Show in web browser", icon_path,, 0)
    gtranslate_menu.Show()
}


gtranslate_fetch(srcTxt, srcLng, transLng) {
    global gtranslate_use_proxy

    a2log_debug("Text to translate:" srcTxt, "gtranslate")
    encoded := uri_encode(srcTxt)

    ApiURi := "https://translate.googleapis.com/translate_a/single?client=gtx"
    ApiURi .= "&sl=" srcLng
    ApiURi .= "&tl=" transLng
    ApiURi .= "&dt=t"
    ApiURi .= "&q=" encoded ;srcTxt
    a2log_debug("Calling URL:" ApiURi, "gtranslate")

    ; Headers := "Content-Type: application/json`n"
    ; Headers .= "user-agent: Mozilla/5.0`n"

    ; if gtranslate_use_proxy
    ; {
    ;     Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " base64_encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?
    ;     Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""
    ; }

    ; a2log_debug("HTTPRequest request HEADER:" Headers, "gtranslate")
    ; a2log_debug("HTTPRequest request Options:" Options, "gtranslate")

    a2tip("gtranslate: looking up '" SubStr(srcTxt, 1 , 32) "' ...", 2)
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", ApiURi, true)
    whr.SetRequestHeader("Content-Type", "application/json")
    whr.SetRequestHeader("user-agent", "Mozilla/5.0")
    whr.Send()
    ; Using 'true' above and the call below allows the script to remain responsive.
    whr.WaitForResponse()
    response := whr.ResponseText
    ; HTTPRequest(ApiURi , response, Headers, Options)
    a2tip()

    ; a2log_debug("HTTPRequest response HEADER:" Headers, "gtranslate")
    a2log_debug("HTTPRequest response BODY:" response, "gtranslate")

    RegExMatch(response, '\[\"(.+?)\"', &match)
    ;tranlation := uri_decode(match1)
    ;return the tranlation
    return match[1]
}


gtranslate_insert(*) {
    global __gtranslation
    clipboard_paste(__gtranslation)
}


gtranslate_copy(*) {
    global __gtranslation
    A_Clipboard := __gtranslation
}


gtranslate_open_webpage(*) {
    global __gtranslate_search, __gtranslate_lngs
    lng_from_to := StrSplit(__gtranslate_lngs, "|")
    url := "https://translate.google.com/#"
    url .= lng_from_to[1] "/" lng_from_to[2] "/"
    url .= __gtranslate_search
    Run url
}

gtranslate_any(){
    icon_path := path_neighbor(A_LineFile, "a2icon24.png")
    user_cfg := Jxon_Load(a2.db.find(A_LineFile, "user_cfg"))
    languages := Jxon_Read(path_neighbor(A_LineFile, "languages.json"))
    last_selected_any := a2.db.find(A_LineFile, "last_selected_any")

    gtranslate_anymenu := Menu()
    for name, data in user_cfg.gtranslate_lister {
        gtranslate_anymenu.Add(name, _gtranslate_any_handler)
        gtranslate_anymenu.SetIcon(name, icon_path,, 0)
    }

    gtranslate_submenu := Menu()
    for lang, short in languages
    {
        gtranslate_submenu.Add(lang . ":" . short, _gtranslate_any_lang_handler)
        ; NOPE! Adding icons to ALL of the languages takes a couple seconds!!
        ; Menu, gtranslate_submenu, Icon, %lang%: %short%, %icon_path%,, 0
    }
    gtranslate_anymenu.Add("All Languages", gtranslate_submenu)
    gtranslate_anymenu.SetIcon("All Languages", icon_path,, 0)
    if (last_selected_any)
    {
        gtranslate_anymenu.Add(last_selected_any, _gtranslate_any_lang_handler)
        gtranslate_anymenu.SetIcon(last_selected_any, icon_path,, 0)
    }

    gtranslate_anymenu.Show()
}

_gtranslate_any_lang_handler(sel, *){
    parts := StrSplit(sel, ": ")
    a2.db.find_set(A_LineFile, "last_selected_any", sel)
    gtranslate("auto", parts[2])
}

_gtranslate_any_handler(sel, *){
    parts := StrSplit(sel, " > ")
    gtranslate(parts[1], parts[2])
}

; Short version of `GetAudioFromGoogle` from Cyberklabauters input
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=63835
; credits to: teadrinker, garry
gtranslate_audio(*) {
    global __gtranslation, __gtranslate_lngs
    lng_from_to := StrSplit(__gtranslate_lngs, "|")
    url := "https://translate.google.com/translate_tts?ie=UTF-8&q=" __gtranslation "&tl=" lng_from_to[2] "&client=tw-ob"

    whr := ComObject("Msxml2.XMLHTTP.6.0")
    whr.Open("GET", url, false)
    whr.Send()

    if (whr.Status != 200) {
        a2tip("Error! Status: " . whr.Status . "`n`n" . whr.responseBody)
        Return
    }

    tmp_path := A_Temp . "\__translate_tts.mp3"
    stream := ComObject("ADODB.Stream")
    stream.type := 1  ; Binary data
    stream.Open
    stream.Write(whr.responseBody)
    stream.SaveToFile(tmp_path, 2)
    stream.Close
    whr := ""

    a2tip('gtranslate: Playing back "' . lng_from_to[2] '" ...', 10)
    SoundPlay(tmp_path, "Wait")
    filedelete(tmp_path)
    a2tip()
}
