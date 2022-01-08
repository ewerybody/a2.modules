# CommandLine

Connects Explorer and CommandLine Console/Terminal and adds simple closing functionality.

### Close commandline window

Some keys you might want to use to get rid of the CommandLine/Console/Terminal window.
* <kbd>Ctrl+W</kbd> - The **standard** "Close Window" shortcut now also for these.
* <kbd>Escape</kbd> - Extra quickly away with these windows. Off by default. Be careful this might be a little too quick.
* <kbd>Alt+F4</kbd> - Might be Windows solved this one already on it's own. This actually didn't work once. So its off by default now.


### Open Up from Explorer <kbd>Win+C</kbd> (on Explorer windows)

Opens up a CommandLine/Console/Terminal window with the current path active.

### Use Explorer Address bar as commandline interface.

<kbd>WIP</kbd> This replicates the behavior of the old ac'tivAid "CommandLine" extension:
* Type `<` or `<<` as the first characters
* append any commandline action
* Hit Enter to perform on the currently active Explorer path.

Where `<` means execute with visible commandline window and `<<` will just perform the action and leave no commandline window open.

For Example: If you have ImageMagick installed and want to convert an image in your active Explorer window:
```
<< magick some_image.gif some_image.png
```
Will perform the command hidden without you having to open up the path in cmd, goto the path, execute the command, and close the cmd window again.

Note: Contrary to the actual commandline window there is no such auto-completion Explorer adress bar. But this wouldn't be impossible to pull of. If you want this or have ideas about it please [file a **CommandLine** issue](https://github.com/ewerybody/a2.modules/issues/new?labels=mod%3ACommandLine) and lets chat!
