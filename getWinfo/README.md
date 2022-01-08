# getWinfo

### A quick window information getter.

Press the **hotkey**. (<kbd>**Win+Shift+W**</kbd> by default)\
Get a **menu** with stats about the currently active window.\
**Click** and entry to copy a value.\

> ![example](https://i.imgur.com/pXwhkrp.png)

All these **lowercase** ones can be **clicked** to get their **value into the clipboard**:
- **title**: The [window title](https://www.autohotkey.com/docs/misc/WinTitle.htm) no matter if visible or not.
- **class**: The [class name of the window](https://www.autohotkey.com/docs/misc/WinTitle.htm#ahk_class).
- **hwnd**: [window handle](https://en.wikipedia.org/wiki/Handle_(computing)).
- **pid**: The windows [Process ID](https://www.autohotkey.com/docs/misc/WinTitle.htm#ahk_pid).
- **process**: The process executable name.
- **version**: Version info of the executable.
- **path**: The path to the executable.

The other options do some different things:
- **Explore to path** - Opens up the Windows Explorer with the executable selected.
- **Controls...** - Window controls information (if available).
- **Copy All Control Info** - Will loop over all available window components and assemble a text with their info<br>
like `WindowName WindowHandle WindowText` one line per control.
- **Pos** - A submenu with the windows topleft x/y position, width/height dimensions and an option to bring the window to the current cursor positon (In case it went off the screen)
- **Cancel** - Dismisses the menu.

[file a **getWinfo** issue](https://github.com/ewerybody/a2.modules/issues/new?labels=mod%3AgetWinfo)
