# WebTools

Snippets to work with your selection for things on the internet...

### html tools menu <kbd>Ctrl+Alt+H</kbd>
* a - enclose with HTML hyperlink code like `<a href=https://github.com>asd</a>`  
  **Note**: This one has some special behavior:
  * with URL in clipboard this will put the URL into the `href` argument
  * with text selected the text goes between the `> <`.
  * A selected URL will also put it to the `href` argument and put your cursor between the `>|<`.
* b - Enclose with `<b>` tags for **bold**/fat or **strong** text.
* i - Enclose with `<i>` tags for *italic* or slanted text.
* li - Enclose with `<li>` tags for making "list items".
* img - Wrap **image tag** around, put selected text to `src` argument like `<img src=https://placekitten.com/g/200/300 />`
* testHTML - Copy your selected code to a `testHTML.html` file in your temp directory and run it with your default browser.
* encodeURI - Replace non-letter-non-number characters with percentage notation. For instance "space" is `%20`
  `https://github.com/ewerybody/a2.modules` -> `https%3A%2F%2Fgithub%2Ecom%2Fewerybody%2Fa2%2Emodules`

### bbCode & forum stuff menu <kbd>Ctrl+Alt+B</kbd>
* IMG - similar to the ing-HTML function ^ this makes BBCode style image notation. `[IMG]https://placekitten.com/g/200/300[/IMG]`
* URL - enclose with hyperlink BBCode like `[URL=https://github.com]fafas[/URL]`
  **Note**: This also has some special behavior:
  * with URL in clipboard this will put the URL a the `URL=` argument
  * with text selected the text goes between the `][`.
  * A **selected URL** will also put it to the `URL=` argument and put your cursor between the `]|[`.
* QUOTE - Enclose with `[QUOTE]` tags to make replies.
* B - Enclose with `[B]` tags to make **bold**/fat or **strong** text.
* `<kbd>` - Enclose with `<kbd>` tags to display a keyboard shortcut (This is one for **GitHub**! No idea where else this works)

