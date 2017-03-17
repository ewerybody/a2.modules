#include lib\ahklib\uri_encode.ahk

gtranslate() {
    WriteDebug("triggered", "", "debug", "gtranslate")

    sel := getSelection() ; get selected text
    tranlation := gtranslate_fetch(sel, "en", "de") ; translate

    MsgBox % "Translation: " tranlation
}


gtranslate_fetch(srcTxt, srcLng, transLng)
{
    global gtranslate_use_proxy

    WriteDebug("Text to translate:", srcTxt, "debug", gtranslate)

    ApiURi := "https://translate.googleapis.com/translate_a/single?client=gtx"
    ApiURi .= "&sl=" srcLng
    ApiURi .= "&tl=" transLng
    ApiURi .= "&dt=t"
    ApiURi .= "&q=" LC_UrlEncode(srcTxt)
    WriteDebug("Calling URL:", ApiURi, "debug", gtranslate)

    Headers := "Content-Type: application/json`n"
    Headers .= "Referer: https://github.com/lipkau/ol.modules`n"

    Options := "Method: GET`n"
    Options .= "Charset: UTF-8`n"

    if gtranslate_use_proxy
    {
        Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " Base64Encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""
    }

    WriteDebug("HTTPRequest request HEADER:", Headers, "debug", "gtranslate")
    WriteDebug("HTTPRequest request Options:", Options, "debug", "gtranslate")

    HTTPRequest(ApiURi , response, Headers, Options)

    WriteDebug("HTTPRequest response HEADER:", Headers, "debug", "gtranslate")
    WriteDebug("HTTPRequest response BODY:", response, "debug", "gtranslate")

    RegExMatch(response, "\[\""(.+?)\""", match)
    return match1
}
