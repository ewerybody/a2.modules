# A user interface for Autohotkeys typing activated string replacements or command triggering.

from the original Autohotkey Hotstrings documentation - [**autohotkey.com/docs/Hotstrings**](https://autohotkey.com/docs/Hotstrings.htm):
> Although hotstrings are mainly used to expand abbreviations as you type them (auto-replace), they can also be used to launch any scripted action. In this respect, they are similar to hotkeys except that they are typically composed of more than one character (that is, a string).

**a2.modules HotStrings** enables you to do almost everything the original implementation does from an editor ui without hacking any code.

  * Gather and arrange Hotstrings in groups
  * Add and edit scopes of groups
    * to make them work context sensitively in- or excluding certain application windows.
  * rename or deactivate groups
  * Import/Export Hotstrings
    * to or from JSON or Autohotkey code

![image](https://user-images.githubusercontent.com/218956/119238088-b4c45980-bb40-11eb-9dff-a7f00ded3dc0.png)

In the **simplest form** a replacement is triggered by typing a new abbreviation word and "ending" it.<br>
That's usually a press of <kbd>Space</kbd> or <kbd>Enter</kbd> but also by any punctuation.

### Options:

Pretty much whats [documented for the original functionality](https://autohotkey.com/docs/Hotstrings.htm#Options):

* **Triggered Immediately** - makes the replacement appear as soon as the last letter of the abbreviation was typed. `*`

* **Ignore Characters Causing Replacement** - will make the triggering keys like the bespoke "press of <kbd>Space</kbd> or <kbd>Enter</kbd> but also any puntuation" to not be actually written. They will cause the activation but they will not be visible. `O`

* **Replace Inside Words** - makes the replacement appear although you did not type a new word. Usually when you're typing along it will make Hotstrings stop looking for matches and kick back in as soon as you start a new word. `?`

* **Don't Replace Abbreviation, Just append** - turns off "automatic backspacing". The abbreviation is usually erased and replaced with the replacement text. With this the replacement will be just typed right after the abbreviation. `B0`

* **Mode**
  * **a2 default escape "!+^#"** - To type more easily in the Hotstrings user interface [these modifier symbols](https://autohotkey.com/docs/commands/Send.htm#specialchars) are escaped for you in the background but commands like `{Enter}` will still work.
  * **Execute as Autohotkey code** - Will run the replacement string as Autohotkey script. Can also be multiple lines.<br>
    **Be careful!** Invalid code will prevent the reloading of the a2 runtime!<br>
    But you'll be back online as soon as your code is fixed!
  * **Let !+^# press Alt, Shift, Ctrl, Win** - The actual original mode of Hotstrings.
  * **Raw - Control-Characters as Plain Text** - Will cause nothing than writing the raw replacement.
  * **Text - new. Similar to raw mode** - See the [send documentation](https://autohotkey.com/docs/commands/Send.htm#SendText) for more.

* **Case**
  * **Forward to text** - A kind of smart case handling. Will keep the replacement written lower case if abbreviation is lower case/Capitalize the first letter of the replacement if abbreviation is typed with first letters upper case/Makes the replacement ALL CAPS if abbreviation is typed all upper case.
  * **Sensitive** makes the Hotstring ONLY work if the exact cased abbreviation is typed.
  * **Keep Original** is triggered by any casing of the abbreviation but always writes the replacement as is.

* **Send Method**
  * **Default** does not specify the send method for the Hotstring
  * **SendInput**, **SendPlay**, **SendEvent** will make the Hotstring use the specified Send method.<br>
  
  Please also see [the Autohotkey documentation](https://autohotkey.com/docs/Hotstrings.htm#SendMode) about SendModes.
