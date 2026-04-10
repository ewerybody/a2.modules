/* gtranslate - to look up selected text on an online translator.

direct to user website
https://translate.google.com/#en/de/hallo
translate website
https://translate.google.com/translate?sl=de&tl=en&js=y&prev=_t&hl=en&ie=UTF-8&u=&edit-text=&act=url
translate api call
https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=de&dt=t&q=File%20not%20visible
other translate api call
http://translate.google.de/translate_a/t?client=x&text=File%20not%20visible&sl=auto&tl=de
text to speech
https://translate.google.com/translate_tts?ie=UTF-8&q=bonjour&tl=fr&client=tw-ob
https://stackoverflow.com/questions/32053442/google-translate-tts-api-blocked
*/
#include <a2dlg>
#Include <i18n>
#include <uri>

__gtranslation := ""
__gtranslate_search := ""
__gtranslate_langs := ""

gtranslate(from := "en", to := "de") {
    global __gtranslate_search, __gtranslate_langs, __gtranslation
    t := i18n_domain('general')
    tg := i18n_locale(A_LineFile)
    sel := clipboard_get()

    __gtranslate_search := trim(sel, " `n`t`r")
    __gtranslate_search := RegExReplace(__gtranslate_search, '\s+', " ")
    __gtranslate_langs := from "|" to

    ; No Selection:
    if (__gtranslate_search == "") {
        msg := tg['enter_something'] " (" from " > " to ") ..."
        result := a2dlg_input(msg, "gtranslate")
        if !result
            return
        __gtranslate_search := trim(result)
    }
    else if string_is_web_address(__gtranslate_search) {
        if gtranslate_ask_website_translate {
            msg := tg['ask_whole_page'] from . " > " . to . "?"
            if !a2dlg_yes_no(msg, tg["translate_whole"])
                return
        }

        gtranslate_website(from, to)
        return
    }

    __gtranslation := gtranslate_fetch(__gtranslate_search, from, to)
    if (__gtranslation == "") {
        a2dlg_error(Format(tg['error_nothing_found'], __gtranslate_search) "`n" t['ask_net_connection'])
        return
    }

    __gtranslation := RegExReplace(__gtranslation, '\\r\\n', "`n")
    icon_path := path_neighbor(A_LineFile, "a2icon24.png")

    max_menu_chars := 64
    if StrLen(__gtranslation) > max_menu_chars
        menu_label := t['paste'] ': "' SubStr(__gtranslation, 1, max_menu_chars) . '"...'
    else
        menu_label := t['paste'] ': "' __gtranslation '"'

    gtranslate_menu := Menu()
    if (__gtranslation = __gtranslate_search) {
        if (from == "auto")
            same_label := "Auto-"
        same_label .= tg['identical']

        gtranslate_menu.Add(same_label, gtranslate_insert)
        gtranslate_menu.Disable(same_label)
    }

    gtranslate_menu.Add(menu_label, gtranslate_insert)
    gtranslate_menu.SetIcon(menu_label, A2Icons.paste,, 0)
    gtranslate_menu.Add(t['to_clipboard'], gtranslate_copy)
    gtranslate_menu.SetIcon(t['to_clipboard'], A2Icons.to_clipboard,, 0)
    audio_label := tg['play_audio'] ' "' . to . '"'
    gtranslate_menu.Add(audio_label, gtranslate_audio)
    gtranslate_menu.SetIcon(audio_label, A2Icons.volume_up,, 0)

    gtranslate_menu.Add(t['show_in_web'], gtranslate_open_website)
    gtranslate_menu.SetIcon(t['show_in_web'], icon_path,, 0)
    gtranslate_menu.Show()
}

