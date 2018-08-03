 ; Some initial comment ...
#IfWinActive,
:*:aucgh::auch ; a comment!
:*:machne::machen
:*b0o:irg.::endwie
; 1-line code blocks
:*:.lrg::
    msgbox 👋!
return
::xxx::s👍👍{!} ;needs to be un-escaped
:*:shcon::schon
:*C:aA::ac'tivAid
:*::flip::(╯°□°)╯︵ ┻━┻
::Strala::Stråla
:*:nat.::natürlich
:r:.raw::Raw Rest{!}
; multi line code blocks
::#code::
    MsgBox CodeTest!
    MsgBox works!
return
:*x:#code2::MsgBox CodeTest2 works2! ; inline code hotstring
:*::ck::✔
::gruse::grüße
:*:::dd::ColonDouble`: ; `: also needs un-escaping
#IfWinActive, ahk_class Notepad++ ; will be ignored
#IfWinActive ahk_class Chrome_WidgetWin_1
:C:AHK::Autohotkey
#IfWinActive, ahk_class SWT_Window0 ; test same hotkeys in different scopes
:C:AHK::Autohotkey in Eclipse{!}{!}

#IfWinNotActive, ; empty WinNotActive defaults to global
::.sx::SomeHotstring
