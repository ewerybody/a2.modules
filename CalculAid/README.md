# CalculAid

A configurable Calculator opener.

Press a shortcut <kbd>**Ctrl+Alt+R**</kbd> (default).\
and have a Calculator at your fingertips. With options to:

* Make it appear under your mouse pointer.
* Make it **Always On Top** so its not obstructed by other windows.
* Focus already opened one/create new if none available or focussed. (contriburor idea! 🙏)

And make it close by <kbd>Esc</kbd> if wanted. *

### Future ideas

We used to take selected numbers and "open them" in a Calculator. That'd be nice to re-implement.

### * remarks

Detecting this Calculator window is surely something since Windows 10... Well it once used to be like call `calc.exe` and the `pid` you get is the app and its still `calc.exe` with a dedicated class. Now MS introduced their `ApplicationFrameHost` and the new shiny Calculator makes good use of it. You still call `calc.exe` but the pid you get from it wont be the one on the resulting window. This will be just the same class and executable and pid as ALL running `ApplicationFrameHost` windows. Like the Settings Window (Win+I) for instance. So far the ONLY way to get the dedicated handle seems to be from the window title. But yeah: that depends on the language you have set. So thats:
* Calculator for english
* Rechner for german
* ...
 
feel free to contribute more :)\
_Thanks already!_