gtranslate_fetch(srcTxt, srcLng, transLng) {
    global gtranslate_use_proxy

    a2log_debug("Text to translate:" srcTxt, "gtranslate")
    encoded := uri_encode(srcTxt)
    encoded := RegExReplace(encoded, "%0D", "")

    ApiURi := "https://translate.googleapis.com/translate_a/single?client=gtx"
    ApiURi .= "&sl=" srcLng
    ApiURi .= "&tl=" transLng
    ApiURi .= "&dt=t"
    ApiURi .= "&q=" encoded ;srcTxt
    a2log_debug("Calling URL:" ApiURi, "gtranslate")

    a2tip("gtranslate: looking up '" SubStr(srcTxt, 1, 32) "' ...", 2)
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", ApiURi, true)
    whr.SetRequestHeader("Content-Type", "application/json")
    whr.SetRequestHeader("user-agent", "Mozilla/5.0")
    whr.Send()
    ; Using 'true' above and the call below allows the script to remain responsive.
    try
        whr.WaitForResponse()
    catch {
        a2tip("WinHttpRequest Failed!")
        a2log_error("WinHttpRequest Failed!", "gtranslate")
        return
    }

    response := whr.ResponseText
    a2tip()
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

gtranslate_open_website(*) {
    lng_from_to := StrSplit(__gtranslate_langs, "|",, MaxArraySize := 2)
    url := "https://translate.google.com/?"
    url .= "sl=" lng_from_to[1] "&tl=" lng_from_to[2] "&text="
    url .= uri_encode(__gtranslate_search)
    Run(url)
}

gtranslate_any() {
    icon_path := path_neighbor(A_LineFile, "a2icon24.png")
    user_cfg_str := a2.db.find(A_LineFile, "user_cfg")
    user_cfg := Jxon_Load(&user_cfg_str)
    languages := Jxon_Read(path_neighbor(A_LineFile, "languages.json"))
    last_selected_any := a2.db.find(A_LineFile, "last_selected_any")
    tg := i18n_locale(A_LineFile, 'de')

    gtranslate_any_menu := Menu()
    for name, data in user_cfg["gtranslate_lister"] {
        gtranslate_any_menu.Add(name, _gtranslate_any_handler)
        gtranslate_any_menu.SetIcon(name, icon_path,, 0)
    }

    gtranslate_submenu := Menu()
    for lang, short in languages {
        gtranslate_submenu.Add(lang . ":" . short, _gtranslate_any_lang_handler)
        ; NOPE! Adding icons to ALL of the languages takes a couple seconds!!
        ; Menu, gtranslate_submenu, Icon, %lang%: %short%, %icon_path%,, 0
    }
    gtranslate_any_menu.Add(tg['all_languages'], gtranslate_submenu)
    gtranslate_any_menu.SetIcon(tg['all_languages'], icon_path, , 0)
    if (last_selected_any) {
        gtranslate_any_menu.Add(last_selected_any, _gtranslate_any_lang_handler)
        gtranslate_any_menu.SetIcon(last_selected_any, icon_path,, 0)
    }

    gtranslate_any_menu.Show()
}

_gtranslate_any_lang_handler(sel, *) {
    parts := StrSplit(sel, ":")
    a2.db.find_set(A_LineFile, "last_selected_any", sel)
    gtranslate("auto", Trim(parts[2]))
}

_gtranslate_any_handler(sel, *) {
    parts := StrSplit(sel, " > ")
    gtranslate(parts[1], parts[2])
}

; Short version of `GetAudioFromGoogle` from Cyberklabauters input
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=63835
; credits to: teadrinker, garry
gtranslate_audio(*) {
    global __gtranslation, __gtranslate_langs
    lng_from_to := StrSplit(__gtranslate_langs, "|")
    url := "https://translate.google.com/translate_tts?ie=UTF-8&q=" __gtranslation "&tl=" lng_from_to[2] "&client=tw-ob"

    whr := ComObject("Msxml2.XMLHTTP.6.0")
    whr.Open("GET", url, false)
    whr.Send()

    if (whr.Status != 200) {
        a2tip("Error! Status: " . whr.Status . "`n`n" . whr.responseBody)
        return
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
    FileDelete(tmp_path)
    a2tip()
}

gtranslate_website(from, to) {
    url_parts := StrSplit(__gtranslate_search, "://",, MaxArraySize := 2)
    ; gtranslate url has to start with https anyway
    url := "https://"
    ; deal with search string not containing http
    start_index := 1
    if InStr(url_parts[1], "http")
        start_index++

    if InStr(url_parts[start_index], "/") {
        root_rest := StrSplit(url_parts[start_index], "/",, MaxArraySize := 2)
        root := root_rest[1]
        rest := root_rest[2]
    } else {
        root := url_parts[2]
        rest := ""
    }
    ; dashes to double dashes
    root := StrReplace(root, "-", "--")
    ; add root path with replaced dots as dashes in from of the google address
    url .= StrReplace(root, ".", "-") ".translate.goog/"

    languages_code := "?_x_tr_sl=" from "&_x_tr_tl=" to "&_x_tr_hl=" to
    ; deal with anchor in links
    if InStr(rest, "#") {
        anchor_parts := StrSplit(rest, "#",, MaxArraySize := 2)
        url .= anchor_parts[1] languages_code
        url .= "#" anchor_parts[2]
    } else {
        url .= rest languages_code
    }

    Run(url)
}
