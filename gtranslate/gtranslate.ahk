gtranslate() {
    sel := getSelection()
    sel := gtranslate_fetch(sel, "en", "de")
    
    MsgBox sel: %sel%
}


gtranslate_fetch(srcTxt, srcLng, transLng)
{
    global gtranslate_use_proxy
    ApiURi := "https://translate.googleapis.com/translate_a/single?client=gtx"
    ApiURi .= "&sl=" srcLng
    ApiURi .= "&tl=" transLng
    ApiURi .= "&dt=t"
    ApiURi .= "&q=" uri_encode(srcTxt) ; https://autohotkey.com/board/topic/75390-ahk-l-unicode-uri-encode-url-encode-function/

    Headers := "Content-Type: application/json`n"
    Headers .= "Referer: https://github.com/lipkau/ol.modules`n"
    
    Options := "Method: GET`n"
    Options .= "Charset: UTF-8`n"
    
    if gtranslate_use_proxy
    {
        Headers .= Settings.Proxy.Authentication.Username && Settings.Proxy.Authentication.Password ? "Proxy-Authorization: Basic " Base64Encode(Settings.Proxy.Authentication.Username ":" Settings.Proxy.Authentication.Password) : ""  ; TODO decrypt pw?
        Options .= Settings.Proxy.Enabled ? "Proxy: " Settings.Proxy.Address ":" Settings.Proxy.Port "`n" : ""
    }

    WriteDebug("HTTPRequest request HEADER:", Headers, "debug", this.moduleName)
    WriteDebug("HTTPRequest request Options:", Options, "debug", this.moduleName)

    HTTPRequest(ApiURi , response, Headers, Options)

    WriteDebug("HTTPRequest response HEADER:", Headers, "debug", this.moduleName)
    WriteDebug("HTTPRequest response BODY:", POSTdata, "debug", this.moduleName)

    RegExMatch(response, "\[\""(.+?)\""", match)
    return match1
}
