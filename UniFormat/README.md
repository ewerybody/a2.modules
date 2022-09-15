# UniFormat

### Find and Replace in selected text with sets from the huge unicode repository.

Docs `WIP`

usage:
* Select some text
* press Main UniFormat hotkey (default <kbd>Win+Shift+U</kbd>)
* select a set
* 𝓥𝓸𝓲𝓵𝓪!

Set up a "**Format with ... directly**" hotkey to apply that set directly to a selection without any more steps.

The **տiCr㎲h** set is basically [htwins's **Unicrush**](https://htwins.net/unicrush) ported to an a2 Autohotkey module. Lots of Kudos! 🙇‍♀️
In fact **this WHOLE thing** went off from the Unicrush idea and extrapolated to an arbitrary number of sets for finding/replacing.
This isn't even constrained to Unicode at all! One could set up any list of strings to find with strings to be replaced ... (maybe find swear words and replace them with emojis or whatever ...)
Making the huge amount of untapped latin unicode characters more accessible was just the most fun application. Sure lets do more!

For suggestions or bug reports please [file a **UniFormat** issue](https://github.com/ewerybody/a2.modules/issues/new?labels=mod%3AUniFormat). Thank you!

### remarks

Making these replacements went through quite some underlying problems. Generally it's
like:
* get selected text
* Go through list of search, replace character pairs,
* for each: look for character `a` replace it with `b`
* paste changed text

Simple right? Well ...

#### The 'dictionaries'.

In Python dictionaries are super useful, well embedded and understood. For me
it still feels like "objects" how they are called (or associative arrays) are kind
of new to Autohotkey. And they carry some weirdness that shines when you want to
do something like this here! For instance Case-Insensitivity! In Autohotkey: `d["a"]` will point to the same as `d["A"]` so having them as a key/value data structure for search/replace pairs is out of question because we surely want to have different things based on upper and lower case versions of what we search for.

Finally the internal data structure used for these pairs are now 2 lists (or simple arrays) where one index points either search or replace string.

#### 69 problems

With the `StrReplace` function Autohotkey can conveniently put strings to all occurences of another string. Now in the most cases it's good to make use of built-in
functions like these as much as possible. But now look at our [flipped](https://github.com/ewerybody/a2.modules/blob/master/UniFormat/sets/flipped.txt)-set!
We go search one pair by one and replace. For instance all `t` become `ʇ` (thats not on MY keyboard!) but conveniently `b` for instance can simply become `q`. There is more!: `p>d`, `n>u` and famously `6>9`.
Now when you replaced all `b` with `q` what do you do with all the `q`s?
Of course these used to be replaced with `b` again because we didn't keep track
of anything and just brute replaced all.
Finding these pairs of replacements that appear in searches was easy but how to do "smart" `StrReplace`? We can't even just go through the whole selection char by
char because we want to (and DO already) support multi char replacements. Just
remembering the positions and then replace only these may also break because lengths
could have changed.
Replacing with some `%%%x%%%` placeholder and then replace again afterwards also
seems shaky. What if the placeholder already exists?!