# ExplorerHotkeys

### Some extra shortcuts for your Windows Filebrowser.

This one was partially ported from the original ac'tivAid ExplorerHotkeys by [Wolfgang Reszel](https://github.com/Tekl).  
If you're missing functionality or have some ideas: [Please open an issue](https://github.com/ewerybody/a2.modules/issues/new/?labels=mod:ExplorerHotkeys).

* ### Call Explorer with a predefined path <kbd>Win+E</kbd>
  The standard "Open Explorer" shortcut brings you to the "This PC" space,
  well here you can **override** that with any directory you please.
  
* ### Toggle Hidden Items <kbd>Ctrl+H</kbd>
  Turns the visibility of **Hidden Items** on/off accordinhg to the current state.
  
  This is usually a little buried in the Ribbon. And if you don't have the Ribbon showing. I'd be <kbd>Alt</kbd>, <kbd>V</kbd>, <kbd>HH</kbd> ...  
  Now this one you can have at whatever shortcut.
  
  > **Note**: There is an issue when the toggling is not visually happening. This might happen when the main file item box of the Explorere dos NOT hava focus.
  > It turns the variables in the background tho! A refresh is sent but not received by this central box. You can click into the center in this case and hit F5 to see the change.
  > Also note that this is about the Explorere setting and does **not change** attributes on selected files.

* ### Toggle File Extensions <kbd>Ctrl+E</kbd>
  Turns the visibility of **File name extensions** on/off accordinhg to the current state.
  
  That'd be <kbd>Alt</kbd>, <kbd>V</kbd>, <kbd>HF</kbd> on the Ribbon.
  
  > **Note**: The same **focus issue** from before applies to this one!

* ### Browse Forward/Backward on MouseWheel <kbd>Shift+WheelUp/Down</kbd>
  Don't have Forward/Back-buttons on your mouse? This might be for you! Since this shortcut is also implemented in some other apps.
  
* ### from FTP-Explorer get http-url into Clipboard <kbd>Alt+V</kbd>
  If you also use the Explorer for browsing files on your FTP this might be a nice shortcut for turning selected items there into http-links that you can paste into your code, some emails, messages for sharing of whatnot...
  
* ### Toggle Navigation Panel (Experimental) <kbd>Alt+N</kbd>
  > Note: Sadly this one does not work so well. There seems to be no variable that we can trigger and refresh the Explorer view. So we literally try to mimic going through the Ribbon shortcuts. Since it depends on delays of certain ui elements to appear is't not always successful.

* ### Go "Up" instead of Back
  Make your "Back-Button" go up a directory instead of back in the browsing history.
  
* ### Reload Explorer process & windows <kbd>Win+Shift+E</kbd>
  If you need to restart the Explorer-process completely or want to remove duplicates from all your open Explorers:
  Looks up the current paths of all open Explorer windows, closes all running processes and re-opens an Explorer for each found path.
