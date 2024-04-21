 ; Some initial comment ...
#HotIf
:*:aucgh::auch ; a comment!
:*:machne::machen
:*b0o:irg.::endwie
; 1-line code blocks
:*:.lrg::
{
    msgbox "👋!"
}
::xxx::s👍👍{!} ;needs to be un-escaped
:*:shcon::schon
::arent::aren't
::Strala::Stråla
:*:nat.::natürlich
:r:.raw::Raw Rest{!}
; multi line code blocks
::#code::
{
    MsgBox "CodeTest!"
    MsgBox "works!"
}
:*x:#code2::MsgBox "CodeTest2 works2!" ; inline code hotstring
:*::ck::✔
::gruse::grüße
:*:::dd::ColonDouble`: ; `: also needs un-escaping
#HotIf WinActive("ahk_class Notepad++") ; will be ignored
#HotIf WinActive("ahk_class Chrome_WidgetWin_1")
; test same hotkeys in different scopes
:C:AHK::Autohotkey
:*C:aA::ac'tivAid
#HotIf WinActive("ahk_class MozillaWindowClass")
:Ct:aA::ACTIVEAID!!
#HotIf !WinActive("ahk_class Notepad++")
:*::flip::(╯°□°)╯︵ ┻━┻
#HotIf WinActive("ahk_class SWT_Window0")
:C:AHK::Autohotkey in Eclipse{!}{!}

#HotIf ; empty WinNotActive defaults to global
::.sx::SomeHotstring
