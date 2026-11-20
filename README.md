# NowYouSee.md

A small Markdown viewer and editor for Windows. It opens on the rendered page. **View** and
**Edit** switch in place on the same text, and the file is written only when you save.

## Use it

Open a Markdown file, drop one onto the window, or pass one on the command line:

```
NowYouSee.exe notes.md
```

- **View** shows the rendered page. Web links open in your browser. A link to another
  Markdown file opens that file here.
- **Edit** shows the source. Markdown syntax is drawn in blue and your own words in black, so
  the marks are easy to tell from the text. Code has a shaded background.
- Switching keeps your place: Edit opens at the part of the page you were reading, and View
  scrolls to the line you were editing.
- The inline buttons (bold, italic, code, link) wrap the selection. The block buttons
  (headings, quote, lists, task) mark whole lines at the start of the line, wherever the caret
  is, and take the mark off again if every line already has it.
- Files are read as UTF-8, or UTF-16 when they say so. A file that is not valid UTF-8 is read
  as ANSI, the Windows code page. Saving keeps the file's encoding, line endings, and byte
  order mark. The status bar shows the encoding.
- Each save keeps the previous version beside the file as `<name>.bak`.
- If another program changes the open file, it is read again, at the same place. If you have
  unsaved edits, you are asked first.

| Key | Action |
|---|---|
| Ctrl+E | Switch between View and Edit |
| Ctrl+O | Open |
| Ctrl+S | Save |
| Ctrl+Shift+S | Save as |
| Tab / Shift+Tab | Indent / unindent the selected lines |
| Ctrl+mouse wheel | Zoom the page in View |

Settings are kept in `%APPDATA%\NowYouSee\settings.json`: the theme (`light` or `dark`), the
zoom, and where the window was. The file is created on first run.

## Build it

Delphi 12 or later, with the VCL and the Win64 compiler.

```
powershell -ExecutionPolicy Bypass -File tools\build-delphi.ps1
```

The script fetches the two third-party pieces that are not in this repository (see below),
builds `src\delphi\NowYouSee.dproj`, and leaves `NowYouSee.exe` with `WebView2Loader.dll`
beside it in `src\delphi\Win64\Release`. Add `-Config Debug` for a debug build.

To build in the IDE, run `tools\fetch-nocommit.ps1` once, then open
`src\delphi\NowYouSee.dproj`. Nothing needs installing into the IDE: the editor control is
created in code, and the project finds its source by search path.

The script looks for Delphi 12 (Studio 23.0) and then Delphi 13 (Studio 37.0) under
`Program Files (x86)`. The command-line build was verified on Delphi 13.

The program needs the Microsoft Edge WebView2 Runtime to show the rendered page. Windows 11
has it. Without it, Edit still works.

## What is in this repository

| Path | What it is | License |
|---|---|---|
| `src/delphi` | The program: the form, the button drawing, the Markdown highlighter | MIT, ours |
| `src/core` | Settings, the document, the edit commands, Markdown to HTML. No VCL in these units. | MIT, ours |
| `src/markdown` | [MarkdownProcessor](https://github.com/EtheaDev/MarkdownProcessor) by Ethea S.r.l., an unmodified copy | Apache 2.0 |
| `tools` | The build and fetch scripts | MIT, ours |

Two more pieces are needed to build, and are deliberately **not** in this repository. They
are downloaded into `no-commit/`, which git ignores:

| Piece | What it is | License | Why it is not committed |
|---|---|---|---|
| [TurboPack SynEdit](https://github.com/TurboPack/SynEdit) | The edit control | MPL 1.1 | A large upstream project under a different license. We compile it unmodified from a pinned commit. |
| `WebView2Loader.dll` | Microsoft's loader for the WebView2 Runtime | BSD-3-Clause | A binary. |

Also used, and part of Delphi rather than this repository: the VCL, including `TEdgeBrowser`.

Where to read more:

- [DEPENDENCIES.md](DEPENDENCIES.md): what is in `no-commit/`, the pinned versions, and how to fetch it.
- [CREDITS.md](CREDITS.md): the third-party notices. This file goes with any copy of the program you give away.
- [license-info/LICENSES.md](license-info/LICENSES.md): the rules this repository follows for third-party code.

## License

[MIT](LICENSE) for everything written here. Third-party code keeps its own license, as listed
above. Provided as is, without warranty of any kind.
